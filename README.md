# MindLoad - AI Study Companion

<div align="center">
  <img src="assets/icon/brain_logo.png" alt="MindLoad Logo" width="200"/>
  
  ### 🧠 AI-Powered Learning Platform
  
  **Version 18** - Enhanced with daily notifications, improved authentication, and comprehensive study tools
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.6.0+-blue.svg)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-3.6.0+-blue.svg)](https://dart.dev)
  [![Firebase](https://img.shields.io/badge/Firebase-Latest-orange.svg)](https://firebase.google.com)
  [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
</div>

---

## 🚀 Features

### 📚 Study Tools
- **AI-Generated Flashcards** - Convert any text into interactive flashcards
- **Smart Quizzes** - Adaptive quizzes based on your study material
- **Ultra Study Mode** - Focus mode with binaural beats for enhanced learning
- **Progress Tracking** - Monitor your learning journey with detailed analytics

### 🔔 Smart Notifications
- **Daily Reminders** - 3x daily notifications (9 AM, 1 PM, 7 PM)
- **Offline Support** - Works completely offline with local notifications
- **Cross-Platform** - iOS and Android compatible
- **Persistent Scheduling** - Continues even after app restarts

### 🔐 Secure Authentication
- **Multiple Sign-In Options** - Google, Apple, Microsoft, Email
- **Biometric Authentication** - Face ID/Touch ID support
- **Enhanced Security** - Fixed authentication crashes and improved error handling
- **Cross-Platform** - Works seamlessly on iOS and Android

### 💰 Economy System
- **Credit-Based System** - Manage study content generation
- **Subscription Plans** - Premium features and unlimited access
- **In-App Purchases** - StoreKit 2 and Google Play Billing support

---

## 📱 Screenshots

<div align="center">
  <img src="docs/screenshots/home.png" alt="Home Screen" width="200"/>
  <img src="docs/screenshots/study.png" alt="Study Mode" width="200"/>
  <img src="docs/screenshots/quiz.png" alt="Quiz Mode" width="200"/>
  <img src="docs/screenshots/notifications.png" alt="Notifications" width="200"/>
</div>

---

## 🛠 Installation

### Prerequisites
- Flutter SDK 3.6.0 or higher
- Dart SDK 3.6.0 or higher
- iOS 13.0+ / Android API 21+
- Firebase project setup

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/mindload.git
   cd mindload
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**
   - Add `google-services.json` to `android/app/`
   - Add `GoogleService-Info.plist` to `ios/Runner/`
   - Enable Authentication providers in Firebase Console
   - Configure Google Sign-In and Apple Sign-In

4. **iOS Configuration**
   - Enable "Sign In with Apple" capability in Xcode
   - Configure URL schemes in `ios/Runner/Info.plist`
   - Add SHA certificates to Firebase Console

5. **Android Configuration**
   - Add SHA-1 and SHA-256 fingerprints to Firebase Console
   - Configure Google Sign-In in Firebase Console

6. **Run the app**
   ```bash
   flutter run
   ```

---

## 🔧 Configuration

### Environment Variables
Create a `.env` file in the root directory:
```env
OPENAI_API_KEY=your_openai_api_key
FIREBASE_PROJECT_ID=your_firebase_project_id
```

### Firebase Setup
1. Create a new Firebase project
2. Enable Authentication with Google and Apple providers
3. Configure Firestore database
4. Set up Firebase Storage
5. Configure Firebase Messaging for notifications

### iOS Specific Setup
```xml
<!-- Add to ios/Runner/Info.plist -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLName</key>
    <string>google-signin</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

---

## 📁 Project Structure

```
lib/
├── config/                 # Configuration files
├── firestore/             # Firestore data models and repository
├── models/                # Data models
├── screens/               # UI screens
├── services/              # Business logic services
├── theme/                 # App theming
├── utils/                 # Utility functions
└── widgets/               # Reusable widgets

assets/
├── audio/                 # Audio files for binaural beats
├── images/                # App images and icons
└── phrases/               # Notification phrases

ios/                       # iOS specific configuration
android/                   # Android specific configuration
web/                       # Web platform files
```

---

## 🧪 Testing

### Run Tests
```bash
flutter test
```

### Test Notifications
1. Navigate to `/notification-debug` route
2. Use "Setup 3x Daily Notifications" button
3. Test daily notification system
4. Verify notification scheduling

### Test Authentication
1. Test Google Sign-In on iOS and Android
2. Test Apple Sign-In on iOS devices
3. Verify error handling and user feedback

---

## 🚀 Deployment

### iOS App Store
```bash
flutter build ios --release
# Open ios/Runner.xcworkspace in Xcode
# Archive and upload to App Store Connect
```

### Android Play Store
```bash
flutter build appbundle --release
# Upload app bundle to Google Play Console
```

### Web Deployment
```bash
flutter build web --release
# Deploy build/web/ directory to your hosting service
```

---

## 🔄 Recent Updates (Version 18)

### ✅ Fixed Issues
- **Authentication Crashes** - Resolved Google and Apple Sign-In crashes on iOS
- **Daily Notifications** - Implemented robust daily notification system
- **Error Handling** - Enhanced error messages and user feedback
- **Platform Compatibility** - Improved iOS and Android support

### 🆕 New Features
- **Daily Study Reminders** - Automatic 3x daily notifications
- **Enhanced Authentication** - Better error handling and user guidance
- **Improved Performance** - Optimized app startup and memory usage
- **Better Debugging** - Enhanced logging and error reporting

### 🔧 Technical Improvements
- **Timeout Protection** - 60-second timeouts for authentication
- **Platform-Specific Code** - iOS and Android optimized flows
- **Better Error Messages** - User-friendly error descriptions
- **Enhanced Logging** - Comprehensive debug information

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Flutter best practices
- Write comprehensive tests
- Update documentation for new features
- Ensure cross-platform compatibility

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🆘 Support

- **Documentation**: [Wiki](https://github.com/yourusername/mindload/wiki)
- **Issues**: [GitHub Issues](https://github.com/yourusername/mindload/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/mindload/discussions)
- **Email**: support@mindload.app

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase team for backend services
- OpenAI for AI capabilities
- All contributors and beta testers

---

<div align="center">
  <p>Made with ❤️ by the MindLoad Team</p>
  <p>Version 18 - Enhanced Learning Experience</p>
</div>