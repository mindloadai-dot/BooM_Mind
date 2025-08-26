import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:mindload/models/youtube_preview_models.dart';
import 'package:mindload/models/atomic_ledger_models.dart';
import 'package:mindload/services/auth_service.dart';
import 'package:mindload/services/enhanced_abuse_prevention_service.dart';
import 'package:mindload/services/atomic_ledger_service.dart';

/// Enhanced YouTube service with resilience and backoff
/// Implements the requirements from Part 4B-4
class EnhancedYouTubeService {
  static final EnhancedYouTubeService _instance = EnhancedYouTubeService._internal();
  factory EnhancedYouTubeService() => _instance;
  EnhancedYouTubeService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  final AuthService _authService = AuthService.instance;
  final EnhancedAbusePrevention _abusePrevention = EnhancedAbusePrevention.instance;
  final AtomicLedgerService _ledgerService = AtomicLedgerService.instance;

  // Configuration constants
  static const List<String> ALLOWED_HOSTS = ['youtube.com', 'youtu.be'];
  static const bool VALIDATE_ID_ENABLED = true;
  static const Duration TRANSCRIPT_BACKOFF_DURATION = Duration(hours: 1);
  
  // In-memory cache for preview results with TTL
  final Map<String, _CachedPreview> _previewCache = {};
  static const Duration _cacheTtl = Duration(minutes: 15);
  
  // Transcript failure tracking for backoff
  final Map<String, _TranscriptFailureRecord> _transcriptFailures = {};
  
  // Rate limiting for abuse prevention
  final Map<String, List<DateTime>> _userRequestHistory = {};
  final Map<String, DateTime> _userIngestHistory = {};
  static const int _maxPreviewRequestsPerMinute = 10;
  static const int _maxPreviewRequestsPerHour = 60;
  static const Duration _minIngestInterval = Duration(minutes: 2);

