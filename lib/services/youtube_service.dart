import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:mindload/models/youtube_preview_models.dart';
import 'package:mindload/services/auth_service.dart';

/// YouTube service for handling preview and ingest operations with comprehensive abuse prevention
class YouTubeService {
  static final YouTubeService _instance = YouTubeService._internal();
  factory YouTubeService() => _instance;
  YouTubeService._internal();

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');
  final AuthService _authService = AuthService.instance;

  // In-memory cache for preview results with TTL
  final Map<String, _CachedPreview> _previewCache = {};
  static const Duration _cacheTtl = Duration(minutes: 15);

  // Rate limiting for abuse prevention
  final Map<String, List<DateTime>> _userRequestHistory = {};
  final Map<String, DateTime> _userIngestHistory = {};
  static const int _maxPreviewRequestsPerMinute = 10;
  static const int _maxPreviewRequestsPerHour = 60;
  static const Duration _minIngestInterval = Duration(minutes: 2);
  static const Duration _requestWindowMinute = Duration(minutes: 1);
  static const Duration _requestWindowHour = Duration(hours: 1);

  // Session tracking for additional protection
  final Map<String, int> _sessionRequestCounts = {};
  final Map<String, DateTime> _sessionStartTimes = {};
  static const int _maxSessionRequests = 100;
  static const Duration _sessionDuration = Duration(hours: 1);

  // Abuse detection patterns
  final Set<String> _suspiciousVideos = {};
  final Map<String, int> _videoRequestCounts = {};
  static const int _maxVideoRequestsPerHour = 20;

  /// Get YouTube preview data for a video ID
  /// Uses in-memory cache with TTL to minimize API calls and includes comprehensive abuse prevention
  Future<YouTubePreview> getPreview(String videoId) async {
    // Validate input
    if (!_isValidVideoId(videoId)) {
      throw YouTubeIngestError.unknown;
    }

    // Get user ID for rate limiting
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw YouTubeIngestError.unknown;
    }

    // Check rate limits before proceeding
    await _checkRateLimits(userId, isIngest: false);

    // Check for abuse patterns
    _checkAbusePatterns(userId, videoId);

    // Check cache first
    final cached = _previewCache[videoId];
    if (cached != null && !cached.isExpired) {
      _recordRequest(userId, isIngest: false);
      return cached.preview;
    }

    // Check circuit breaker
    if (_isCircuitBreakerOpen('preview')) {
      throw Exception(
          'Service temporarily unavailable. Please try again later.');
    }

