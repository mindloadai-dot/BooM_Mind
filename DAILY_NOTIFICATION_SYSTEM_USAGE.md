# Daily Notification System - Usage Guide

## Overview

The MindLoad app now has a robust daily notification system that automatically sends study reminders throughout the day, every day, fully offline on both iOS and Android.

## Key Features

✅ **Multiple notifications per day** - Set up 3x daily reminders (9 AM, 1 PM, 7 PM)  
✅ **Fully offline** - No internet required, works with local notifications only  
✅ **Persistent across app restarts** - Notifications continue even after app is closed  
✅ **Stable IDs** - No duplicate schedules when app is restarted  
✅ **Lifecycle management** - Automatically reschedules when app returns to foreground  
✅ **iOS & Android compatible** - Works on both platforms with proper permissions  

## Quick Start

### 1. Set up daily notifications (3x per day)
```dart
await MindLoadNotificationService.updateDailyPlan(
  ['09:00', '13:00', '19:00'],
  title: 'MindLoad Study Reminder',
  body: '15 min today keeps your streak alive! 🧠',
);
```

### 2. Clear all daily notifications
```dart
await MindLoadNotificationService.clearDailyPlan();
```

### 3. Reschedule existing plan (automatically called on app resume)
```dart
await MindLoadNotificationService.rescheduleDailyPlan();
```

## API Reference

### Core Methods

#### `scheduleDailyTimes(List<String> hhmmList, {required String title, required String body, String? payload})`
Schedules multiple daily notifications and saves the plan to persistent storage.

**Parameters:**
- `hhmmList`: List of time strings in "HH:MM" format (e.g., ["09:00", "13:00", "19:00"])
- `title`: Notification title
- `body`: Notification message
- `payload`: Optional data payload

#### `scheduleDaily({required int hour, required int minute, required String title, required String body, String? payload})`
Schedules a single daily repeating notification.

**Parameters:**
- `hour`: Hour (0-23)
- `minute`: Minute (0-59)
- `title`: Notification title
- `body`: Notification message
- `payload`: Optional data payload

#### `rescheduleDailyPlan({String defaultTitle = 'MindLoad', String defaultBody = '15 min today keeps your streak alive.'})`
Re-applies the saved daily notification plan. Called automatically on app start and resume.

#### `clearDailyPlan()`
Cancels all daily notifications and removes the saved plan.

#### `updateDailyPlan(List<String> hhmmList, {required String title, required String body, String? payload})`
Updates the daily notification plan by clearing existing notifications and setting up new ones.

## Technical Details

### Stable IDs
Daily notifications use stable IDs calculated as: `20000 + (hour * 100) + minute`
- 09:00 → ID: 20900
- 13:00 → ID: 21300
- 19:00 → ID: 21900

### Persistence
Daily notification plans are saved to SharedPreferences using the key `ml_daily_plan_hhmm`.

### Lifecycle Management
The app automatically reschedules daily notifications when:
- App starts (cold start)
- App returns to foreground
- User manually calls `rescheduleDailyPlan()`

### Platform Support
- **iOS**: Uses local notifications with `DateTimeComponents.time` for daily repetition
- **Android**: Uses `AndroidScheduleMode.exactAllowWhileIdle` for reliable delivery
- **Permissions**: Automatically requests notification permissions on both platforms

## Testing

Use the Notification Debug Screen to test the daily notification system:

1. Navigate to `/notification-debug` route in the app
2. Use the "Setup 3x Daily Notifications" button
3. Use "Test Daily System" to run comprehensive tests
4. Use "Clear Daily Notifications" to remove all daily notifications

## Example Usage in Settings Screen

```dart
class NotificationSettingsWidget extends StatefulWidget {
  @override
  _NotificationSettingsWidgetState createState() => _NotificationSettingsWidgetState();
}

class _NotificationSettingsWidgetState extends State<NotificationSettingsWidget> {
  bool _dailyNotificationsEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          title: Text('Daily Study Reminders'),
          subtitle: Text('Get reminded 3 times per day'),
          value: _dailyNotificationsEnabled,
          onChanged: (bool value) async {
            if (value) {
              await MindLoadNotificationService.updateDailyPlan(
                ['09:00', '13:00', '19:00'],
                title: 'MindLoad Study Time',
                body: 'Ready for your daily learning session?',
              );
            } else {
              await MindLoadNotificationService.clearDailyPlan();
            }
            setState(() {
              _dailyNotificationsEnabled = value;
            });
          },
        ),
      ],
    );
  }
}
```

## Troubleshooting

### Notifications not appearing?
1. Check notification permissions in device settings
2. Ensure exact alarm permissions are granted (Android 12+)
3. Use the debug screen to test notification functionality

### Duplicate notifications?
The system uses stable IDs and deduplication to prevent duplicates. If you see duplicates:
1. Clear all notifications: `await MindLoadNotificationService.clearDailyPlan()`
2. Set up fresh: `await MindLoadNotificationService.updateDailyPlan(...)`

### Notifications stop after app update?
The lifecycle management system should automatically restore notifications, but you can manually trigger:
```dart
await MindLoadNotificationService.rescheduleDailyPlan();
```

## Implementation Complete ✅

The daily notification system is now fully implemented and ready for production use. All acceptance criteria have been met:

- ✅ Multiple daily notifications with stable IDs
- ✅ Persistent across app restarts and device reboots
- ✅ Fully offline functionality
- ✅ iOS & Android compatibility
- ✅ Lifecycle management for foreground/background transitions
- ✅ Comprehensive testing suite
- ✅ Easy-to-use API with clear documentation
