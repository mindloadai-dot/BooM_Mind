import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

class AbusePrevention {
  static final AbusePrevention _instance = AbusePrevention._internal();
  static AbusePrevention get instance => _instance;

  AbusePrevention._internal();

  // Device fingerprinting and tracking
  final Map<String, DeviceSignature> _deviceSignatures = {};

  // Suspicious activity tracking
  final Map<String, SuspiciousActivityLog> _suspiciousActivityLogs = {};

  // Rate limiting configuration
  static const int MAX_ACTIONS_PER_HOUR = 12;
  static const int MAX_ACTIONS_PER_DAY = 60;
  static const int MAX_NEW_ACCOUNTS_PER_DEVICE_PER_DAY = 3;

  // Generates a device fingerprint hash
  String generateDeviceFingerprint(Map<String, dynamic> deviceInfo) {
    final sortedInfo = Map.fromEntries(
      deviceInfo.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key))
    );
    final jsonString = jsonEncode(sortedInfo);
    return sha256.convert(utf8.encode(jsonString)).toString();
  }

  // Check if an action is allowed based on rate limits
  Future<bool> canPerformAction({
    required String userId, 
    required String actionType,
    required Map<String, dynamic> deviceInfo,
  }) async {
    final deviceFingerprint = generateDeviceFingerprint(deviceInfo);
    
    // Check device-level abuse signals
    if (!_checkDeviceLevelAbuse(deviceFingerprint)) {
      await _logAbusiveActivity(
        userId: userId, 
        deviceFingerprint: deviceFingerprint, 
        reason: 'Device-level abuse detected',
      );
      return false;
    }

    // Check user-level rate limits
    if (!_checkUserRateLimits(userId, actionType)) {
      await _logAbusiveActivity(
        userId: userId, 
        deviceFingerprint: deviceFingerprint, 
        reason: 'Rate limit exceeded',
      );
      return false;
    }

    // Log successful action
    _recordAction(userId, deviceFingerprint, actionType);
    return true;
  }

  bool _checkDeviceLevelAbuse(String deviceFingerprint) {
    final deviceSignature = _deviceSignatures[deviceFingerprint] 
      ?? DeviceSignature(fingerprint: deviceFingerprint);
    
    // Check new account creation limit
    if (deviceSignature.newAccountsCreatedToday >= MAX_NEW_ACCOUNTS_PER_DEVICE_PER_DAY) {
      return false;
    }

    return true;
  }

  bool _checkUserRateLimits(String userId, String actionType) {
    final now = DateTime.now();
    final userActivityLog = _suspiciousActivityLogs[userId] 
      ?? SuspiciousActivityLog(userId: userId);

    // Remove old timestamps
    userActivityLog.actionTimestamps.removeWhere(
      (timestamp) => now.difference(timestamp).inHours >= 1
    );

    // Check hourly limit
    if (userActivityLog.actionTimestamps.length >= MAX_ACTIONS_PER_HOUR) {
      return false;
    }

    return true;
  }

  void _recordAction(String userId, String deviceFingerprint, String actionType) {
    final now = DateTime.now();

    // Update device signature
    final deviceSignature = _deviceSignatures[deviceFingerprint] 
      ?? DeviceSignature(fingerprint: deviceFingerprint);
    deviceSignature.recordAction(now);
    _deviceSignatures[deviceFingerprint] = deviceSignature;

    // Update user activity log
    final userActivityLog = _suspiciousActivityLogs[userId] 
      ?? SuspiciousActivityLog(userId: userId);
    userActivityLog.recordAction(now);
    _suspiciousActivityLogs[userId] = userActivityLog;

    // Log to Firestore for persistent tracking
    _logActionToFirestore(userId, deviceFingerprint, actionType);
  }

  Future<void> _logAbusiveActivity({
    required String userId, 
    required String deviceFingerprint, 
    required String reason,
  }) async {
    await FirebaseFirestore.instance.collection('abuse_logs').add({
      'userId': userId,
      'deviceFingerprint': deviceFingerprint,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
      'ipAddress': null, // TODO: Implement IP tracking
    });
  }

  void _logActionToFirestore(String userId, String deviceFingerprint, String actionType) {
    FirebaseFirestore.instance.collection('action_logs').add({
      'userId': userId,
      'deviceFingerprint': deviceFingerprint,
      'actionType': actionType,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Periodic cleanup of old logs
  void cleanupOldLogs() {
    final now = DateTime.now();
    _deviceSignatures.removeWhere(
      (key, value) => now.difference(value.lastActionTimestamp).inDays > 1
    );
    _suspiciousActivityLogs.removeWhere(
      (key, value) => now.difference(value.lastActionTimestamp).inDays > 1
    );
  }
}

class DeviceSignature {
  final String fingerprint;
  DateTime lastActionTimestamp = DateTime.now();
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

  void recordNewAccountCreation() {
    newAccountsCreatedToday++;
  }
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
