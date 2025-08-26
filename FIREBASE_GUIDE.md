# Firebase Client Service Guide - Mindload App

This guide provides comprehensive documentation for using Firebase in your Mindload application. The Firebase client service provides authentication, database operations, file storage, and push notifications.

## 🚀 Quick Start

### 1. Initialization

Firebase is automatically initialized when the app starts. To check status:

```dart
import 'package:mindload/services/firebase_client_service.dart';

final firebase = FirebaseClientService.instance;

// Check if Firebase is ready
if (firebase.isInitialized && firebase.isFirebaseConfigured) {
  print('✅ Firebase is ready');
} else {
  print('⚠️ Firebase configuration needed');
}
```

### 2. Authentication

#### Sign In with Google
```dart
final result = await firebase.signInWithGoogle();
if (result.success) {
  print('✅ Signed in: ${result.user?.email}');
} else {
  print('❌ Error: ${result.error}');
}
```

#### Sign In with Apple
```dart
final result = await firebase.signInWithApple();
if (result.success) {
  print('✅ Apple Sign In successful');
} else {
  print('❌ Error: ${result.error}');
}
```

#### Sign In with Face ID/Touch ID
```dart
final result = await firebase.signInWithBiometrics();
if (result.success) {
  print('✅ Biometric authentication successful');
} else {
  print('❌ Error: ${result.error}');
}
```

#### Email/Password Authentication
```dart
// Sign In
final result = await firebase.signInWithEmailAndPassword(
  'user@example.com',
  'password123'
);

// Sign Up
final result = await firebase.createUserWithEmailAndPassword(
  'newuser@example.com',
  'password123',
  'John Doe'
);
```

### 3. Study Set Management

#### Upload Study Set
```dart
final studySet = StudySet(
  id: 'unique_id',
  title: 'Biology Chapter 1',
  content: 'Study content...',
  flashcards: [...],
  quizzes: [...],
  createdDate: DateTime.now(),
  lastStudied: DateTime.now(),
);

final success = await firebase.uploadStudySet(
  studySet,
  originalFileName: 'biology_ch1.pdf',
  fileType: 'pdf',
  tags: ['biology', 'cells'],
);
```

#### Get User's Study Sets (Real-time Stream)
```dart
firebase.getUserStudySets().listen((studySets) {
  print('📚 Loaded ${studySets.length} study sets');
  for (final studySet in studySets) {
    print('  - ${studySet.title} (${studySet.flashcards.length} cards)');
  }
});
```

#### Update Study Progress
```dart
await firebase.updateStudySetProgress('study_set_id');
```

### 4. Quiz Results & Progress

#### Save Quiz Result
```dart
final success = await firebase.saveQuizResult(
  'study_set_id',
  'quiz_id',
  'Quiz Title',
  8,  // score
  10, // total questions
  Duration(minutes: 5), // time taken
  ['question_3', 'question_7'], // incorrect answers
);
```

#### Get User Progress
```dart
final progress = await firebase.getUserProgress();
if (progress != null) {
  print('Current Streak: ${progress.currentStreak} days');
  print('Total XP: ${progress.totalXP}');
  print('Study Time: ${progress.totalStudyTime} minutes');
}
```

#### Update Streak
```dart
await firebase.updateStreak(15, 20); // current streak, longest streak
```

### 5. Credit Management

#### Check Available Credits
```dart
final credits = await firebase.getAvailableCredits();
print('💳 Available credits: $credits');
```

#### Use Credits for AI Operations
```dart
final success = await firebase.useCredits(5, 'generate_flashcards');
if (success) {
  print('✅ Credits used successfully');
} else {
  print('❌ Insufficient credits');
}
```

### 6. File Upload

#### Upload PDF File
```dart
// From File Picker result
final downloadUrl = await firebase.uploadPDF(pdfFile, userId);
if (downloadUrl != null) {
  print('✅ PDF uploaded: $downloadUrl');
}
```

#### Upload Generic File
```dart
final downloadUrl = await firebase.uploadFile(
  fileBytes,
  'document.pdf',
  userId
);
```

### 7. Push Notifications

#### Get Notification Preferences
```dart
final prefs = await firebase.getNotificationPreferences();
if (prefs != null) {
  print('Daily Reminders: ${prefs.dailyReminders}');
  print('Surprise Quizzes: ${prefs.surpriseQuizzes}');
  print('Reminder Time: ${prefs.reminderTime}');
}
```

#### Update Notification Preferences
```dart
final success = await firebase.updateNotificationPreferences({
  'dailyReminders': true,
  'surpriseQuizzes': false,
  'streakReminders': true,
  'reminderTime': '20:00',
});
```

### 8. Authentication State Management

#### Listen to Auth State Changes
```dart
firebase.addListener(() {
  if (firebase.isAuthenticated) {
    print('✅ User: ${firebase.currentUser?.email}');
    print('📱 Device Token: ${firebase.deviceToken}');
  } else {
    print('❌ User not authenticated');
  }
  
  if (firebase.isOffline) {
    print('📡 Offline mode');
  } else {
    print('🌐 Online');
  }
});
```

#### Sign Out
```dart
await firebase.signOut();
```

#### Delete Account
```dart
final success = await firebase.deleteAccount();
if (success) {
  print('✅ Account deleted');
}
```

#### Reset Password
```dart
final success = await firebase.resetPassword('user@example.com');
if (success) {
  print('✅ Password reset email sent');
}
```

## 📊 Testing Firebase Configuration

