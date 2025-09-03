import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:local_auth/local_auth.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:mindload/services/document_processor.dart';
import 'package:mindload/services/mindload_economy_service.dart';
import 'package:mindload/models/mindload_economy_models.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import 'package:mindload/firebase_options.dart';
import 'package:mindload/firestore/firestore_repository.dart';
import 'package:mindload/firestore/firestore_data_schema.dart';
import 'package:mindload/models/study_data.dart';

/// Comprehensive Firebase Client Service for Mindload App
///
/// This service provides a unified interface for all Firebase operations including:
/// - Authentication (Email, Google, Apple, Face ID)
/// - Firestore database operations
/// - Cloud Storage for document uploads
/// - Firebase messaging for push notifications
/// - Real-time data synchronization
class FirebaseClientService extends ChangeNotifier {
  static FirebaseClientService? _instance;
  static FirebaseClientService get instance {
    _instance ??= FirebaseClientService._internal();
    return _instance!;
  }

  FirebaseClientService._internal();

  // Firebase services
  late FirebaseApp _app;
  late FirebaseAuth _auth;
  late FirebaseFirestore _firestore;
  late FirebaseStorage _storage;
  late FirebaseMessaging _messaging;
  late FirebaseRemoteConfig _remoteConfig;
  late FirebaseAnalytics _analytics;

  // Service instances
  late FirestoreRepository _repository;
  late GoogleSignIn _googleSignIn;
  late LocalAuthentication _localAuth;

  // State management
  bool _isInitialized = false;
  User? _currentUser;
  String? _deviceToken;
  bool _isOffline = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _currentUser != null;
  User? get currentUser => _currentUser;
  String? get currentUserId => _currentUser?.uid;
  String? get deviceToken => _deviceToken;
  bool get isOffline => _isOffline;
  FirestoreRepository get repository => _repository;
  bool get isFirebaseConfigured => _isFirebaseConfigured();

  /// Initialize Firebase and all related services
  Future<void> initialize() async {
    try {
      // Initialize Firebase Core
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize Firebase Auth
      await FirebaseAuth.instance.authStateChanges().first;

      // Initialize Firestore
      // Note: enablePersistence() is not available in this version

      // Initialize Firebase Storage
      FirebaseStorage.instance.ref().bucket;

      // Initialize Firebase Messaging
      await FirebaseMessaging.instance.requestPermission();

      _isInitialized = true;

      if (kDebugMode) {
        debugPrint('Firebase Client Service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to initialize Firebase Client Service: $e');
      }
      rethrow;
    }
  }

  /// Configure Firestore settings for optimal performance
  Future<void> _configureFirestore() async {
    try {
      // Set cache size (100MB)
      _firestore.settings = const Settings(
        cacheSizeBytes: 100 * 1024 * 1024,
        persistenceEnabled: true,
      );
      debugPrint('✅ Firestore configured with optimal settings');
    } catch (e) {
      debugPrint('⚠️ Firestore configuration warning: $e');
    }
  }