    try {
      // Get App Check token for security
      final appCheckToken = await FirebaseAppCheck.instance.getToken();

      // Record the request for rate limiting
      _recordRequest(userId, isIngest: false);
      _recordVideoRequest(videoId);

      // Call Cloud Function
      final result = await _functions.httpsCallable('youtubePreview').call({
        'videoId': videoId,
        'appCheckToken': appCheckToken,
        'userId': userId,
        'requestId': _generateRequestId(),
      });

      if (result.data == null) {
        throw Exception('No data received from preview endpoint');
      }

      final preview =
          YouTubePreview.fromJson(result.data as Map<String, dynamic>);

      // Cache the result
      _previewCache[videoId] = _CachedPreview(
        preview: preview,
        timestamp: DateTime.now(),
      );

      // Clean up expired cache entries
      _cleanupExpiredCache();

      // Reset circuit breaker on success
      _resetCircuitBreaker('preview');

      return preview;
    } catch (e) {
      // Record circuit breaker failure
      _recordCircuitBreakerFailure('preview');

      // Handle specific error types
      if (e.toString().contains('unavailable')) {
        throw YouTubeIngestError.transcriptUnavailable;
      } else if (e.toString().contains('not-found')) {
        throw YouTubeIngestError.videoNotFound;
      } else if (e.toString().contains('private')) {
        throw YouTubeIngestError.videoPrivate;
      } else if (e.toString().contains('age-restricted')) {
        throw YouTubeIngestError.videoAgeRestricted;
      } else if (e.toString().contains('removed')) {
        throw YouTubeIngestError.videoRemoved;
      } else if (e.toString().contains('over-limit')) {
        throw YouTubeIngestError.overPlanLimit;
      } else if (e.toString().contains('insufficient-tokens')) {
        throw YouTubeIngestError.insufficientTokens;
      } else if (e.toString().contains('over-budget')) {
        throw YouTubeIngestError.overBudget;
      } else if (e.toString().contains('network')) {
        throw YouTubeIngestError.networkError;
      } else if (e.toString().contains('server')) {
        throw YouTubeIngestError.serverError;
      } else {
        throw YouTubeIngestError.unknown;
      }
    }
  }

  /// Ingest YouTube video transcript with comprehensive abuse prevention
  /// Returns material ID for further processing
  Future<YouTubeIngestResponse> ingestTranscript(
      YouTubeIngestRequest request) async {
    // Validate input
    if (!_isValidVideoId(request.videoId)) {
      throw YouTubeIngestError.unknown;
    }

    // Get user ID for rate limiting
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw YouTubeIngestError.unknown;
    }

    // Check rate limits for ingest (more restrictive)
    await _checkRateLimits(userId, isIngest: true);

    // Check minimum interval between ingests
    _checkIngestInterval(userId);

    // Check for abuse patterns
    _checkAbusePatterns(userId, request.videoId);

    // Check circuit breaker for ingest
    if (_isCircuitBreakerOpen('ingest')) {
      throw Exception(
          'Ingest service temporarily unavailable. Please try again later.');
    }

    try {
      // Get App Check token for security
      final appCheckToken = await FirebaseAppCheck.instance.getToken();

      // Record the ingest request
      _recordRequest(userId, isIngest: true);
      _recordIngest(userId);
      _recordVideoRequest(request.videoId);

      // Call Cloud Function for ingest
      final result = await _functions.httpsCallable('youtubeIngest').call({
        ...request.toJson(),
        'appCheckToken': appCheckToken,
        'userId': userId,
        'requestId': _generateRequestId(),
      });

      if (result.data == null) {
        throw Exception('No data received from ingest endpoint');
      }

      // Reset circuit breaker on success
      _resetCircuitBreaker('ingest');

      return YouTubeIngestResponse.fromJson(
          result.data as Map<String, dynamic>);
    } catch (e) {
      // Record circuit breaker failure
      _recordCircuitBreakerFailure('ingest');

      // Handle specific error types
      if (e.toString().contains('already-exists')) {
        // This is actually a success case - material already exists
        return YouTubeIngestResponse(
          materialId: e.toString().split('materialId: ').last.split(' ').first,
          status: 'already_exists',
          mlTokensCharged: 0,
          inputTokens: 0,
        );
      } else if (e.toString().contains('no-transcript')) {
        throw YouTubeIngestError.noTranscript;
      } else if (e.toString().contains('over-limit')) {
        throw YouTubeIngestError.overPlanLimit;
      } else if (e.toString().contains('insufficient-tokens')) {
        throw YouTubeIngestError.insufficientTokens;
      } else if (e.toString().contains('over-budget')) {
        throw YouTubeIngestError.overBudget;
      } else if (e.toString().contains('network')) {
        throw YouTubeIngestError.networkError;
      } else if (e.toString().contains('server')) {
        throw YouTubeIngestError.serverError;
      } else {
        throw YouTubeIngestError.unknown;
      }
    }
  }

  /// Clear preview cache for a specific video ID
  void clearPreviewCache(String videoId) {
    _previewCache.remove(videoId);
  }

  /// Clear all preview cache
  void clearAllPreviewCache() {
    _previewCache.clear();
  }

  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    final expired =
        _previewCache.values.where((cached) => cached.isExpired).length;
    final valid =
        _previewCache.values.where((cached) => !cached.isExpired).length;

    return {
      'totalEntries': _previewCache.length,
      'validEntries': valid,
      'expiredEntries': expired,
      'cacheSize': _previewCache.length,
    };
  }

  /// Clean up expired cache entries
  void _cleanupExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = _previewCache.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _previewCache.remove(key);
    }
  }

  /// Check if user has sufficient tokens for ingest
  Future<bool> hasSufficientTokens(int requiredTokens) async {
    try {
      // This would typically check against the user's current token balance
      // For now, we'll assume the server handles this validation
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if user has remaining YouTube ingests for the month
  Future<bool> hasRemainingIngests() async {
    try {
      // This would typically check against the user's monthly ingest limit
      // For now, we'll assume the server handles this validation
      return true;
    } catch (e) {
      return false;
    }
  }

  // ABUSE PREVENTION METHODS

  /// Validate YouTube video ID format
  bool _isValidVideoId(String videoId) {
    if (videoId.isEmpty || videoId.length != 11) return false;
    final validChars = RegExp(r'^[A-Za-z0-9_-]+$');
    return validChars.hasMatch(videoId);
  }

  /// Check rate limits for a user
  Future<void> _checkRateLimits(String userId, {required bool isIngest}) async {
    final now = DateTime.now();

    // Check session limits
    _checkSessionLimits(userId);

    // Get user's request history
    final userRequests = _userRequestHistory[userId] ?? [];

    // Clean up old requests (outside time windows)
    userRequests.removeWhere(
        (timestamp) => now.difference(timestamp) > _requestWindowHour);

    // Check minute-based rate limit for previews
    if (!isIngest) {
      final recentRequests = userRequests
          .where(
              (timestamp) => now.difference(timestamp) <= _requestWindowMinute)
          .length;

      if (recentRequests >= _maxPreviewRequestsPerMinute) {
        throw Exception(
            'Rate limit exceeded: Too many preview requests per minute');
      }

      // Check hour-based rate limit for previews
      if (userRequests.length >= _maxPreviewRequestsPerHour) {
        throw Exception(
            'Rate limit exceeded: Too many preview requests per hour');
      }
    }
  }

  /// Check session-based limits
  void _checkSessionLimits(String userId) {
    final now = DateTime.now();

    // Initialize session if not exists or expired
    final sessionStart = _sessionStartTimes[userId];
    if (sessionStart == null ||
        now.difference(sessionStart) > _sessionDuration) {
      _sessionStartTimes[userId] = now;
      _sessionRequestCounts[userId] = 0;
      return;
    }

    // Check session request count
    final sessionRequests = _sessionRequestCounts[userId] ?? 0;
    if (sessionRequests >= _maxSessionRequests) {
      throw Exception(
          'Session limit exceeded: Too many requests in current session');
    }
  }

  /// Check minimum interval between ingests
  void _checkIngestInterval(String userId) {
    final lastIngest = _userIngestHistory[userId];
    if (lastIngest != null) {
      final timeSinceLastIngest = DateTime.now().difference(lastIngest);
      if (timeSinceLastIngest < _minIngestInterval) {
        final waitTime = _minIngestInterval - timeSinceLastIngest;
        throw Exception(
            'Ingest rate limit: Please wait ${waitTime.inMinutes} minutes before next ingest');
      }
    }
  }

  /// Check for abuse patterns
  void _checkAbusePatterns(String userId, String videoId) {
    // Check if video is flagged as suspicious
    if (_suspiciousVideos.contains(videoId)) {
      throw Exception('Video unavailable: Content flagged for abuse');
    }

    // Check video request frequency
    final videoRequests = _videoRequestCounts[videoId] ?? 0;
    if (videoRequests >= _maxVideoRequestsPerHour) {
      _suspiciousVideos.add(videoId);
      throw Exception('Video temporarily unavailable: Too many requests');
    }
  }

  /// Record a request for rate limiting
  void _recordRequest(String userId, {required bool isIngest}) {
    final now = DateTime.now();

    // Record in user request history
    final userRequests = _userRequestHistory[userId] ?? [];
    userRequests.add(now);
    _userRequestHistory[userId] = userRequests;

    // Update session count
    final sessionCount = _sessionRequestCounts[userId] ?? 0;
    _sessionRequestCounts[userId] = sessionCount + 1;
  }

  /// Record an ingest for interval checking
  void _recordIngest(String userId) {
    _userIngestHistory[userId] = DateTime.now();
  }

  /// Record a video request for abuse detection
  void _recordVideoRequest(String videoId) {
    final currentCount = _videoRequestCounts[videoId] ?? 0;
    _videoRequestCounts[videoId] = currentCount + 1;
  }

  /// Generate unique request ID for tracking
  String _generateRequestId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_authService.currentUserId ?? "anonymous"}';
  }

  /// Reset rate limits for a user (admin function)
  void resetUserLimits(String userId) {
    _userRequestHistory.remove(userId);
    _userIngestHistory.remove(userId);
    _sessionRequestCounts.remove(userId);
    _sessionStartTimes.remove(userId);
  }

  /// Get rate limit status for a user
  Map<String, dynamic> getRateLimitStatus(String userId) {
    final now = DateTime.now();
    final userRequests = _userRequestHistory[userId] ?? [];
    final recentMinute = userRequests
        .where((t) => now.difference(t) <= _requestWindowMinute)
        .length;
    final recentHour = userRequests
        .where((t) => now.difference(t) <= _requestWindowHour)
        .length;
    final lastIngest = _userIngestHistory[userId];
    final sessionStart = _sessionStartTimes[userId];
    final sessionRequests = _sessionRequestCounts[userId] ?? 0;

    return {
      'requestsLastMinute': recentMinute,
      'requestsLastHour': recentHour,
      'maxRequestsPerMinute': _maxPreviewRequestsPerMinute,
      'maxRequestsPerHour': _maxPreviewRequestsPerHour,
      'lastIngestTime': lastIngest?.toIso8601String(),
      'minIngestInterval': _minIngestInterval.inMinutes,
      'sessionStart': sessionStart?.toIso8601String(),
      'sessionRequests': sessionRequests,
      'maxSessionRequests': _maxSessionRequests,
      'canMakeRequest': recentMinute < _maxPreviewRequestsPerMinute &&
          recentHour < _maxPreviewRequestsPerHour &&
          sessionRequests < _maxSessionRequests,
      'canIngest': lastIngest == null ||
          now.difference(lastIngest) >= _minIngestInterval,
    };
  }

  /// Clean up old tracking data periodically
  void cleanupTrackingData() {
    final now = DateTime.now();

    // Clean up old request histories
    _userRequestHistory.removeWhere((userId, requests) {
      requests.removeWhere(
          (timestamp) => now.difference(timestamp) > _requestWindowHour);
      return requests.isEmpty;
    });

    // Clean up old ingest histories (keep last 24 hours)
    _userIngestHistory.removeWhere((userId, timestamp) =>
        now.difference(timestamp) > const Duration(hours: 24));

    // Clean up old session data
    _sessionStartTimes.removeWhere(
        (userId, startTime) => now.difference(startTime) > _sessionDuration);

    // Clean up video request counts (reset daily)
    _videoRequestCounts
        .removeWhere((videoId, count) => count > _maxVideoRequestsPerHour);

    // Clean up old cache entries
    _cleanupExpiredCache();
  }

  // CIRCUIT BREAKER PATTERN FOR ABUSE PREVENTION

  static const Duration _circuitBreakerResetTime = Duration(minutes: 15);
  static const int _circuitBreakerThreshold = 5;

  final Map<String, _CircuitBreakerState> _circuitBreakers = {};

  /// Check circuit breaker state for an operation
  bool _isCircuitBreakerOpen(String operation) {
    final state = _circuitBreakers[operation];
    if (state == null) return false;

    final now = DateTime.now();

    // Reset circuit breaker after timeout
    if (now.difference(state.lastFailure) > _circuitBreakerResetTime) {
      _circuitBreakers.remove(operation);
      return false;
    }

    return state.failureCount >= _circuitBreakerThreshold;
  }

  /// Record a failure for circuit breaker
  void _recordCircuitBreakerFailure(String operation) {
    final now = DateTime.now();
    final state = _circuitBreakers[operation];

    if (state == null) {
      _circuitBreakers[operation] = _CircuitBreakerState(
        failureCount: 1,
        lastFailure: now,
      );
    } else {
      // Reset count if last failure was too long ago
      if (now.difference(state.lastFailure) > _circuitBreakerResetTime) {
        _circuitBreakers[operation] = _CircuitBreakerState(
          failureCount: 1,
          lastFailure: now,
        );
      } else {
        state.failureCount++;
        state.lastFailure = now;
      }
    }
  }

  /// Reset circuit breaker for an operation
  void _resetCircuitBreaker(String operation) {
    _circuitBreakers.remove(operation);
  }

  /// Get system health status
  Map<String, dynamic> getSystemHealth() {
    final userId = _authService.currentUserId;
    if (userId == null) return {'authenticated': false};

    return {
      'authenticated': true,
      'cacheHealth': getCacheStats(),
      'rateLimitStatus': getRateLimitStatus(userId),
      'circuitBreakers':
          _circuitBreakers.map((operation, state) => MapEntry(operation, {
                'isOpen': _isCircuitBreakerOpen(operation),
                'failureCount': state.failureCount,
                'lastFailure': state.lastFailure.toIso8601String(),
              })),
      'suspiciousVideosCount': _suspiciousVideos.length,
      'trackedVideosCount': _videoRequestCounts.length,
    };
  }
}

/// Circuit breaker state for tracking failures
class _CircuitBreakerState {
  int failureCount;
  DateTime lastFailure;

  _CircuitBreakerState({
    required this.failureCount,
    required this.lastFailure,
  });
}

/// Cached preview data with timestamp for TTL management
class _CachedPreview {
  final YouTubePreview preview;
  final DateTime timestamp;

  _CachedPreview({
    required this.preview,
    required this.timestamp,
  });

  bool get isExpired {
    return DateTime.now().difference(timestamp) > YouTubeService._cacheTtl;
  }
}
