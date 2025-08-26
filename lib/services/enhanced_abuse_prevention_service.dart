import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

/// Enhanced abuse prevention service with device/IP controls and human challenges
/// Implements the requirements from Part 4B-3
class EnhancedAbusePrevention {
  static final EnhancedAbusePrevention _instance = EnhancedAbusePrevention._internal();
  static EnhancedAbusePrevention get instance => _instance;

  EnhancedAbusePrevention._internal();

  // Configuration constants
  static const int DEVICE_MULTI_ACCOUNT_THRESHOLD = 3;
  static const Duration DEVICE_MULTI_ACCOUNT_WINDOW = Duration(hours: 24);
  static const int MAX_ACTIONS_PER_HOUR = 12;
  static const int MAX_ACTIONS_PER_DAY = 60;
  static const int MAX_BURST_ACTIONS = 4;
  static const Duration BURST_WINDOW = Duration(seconds: 10);
  static const Duration SET_COOLDOWN = Duration(seconds: 10);

  // Device fingerprinting and tracking
  final Map<String, DeviceSignature> _deviceSignatures = {};
  final Map<String, List<String>> _deviceToUsers = {}; // device -> [userIds]
  final Map<String, String> _userToDevice = {}; // userId -> device

  // IP reputation tracking
  final Map<String, IPReputation> _ipReputations = {};
  final Map<String, String> _userToIP = {}; // userId -> IP (simplified)

  // Rate limiting and cooldowns
  final Map<String, UserRateLimits> _userRateLimits = {};
  final Map<String, SetCooldown> _setCooldowns = {};

  // Challenge and blocking system
  final Map<String, ChallengeState> _challengeStates = {};
  final Map<String, BlockState> _blockStates = {};

  // Abuse detection patterns
  final Map<String, SuspiciousActivityLog> _suspiciousActivityLogs = {};

  /// Check if an action is allowed based on comprehensive abuse prevention
  Future<AbuseCheckResult> canPerformAction({
    required String userId,
    required String actionType,
    required Map<String, dynamic> deviceInfo,
    String? setId,
    String? ipAddress,
  }) async {
    final deviceFingerprint = generateDeviceFingerprint(deviceInfo);
    
    // Update device-user mappings
    _updateDeviceUserMapping(deviceFingerprint, userId);
    if (ipAddress != null) {
      _userToIP[userId] = ipAddress;
    }

    // Check device-level abuse signals
    final deviceCheck = await _checkDeviceLevelAbuse(deviceFingerprint, userId);
    if (!deviceCheck.isAllowed) {
      await _logAbusiveActivity(
        userId: userId,
        deviceFingerprint: deviceFingerprint,
        ipAddress: ipAddress,
        reason: deviceCheck.reason,
        severity: 'high',
      );
      return AbuseCheckResult(
        isAllowed: false,
        reason: deviceCheck.reason,
        requiresChallenge: deviceCheck.requiresChallenge,
        blockDuration: deviceCheck.blockDuration,
      );
    }

    // Check IP reputation
    if (ipAddress != null) {
      final ipCheck = _checkIPReputation(ipAddress, userId);
      if (!ipCheck.isAllowed) {
        await _logAbusiveActivity(
          userId: userId,
          deviceFingerprint: deviceFingerprint,
          ipAddress: ipAddress,
          reason: ipCheck.reason,
          severity: 'medium',
        );
        return AbuseCheckResult(
          isAllowed: false,
          reason: ipCheck.reason,
          requiresChallenge: ipCheck.requiresChallenge,
          blockDuration: ipCheck.blockDuration,
        );
      }
    }

    // Check user-level rate limits
    final rateCheck = _checkUserRateLimits(userId, actionType);
    if (!rateCheck.isAllowed) {
      await _logAbusiveActivity(
        userId: userId,
        deviceFingerprint: deviceFingerprint,
        ipAddress: ipAddress,
        reason: rateCheck.reason,
        severity: 'medium',
      );
      return AbuseCheckResult(
        isAllowed: false,
        reason: rateCheck.reason,
        requiresChallenge: rateCheck.requiresChallenge,
        blockDuration: rateCheck.blockDuration,
      );
    }

    // Check set-specific cooldowns
    if (setId != null) {
      final cooldownCheck = _checkSetCooldown(userId, setId, actionType);
      if (!cooldownCheck.isAllowed) {
        return AbuseCheckResult(
          isAllowed: false,
          reason: cooldownCheck.reason,
          requiresChallenge: false,
          blockDuration: null,
        );
      }
    }

    // Record successful action
    _recordAction(userId, deviceFingerprint, actionType, setId);
    
    return AbuseCheckResult(
      isAllowed: true,
      reason: 'Action allowed',
      requiresChallenge: false,
      blockDuration: null,
    );
  }

