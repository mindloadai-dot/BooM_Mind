// DEPRECATED: This service has been replaced by the unified NotificationService.
// This file exists only to prevent import errors during migration.
// All functionality has been moved to NotificationService.

export 'notification_service.dart';

// Legacy compatibility - will be removed in future versions
@Deprecated('Use NotificationService instead')
class EnhancedNotificationPreferenceService {
  // This class is deprecated and should not be used
  EnhancedNotificationPreferenceService() {
    throw UnsupportedError(
      'EnhancedNotificationPreferenceService is deprecated. Use NotificationService instead.'
    );
  }
}