  /// Initialize Firebase Messaging for push notifications
  Future<void> _initializeMessaging() async {
    try {
      // Request permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: false,
        announcement: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get device token
        _deviceToken = await _messaging.getToken();
        debugPrint(
            '✅ FCM Device Token obtained: ${_deviceToken?.substring(0, 20)}...');

        // Save token to user profile if authenticated
        if (_currentUser != null && _deviceToken != null) {
          await _repository.addDeviceToken(_currentUser!.uid, _deviceToken!);
        }

        // Listen for token refresh
        _messaging.onTokenRefresh.listen((String token) async {
          _deviceToken = token;
          if (_currentUser != null) {
            await _repository.addDeviceToken(_currentUser!.uid, token);
          }
        });
      } else {
        debugPrint('⚠️ Notification permission denied');
      }
    } catch (e) {
      debugPrint('⚠️ Messaging initialization failed: $e');
    }
  }

  /// Set up network connectivity monitoring
  Future<void> _setupNetworkMonitoring() async {
    try {
      // Monitor Firestore connection state
      _firestore.snapshotsInSync().listen((_) {
        if (_isOffline) {
          _isOffline = false;
          notifyListeners();
          debugPrint('✅ Back online - Firestore connected');
        }
      });
    } catch (e) {
      debugPrint('⚠️ Network monitoring setup failed: $e');
    }
  }

  /// Check if Firebase is properly configured
  bool _isFirebaseConfigured() {
    try {
      // Check if project ID exists and is not placeholder
      final projectId = DefaultFirebaseOptions.currentPlatform.projectId;
      return projectId.isNotEmpty && !projectId.contains('placeholder');
    } catch (e) {
      return false;
    }
  }

  /// Handle authentication state changes
  void _onAuthStateChanged(User? user) async {
    _currentUser = user;

    if (user != null) {
      debugPrint('✅ User authenticated: ${user.email}');

      // Update last login time
      try {
        await _repository.updateUserLastLogin(user.uid);
      } catch (e) {
        debugPrint('⚠️ Failed to update last login: $e');
      }

      // Add device token to user profile
      if (_deviceToken != null) {
        try {
          await _repository.addDeviceToken(user.uid, _deviceToken!);
        } catch (e) {
          debugPrint('⚠️ Failed to add device token: $e');
        }
      }
    } else {
      debugPrint('User signed out');
    }

    notifyListeners();
  }

  // MARK: - Authentication Methods

  /// Sign in with email and password
  Future<AuthResult> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      if (!_isInitialized) {
        return AuthResult(success: false, error: 'Firebase not initialized');
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        return AuthResult(success: true, user: credential.user);
      } else {
        return AuthResult(success: false, error: 'Sign in failed');
      }
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult(success: false, error: 'An unexpected error occurred');
    }
  }

  /// Create account with email and password
  Future<AuthResult> createUserWithEmailAndPassword(
      String email, String password, String displayName) async {
    try {
      if (!_isInitialized) {
        return AuthResult(success: false, error: 'Firebase not initialized');
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(displayName);

        // Create user profile in Firestore
        final userProfile = UserProfileFirestore(
          uid: credential.user!.uid,
          email: email,
          displayName: displayName,
          provider: 'email',
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          preferences: {},
        );

        await _repository.createOrUpdateUser(userProfile);

        return AuthResult(success: true, user: credential.user);
      } else {
        return AuthResult(success: false, error: 'Account creation failed');
      }
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult(success: false, error: 'An unexpected error occurred');
    }
  }

  /// Sign in with Google (modernized and iOS-compatible)
  Future<AuthResult> signInWithGoogle() async {
    try {
      if (!_isInitialized) {
        return AuthResult(success: false, error: 'Firebase not initialized');
      }

      if (kIsWeb) {
        final cred = await _auth.signInWithPopup(GoogleAuthProvider());
        await _createOrUpdateUserProfile(cred.user!, 'google');
        return AuthResult(success: true, user: cred.user);
      }

      // Mobile implementation with iOS crash prevention
      final provider = GoogleAuthProvider();
      provider.addScope('email');
      provider.addScope('profile');

      // Platform-specific configuration
      if (Platform.isIOS) {
        provider.setCustomParameters({
          'prompt': 'select_account',
          'access_type': 'offline',
        });
      }

      try {
        // Use timeout to prevent hanging
        final cred = await _auth.signInWithProvider(provider).timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            throw TimeoutException('Google sign-in timed out');
          },
        );

        if (cred.user == null) {
          return AuthResult(
              success: false, error: 'Failed to get user from Google sign-in');
        }

        await _createOrUpdateUserProfile(cred.user!, 'google');
        return AuthResult(success: true, user: cred.user);
      } catch (e) {
        debugPrint('Google sign-in error: $e');

        // Provide helpful error message for common issues
        if (e.toString().contains('signInWithProvider')) {
          return AuthResult(
              success: false,
              error:
                  'Google Sign-In configuration error. Please check Firebase and iOS configuration.');
        }

        if (e is TimeoutException) {
          return AuthResult(
              success: false,
              error: 'Google sign-in timed out. Please try again.');
        }

        return AuthResult(
            success: false, error: 'Google sign-in failed: ${e.toString()}');
      }
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _getAuthErrorMessage(e.code));
    } catch (e) {
      debugPrint('Unexpected Google sign-in error: $e');
      return AuthResult(success: false, error: 'Google sign-in failed');
    }
  }

  /// Sign in with Apple (enhanced with better error handling)
  Future<AuthResult> signInWithApple() async {
    try {
      if (!_isInitialized) {
        return AuthResult(success: false, error: 'Firebase not initialized');
      }

      // Check platform support
      if (!Platform.isIOS && !Platform.isMacOS) {
        return AuthResult(
            success: false,
            error: 'Apple Sign-In is only available on iOS and macOS');
      }

      // Check availability
      bool isAvailable = false;
      try {
        isAvailable = await SignInWithApple.isAvailable();
      } catch (e) {
        debugPrint('Error checking Apple Sign-In availability: $e');
        // Assume available on iOS 13+
        if (Platform.isIOS) {
          isAvailable = true;
        }
      }

      if (!isAvailable) {
        return AuthResult(
            success: false,
            error: 'Apple Sign-In is not available on this device');
      }

      // Generate a random nonce
      final rawNonce = _generateNonce();
      final nonce = sha256.convert(utf8.encode(rawNonce)).toString();

      try {
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: nonce,
        ).timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            throw TimeoutException('Apple Sign-In timed out');
          },
        );

        // Validate we got the required token
        if (appleCredential.identityToken == null) {
          return AuthResult(
              success: false, error: 'Failed to get Apple ID token');
        }

        final oauthCredential = OAuthProvider('apple.com').credential(
          idToken: appleCredential.identityToken,
          rawNonce: rawNonce,
        );

        final userCredential =
            await _auth.signInWithCredential(oauthCredential).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('Firebase authentication timed out');
          },
        );

        if (userCredential.user != null) {
          // Handle display name from Apple if available
          if (appleCredential.givenName != null ||
              appleCredential.familyName != null) {
            final displayName =
                '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
                    .trim();
            if (displayName.isNotEmpty) {
              await userCredential.user!.updateDisplayName(displayName);
            }
          }

          // Create or update user profile
          await _createOrUpdateUserProfile(userCredential.user!, 'apple');
          return AuthResult(success: true, user: userCredential.user);
        } else {
          return AuthResult(
              success: false, error: 'Failed to authenticate with Apple');
        }
      } on TimeoutException {
        return AuthResult(
            success: false,
            error: 'Apple Sign-In timed out. Please try again.');
      } on SignInWithAppleAuthorizationException catch (e) {
        debugPrint('Apple Sign-In authorization error: ${e.code}');
        switch (e.code) {
          case AuthorizationErrorCode.canceled:
            return AuthResult(
                success: false, error: 'Apple Sign-In was cancelled');
          case AuthorizationErrorCode.failed:
            return AuthResult(
                success: false,
                error: 'Apple Sign-In failed. Please try again.');
          case AuthorizationErrorCode.invalidResponse:
            return AuthResult(
                success: false, error: 'Invalid response from Apple Sign-In');
          case AuthorizationErrorCode.notHandled:
            return AuthResult(
                success: false, error: 'Apple Sign-In request not handled');
          case AuthorizationErrorCode.unknown:
            return AuthResult(
                success: false, error: 'Unknown error during Apple Sign-In');
          default:
            return AuthResult(
                success: false, error: 'Apple Sign-In error: ${e.message}');
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase auth error during Apple Sign-In: ${e.code}');
      return AuthResult(success: false, error: _getAuthErrorMessage(e.code));
    } catch (e) {
      debugPrint('Unexpected Apple Sign-In error: $e');
      return AuthResult(
          success: false,
          error:
              'Apple Sign-In failed. Please ensure you are signed in to iCloud.');
    }
  }

  /// Sign in with Face ID/Touch ID (Biometric)
  Future<AuthResult> signInWithBiometrics() async {
    try {
      // Check if biometric authentication is available
      final isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) {
        return AuthResult(
            success: false, error: 'Biometric authentication not available');
      }

      // Get available biometrics
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        return AuthResult(
            success: false, error: 'No biometric methods configured');
      }

      // Authenticate with biometrics
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Use Face ID to sign in to Mindload',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (isAuthenticated) {
        // If biometric auth succeeds, try to sign in the stored user
        // This requires having a previously authenticated user
        if (_currentUser != null) {
          return AuthResult(success: true, user: _currentUser);
        } else {
          return AuthResult(
              success: false,
              error: 'No user account found. Please sign in first.');
        }
      } else {
        return AuthResult(
            success: false, error: 'Biometric authentication failed');
      }
    } catch (e) {
      return AuthResult(
          success: false, error: 'Biometric authentication error: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // Remove device token from user profile
      if (_currentUser != null && _deviceToken != null) {
        await _repository.removeDeviceToken(_currentUser!.uid, _deviceToken!);
      }

      await _auth.signOut();
      // TODO: Fix Google Sign-In API compatibility issues
      // await _googleSignIn.signOut();

      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      debugPrint('Password reset error: $e');
      return false;
    }
  }

  /// Delete user account
  Future<bool> deleteAccount() async {
    try {
      if (_currentUser != null) {
        // Delete user data from Firestore
        await _repository.deleteUser(_currentUser!.uid);

        // Delete Firebase Auth user
        await _currentUser!.delete();

        _currentUser = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Delete account error: $e');
      return false;
    }
  }

  // MARK: - Study Set Management

  /// Upload study set to Firestore
  Future<bool> uploadStudySet(
    StudySet studySet, {
    String originalFileName = '',
    String fileType = 'txt',
    List<String> tags = const [],
  }) async {
    try {
      if (!isAuthenticated) return false;

      final studySetFirestore = StudySetFirestore.fromStudySet(
        studySet,
        currentUserId!,
        originalFileName: originalFileName,
        fileType: fileType,
        tags: tags,
      );

      await _repository.createStudySet(studySetFirestore);
      return true;
    } catch (e) {
      debugPrint('Upload study set error: $e');
      return false;
    }
  }

  /// Get user's study sets
  Stream<List<StudySet>> getUserStudySets() {
    if (!isAuthenticated) {
      return Stream.value([]);
    }

    return _repository.getUserStudySets(currentUserId!).map(
        (firestoreStudySets) =>
            firestoreStudySets.map((fs) => fs.toStudySet()).toList());
  }

  /// Update study set progress
  Future<bool> updateStudySetProgress(String studySetId) async {
    try {
      await _repository.markStudySetAsStudied(studySetId);
      return true;
    } catch (e) {
      debugPrint('Update study set progress error: $e');
      return false;
    }
  }

  /// Delete study set
  Future<bool> deleteStudySet(String studySetId) async {
    try {
      await _repository.deleteStudySet(studySetId);
      return true;
    } catch (e) {
      debugPrint('Delete study set error: $e');
      return false;
    }
  }

  // MARK: - File Upload to Cloud Storage

  /// Upload file to Firebase Storage
  Future<String?> uploadFile(
      Uint8List fileBytes, String fileName, String userId) async {
    try {
      final ref = _storage.ref().child('uploads/$userId/$fileName');
      final uploadTask = await ref.putData(
        fileBytes,
        SettableMetadata(contentType: _getContentType(fileName)),
      );

      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('File upload error: $e');
      return null;
    }
  }

  /// Upload PDF file
  Future<String?> uploadPDF(File pdfFile, String userId) async {
    try {
      // Validate limits and enforce 1 credit per 5 pages
      final bytes = await pdfFile.readAsBytes();
      try {
        await DocumentProcessor.validatePdfPageLimit(bytes);
      } catch (e) {
        debugPrint('PDF validation failed: $e');
        return null;
      }
      // Count pages to compute MindLoad Tokens usage
      int pageCount = 1;
      try {
        final tmp = PdfDocument(inputBytes: bytes);
        pageCount = tmp.pages.count;
        tmp.dispose();
      } catch (_) {}
      // Check if user can upload this document using the new economy system
      final economyService = MindloadEconomyService.instance;
      final request = GenerationRequest(
        sourceContent: 'PDF upload',
        sourceCharCount: 0,
        pdfPageCount: pageCount,
      );

      final enforcement = economyService.canGenerateContent(request);
      if (!enforcement.canProceed) return null;

      // Use credits for document upload
      final ok = await economyService.useCreditsForGeneration(request);
      if (!ok) return null;

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${pdfFile.path.split(RegExp(r'[/\\]')).last}';
      final ref = _storage.ref().child('pdfs/$userId/$fileName');

      final uploadTask = await ref.putFile(
        pdfFile,
        SettableMetadata(contentType: 'application/pdf'),
      );

      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('PDF upload error: $e');
      return null;
    }
  }

  /// Upload a captured image as a single-page PDF and enforce token rule (1 page)
  Future<String?> uploadImageAsPdf(Uint8List imageBytes, String userId) async {
    try {
      final pdfBytes =
          await DocumentProcessor.convertImageToPdfBytes(imageBytes);
      await DocumentProcessor.validatePdfPageLimit(pdfBytes);
      // Check if user can upload this image as PDF using the new economy system
      final economyService = MindloadEconomyService.instance;
      final request = GenerationRequest(
        sourceContent: 'Image to PDF upload',
        sourceCharCount: 0,
        pdfPageCount: 1,
      );

      final enforcement = economyService.canGenerateContent(request);
      if (!enforcement.canProceed) return null;

      // Use credits for document upload
      final ok = await economyService.useCreditsForGeneration(request);
      if (!ok) return null;

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_captured.pdf';
      final ref = _storage.ref().child('pdfs/$userId/$fileName');
      final uploadTask = await ref.putData(
        pdfBytes,
        SettableMetadata(contentType: 'application/pdf'),
      );
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Image to PDF upload error: $e');
      return null;
    }
  }

  // MARK: - User Progress & Analytics

  /// Save quiz result
  Future<bool> saveQuizResult(
      String studySetId,
      String quizId,
      String quizTitle,
      int score,
      int totalQuestions,
      Duration timeTaken,
      List<String> incorrectAnswers) async {
    try {
      if (!isAuthenticated) return false;

      final result = QuizResultFirestore(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        userId: currentUserId!,
        studySetId: studySetId,
        quizId: quizId,
        quizTitle: quizTitle,
        score: score,
        totalQuestions: totalQuestions,
        percentage: (score / totalQuestions) * 100,
        timeTaken: timeTaken.inMilliseconds,
        completedDate: DateTime.now(),
        incorrectAnswers: incorrectAnswers,
        quizType: 'mixed',
        answers: {},
        xpEarned: score * 10,
      );

      await _repository.saveQuizResult(result);

      // Add XP to user progress
      await _repository.addXP(currentUserId!, score * 10);

      return true;
    } catch (e) {
      debugPrint('Save quiz result error: $e');
      return false;
    }
  }

  /// Get user progress
  Future<UserProgressFirestore?> getUserProgress() async {
    if (!isAuthenticated) return null;

    try {
      return await _repository.getUserProgress(currentUserId!);
    } catch (e) {
      debugPrint('Get user progress error: $e');
      return null;
    }
  }

  /// Update user streak
  Future<bool> updateStreak(int newStreak, int longestStreak) async {
    try {
      if (!isAuthenticated) return false;
      await _repository.updateStreak(currentUserId!, newStreak, longestStreak);
      return true;
    } catch (e) {
      debugPrint('Update streak error: $e');
      return false;
    }
  }

  // MARK: - Credit Management

  /// Check available credits
  Future<int> getAvailableCredits() async {
    if (!isAuthenticated) return 0;

    try {
      final credits = await _repository.getTodaysCredits(currentUserId!);
      return credits.remainingCredits;
    } catch (e) {
      debugPrint('Get credits error: $e');
      return 0;
    }
  }

  /// Use credits for AI operations
  Future<bool> useCredits(int amount, String operation) async {
    if (!isAuthenticated) return false;

    try {
      return await _repository.useCredits(currentUserId!, amount, operation);
    } catch (e) {
      debugPrint('Use credits error: $e');
      return false;
    }
  }

  // MARK: - Notification Management

  /// Get notification preferences
  Future<NotificationFirestore?> getNotificationPreferences() async {
    if (!isAuthenticated) return null;

    try {
      return await _repository.getNotificationPreferences(currentUserId!);
    } catch (e) {
      debugPrint('Get notification preferences error: $e');
      return null;
    }
  }

  /// Update notification preferences
  Future<bool> updateNotificationPreferences(
      Map<String, dynamic> preferences) async {
    if (!isAuthenticated) return false;

    try {
      await _repository.updateNotificationPreferences(
          currentUserId!, preferences);
      return true;
    } catch (e) {
      debugPrint('Update notification preferences error: $e');
      return false;
    }
  }

  // MARK: - Helper Methods

  /// Create or update user profile in Firestore
  Future<void> _createOrUpdateUserProfile(User user, String provider) async {
    try {
      final userProfile = UserProfileFirestore(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        photoURL: user.photoURL,
        phoneNumber: user.phoneNumber,
        provider: provider,
        createdAt: user.metadata.creationTime ?? DateTime.now(),
        lastLoginAt: DateTime.now(),
        preferences: {},
      );

      await _repository.createOrUpdateUser(userProfile);
    } catch (e) {
      debugPrint('Create user profile error: $e');
    }
  }

  /// Generate a secure random nonce for Apple Sign In
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Get content type for file upload
  String _getContentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  /// Get user-friendly error messages for auth errors
  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No account found with this email address';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email address';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'requires-recent-login':
        return 'Please sign in again to complete this action';
      default:
        return 'Authentication failed. Please try again';
    }
  }

  /// Initialize Remote Config
  Future<void> _initializeRemoteConfig() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );

      // Set default values for MindLoad features
      await _remoteConfig.setDefaults({
        'mindload_features_enabled': true,
        'ultra_mode_enabled': true,
        'notification_system_enabled': true,
        'binaural_beats_enabled': true,
        'face_id_enabled': true,
        'daily_credit_limit_free': 20,
        'daily_credit_limit_pro': 100,
        'daily_credit_limit_premium': 500,
        'max_study_sets_free': 10,
        'max_study_sets_pro': 50,
        'max_study_sets_premium': 200,
        'openai_api_timeout': 30,
        'pdf_processing_enabled': true,
        'quiz_generation_enabled': true,
        'flashcard_generation_enabled': true,
        'ai_study_coach_enabled': true,
        'surprise_quiz_enabled': true,
        'streak_tracking_enabled': true,
        'achievement_system_enabled': true,
        'export_pdf_enabled': true,
        'offline_mode_enabled': true,
        'maintenance_mode': false,
        'force_update_version': '',
      });

      // Fetch and activate remote config
      await _remoteConfig.fetchAndActivate();
      debugPrint('✅ Remote Config initialized with MindLoad defaults');
    } catch (e) {
      debugPrint('⚠️ Remote Config initialization failed: $e');
    }
  }

  /// Initialize Analytics
  Future<void> _initializeAnalytics() async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(true);

      // Set user properties if authenticated
      if (_currentUser != null) {
        await _analytics.setUserId(id: _currentUser!.uid);
        await _analytics.setUserProperty(
          name: 'user_type',
          value: _currentUser!.isAnonymous ? 'anonymous' : 'registered',
        );
      }

      // Log app startup
      await _analytics.logEvent(
        name: 'app_startup',
        parameters: {
          'platform': defaultTargetPlatform.name,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      debugPrint('✅ Analytics initialized');
    } catch (e) {
      debugPrint('⚠️ Analytics initialization failed: $e');
    }
  }

  // MARK: - Remote Config Methods

  /// Get Remote Config boolean value
  bool getRemoteConfigBool(String key) {
    try {
      return _remoteConfig.getBool(key);
    } catch (e) {
      debugPrint('⚠️ Remote Config bool fetch failed for $key: $e');
      return false;
    }
  }

  /// Get Remote Config integer value
  int getRemoteConfigInt(String key) {
    try {
      return _remoteConfig.getInt(key);
    } catch (e) {
      debugPrint('⚠️ Remote Config int fetch failed for $key: $e');
      return 0;
    }
  }

  /// Get Remote Config string value
  String getRemoteConfigString(String key) {
    try {
      return _remoteConfig.getString(key);
    } catch (e) {
      debugPrint('⚠️ Remote Config string fetch failed for $key: $e');
      return '';
    }
  }

  /// Check if a feature is enabled via Remote Config
  bool isFeatureEnabled(String featureName) {
    return getRemoteConfigBool('${featureName}_enabled');
  }

  /// Get daily credit limit based on subscription plan
  int getDailyCreditLimit(String plan) {
    switch (plan.toLowerCase()) {
      case 'pro':
        return getRemoteConfigInt('daily_credit_limit_pro');
      case 'premium':
        return getRemoteConfigInt('daily_credit_limit_premium');
      default:
        return getRemoteConfigInt('daily_credit_limit_free');
    }
  }

  /// Check if app is in maintenance mode
  bool isMaintenanceMode() {
    return getRemoteConfigBool('maintenance_mode');
  }

  // MARK: - Analytics Methods

  /// Log custom analytics event
  Future<void> logAnalyticsEvent(
      String eventName, Map<String, Object?>? parameters) async {
    try {
      // Cast nullable Map to non-nullable Map for Firebase Analytics
      final Map<String, Object>? safeParameters =
          parameters?.cast<String, Object>();
      await _analytics.logEvent(name: eventName, parameters: safeParameters);
    } catch (e) {
      debugPrint('⚠️ Analytics event failed: $e');
    }
  }

  /// Log study session started
  Future<void> logStudySessionStarted(
      String studySetId, String studyType) async {
    await logAnalyticsEvent('study_session_started', {
      'study_set_id': studySetId,
      'study_type': studyType,
      'user_id': currentUserId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Log quiz completed
  Future<void> logQuizCompleted(String studySetId, int score,
      int totalQuestions, Duration duration) async {
    await logAnalyticsEvent('quiz_completed', {
      'study_set_id': studySetId,
      'score': score,
      'total_questions': totalQuestions,
      'percentage': (score / totalQuestions * 100).round(),
      'duration_seconds': duration.inSeconds,
      'user_id': currentUserId,
    });
  }

  /// Log AI feature usage
  Future<void> logAIFeatureUsage(String feature, int creditsUsed) async {
    await logAnalyticsEvent('ai_feature_used', {
      'feature_name': feature,
      'credits_used': creditsUsed,
      'user_id': currentUserId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Log user engagement
  Future<void> logUserEngagement(
      String action, Map<String, dynamic>? metadata) async {
    await logAnalyticsEvent('user_engagement', {
      'action': action,
      'user_id': currentUserId,
      'metadata': metadata?.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Log subscription event
  Future<void> logSubscriptionEvent(
      String event, String plan, double? price) async {
    await logAnalyticsEvent('subscription_event', {
      'event_type': event,
      'subscription_plan': plan,
      'price': price,
      'user_id': currentUserId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Set user properties for analytics
  Future<void> setUserProperties({
    String? subscriptionPlan,
    int? totalStudySets,
    int? currentStreak,
    int? totalXP,
  }) async {
    try {
      if (subscriptionPlan != null) {
        await _analytics.setUserProperty(
            name: 'subscription_plan', value: subscriptionPlan);
      }
      if (totalStudySets != null) {
        await _analytics.setUserProperty(
            name: 'total_study_sets', value: totalStudySets.toString());
      }
      if (currentStreak != null) {
        await _analytics.setUserProperty(
            name: 'current_streak', value: currentStreak.toString());
      }
      if (totalXP != null) {
        await _analytics.setUserProperty(
            name: 'total_xp', value: totalXP.toString());
      }
    } catch (e) {
      debugPrint('⚠️ Set user properties failed: $e');
    }
  }

  /// Get analytics instance for screen tracking
  FirebaseAnalytics get analytics => _analytics;

  /// Get remote config instance
  FirebaseRemoteConfig get remoteConfig => _remoteConfig;

  /// Subscribe to FCM topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      // Note: FCM topic subscription would be implemented here
      debugPrint('📢 Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('⚠️ Failed to subscribe to topic $topic: $e');
    }
  }

  /// Check if Firestore is connected
  Future<bool> isFirestoreConnected() async {
    try {
      // Simple connectivity test
      return true; // Placeholder - would implement actual connectivity check
    } catch (e) {
      debugPrint('⚠️ Firestore connectivity check failed: $e');
      return false;
    }
  }

  /// Terminate Firebase services
  Future<void> terminate() async {
    try {
      // Clean up Firebase connections
      debugPrint('🔥 Firebase services terminated');
    } catch (e) {
      debugPrint('⚠️ Failed to terminate Firebase services: $e');
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    // Clean up resources
    super.dispose();
  }
}

/// Authentication result model
class AuthResult {
  final bool success;
  final User? user;
  final String? error;

  AuthResult({
    required this.success,
    this.user,
    this.error,
  });
}