  /// Generate device fingerprint from device information
  String generateDeviceFingerprint(Map<String, dynamic> deviceInfo) {
    final sortedInfo = Map.fromEntries(
      deviceInfo.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key))
    );
    final jsonString = jsonEncode(sortedInfo);
    return sha256.convert(utf8.encode(jsonString)).toString();
  }

  /// Update device-user mapping for multi-account detection
  void _updateDeviceUserMapping(String deviceFingerprint, String userId) {
    // Remove user from old device mapping
    _userToDevice.remove(userId);
    
    // Add user to new device mapping
    _deviceToUsers.putIfAbsent(deviceFingerprint, () => []).add(userId);
    _userToDevice[userId] = deviceFingerprint;
    
    // Clean up old mappings
    _deviceToUsers.removeWhere((device, users) {
      users.remove(userId);
      return users.isEmpty;
    });
  }

  /// Check device-level abuse signals
  Future<DeviceCheckResult> _checkDeviceLevelAbuse(String deviceFingerprint, String userId) async {
    final deviceSignature = _deviceSignatures[deviceFingerprint] 
      ?? DeviceSignature(fingerprint: deviceFingerprint);
    
    final now = DateTime.now();
    
    // Check new account creation limit
    if (deviceSignature.newAccountsCreatedToday >= DEVICE_MULTI_ACCOUNT_THRESHOLD) {
      // Flag device for review
      await _flagDeviceForReview(deviceFingerprint, 'Multi-account threshold exceeded');
      
      return DeviceCheckResult(
        isAllowed: false,
        reason: 'Device flagged for suspicious activity',
        requiresChallenge: true,
        blockDuration: Duration(hours: 24),
      );
    }

    // Check if this is a new account creation
    if (!deviceSignature.knownUsers.contains(userId)) {
      deviceSignature.recordNewAccountCreation(userId);
      _deviceSignatures[deviceFingerprint] = deviceSignature;
    }

    return DeviceCheckResult(
      isAllowed: true,
      reason: 'Device check passed',
      requiresChallenge: false,
      blockDuration: null,
    );
  }

  /// Check IP reputation and fail2ban
  IPCheckResult _checkIPReputation(String ipAddress, String userId) {
    final reputation = _ipReputations[ipAddress] ?? IPReputation(ip: ipAddress);
    final now = DateTime.now();
    
    // Check if IP is temporarily blocked
    if (reputation.isBlocked && reputation.blockUntil != null && reputation.blockUntil!.isAfter(now)) {
      return IPCheckResult(
        isAllowed: false,
        reason: 'IP address temporarily blocked',
        requiresChallenge: true,
        blockDuration: reputation.blockUntil!.difference(now),
      );
    }
    
    // Check for repeated auth failures
    if (reputation.authFailures >= 5) {
      reputation.blockUntil = now.add(Duration(hours: 1));
      _ipReputations[ipAddress] = reputation;
      
      return IPCheckResult(
        isAllowed: false,
        reason: 'IP address blocked due to repeated failures',
        requiresChallenge: true,
        blockDuration: Duration(hours: 1),
      );
    }
    
    // Check for rate limit violations
    if (reputation.rateLimitViolations >= 3) {
      reputation.blockUntil = now.add(Duration(minutes: 30));
      _ipReputations[ipAddress] = reputation;
      
      return IPCheckResult(
        isAllowed: false,
        reason: 'IP address blocked due to rate limit violations',
        requiresChallenge: true,
        blockDuration: Duration(minutes: 30),
      );
    }
    
    return IPCheckResult(
      isAllowed: true,
      reason: 'IP check passed',
      requiresChallenge: false,
      blockDuration: null,
    );
  }

  /// Check user-level rate limits
  RateLimitCheckResult _checkUserRateLimits(String userId, String actionType) {
    final now = DateTime.now();
    final rateLimits = _userRateLimits[userId] ?? UserRateLimits(userId: userId);
    
    // Clean up old timestamps
    rateLimits.actionTimestamps.removeWhere(
      (timestamp) => now.difference(timestamp) > Duration(hours: 1)
    );
    
    // Check hourly limit
    if (rateLimits.actionTimestamps.length >= MAX_ACTIONS_PER_HOUR) {
      return RateLimitCheckResult(
        isAllowed: false,
        reason: 'Hourly rate limit exceeded',
        requiresChallenge: false,
        blockDuration: Duration(minutes: 5),
      );
    }
    
    // Check burst limit
    final recentActions = rateLimits.actionTimestamps.where(
      (timestamp) => now.difference(timestamp) <= BURST_WINDOW
    ).length;
    
    if (recentActions >= MAX_BURST_ACTIONS) {
      return RateLimitCheckResult(
        isAllowed: false,
        reason: 'Burst rate limit exceeded',
        requiresChallenge: false,
        blockDuration: Duration(minutes: 2),
      );
    }
    
    return RateLimitCheckResult(
      isAllowed: true,
      reason: 'Rate limit check passed',
      requiresChallenge: false,
      blockDuration: null,
    );
  }

  /// Check set-specific cooldowns
  CooldownCheckResult _checkSetCooldown(String userId, String setId, String actionType) {
    final cooldownKey = '${userId}_$setId';
    final cooldown = _setCooldowns[cooldownKey] ?? SetCooldown(setId: setId);
    final now = DateTime.now();
    
    // Check if cooldown is active
    if (cooldown.lastActionTime != null && 
        now.difference(cooldown.lastActionTime!) < SET_COOLDOWN) {
      final remaining = SET_COOLDOWN - now.difference(cooldown.lastActionTime!);
      return CooldownCheckResult(
        isAllowed: false,
        reason: 'Set cooldown active: ${remaining.inSeconds}s remaining',
        requiresChallenge: false,
        blockDuration: remaining,
      );
    }
    
    return CooldownCheckResult(
      isAllowed: true,
      reason: 'Cooldown check passed',
      requiresChallenge: false,
      blockDuration: null,
    );
  }

  /// Record a successful action
  void _recordAction(String userId, String deviceFingerprint, String actionType, String? setId) {
    final now = DateTime.now();
    
    // Update device signature
    final deviceSignature = _deviceSignatures[deviceFingerprint] 
      ?? DeviceSignature(fingerprint: deviceFingerprint);
    deviceSignature.recordAction(now);
    _deviceSignatures[deviceFingerprint] = deviceSignature;
    
    // Update user rate limits
    final rateLimits = _userRateLimits[userId] ?? UserRateLimits(userId: userId);
    rateLimits.recordAction(now);
    _userRateLimits[userId] = rateLimits;
    
    // Update set cooldown
    if (setId != null) {
      final cooldownKey = '${userId}_$setId';
      _setCooldowns[cooldownKey] = SetCooldown(
        setId: setId,
        lastActionTime: now,
      );
    }
    
    // Log to Firestore
    _logActionToFirestore(userId, deviceFingerprint, actionType, setId);
  }

  /// Issue human challenge for suspicious activity
  Future<ChallengeResult> issueChallenge(String userId, String challengeType) async {
    final challengeId = _generateChallengeId();
    final now = DateTime.now();
    
    final challenge = ChallengeState(
      challengeId: challengeId,
      userId: userId,
      challengeType: challengeType,
      issuedAt: now,
      expiresAt: now.add(Duration(minutes: 10)),
    );
    
    _challengeStates[challengeId] = challenge;
    
    // Log challenge issuance
    await _logTelemetry('abuse.challenge_issued', {
      'userId': userId,
      'challengeId': challengeId,
      'challengeType': challengeType,
      'timestamp': now.toIso8601String(),
    });
    
    return ChallengeResult(
      challengeId: challengeId,
      challengeType: challengeType,
      expiresAt: challenge.expiresAt,
    );
  }

  /// Verify challenge completion
  Future<bool> verifyChallenge(String challengeId, String response) async {
    final challenge = _challengeStates[challengeId];
    if (challenge == null) return false;
    
    final now = DateTime.now();
    if (now.isAfter(challenge.expiresAt)) {
      _challengeStates.remove(challengeId);
      return false;
    }
    
    // Simple CAPTCHA verification (in production, use proper CAPTCHA service)
    final isValid = _verifyChallengeResponse(challenge.challengeType, response);
    
    if (isValid) {
      // Clear challenge and unblock user
      _challengeStates.remove(challengeId);
      _unblockUser(challenge.userId);
      
      await _logTelemetry('abuse.challenge_passed', {
        'userId': challenge.userId,
        'challengeId': challengeId,
        'timestamp': now.toIso8601String(),
      });
    } else {
      // Increment challenge failures
      challenge.failureCount++;
      if (challenge.failureCount >= 3) {
        // Block user after multiple failures
        await _blockUser(challenge.userId, Duration(hours: 24), 'Multiple challenge failures');
        _challengeStates.remove(challengeId);
      }
    }
    
    return isValid;
  }

  /// Block user temporarily
  Future<void> _blockUser(String userId, Duration duration, String reason) async {
    final now = DateTime.now();
    final blockUntil = now.add(duration);
    
    _blockStates[userId] = BlockState(
      userId: userId,
      blockedAt: now,
      blockedUntil: blockUntil,
      reason: reason,
    );
    
    await _logTelemetry('abuse.temp_blocked', {
      'userId': userId,
      'reason': reason,
      'blockedAt': now.toIso8601String(),
      'blockedUntil': blockUntil.toIso8601String(),
    });
  }

  /// Unblock user
  void _unblockUser(String userId) {
    _blockStates.remove(userId);
  }

  /// Flag device for manual review
  Future<void> _flagDeviceForReview(String deviceFingerprint, String reason) async {
    await FirebaseFirestore.instance.collection('device_flags').add({
      'deviceFingerprint': deviceFingerprint,
      'reason': reason,
      'flaggedAt': FieldValue.serverTimestamp(),
      'status': 'pending_review',
    });
  }

  /// Log abusive activity to Firestore
  Future<void> _logAbusiveActivity({
    required String userId,
    required String deviceFingerprint,
    String? ipAddress,
    required String reason,
    required String severity,
  }) async {
    await FirebaseFirestore.instance.collection('abuse_logs').add({
      'userId': userId,
      'deviceFingerprint': deviceFingerprint,
      'ipAddress': ipAddress,
      'reason': reason,
      'severity': severity,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Log action to Firestore for tracking
  void _logActionToFirestore(String userId, String deviceFingerprint, String actionType, String? setId) {
    FirebaseFirestore.instance.collection('action_logs').add({
      'userId': userId,
      'deviceFingerprint': deviceFingerprint,
      'actionType': actionType,
      'setId': setId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Log telemetry events
  Future<void> _logTelemetry(String event, Map<String, dynamic> parameters) async {
    await FirebaseFirestore.instance.collection('telemetry_events').add({
      'event': event,
      'parameters': parameters,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Generate unique challenge ID
  String _generateChallengeId() {
    return 'challenge_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
  }

  /// Generate random string for challenge ID
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(DateTime.now().millisecond % chars.length))
    );
  }

  /// Verify challenge response (simplified)
  bool _verifyChallengeResponse(String challengeType, String response) {
    // In production, implement proper CAPTCHA verification
    switch (challengeType) {
      case 'captcha':
        return response.toLowerCase() == 'mindload';
      case 'math':
        try {
          final parts = response.split('+');
          if (parts.length == 2) {
            final a = int.parse(parts[0].trim());
            final b = int.parse(parts[1].trim());
            return a + b == 15; // Simple math challenge
          }
        } catch (e) {
          return false;
        }
        return false;
      default:
        return false;
    }
  }

  /// Get abuse prevention status for a user
  Map<String, dynamic> getAbusePreventionStatus(String userId) {
    final deviceFingerprint = _userToDevice[userId];
    final ipAddress = _userToIP[userId];
    final rateLimits = _userRateLimits[userId];
    final blockState = _blockStates[userId];
    
    return {
      'userId': userId,
      'deviceFingerprint': deviceFingerprint,
      'ipAddress': ipAddress,
      'isBlocked': blockState != null && blockState.blockedUntil.isAfter(DateTime.now()),
      'blockReason': blockState?.reason,
      'blockedUntil': blockState?.blockedUntil.toIso8601String(),
      'rateLimitStatus': rateLimits?.getStatus(),
      'deviceMultiAccountCount': deviceFingerprint != null 
          ? (_deviceToUsers[deviceFingerprint]?.length ?? 0) 
          : 0,
      'requiresChallenge': blockState != null && blockState.requiresChallenge,
    };
  }

  /// Clean up old data periodically
  void cleanupOldData() {
    final now = DateTime.now();
    
    // Clean up old device signatures
    _deviceSignatures.removeWhere((key, value) => 
        now.difference(value.lastActionTimestamp).inDays > 1);
    
    // Clean up old rate limits
    _userRateLimits.removeWhere((key, value) => 
        now.difference(value.lastActionTimestamp).inDays > 1);
    
    // Clean up old cooldowns
    _setCooldowns.removeWhere((key, value) => 
        value.lastActionTime != null && 
        now.difference(value.lastActionTime!).inHours > 1);
    
    // Clean up expired challenges
    _challengeStates.removeWhere((key, value) => 
        now.isAfter(value.expiresAt));
    
    // Clean up expired blocks
    _blockStates.removeWhere((key, value) => 
        now.isAfter(value.blockedUntil));
    
    // Clean up old IP reputations
    _ipReputations.removeWhere((key, value) => 
        now.difference(value.lastSeen).inDays > 7);
  }
}

// Result classes for abuse checks
class AbuseCheckResult {
  final bool isAllowed;
  final String reason;
  final bool requiresChallenge;
  final Duration? blockDuration;

  const AbuseCheckResult({
    required this.isAllowed,
    required this.reason,
    required this.requiresChallenge,
    this.blockDuration,
  });
}

class DeviceCheckResult {
  final bool isAllowed;
  final String reason;
  final bool requiresChallenge;
  final Duration? blockDuration;

  const DeviceCheckResult({
    required this.isAllowed,
    required this.reason,
    required this.requiresChallenge,
    this.blockDuration,
  });
}

class IPCheckResult {
  final bool isAllowed;
  final String reason;
  final bool requiresChallenge;
  final Duration? blockDuration;

  const IPCheckResult({
    required this.isAllowed,
    required this.reason,
    required this.requiresChallenge,
    this.blockDuration,
  });
}

class RateLimitCheckResult {
  final bool isAllowed;
  final String reason;
  final bool requiresChallenge;
  final Duration? blockDuration;

  const RateLimitCheckResult({
    required this.isAllowed,
    required this.reason,
    required this.requiresChallenge,
    this.blockDuration,
  });
}

class CooldownCheckResult {
  final bool isAllowed;
  final String reason;
  final bool requiresChallenge;
  final Duration? blockDuration;

  const CooldownCheckResult({
    required this.isAllowed,
    required this.reason,
    required this.requiresChallenge,
    this.blockDuration,
  });
}

class ChallengeResult {
  final String challengeId;
  final String challengeType;
  final DateTime expiresAt;

  const ChallengeResult({
    required this.challengeId,
    required this.challengeType,
    required this.expiresAt,
  });
}

// Data classes for tracking
class DeviceSignature {
  final String fingerprint;
  DateTime lastActionTimestamp = DateTime.now();
  final Set<String> knownUsers = {};
  int newAccountsCreatedToday = 0;
  final List<DateTime> actionTimestamps = [];

  DeviceSignature({required this.fingerprint});

  void recordAction(DateTime timestamp) {
    lastActionTimestamp = timestamp;
    actionTimestamps.add(timestamp);
    
    // Reset daily counter if it's a new day
    if (timestamp.day != lastActionTimestamp.day) {
      newAccountsCreatedToday = 0;
    }
  }

  void recordNewAccountCreation(String userId) {
    if (!knownUsers.contains(userId)) {
      knownUsers.add(userId);
      newAccountsCreatedToday++;
    }
  }
}

class IPReputation {
  final String ip;
  DateTime lastSeen = DateTime.now();
  int authFailures = 0;
  int rateLimitViolations = 0;
  DateTime? blockUntil;

  IPReputation({required this.ip});

  bool get isBlocked => blockUntil != null && blockUntil!.isAfter(DateTime.now());
}

class UserRateLimits {
  final String userId;
  DateTime lastActionTimestamp = DateTime.now();
  final List<DateTime> actionTimestamps = [];

  UserRateLimits({required this.userId});

  void recordAction(DateTime timestamp) {
    lastActionTimestamp = timestamp;
    actionTimestamps.add(timestamp);
  }

  Map<String, dynamic> getStatus() {
    final now = DateTime.now();
    final recentHour = actionTimestamps.where(
      (t) => now.difference(t) <= Duration(hours: 1)
    ).length;
    final recentBurst = actionTimestamps.where(
      (t) => now.difference(t) <= Duration(seconds: 10)
    ).length;
    
    return {
      'actionsLastHour': recentHour,
      'actionsLastBurst': recentBurst,
      'maxPerHour': EnhancedAbusePrevention.MAX_ACTIONS_PER_HOUR,
      'maxPerBurst': EnhancedAbusePrevention.MAX_BURST_ACTIONS,
    };
  }
}

class SetCooldown {
  final String setId;
  DateTime? lastActionTime;

  SetCooldown({required this.setId, this.lastActionTime});
}

class ChallengeState {
  final String challengeId;
  final String userId;
  final String challengeType;
  final DateTime issuedAt;
  final DateTime expiresAt;
  int failureCount = 0;

  ChallengeState({
    required this.challengeId,
    required this.userId,
    required this.challengeType,
    required this.issuedAt,
    required this.expiresAt,
  });
}

class BlockState {
  final String userId;
  final DateTime blockedAt;
  final DateTime blockedUntil;
  final String reason;
  bool requiresChallenge = true;

  BlockState({
    required this.userId,
    required this.blockedAt,
    required this.blockedUntil,
    required this.reason,
  });
}

class SuspiciousActivityLog {
  final String userId;
  DateTime lastActionTimestamp = DateTime.now();
  final List<DateTime> actionTimestamps = [];

  SuspiciousActivityLog({required this.userId});

  void recordAction(DateTime timestamp) {
    lastActionTimestamp = timestamp;
    actionTimestamps.add(timestamp);
  }
}