  /// Get YouTube preview data for a video URL or ID
  /// Validates hosts and implements transcript backoff
  Future<YouTubePreview> getPreview(String videoUrlOrId) async {
    // Validate input and extract video ID
    final videoId = _extractAndValidateVideoId(videoUrlOrId);
    if (videoId == null) {
      throw YouTubeIngestError.invalidUrl;
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

    // Check transcript backoff
    if (_isTranscriptBackoffActive(videoId)) {
      final failureRecord = _transcriptFailures[videoId]!;
      final remainingTime = failureRecord.backoffUntil.difference(DateTime.now());
      
      throw YouTubeIngestError.transcriptUnavailable;
    }

    try {
      // Get App Check token for security
      final appCheckToken = await FirebaseAppCheck.instance.getToken();
      
      // Record the request for rate limiting
      _recordRequest(userId, isIngest: false);
      
      // Call Cloud Function
      final result = await _functions
          .httpsCallable('youtubePreview')
          .call({
        'videoId': videoId,
        'appCheckToken': appCheckToken,
        'userId': userId,
        'requestId': _generateRequestId(),
      });

      if (result.data == null) {
        throw Exception('No data received from preview endpoint');
      }

      final preview = YouTubePreview.fromJson(result.data as Map<String, dynamic>);
      
      // Cache the result
      _previewCache[videoId] = _CachedPreview(
        preview: preview,
        timestamp: DateTime.now(),
      );

      // Clean up expired cache entries
      _cleanupExpiredCache();

      return preview;
    } catch (e) {
      // Handle specific error types
      if (e.toString().contains('transcript-unavailable')) {
        // Record transcript failure for backoff
        _recordTranscriptFailure(videoId);
        throw YouTubeIngestError.transcriptUnavailable;
      } else if (e.toString().contains('video-not-found')) {
        throw YouTubeIngestError.videoNotFound;
      } else if (e.toString().contains('video-private')) {
        throw YouTubeIngestError.videoPrivate;
      } else if (e.toString().contains('video-age-restricted')) {
        throw YouTubeIngestError.videoAgeRestricted;
      } else if (e.toString().contains('video-removed')) {
        throw YouTubeIngestError.videoRemoved;
      } else if (e.toString().contains('over-plan-limit')) {
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

  /// Ingest YouTube video transcript with resilience features
  /// Returns material ID for further processing
  Future<YouTubeIngestResponse> ingestTranscript(YouTubeIngestRequest request) async {
    // Validate video ID
    if (!_isValidVideoId(request.videoId)) {
      throw YouTubeIngestError.invalidUrl;
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

    // Check transcript backoff
    if (_isTranscriptBackoffActive(request.videoId)) {
      final failureRecord = _transcriptFailures[request.videoId]!;
      final remainingTime = failureRecord.backoffUntil.difference(DateTime.now());
      
      throw YouTubeIngestError.transcriptUnavailable;
    }

    try {
      // Get App Check token for security
      final appCheckToken = await FirebaseAppCheck.instance.getToken();
      
      // Record the ingest request
      _recordRequest(userId, isIngest: true);
      _recordIngest(userId);
      
      // Call Cloud Function for ingest
      final result = await _functions
          .httpsCallable('youtubeIngest')
          .call({
        ...request.toJson(),
        'appCheckToken': appCheckToken,
        'userId': userId,
        'requestId': _generateRequestId(),
      });

      if (result.data == null) {
        throw Exception('No data received from ingest endpoint');
      }

      final response = YouTubeIngestResponse.fromJson(result.data as Map<String, dynamic>);
      
      // Log successful ingest to ledger
      if (response.mlTokensCharged > 0) {
        await _logTokenConsumption(userId, response.mlTokensCharged, request.videoId);
      }
      
      return response;
    } catch (e) {
      // Handle specific error types
      if (e.toString().contains('transcript-unavailable')) {
        // Record transcript failure for backoff
        _recordTranscriptFailure(request.videoId);
        throw YouTubeIngestError.transcriptUnavailable;
      } else if (e.toString().contains('already-exists')) {
        // This is actually a success case - material already exists
        return YouTubeIngestResponse(
          materialId: e.toString().split('materialId: ').last.split(' ').first,
          status: 'already_exists',
          mlTokensCharged: 0,
          inputTokens: 0,
        );
      } else if (e.toString().contains('no-transcript')) {
        // Record transcript failure for backoff
        _recordTranscriptFailure(request.videoId);
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

  /// Extract and validate video ID from URL or direct ID
  String? _extractAndValidateVideoId(String videoUrlOrId) {
    // If it's already a video ID, validate it
    if (_isValidVideoId(videoUrlOrId)) {
      return videoUrlOrId;
    }
    
    // Try to extract from URL
    try {
      final uri = Uri.parse(videoUrlOrId);
      
      // Check if host is allowed
      if (!ALLOWED_HOSTS.contains(uri.host)) {
        throw YouTubeIngestError.invalidUrl;
      }
      
      // Extract video ID based on host
      String? videoId;
      if (uri.host == 'youtube.com' && uri.pathSegments.contains('watch')) {
        videoId = uri.queryParameters['v'];
      } else if (uri.host == 'youtu.be') {
        videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      }
      
      // Validate extracted video ID
      if (videoId != null && _isValidVideoId(videoId)) {
        return videoId;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Validate YouTube video ID format
  bool _isValidVideoId(String videoId) {
    if (!VALIDATE_ID_ENABLED) return true;
    
    if (videoId.isEmpty || videoId.length != 11) return false;
    final validChars = RegExp(r'^[A-Za-z0-9_-]+$');
    return validChars.hasMatch(videoId);
  }

  /// Check if transcript backoff is active for a video
  bool _isTranscriptBackoffActive(String videoId) {
    final failureRecord = _transcriptFailures[videoId];
    if (failureRecord == null) return false;
    
    return DateTime.now().isBefore(failureRecord.backoffUntil);
  }

  /// Record transcript failure for backoff
  void _recordTranscriptFailure(String videoId) {
    final now = DateTime.now();
    final backoffUntil = now.add(TRANSCRIPT_BACKOFF_DURATION);
    
    _transcriptFailures[videoId] = _TranscriptFailureRecord(
      videoId: videoId,
      failureCount: (_transcriptFailures[videoId]?.failureCount ?? 0) + 1,
      lastFailure: now,
      backoffUntil: backoffUntil,
    );
    
    // Log transcript failure for monitoring
    _logTranscriptFailure(videoId);
  }

  /// Log transcript failure for monitoring
  void _logTranscriptFailure(String videoId) {
    final failureRecord = _transcriptFailures[videoId]!;
    
    // In a real app, this would log to Firestore or analytics
    print('Transcript failure recorded for video $videoId. '
          'Failure count: ${failureRecord.failureCount}, '
          'Backoff until: ${failureRecord.backoffUntil}');
  }

  /// Check rate limits for a user
  Future<void> _checkRateLimits(String userId, {required bool isIngest}) async {
    final now = DateTime.now();
    
    // Get user's request history
    final userRequests = _userRequestHistory[userId] ?? [];
    
    // Clean up old requests (outside time windows)
    userRequests.removeWhere((timestamp) => 
        now.difference(timestamp) > Duration(hours: 1));
    
    // Check minute-based rate limit for previews
    if (!isIngest) {
      final recentRequests = userRequests.where((timestamp) => 
          now.difference(timestamp) <= Duration(minutes: 1)).length;
      
      if (recentRequests >= _maxPreviewRequestsPerMinute) {
        throw Exception('Rate limit exceeded: Too many preview requests per minute');
      }
      
      // Check hour-based rate limit for previews
      if (userRequests.length >= _maxPreviewRequestsPerHour) {
        throw Exception('Rate limit exceeded: Too many preview requests per hour');
      }
    }
  }

  /// Check minimum interval between ingests
  void _checkIngestInterval(String userId) {
    final lastIngest = _userIngestHistory[userId];
    if (lastIngest != null) {
      final timeSinceLastIngest = DateTime.now().difference(lastIngest);
      if (timeSinceLastIngest < _minIngestInterval) {
        final waitTime = _minIngestInterval - timeSinceLastIngest;
        throw Exception('Ingest rate limit: Please wait ${waitTime.inMinutes} minutes before next ingest');
      }
    }
  }

  /// Check for abuse patterns
  void _checkAbusePatterns(String userId, String videoId) {
    // Check if video is flagged as suspicious
    if (_transcriptFailures[videoId]?.failureCount != null && _transcriptFailures[videoId]!.failureCount >= 5) {
      throw Exception('Video temporarily unavailable: Too many transcript failures');
    }
  }

  /// Record a request for rate limiting
  void _recordRequest(String userId, {required bool isIngest}) {
    final now = DateTime.now();
    
    // Record in user request history
    final userRequests = _userRequestHistory[userId] ?? [];
    userRequests.add(now);
    _userRequestHistory[userId] = userRequests;
  }

  /// Record an ingest for interval checking
  void _recordIngest(String userId) {
    _userIngestHistory[userId] = DateTime.now();
  }

  /// Log token consumption to ledger
  Future<void> _logTokenConsumption(String userId, int tokens, String videoId) async {
    try {
      await _ledgerService.writeLedgerEntry(
        action: 'debit',
        tokens: tokens,
        requestId: _generateRequestId(),
        source: LedgerSource.generate,
        metadata: {
          'videoId': videoId,
          'action': 'youtube_ingest',
        },
      );
    } catch (e) {
      // Log error but don't fail the ingest
      print('Failed to log token consumption: $e');
    }
  }

  /// Generate unique request ID for tracking
  String _generateRequestId() {
    return 'youtube_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
  }

  /// Generate random string for request ID
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(DateTime.now().millisecond % chars.length))
    );
  }

  /// Clear preview cache for a specific video ID
  void clearPreviewCache(String videoId) {
    _previewCache.remove(videoId);
  }

  /// Clear all preview cache
  void clearAllPreviewCache() {
    _previewCache.clear();
  }

  /// Clear transcript failure records for a video
  void clearTranscriptFailures(String videoId) {
    _transcriptFailures.remove(videoId);
  }

  /// Clear all transcript failure records
  void clearAllTranscriptFailures() {
    _transcriptFailures.clear();
  }

  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    final expired = _previewCache.values.where((cached) => cached.isExpired).length;
    final valid = _previewCache.values.where((cached) => !cached.isExpired).length;
    
    return {
      'totalEntries': _previewCache.length,
      'validEntries': valid,
      'expiredEntries': expired,
      'cacheSize': _previewCache.length,
    };
  }

  /// Get transcript failure statistics
  Map<String, dynamic> getTranscriptFailureStats() {
    final now = DateTime.now();
    final activeFailures = _transcriptFailures.values.where(
      (record) => now.isBefore(record.backoffUntil)
    ).length;
    final totalFailures = _transcriptFailures.length;
    
    return {
      'totalFailures': totalFailures,
      'activeFailures': activeFailures,
      'backoffDuration': TRANSCRIPT_BACKOFF_DURATION.inHours,
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

  /// Clean up expired transcript failure records
  void cleanupExpiredTranscriptFailures() {
    final now = DateTime.now();
    final expiredKeys = _transcriptFailures.entries
        .where((entry) => now.isAfter(entry.value.backoffUntil))
        .map((entry) => entry.key)
        .toList();
    
    for (final key in expiredKeys) {
      _transcriptFailures.remove(key);
    }
  }

  /// Get system health status
  Map<String, dynamic> getSystemHealth() {
    final userId = _authService.currentUserId;
    if (userId == null) return {'authenticated': false};
    
    return {
      'authenticated': true,
      'cacheHealth': getCacheStats(),
      'transcriptFailureHealth': getTranscriptFailureStats(),
      'rateLimitStatus': _getRateLimitStatus(userId),
      'allowedHosts': ALLOWED_HOSTS,
      'validateIdEnabled': VALIDATE_ID_ENABLED,
      'transcriptBackoffDuration': TRANSCRIPT_BACKOFF_DURATION.inHours,
    };
  }

  /// Get rate limit status for a user
  Map<String, dynamic> _getRateLimitStatus(String userId) {
    final now = DateTime.now();
    final userRequests = _userRequestHistory[userId] ?? [];
    final recentMinute = userRequests.where((t) => 
        now.difference(t) <= Duration(minutes: 1)).length;
    final recentHour = userRequests.where((t) => 
        now.difference(t) <= Duration(hours: 1)).length;
    final lastIngest = _userIngestHistory[userId];
    
    return {
      'requestsLastMinute': recentMinute,
      'requestsLastHour': recentHour,
      'maxRequestsPerMinute': _maxPreviewRequestsPerMinute,
      'maxRequestsPerHour': _maxPreviewRequestsPerHour,
      'lastIngestTime': lastIngest?.toIso8601String(),
      'minIngestInterval': _minIngestInterval.inMinutes,
      'canMakeRequest': recentMinute < _maxPreviewRequestsPerMinute && 
                       recentHour < _maxPreviewRequestsPerHour,
      'canIngest': lastIngest == null || 
                   now.difference(lastIngest) >= _minIngestInterval,
    };
  }

  /// Reset rate limits for a user (admin function)
  void resetUserLimits(String userId) {
    _userRequestHistory.remove(userId);
    _userIngestHistory.remove(userId);
  }

  /// Clean up old tracking data periodically
  void cleanupTrackingData() {
    final now = DateTime.now();
    
    // Clean up old request histories
    _userRequestHistory.removeWhere((userId, requests) {
      requests.removeWhere((timestamp) => 
          now.difference(timestamp) > Duration(hours: 1));
      return requests.isEmpty;
    });
    
    // Clean up old ingest histories (keep last 24 hours)
    _userIngestHistory.removeWhere((userId, timestamp) => 
        now.difference(timestamp) > Duration(hours: 24));
    
    // Clean up expired cache entries
    _cleanupExpiredCache();
    
    // Clean up expired transcript failure records
    cleanupExpiredTranscriptFailures();
  }
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
    return DateTime.now().difference(timestamp) > EnhancedYouTubeService._cacheTtl;
  }
}

/// Transcript failure record for backoff management
class _TranscriptFailureRecord {
  final String videoId;
  final int failureCount;
  final DateTime lastFailure;
  final DateTime backoffUntil;

  _TranscriptFailureRecord({
    required this.videoId,
    required this.failureCount,
    required this.lastFailure,
    required this.backoffUntil,
  });
}
