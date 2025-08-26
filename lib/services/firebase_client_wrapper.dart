import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mindload/services/firebase_client_service.dart';
import 'package:mindload/services/firebase_mindload_service.dart';
import 'package:mindload/firestore/firestore_repository.dart';
import 'package:mindload/firestore/firestore_helper.dart';
import 'package:mindload/models/study_data.dart';

// Re-export commonly used models for convenience
export 'package:mindload/services/firebase_mindload_service.dart' show 
    StudyRecommendation, 
    StudyScheduleItem, 
    StudyAnalytics,
    RecommendationType;

/// Unified Firebase Client Wrapper for MindLoad
/// This service provides a single entry point for all Firebase operations
class FirebaseClientWrapper extends ChangeNotifier {
  static FirebaseClientWrapper? _instance;
  static FirebaseClientWrapper get instance => _instance ??= FirebaseClientWrapper._internal();

  FirebaseClientWrapper._internal();

  // Core services
  final FirebaseClientService _firebaseClient = FirebaseClientService.instance;
  final FirebaseMindLoadService _mindloadService = FirebaseMindLoadService.instance;

  // State
  bool _isInitialized = false;
  String? _initializationError;
  late StreamSubscription<User?> _authSubscription;

  // Getters
  bool get isInitialized => _isInitialized;
  String? get initializationError => _initializationError;
  bool get isAuthenticated => _firebaseClient.isAuthenticated;
  User? get currentUser => _firebaseClient.currentUser;
  String? get currentUserId => _firebaseClient.currentUserId;
  FirestoreRepository? get repository => _firebaseClient.repository;

  /// Initialize the wrapper
  Future<void> initialize() async {
    try {
      await _firebaseClient.initialize();
      _isInitialized = true;
      
      if (kDebugMode) {
        debugPrint('Firebase Client Wrapper initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to initialize Firebase Client Wrapper: $e');
      }
      rethrow;
    }
  }

  /// Handle authentication state changes
  void _onAuthStateChanged(User? user) {
    print('🔐 Auth state changed: ${user?.email ?? 'Not signed in'}');
    notifyListeners();
    
    if (user != null) {
      // Set up user-specific configurations
      _setupUserConfiguration(user);
    } else {
      // Clean up user-specific data
      _cleanupUserData();
    }
  }

