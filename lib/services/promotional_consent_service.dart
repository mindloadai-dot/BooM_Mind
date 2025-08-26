import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mindload/models/notification_models.dart';

/// Service for managing promotional message consent and ensuring compliance
class PromotionalConsentService {
  static final PromotionalConsentService _instance = PromotionalConsentService._internal();
  factory PromotionalConsentService() => _instance;
  PromotionalConsentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if user can receive promotional messages
  Future<bool> canReceivePromotionalMessages() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore
          .collection('user_preferences')
          .doc(user.uid)
          .get();

      if (!doc.exists) return false;

      final preferences = UserNotificationPreferences.fromJson(doc.data()!);
      
      // Must have both consent AND system permission for promotional messages
      return preferences.promotionalConsent.canReceive && 
             preferences.permissionStatus.systemPermissionGranted;
    } catch (e) {
      debugPrint('❌ Failed to check promotional consent: $e');
      return false;
    }
  }

  /// Grant promotional consent
  Future<void> grantPromotionalConsent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore
          .collection('user_preferences')
          .doc(user.uid)
          .get();

      UserNotificationPreferences preferences;
      if (!doc.exists) {
        // Create default preferences if document doesn't exist
        preferences = UserNotificationPreferences.defaultPreferences(user.uid);
      } else {
        preferences = UserNotificationPreferences.fromJson(doc.data()!);
      }
      
      final updatedConsent = preferences.promotionalConsent.copyWith(
        hasConsented: true,
        consentedAt: DateTime.now(),
        revokedAt: null,
        canReceive: true,
        consentSource: 'in_app',
      );

      final updatedPreferences = preferences.copyWith(
        promotionalConsent: updatedConsent,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('user_preferences')
          .doc(user.uid)
          .set(updatedPreferences.toJson(), SetOptions(merge: true));

      debugPrint('✅ Promotional consent granted');
    } catch (e) {
      debugPrint('❌ Failed to grant promotional consent: $e');
      rethrow;
    }
  }

  /// Revoke promotional consent
  Future<void> revokePromotionalConsent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore
          .collection('user_preferences')
          .doc(user.uid)
          .get();

      UserNotificationPreferences preferences;
      if (!doc.exists) {
        // Create default preferences if document doesn't exist
        preferences = UserNotificationPreferences.defaultPreferences(user.uid);
      } else {
        preferences = UserNotificationPreferences.fromJson(doc.data()!);
      }
      
      final updatedConsent = preferences.promotionalConsent.copyWith(
        hasConsented: false,
        revokedAt: DateTime.now(),
        canReceive: false,
        consentSource: 'in_app_revoked',
      );

      final updatedPreferences = preferences.copyWith(
        promotionalConsent: updatedConsent,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('user_preferences')
          .doc(user.uid)
          .set(updatedPreferences.toJson(), SetOptions(merge: true));

      debugPrint('✅ Promotional consent revoked');
    } catch (e) {
      debugPrint('❌ Failed to revoke promotional consent: $e');
      rethrow;
    }
  }

  /// Get current promotional consent status
  Future<PromotionalConsent> getPromotionalConsent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return PromotionalConsent.defaultConsent();

    try {
      final doc = await _firestore
          .collection('user_preferences')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        // Create default preferences document if it doesn't exist
        final preferences = UserNotificationPreferences.defaultPreferences(user.uid);
        await _firestore
            .collection('user_preferences')
            .doc(user.uid)
            .set(preferences.toJson(), SetOptions(merge: true));
        
        return preferences.promotionalConsent;
      }

      final preferences = UserNotificationPreferences.fromJson(doc.data()!);
      return preferences.promotionalConsent;
    } catch (e) {
      debugPrint('❌ Failed to get promotional consent: $e');
      return PromotionalConsent.defaultConsent();
    }
  }

  /// Check and update system notification permission status
  Future<NotificationPermissionStatus> updatePermissionStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return NotificationPermissionStatus.defaultStatus();

    try {
      // Check actual system permission
      final permissionStatus = await Permission.notification.status;
      final systemGranted = permissionStatus == PermissionStatus.granted;

      final doc = await _firestore
          .collection('user_preferences')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        return NotificationPermissionStatus(
          systemPermissionGranted: systemGranted,
          appNotificationsEnabled: true,
          lastChecked: DateTime.now(),
          gracefulDegradationActive: !systemGranted,
        );
      }

      final preferences = UserNotificationPreferences.fromJson(doc.data()!);
      
      final updatedStatus = preferences.permissionStatus.copyWith(
        systemPermissionGranted: systemGranted,
        lastChecked: DateTime.now(),
        gracefulDegradationActive: !systemGranted,
      );

      final updatedPreferences = preferences.copyWith(
        permissionStatus: updatedStatus,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('user_preferences')
          .doc(user.uid)
          .update(updatedPreferences.toJson());

      debugPrint('✅ Permission status updated: system=$systemGranted');
      return updatedStatus;
    } catch (e) {
      debugPrint('❌ Failed to update permission status: $e');
      return NotificationPermissionStatus.defaultStatus();
    }
  }

  /// Enable graceful degradation when notifications are denied
  Future<void> enableGracefulDegradation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore
          .collection('user_preferences')
          .doc(user.uid)
          .get();

      if (!doc.exists) return;

      final preferences = UserNotificationPreferences.fromJson(doc.data()!);
      
      final updatedStatus = preferences.permissionStatus.copyWith(
        gracefulDegradationActive: true,
        appNotificationsEnabled: true, // Keep app-level notifications enabled
        lastChecked: DateTime.now(),
      );

      final updatedPreferences = preferences.copyWith(
        permissionStatus: updatedStatus,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('user_preferences')
          .doc(user.uid)
          .update(updatedPreferences.toJson());

      debugPrint('✅ Graceful degradation enabled - app remains fully functional');
    } catch (e) {
      debugPrint('❌ Failed to enable graceful degradation: $e');
    }
  }

  /// Disable app-level notifications (user choice)
  Future<void> disableAppNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore
          .collection('user_preferences')
          .doc(user.uid)
          .get();

      if (!doc.exists) return;

      final preferences = UserNotificationPreferences.fromJson(doc.data()!);
      
      final updatedStatus = preferences.permissionStatus.copyWith(
        appNotificationsEnabled: false,
        lastChecked: DateTime.now(),
      );

      // Also revoke promotional consent since notifications are disabled
      final updatedConsent = preferences.promotionalConsent.copyWith(
        canReceive: false,
        revokedAt: DateTime.now(),
        consentSource: 'notifications_disabled',
      );

      final updatedPreferences = preferences.copyWith(
        permissionStatus: updatedStatus,
        promotionalConsent: updatedConsent,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('user_preferences')
          .doc(user.uid)
          .update(updatedPreferences.toJson());

      debugPrint('✅ App notifications disabled by user');
    } catch (e) {
      debugPrint('❌ Failed to disable app notifications: $e');
    }
  }

  /// Re-enable app-level notifications
  Future<void> enableAppNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore
          .collection('user_preferences')
          .doc(user.uid)
          .get();

      if (!doc.exists) return;

      final preferences = UserNotificationPreferences.fromJson(doc.data()!);
      
      final updatedStatus = preferences.permissionStatus.copyWith(
        appNotificationsEnabled: true,
        lastChecked: DateTime.now(),
      );

      final updatedPreferences = preferences.copyWith(
        permissionStatus: updatedStatus,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('user_preferences')
          .doc(user.uid)
          .update(updatedPreferences.toJson());

      debugPrint('✅ App notifications enabled by user');
    } catch (e) {
      debugPrint('❌ Failed to enable app notifications: $e');
    }
  }

  /// Check if app should show promotional content
  Future<bool> shouldShowPromotionalContent() async {
    // Even if push notifications are disabled, user might still want to see
    // promotional content within the app (banners, etc.)
    final consent = await getPromotionalConsent();
    return consent.hasConsented ?? false;
  }

  /// Ensure notification content is privacy-compliant
  String sanitizeNotificationContent(String content, {bool isTitle = false}) {
    // Remove any potential sensitive information from notification content
    // This is a basic implementation - in production, use more sophisticated NLP
    
    final sensitivePatterns = [
      RegExp(r'\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b'), // Credit card numbers
      RegExp(r'\b\d{3}[-\s]?\d{2}[-\s]?\d{4}\b'), // SSN patterns
      RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'), // Email addresses
      RegExp(r'\b\d{3}[-\s]?\d{3}[-\s]?\d{4}\b'), // Phone numbers
    ];

    String sanitized = content;
    for (final pattern in sensitivePatterns) {
      sanitized = sanitized.replaceAll(pattern, '[REDACTED]');
    }

    // Limit length for notifications
    if (isTitle && sanitized.length > 50) {
      sanitized = '${sanitized.substring(0, 47)}...';
    } else if (!isTitle && sanitized.length > 200) {
      sanitized = '${sanitized.substring(0, 197)}...';
    }

    return sanitized;
  }

  /// Clean up consent data when user deletes account
  Future<void> cleanupConsentData(String userId) async {
    try {
      // Remove promotional consent data from user preferences
      await _firestore
          .collection('user_preferences')
          .doc(userId)
          .delete();

      // Remove any promotional message logs
      final logsQuery = await _firestore
          .collection('promotional_logs')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in logsQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      debugPrint('✅ Promotional consent data cleaned up for user: $userId');
    } catch (e) {
      debugPrint('❌ Failed to cleanup consent data: $e');
    }
  }
}