### Run Complete Test Suite
```dart
import 'package:mindload/services/firebase_client_test.dart';

final testRunner = FirebaseClientTest();
final results = await testRunner.runCompleteTests();

print('Overall Score: ${results.overallScore}/100');
print('Tests Passed: ${results.passedTests}/${results.totalTests}');

if (results.readyForProduction) {
  print('🎉 Ready for production!');
}
```

### Quick Status Check
```dart
import 'package:mindload/services/firebase_client_test.dart';

await FirebaseQuickTest.runQuickCheck();
```

## 🔧 Configuration Files

Your Firebase configuration includes these files:

### 1. `firebase.json` - Project Configuration
```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "functions": {
    "source": "functions",
    "runtime": "nodejs20"
  },
  "hosting": {
    "public": "build/web"
  },
  "storage": {
    "rules": "storage.rules"
  }
}
```

### 2. `firestore.rules` - Database Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /study_sets/{studySetId} {
      allow read: if request.auth != null && (
        resource.data.userId == request.auth.uid || 
        resource.data.isPublic == true
      );
      allow write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
    
    // Additional collections with appropriate rules...
  }
}
```

### 3. `firestore.indexes.json` - Database Indexes
```json
{
  "indexes": [
    {
      "collectionGroup": "study_sets",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "userId", "order": "ASCENDING"},
        {"fieldPath": "lastStudied", "order": "DESCENDING"}
      ]
    }
  ]
}
```

### 4. `lib/firebase_options.dart` - App Configuration
This file contains your Firebase project configuration and is automatically generated by FlutterFire CLI.

## 🗄️ Database Schema

### Collections Structure

1. **users** - User profiles and settings
2. **study_sets** - User's study materials and generated content
3. **quiz_results** - Results from completed quizzes
4. **user_progress** - Learning progress, streaks, and XP
5. **credit_usage** - Daily credit usage tracking
6. **notifications** - Push notification preferences
7. **notification_records** - History of sent notifications

### Data Models

Each collection uses strongly-typed Dart models with `toFirestore()` and `fromFirestore()` methods for seamless data conversion.

## 🔐 Security Best Practices

### Authentication
- Email/password with strong validation
- Google and Apple OAuth integration
- Biometric authentication for returning users
- Secure token management

### Database Rules
- User-based access control
- Field-level validation
- Timestamp requirements
- Public/private content separation

### Data Privacy
- User data isolation
- Automatic cleanup on account deletion
- Encrypted sensitive data
- GDPR compliance ready

## 📱 Platform-Specific Features

### iOS
- Face ID / Touch ID authentication
- Apple Sign In integration
- Rich push notifications
- Background app refresh

### Android
- Fingerprint authentication
- Google Sign In integration
- Notification channels
- Battery optimization handling

### Web
- OAuth redirects
- Local storage persistence
- Service worker notifications
- Progressive Web App features

## 🚨 Error Handling

The Firebase client service provides comprehensive error handling:

```dart
try {
  final result = await firebase.signInWithGoogle();
  if (!result.success) {
    // Handle specific error
    switch (result.error) {
      case 'network-request-failed':
        showSnackbar('Check your internet connection');
        break;
      case 'user-disabled':
        showSnackbar('Account has been disabled');
        break;
      default:
        showSnackbar(result.error ?? 'Unknown error');
    }
  }
} catch (e) {
  // Handle unexpected errors
  showSnackbar('An unexpected error occurred');
}
```

## 📈 Performance Optimization

### Caching
- Offline data persistence enabled
- 100MB cache size configured
- Automatic sync when online

### Query Optimization
- Compound indexes for common queries
- Pagination for large datasets
- Real-time listeners with efficient filters

### Network Usage
- Batch operations where possible
- Compressed uploads
- Delta sync for large documents

## 🔄 Offline Support

Firebase automatically handles offline scenarios:

- **Cached Data**: Previously loaded data available offline
- **Write Operations**: Queued until online
- **Real-time Sync**: Automatic when connection restored
- **Conflict Resolution**: Last-write-wins by default

## 📞 Support & Troubleshooting

### Common Issues

1. **Firebase Not Initialized**
   - Check `firebase_options.dart` exists
   - Verify project ID is not placeholder
   - Ensure Firebase CLI is configured

2. **Authentication Failures**
   - Verify OAuth client IDs
   - Check app signing certificates
   - Review Firebase console settings

3. **Database Permission Denied**
   - Review Firestore security rules
   - Check user authentication status
   - Verify document structure matches rules

4. **Push Notifications Not Working**
   - Check app permissions
   - Verify FCM service account key
   - Test device token generation

### Debug Tools

Use the included test suite to diagnose issues:

```dart
// Complete diagnostic
final testRunner = FirebaseClientTest();
final results = await testRunner.runCompleteTests();

// Quick status check
await FirebaseQuickTest.runQuickCheck();
```

### Logging

Enable detailed logging for troubleshooting:

```dart
// All Firebase operations include detailed console logging
// Check console output for initialization and operation status
```

## 🎯 Next Steps

1. **Configure Firebase Project**: Set up your Firebase project in the console
2. **Update Configuration**: Replace placeholder values with your project details
3. **Test Authentication**: Verify all sign-in methods work correctly
4. **Deploy Security Rules**: Upload Firestore rules and indexes
5. **Enable Services**: Turn on required Firebase services
6. **Test Complete Flow**: Run end-to-end tests with real data

For additional help, refer to:
- `lib/services/firebase_usage_guide.dart` - Code examples
- `lib/services/firebase_client_test.dart` - Testing utilities
- Firebase documentation: https://firebase.google.com/docs