  /// Set up user-specific configurations
  Future<void> _setupUserConfiguration(User user) async {
    try {
      // Set analytics user properties
      await _firebaseClient.setUserProperties();
      
      // Subscribe to user-specific FCM topics
      await _firebaseClient.subscribeToTopic('user_${user.uid}');
      await _firebaseClient.subscribeToTopic('all_users');
      
      // Log user login event
      await _firebaseClient.logAnalyticsEvent('user_login', {
        'user_id': user.uid,
        'email': user.email,
        'provider': user.providerData.first.providerId,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
    } catch (e) {
      print('⚠️ Failed to setup user configuration: $e');
    }
  }

  /// Clean up user-specific data
  Future<void> _cleanupUserData() async {
    try {
      // Clear any cached user data
      await FirestoreHelper.clearCache();
      
      // Log user logout event
      await _firebaseClient.logAnalyticsEvent('user_logout', {
        'timestamp': DateTime.now().toIso8601String(),
      });
      
    } catch (e) {
      print('⚠️ Failed to cleanup user data: $e');
    }
  }

  // MARK: - Authentication Methods

  /// Sign in with email and password
  Future<AuthResult> signInWithEmail(String email, String password) async {
    if (!_isInitialized) {
      return AuthResult(success: false, error: 'Firebase not initialized');
    }
    
    return await _firebaseClient.signInWithEmailAndPassword(email, password);
  }

  /// Create account with email and password
  Future<AuthResult> createAccount(String email, String password, String displayName) async {
    if (!_isInitialized) {
      return AuthResult(success: false, error: 'Firebase not initialized');
    }
    
    return await _firebaseClient.createUserWithEmailAndPassword(email, password, displayName);
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    if (!_isInitialized) {
      return AuthResult(success: false, error: 'Firebase not initialized');
    }
    
    return await _firebaseClient.signInWithGoogle();
  }

  /// Sign in with Apple
  Future<AuthResult> signInWithApple() async {
    if (!_isInitialized) {
      return AuthResult(success: false, error: 'Firebase not initialized');
    }
    
    return await _firebaseClient.signInWithApple();
  }

  /// Sign in with biometrics (Face ID/Touch ID)
  Future<AuthResult> signInWithBiometrics() async {
    if (!_isInitialized) {
      return AuthResult(success: false, error: 'Firebase not initialized');
    }
    
    return await _firebaseClient.signInWithBiometrics();
  }

  /// Sign out current user
  Future<void> signOut() async {
    if (!_isInitialized) return;
    
    await _firebaseClient.signOut();
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    if (!_isInitialized) return false;
    
    return await _firebaseClient.resetPassword(email);
  }

  /// Delete account
  Future<bool> deleteAccount() async {
    if (!_isInitialized) return false;
    
    return await _firebaseClient.deleteAccount();
  }

  // MARK: - Study Management

  /// Get user's study sets with real-time updates
  Stream<List<StudySet>> getStudySets() {
    // Feature flag: gate cloud study sets to prevent accidental switches
    const bool enableCloudStudySets = bool.fromEnvironment('ENABLE_CLOUD_STUDY_SETS', defaultValue: false);
    if (!enableCloudStudySets || !_isInitialized || !isAuthenticated) {
      return Stream.value([]);
    }
    
    return _firebaseClient.getUserStudySets();
  }

  /// Upload new study set
  Future<bool> uploadStudySet(
    StudySet studySet, {
    String originalFileName = '',
    String fileType = 'txt',
    List<String> tags = const [],
  }) async {
    if (!_isInitialized || !isAuthenticated) return false;
    
    return await _firebaseClient.uploadStudySet(
      studySet,
      originalFileName: originalFileName,
      fileType: fileType,
      tags: tags,
    );
  }

  /// Update study set progress
  Future<bool> updateStudyProgress(String studySetId) async {
    if (!_isInitialized || !isAuthenticated) return false;
    
    return await _firebaseClient.updateStudySetProgress(studySetId);
  }

  /// Delete study set
  Future<bool> deleteStudySet(String studySetId) async {
    if (!_isInitialized || !isAuthenticated) return false;
    
    return await _firebaseClient.deleteStudySet(studySetId);
  }

  // MARK: - AI & Analytics

  /// Get study recommendations
  Future<List<StudyRecommendation>> getStudyRecommendations() async {
    if (!_isInitialized || !isAuthenticated) return [];
    
    return await _mindloadService.getStudyRecommendations();
  }

  /// Generate personalized study schedule
  Future<List<StudyScheduleItem>> generateStudySchedule({int daysAhead = 7}) async {
    if (!_isInitialized || !isAuthenticated) return [];
    
    return await _mindloadService.generatePersonalizedSchedule(daysAhead: daysAhead);
  }

  /// Track study session
  Future<void> trackStudySession({
    required String studySetId,
    required String sessionType,
    required Duration duration,
    int? questionsAnswered,
    int? correctAnswers,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!_isInitialized || !isAuthenticated) return;
    
    await _mindloadService.trackStudySession(
      studySetId: studySetId,
      sessionType: sessionType,
      duration: duration,
      questionsAnswered: questionsAnswered,
      correctAnswers: correctAnswers,
      additionalData: additionalData,
    );
  }

  /// Get comprehensive study analytics
  Future<StudyAnalytics> getStudyAnalytics({int daysBack = 30}) async {
    if (!_isInitialized || !isAuthenticated) return StudyAnalytics.empty();
    
    return await _mindloadService.getStudyAnalytics(daysBack: daysBack);
  }

  // MARK: - Credits & Subscription

  /// Get available credits
  Future<int> getAvailableCredits() async {
    if (!_isInitialized || !isAuthenticated) return 0;
    
    return await _firebaseClient.getAvailableCredits();
  }

  /// Use credits for operation
  Future<bool> useCredits(int amount, String operation) async {
    if (!_isInitialized || !isAuthenticated) return false;
    
    return await _firebaseClient.useCredits(amount, operation);
  }

  // MARK: - Remote Config & Feature Flags

  /// Check if feature is enabled
  bool isFeatureEnabled(String featureName) {
    if (!_isInitialized) return false;
    
    return _firebaseClient.isFeatureEnabled(featureName);
  }

  /// Get daily credit limit
  int getDailyCreditLimit(String subscriptionPlan) {
    if (!_isInitialized) return 20; // Default free limit
    
    return _firebaseClient.getDailyCreditLimit(subscriptionPlan);
  }

  /// Check maintenance mode
  bool isMaintenanceMode() {
    if (!_isInitialized) return false;
    
    return _firebaseClient.isMaintenanceMode();
  }

  // MARK: - Analytics & Logging

  /// Log custom event
  Future<void> logEvent(String eventName, Map<String, Object?>? parameters) async {
    if (!_isInitialized) return;
    
    await _firebaseClient.logAnalyticsEvent(eventName, parameters);
  }

  /// Log study session started
  Future<void> logStudySessionStarted(String studySetId, String studyType) async {
    if (!_isInitialized) return;
    
    await _firebaseClient.logStudySessionStarted(studySetId, studyType);
  }

  /// Log quiz completed
  Future<void> logQuizCompleted(String studySetId, int score, int totalQuestions, Duration duration) async {
    if (!_isInitialized) return;
    
    await _firebaseClient.logQuizCompleted(studySetId, score, totalQuestions, duration);
  }

  /// Log AI feature usage
  Future<void> logAIFeatureUsage(String feature, int creditsUsed) async {
    if (!_isInitialized) return;
    
    await _firebaseClient.logAIFeatureUsage(feature, creditsUsed);
  }

  // MARK: - Network & Connectivity

  /// Check if Firestore is connected
  Future<bool> isConnected() async {
    if (!_isInitialized) return false;
    
    return await _firebaseClient.isFirestoreConnected();
  }

  /// Enable offline mode
  Future<void> enableOfflineMode() async {
    if (!_isInitialized) return;
    
    await FirestoreHelper.disableNetwork();
  }

  /// Disable offline mode
  Future<void> disableOfflineMode() async {
    if (!_isInitialized) return;
    
    await FirestoreHelper.enableNetwork();
  }

  // MARK: - Error Handling

  /// Get user-friendly error message
  String getErrorMessage(dynamic error) {
    return FirestoreHelper.handleFirestoreError(error);
  }

  /// Retry failed operation with exponential backoff
  Future<T?> retryOperation<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    Duration delay = initialDelay;
    
    while (attempts < maxAttempts) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts >= maxAttempts) {
          print('Operation failed after $maxAttempts attempts: $e');
          return null;
        }
        
        print('Operation failed (attempt $attempts/$maxAttempts), retrying in ${delay.inSeconds}s: $e');
        await Future.delayed(delay);
        delay *= 2; // Exponential backoff
      }
    }
    
    return null;
  }

  // MARK: - Cleanup

  /// Dispose resources
  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  /// Reset for testing
  Future<void> resetForTesting() async {
    _isInitialized = false;
    _initializationError = null;
    await _firebaseClient.terminate();
    notifyListeners();
  }
}

/// Firebase initialization result
class FirebaseInitResult {
  final bool success;
  final String? error;

  FirebaseInitResult._({required this.success, this.error});

  static FirebaseInitResult _success() => FirebaseInitResult._(success: true);
  static FirebaseInitResult _error(String error) => FirebaseInitResult._(success: false, error: error);
}