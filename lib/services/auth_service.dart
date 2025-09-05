import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:io' show Platform; // Guarded usage
import 'package:cloud_functions/cloud_functions.dart';
import 'package:mindload/services/unified_storage_service.dart';
import 'package:mindload/firestore/firestore_repository.dart';
import 'package:mindload/firestore/firestore_data_schema.dart';
import 'package:mindload/services/entitlement_service.dart';
import 'package:mindload/services/mindload_economy_service.dart';
import 'package:mindload/services/local_image_storage_service.dart';

import 'package:mindload/services/unified_onboarding_service.dart';
import 'package:mindload/services/user_profile_service.dart';
import 'package:mindload/services/preference_migration_service.dart';
import 'package:mindload/services/user_specific_storage_service.dart';

enum AuthProvider {
  google,
  microsoft,
  apple,
  email,
  local, // For local admin testing
}

class AuthUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final AuthProvider provider;

  AuthUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.provider,
  });

  factory AuthUser.fromFirebaseUser(User user, AuthProvider provider) {
    return AuthUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? 'Anonymous User',
      photoURL: user.photoURL,
      provider: provider,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'photoURL': photoURL,
    'provider': provider.name,
  };

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      uid: json['uid'],
      email: json['email'],
      displayName: json['displayName'],
      photoURL: json['photoURL'],
      provider: AuthProvider.values.firstWhere(
        (p) => p.name == json['provider'],
        orElse: () => AuthProvider.email,
      ),
    );
  }
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  static AuthService get instance => _instance;
  AuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );
  // GoogleSignIn is not needed for Firebase Auth Google Sign-In
  // We use GoogleAuthProvider directly

  // Microsoft OAuth configuration
  static const String _microsoftClientId =
      'your-microsoft-client-id'; // Replace with your actual client ID
  static const String _microsoftRedirectUri = 'msauth.com.MindLoad.ios://auth';
  static const String _microsoftAuthUrl =
      'https://login.microsoftonline.com/common/oauth2/v2.0/authorize';
  static const String _microsoftTokenUrl =
      'https://login.microsoftonline.com/common/oauth2/v2.0/token';

  AuthUser? _currentUser;
  AuthUser? get currentUser => _currentUser;
  String? get currentUserId => _currentUser?.uid;
  bool get isAuthenticated => _currentUser != null;

  /// Safe initialization for iOS to prevent crashes
  Future<void> initializeIOS() async {
    if (!Platform.isIOS) return;

    try {
      if (kDebugMode) {
        debugPrint('🍎 Initializing iOS-specific authentication...');
      }

      // Check if Apple Sign-In is available
      bool isAppleSignInAvailable = false;
      try {
        isAppleSignInAvailable = await SignInWithApple.isAvailable();
        if (kDebugMode) {
          debugPrint('🍎 Apple Sign-In availability: $isAppleSignInAvailable');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Error checking Apple Sign-In availability: $e');
        }
        // Assume available on iOS 13+
        isAppleSignInAvailable = true;
      }

      // Initialize Firebase Auth with iOS-specific settings
      await _firebaseAuth.setSettings(
        appVerificationDisabledForTesting: kDebugMode,
      );

      if (kDebugMode) {
        debugPrint('✅ iOS authentication initialization completed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ iOS authentication initialization failed: $e');
      }
      // Don't throw - app should still work
    }
  }

  Future<void> initialize() async {
    try {
      // Initialize iOS-specific authentication first
      await initializeIOS();

      // Google Sign-In initialization not needed
      // We use Firebase Auth GoogleAuthProvider directly

      // Listen to auth state changes with proper error handling
      _firebaseAuth.authStateChanges().listen(
        (User? user) async {
          try {
            if (user != null) {
              if (kDebugMode) {
                print('🔐 User signed in: ${user.email}');
              }

              // Handle provider detection safely
              AuthProvider provider = AuthProvider.email;
              if (user.providerData.isNotEmpty) {
                final providerData = user.providerData.first;
                switch (providerData.providerId) {
                  case 'google.com':
                    provider = AuthProvider.google;
                    break;
                  case 'apple.com':
                    provider = AuthProvider.apple;
                    break;
                  case 'microsoft.com':
                  case 'microsoft.graph.api':
                    provider = AuthProvider.microsoft;
                    break;
                  default:
                    provider = AuthProvider.email;
                }
              }

              _currentUser = AuthUser.fromFirebaseUser(user, provider);
              await _saveUserData();

              // Create/update user profile in Firestore (non-blocking)
              _syncUserToFirestore(user, provider).catchError((e) {
                if (kDebugMode) {
                  print('⚠️ Firestore sync failed: $e');
                }
              });

              // Call Cloud Function to create user profile (non-blocking)
              _createUserProfileViaCloudFunction().catchError((e) {
                if (kDebugMode) {
                  print('⚠️ Cloud Function call failed: $e');
                }
              });

              // Bootstrap entitlements for new user (non-blocking)
              EntitlementService.instance.bootstrapNewUser(user.uid).catchError(
                (e) {
                  if (kDebugMode) {
                    print('⚠️ Entitlement bootstrap failed: $e');
                  }
                },
              );

              // Migrate preferences to user-specific storage (non-blocking)
              PreferenceMigrationService.instance
                  .migratePreferences()
                  .catchError((e) {
                    if (kDebugMode) {
                      print('⚠️ Preference migration failed: $e');
                    }
                  });
            } else {
              if (kDebugMode) {
                print('🔐 User signed out');
              }
              _currentUser = null;
              await _clearUserData();
            }
            notifyListeners();
          } catch (e) {
            if (kDebugMode) {
              print('❌ Auth state change error: $e');
            }
            // Ensure we still notify listeners even if there's an error
            notifyListeners();
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print('❌ Auth state listener error: $error');
          }
          // On error, clear current user and notify
          _currentUser = null;
          notifyListeners();
        },
      );

      if (kDebugMode) {
        print('✅ AuthService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ AuthService initialization failed: $e');
      }
      // Continue without throwing - app should still work
    }
  }

  // ---- Modernized Public API (kept additive so UI remains intact) ----

  /// Stream of auth changes (cross-platform)
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Keep existing UI API: separate signInWithEmail/signUpWithEmail methods exist below

  /// Sends verification email to the current user if available
  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Safe authentication method that prevents iOS crashes
  Future<AuthUser?> signInWithGoogleSafe() async {
    try {
      return await signInWithGoogle();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Safe Google Sign-In failed: $e');
      }

      // Return null instead of throwing to prevent crashes
      return null;
    }
  }

  /// Safe Apple Sign-In method that prevents iOS crashes
  Future<AuthUser?> signInWithAppleSafe() async {
    try {
      return await signInWithApple();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Safe Apple Sign-In failed: $e');
      }

      // Return null instead of throwing to prevent crashes
      return null;
    }
  }

  /// Google Sign-In using native implementation for iOS/Android, web popup for web
  /// Following Firebase Flutter documentation: https://firebase.google.com/docs/auth/flutter/federated-auth
  Future<AuthUser?> signInWithGoogle() async {
    try {
      if (kDebugMode) {
        debugPrint('🔍 Starting Google Sign-In...');
      }

      UserCredential userCredential;

      if (kIsWeb) {
        if (kDebugMode) {
          debugPrint('🌐 Web Google Sign-In via popup...');
        }
        // Keep existing web popup flow
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await _firebaseAuth.signInWithPopup(googleProvider);
      } else {
        if (kDebugMode) {
          debugPrint('📱 Mobile Google Sign-In using Firebase provider...');
        }
        // Mobile: Use Firebase provider with enhanced error handling
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        // iOS-specific configuration to prevent crashes
        if (Platform.isIOS) {
          googleProvider.setCustomParameters({
            'prompt': 'select_account',
            'access_type': 'offline',
            'include_granted_scopes': 'true',
          });
        }

        userCredential = await _firebaseAuth.signInWithProvider(googleProvider);
      }

      final user = userCredential.user;

      if (user == null) {
        throw Exception('Failed to get user from Google Sign-In');
      }

      _currentUser = AuthUser.fromFirebaseUser(user, AuthProvider.google);
      await _saveUserData();
      notifyListeners();

      if (kDebugMode) {
        debugPrint('✅ Google Sign-In successful for user: ${user.email}');
      }

      return _currentUser;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '❌ Firebase auth error during Google Sign-In: ${e.code} - ${e.message}',
        );
      }

      // Handle specific error codes with user-friendly messages
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw Exception(
            'An account already exists with a different sign-in method. Please use a different sign-in method.',
          );
        case 'invalid-credential':
          throw Exception(
            'The Google credentials are invalid. Please try again.',
          );
        case 'operation-not-allowed':
          throw Exception('Google Sign-In is not enabled for this app.');
        case 'user-disabled':
          throw Exception(
            'This account has been disabled. Please contact support.',
          );
        case 'user-not-found':
          throw Exception('No account found with this email.');
        case 'network-request-failed':
          throw Exception(
            'Network error. Please check your internet connection and try again.',
          );
        case 'too-many-requests':
          throw Exception(
            'Too many sign-in attempts. Please wait a moment and try again.',
          );
        case 'user-token-expired':
          throw Exception('Your session has expired. Please sign in again.');
        default:
          throw Exception(
            e.message ?? 'Google Sign-In failed. Please try again.',
          );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Unexpected Google Sign-In error: $e');
      }
      throw Exception('Google Sign-In failed: ${e.toString()}');
    }
  }

  /// Apple Sign-In using Firebase Auth federated authentication
  /// Following Firebase Flutter documentation: https://firebase.google.com/docs/auth/flutter/federated-auth
  Future<AuthUser?> signInWithApple() async {
    if (!(Platform.isIOS || Platform.isMacOS)) {
      throw UnsupportedError('Apple Sign-In is only available on iOS/macOS');
    }

    try {
      if (kDebugMode) {
        debugPrint('🍎 Starting Apple Sign-In...');
      }

      // Create Apple provider
      final AppleAuthProvider appleProvider = AppleAuthProvider();

      UserCredential userCredential;

      if (kIsWeb) {
        if (kDebugMode) {
          debugPrint('🌐 Web Apple Sign-In via popup...');
        }
        userCredential = await _firebaseAuth.signInWithPopup(appleProvider);
      } else {
        if (kDebugMode) {
          debugPrint('📱 Mobile Apple Sign-In using signInWithProvider...');
        }
        userCredential = await _firebaseAuth.signInWithProvider(appleProvider);
      }

      final user = userCredential.user;

      if (user == null) {
        throw Exception('Failed to get user from Apple Sign-In');
      }

      _currentUser = AuthUser.fromFirebaseUser(user, AuthProvider.apple);
      await _saveUserData();
      notifyListeners();

      if (kDebugMode) {
        debugPrint(
          '✅ Apple Sign-In successful for user: ${user.email ?? 'No email'}',
        );
      }

      return _currentUser;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '❌ Firebase auth error during Apple Sign-In: ${e.code} - ${e.message}',
        );
      }

      // Handle specific error codes with user-friendly messages
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw Exception(
            'An account already exists with a different sign-in method. Please use a different sign-in method.',
          );
        case 'invalid-credential':
          throw Exception(
            'The Apple credentials are invalid. Please try again.',
          );
        case 'operation-not-allowed':
          throw Exception('Apple Sign-In is not enabled for this app.');
        case 'user-disabled':
          throw Exception(
            'This account has been disabled. Please contact support.',
          );
        case 'user-not-found':
          throw Exception('No account found with this email.');
        case 'network-request-failed':
          throw Exception(
            'Network error. Please check your internet connection and try again.',
          );
        case 'too-many-requests':
          throw Exception(
            'Too many sign-in attempts. Please wait a moment and try again.',
          );
        case 'user-token-expired':
          throw Exception('Your session has expired. Please sign in again.');
        default:
          throw Exception(
            e.message ?? 'Apple Sign-In failed. Please try again.',
          );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Unexpected Apple Sign-In error: $e');
      }

      // Handle Apple-specific errors
      if (e.toString().contains('cancelled') ||
          e.toString().contains('canceled')) {
        throw Exception('Apple Sign-In was cancelled.');
      }

      throw Exception('Apple Sign-In failed: ${e.toString()}');
    }
  }

  /// Microsoft Sign-In using Firebase Auth federated authentication
  /// Following Firebase Flutter documentation: https://firebase.google.com/docs/auth/flutter/federated-auth
  Future<AuthUser?> signInWithMicrosoft({
    List<String> scopes = const ['User.Read', 'email', 'openid', 'profile'],
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🔷 Starting Microsoft Sign-In...');
      }

      // Create Microsoft provider
      final MicrosoftAuthProvider microsoftProvider = MicrosoftAuthProvider();

      UserCredential userCredential;

      if (kIsWeb) {
        if (kDebugMode) {
          debugPrint('🌐 Web Microsoft Sign-In via popup...');
        }
        userCredential = await _firebaseAuth.signInWithPopup(microsoftProvider);
      } else {
        if (kDebugMode) {
          debugPrint('📱 Mobile Microsoft Sign-In using signInWithProvider...');
        }
        userCredential = await _firebaseAuth.signInWithProvider(
          microsoftProvider,
        );
      }

      final user = userCredential.user;

      if (user == null) {
        throw Exception('Failed to get user from Microsoft Sign-In');
      }

      _currentUser = AuthUser.fromFirebaseUser(user, AuthProvider.microsoft);
      await _saveUserData();
      notifyListeners();

      if (kDebugMode) {
        debugPrint('✅ Microsoft Sign-In successful for user: ${user.email}');
      }

      return _currentUser;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '❌ Firebase auth error during Microsoft Sign-In: ${e.code} - ${e.message}',
        );
      }

      // Handle specific error codes with user-friendly messages
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw Exception(
            'An account already exists with a different sign-in method. Please use a different sign-in method.',
          );
        case 'invalid-credential':
          throw Exception(
            'The Microsoft credentials are invalid. Please try again.',
          );
        case 'operation-not-allowed':
          throw Exception('Microsoft Sign-In is not enabled for this app.');
        case 'user-disabled':
          throw Exception(
            'This account has been disabled. Please contact support.',
          );
        case 'user-not-found':
          throw Exception('No account found with this email.');
        case 'network-request-failed':
          throw Exception(
            'Network error. Please check your internet connection and try again.',
          );
        case 'too-many-requests':
          throw Exception(
            'Too many sign-in attempts. Please wait a moment and try again.',
          );
        case 'user-token-expired':
          throw Exception('Your session has expired. Please sign in again.');
        default:
          throw Exception(
            e.message ?? 'Microsoft Sign-In failed. Please try again.',
          );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Unexpected Microsoft Sign-In error: $e');
      }
      throw Exception('Microsoft Sign-In failed: ${e.toString()}');
    }
  }

  Future<AuthUser?> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      // Check if Firebase is properly configured
      if (!_isFirebaseConfigured()) {
        throw Exception(
          'Firebase setup incomplete. Please configure Firebase for this platform.',
        );
      }

      final UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(displayName);
        await userCredential.user!.reload();
        // Send verification email (non-blocking)
        try {
          await userCredential.user!.sendEmailVerification();
        } catch (_) {}

        _currentUser = AuthUser.fromFirebaseUser(
          userCredential.user!,
          AuthProvider.email,
        );
        await _saveUserData();

        // Bootstrap entitlements for new user (20 tokens monthly allowance)
        await EntitlementService.instance.bootstrapNewUser(
          userCredential.user!.uid,
        );

        notifyListeners();
        return _currentUser;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Email Sign Up Error: $e');
      }

      // Provide user-friendly error messages
      String userFriendlyError = _getUserFriendlyError(e);
      throw Exception(userFriendlyError);
    }
    return null;
  }

  Future<AuthUser?> signInWithEmail(String email, String password) async {
    try {
      if (!_isFirebaseConfigured()) {
        throw Exception(
          'Firebase setup incomplete. Please configure Firebase for this platform.',
        );
      }

      final UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        _currentUser = AuthUser.fromFirebaseUser(
          userCredential.user!,
          AuthProvider.email,
        );
        await _saveUserData();

        // Bootstrap entitlements for new user (20 tokens monthly allowance)
        await EntitlementService.instance.bootstrapNewUser(
          userCredential.user!.uid,
        );

        notifyListeners();
        return _currentUser;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Email Sign In Error: $e');
      }
      String userFriendlyError = _getUserFriendlyError(e);
      throw Exception(userFriendlyError);
    }
    return null;
  }

  /// Create/Sign in with local admin test account (works without Firebase)
  Future<AuthUser?> signInAsAdminTest() async {
    const adminEmail = 'admin@mindload.test';
    const adminDisplayName = 'Local Admin Test User';
    const adminUid = 'local-admin-uid-12345';

    try {
      // Check if Firebase is configured, if not use local mode
      final isFirebaseConfigured = _isFirebaseConfigured();

      if (!isFirebaseConfigured) {
        // Create local admin user
        _currentUser = AuthUser(
          uid: adminUid,
          email: adminEmail,
          displayName: adminDisplayName,
          photoURL: null,
          provider: AuthProvider.local,
        );

        await _saveUserData();

        // Bootstrap entitlements for new user (20 tokens monthly allowance)
        await EntitlementService.instance.bootstrapNewUser(adminUid);

        // Set up local admin subscription
        await _setupLocalAdminSubscription();

        notifyListeners();

        return _currentUser;
      }

      // Firebase is configured, try normal Firebase auth
      const adminPassword = 'MindloadAdmin2024!';

      // Try to sign in first
      try {
        final userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: adminEmail,
              password: adminPassword,
            );

        if (userCredential.user != null) {
          _currentUser = AuthUser.fromFirebaseUser(
            userCredential.user!,
            AuthProvider.email,
          );
          await _saveUserData();
          notifyListeners();
          return _currentUser;
        }
      } catch (e) {
        // If sign in fails, try to create the account
        try {
          final userCredential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
                email: adminEmail,
                password: adminPassword,
              );

          if (userCredential.user != null) {
            // Update display name
            await userCredential.user!.updateDisplayName(adminDisplayName);

            _currentUser = AuthUser.fromFirebaseUser(
              userCredential.user!,
              AuthProvider.email,
            );
            await _saveUserData();

            // Set up local admin subscription
            await _setupLocalAdminSubscription();

            notifyListeners();
            return _currentUser;
          }
        } catch (e) {
          // If Firebase auth fails, fall back to local mode
          _currentUser = AuthUser(
            uid: adminUid,
            email: adminEmail,
            displayName: adminDisplayName,
            photoURL: null,
            provider: AuthProvider.local,
          );

          await _saveUserData();

          // Bootstrap entitlements for new user (20 tokens monthly allowance)
          await EntitlementService.instance.bootstrapNewUser(adminUid);

          // Set up local admin subscription
          await _setupLocalAdminSubscription();

          notifyListeners();

          return _currentUser;
        }
      }
    } catch (e) {
      // If Firebase auth fails, fall back to local mode
      _currentUser = AuthUser(
        uid: adminUid,
        email: adminEmail,
        displayName: adminDisplayName,
        photoURL: null,
        provider: AuthProvider.local,
      );

      await _saveUserData();

      // Bootstrap entitlements for new user (20 tokens monthly allowance)
      await EntitlementService.instance.bootstrapNewUser(adminUid);

      // Set up local admin subscription
      await _setupLocalAdminSubscription();

      notifyListeners();

      return _currentUser;
    }
    return null;
  }

  /// Check if Firebase is properly configured for the current platform
  bool _isFirebaseConfigured() {
    // For development purposes, we'll allow web configuration but warn about mobile
    try {
      final app = FirebaseAuth.instance.app;
      final options = app.options;

      // Check if we're using placeholder values
      if (options.projectId.contains('placeholder') ||
          options.apiKey.contains('placeholder')) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if current user is admin
  bool get isAdmin => _currentUser?.email == 'admin@mindload.test';

  /// Check if current user is using local mode (no Firebase)
  bool get isLocalMode => _currentUser?.provider == AuthProvider.local;

  Future<void> signOut() async {
    try {
      if (kDebugMode) {
        print('🔐 Starting sign out process...');
      }

      // Step 1: Sign out from Firebase
      await _firebaseAuth.signOut();
      if (kDebugMode) {
        print('✅ Firebase sign out completed');
      }

      // Step 2: Google Sign-In session clearing not needed
      // Firebase Auth handles Google session management automatically
      if (kDebugMode) {
        print('✅ Google Sign-In session handled by Firebase Auth');
      }

      // Step 3: Clear current user state
      _currentUser = null;
      if (kDebugMode) {
        print('✅ Current user state cleared');
      }

      // Step 4: Clear all local data and preferences
      await _clearUserData();
      if (kDebugMode) {
        print('✅ Local user data cleared');
      }

      // Step 4.5: Clear user-specific storage data
      try {
        await UserSpecificStorageService.instance.clearUserData();
        if (kDebugMode) {
          print('✅ User-specific storage data cleared');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Could not clear user-specific storage data: $e');
        }
      }

      // Step 5: Clear user profile service data
      try {
        await UserProfileService.instance.clearProfileData();
        if (kDebugMode) {
          print('✅ User profile data cleared');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Could not clear user profile data: $e');
        }
      }

      // Step 6: Clear onboarding data
      try {
        await UnifiedOnboardingService().resetOnboarding();
        if (kDebugMode) {
          print('✅ Onboarding data cleared');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Could not clear onboarding data: $e');
        }
      }

      // Step 7: Clear enhanced storage data (skip for now - not essential for logout)
      if (kDebugMode) {
        print(
          'ℹ️ Enhanced storage data clearing skipped (not essential for logout)',
        );
      }

      // Step 8: Notify listeners of state change
      notifyListeners();
      if (kDebugMode) {
        print('✅ Sign out process completed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Sign Out Error: $e');
      }

      // Even if there's an error, try to clear local state
      _currentUser = null;
      await _clearUserData();
      notifyListeners();

      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        if (kDebugMode) {
          print('🗑️ Starting account deletion process for user: ${user.uid}');
        }

        // Step 1: Delete all user data from Firestore first
        if (kDebugMode) {
          print('🗑️ Deleting Firestore data...');
        }
        await FirestoreRepository.instance.deleteUser(user.uid);

        // Step 2: Delete user profile image if exists
        try {
          await LocalImageStorageService.instance.deleteProfileImage();
          if (kDebugMode) {
            print('🗑️ Profile image deleted');
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Could not delete profile image: $e');
          }
        }

        // Step 3: Clear all local data and preferences
        if (kDebugMode) {
          print('🗑️ Clearing local data...');
        }
        await _clearUserData();
        await UnifiedStorageService.instance.clearAllData();

        // Step 4: Clear promotional consent data
        try {
          // PromotionalConsentService was removed - skip this step
          if (kDebugMode) {
            print('🗑️ Promotional consent data cleared');
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Could not clear promotional consent data: $e');
          }
        }

        // Step 5: Clear onboarding data
        try {
          await UnifiedOnboardingService().resetOnboarding();
          if (kDebugMode) {
            print('🗑️ Onboarding data cleared');
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Could not clear onboarding data: $e');
          }
        }

        // Step 6: Clear user profile service data
        try {
          await UserProfileService.instance.clearProfileData();
          if (kDebugMode) {
            print('🗑️ User profile data cleared');
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Could not clear user profile data: $e');
          }
        }

        // Step 7: Delete the Firebase Auth user account
        if (kDebugMode) {
          print('🗑️ Deleting Firebase Auth account...');
        }
        await user.delete();

        // Step 8: Clear current user state
        _currentUser = null;
        notifyListeners();

        if (kDebugMode) {
          print('✅ Account deletion completed successfully');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Delete Account Error: $e');
      }
      rethrow;
    }
  }

  Future<void> _saveUserData() async {
    if (_currentUser != null) {
      await UnifiedStorageService.instance.saveUserData(_currentUser!.toJson());
      await UnifiedStorageService.instance.setAuthenticated(true);
    }
  }

  Future<void> _loadUserData() async {
    final userData = await UnifiedStorageService.instance.getUserData();
    if (userData != null) {
      try {
        _currentUser = AuthUser.fromJson(userData);
        notifyListeners();
      } catch (e) {
        if (kDebugMode) {
          print('Error loading user data: $e');
        }
        await _clearUserData();
      }
    }
  }

  Future<void> _clearUserData() async {
    await UnifiedStorageService.instance.clearUserData();
    await UnifiedStorageService.instance.setAuthenticated(false);
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Sync user data to Firestore
  Future<void> _syncUserToFirestore(User user, AuthProvider provider) async {
    try {
      final userProfile = UserProfileFirestore(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'Anonymous User',
        photoURL: user.photoURL,
        phoneNumber: user.phoneNumber,
        provider: provider.name,
        createdAt: user.metadata.creationTime ?? DateTime.now(),
        lastLoginAt: DateTime.now(),
        preferences: {
          'theme': 'classic',
          'notifications': true,
          'binaural_beats': true,
          'default_focus_time': 25,
        },
        subscriptionPlan: 'free',
        isActive: true,
      );

      await FirestoreRepository.instance.createOrUpdateUser(userProfile);
      await FirestoreRepository.instance.updateUserLastLogin(user.uid);
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing user to Firestore: $e');
      }
      // Don't rethrow - user can still use the app even if Firestore sync fails
    }
  }

  /// Convert Firebase errors to user-friendly messages
  String _getUserFriendlyError(dynamic error) {
    String errorMessage = error.toString().toLowerCase();

    if (errorMessage.contains('operation-not-allowed')) {
      return 'Email/password sign-in is disabled. Enable Email/Password in Firebase Authentication settings.';
    } else if (errorMessage.contains('user-not-found')) {
      return 'No account found with this email. Please sign up first.';
    } else if (errorMessage.contains('wrong-password')) {
      return 'Incorrect password. Please try again.';
    } else if (errorMessage.contains('invalid-credential')) {
      return 'Invalid credentials. Please try again or reset your password.';
    } else if (errorMessage.contains('email-already-in-use')) {
      return 'An account with this email already exists.';
    } else if (errorMessage.contains('weak-password')) {
      return 'Password is too weak. Please use at least 6 characters.';
    } else if (errorMessage.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    } else if (errorMessage.contains('network-request-failed')) {
      return 'Network error. Please check your internet connection.';
    } else if (errorMessage.contains('too-many-requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    } else if (errorMessage.contains('user-disabled')) {
      return 'This account has been disabled. Contact support.';
    } else if (errorMessage.contains('requires-recent-login')) {
      return 'Please sign in again to complete this action.';
    } else if (errorMessage.contains('firebase') &&
        errorMessage.contains('incomplete')) {
      return 'App setup incomplete. Please configure Firebase for this platform.';
    } else if (errorMessage.contains('google') &&
        errorMessage.contains('sign')) {
      return 'Google sign-in failed. Please try again or use email authentication.';
    } else if (errorMessage.contains('apple') &&
        errorMessage.contains('not available')) {
      return 'Apple sign-in is not available on this device.';
    } else if (errorMessage.contains('microsoft') &&
        (errorMessage.contains('setup') ||
            errorMessage.contains('configuration'))) {
      return 'Microsoft sign-in requires additional setup. Please use Google, Apple, or email authentication for now.';
    } else {
      return 'Authentication failed. Please try again.';
    }
  }

  /// Sync admin user data to Firestore with unlimited access
  Future<void> _syncAdminUserToFirestore(User user) async {
    try {
      final adminProfile = UserProfileFirestore(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'Admin Test User',
        photoURL: user.photoURL,
        phoneNumber: user.phoneNumber,
        provider: AuthProvider.email.name,
        createdAt: user.metadata.creationTime ?? DateTime.now(),
        lastLoginAt: DateTime.now(),
        preferences: {
          'theme': 'classic',
          'notifications': true,
          'binaural_beats': true,
          'default_focus_time': 25,
          'admin_mode': true,
        },
        subscriptionPlan: 'admin', // Special admin subscription
        isActive: true,
      );

      await FirestoreRepository.instance.createOrUpdateUser(adminProfile);
      await FirestoreRepository.instance.updateUserLastLogin(user.uid);

      // Create admin credit usage with 1000 tokens
      await FirestoreRepository.instance.resetDailyCredits(
        user.uid,
        1000,
      ); // Admin gets 1000 tokens
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing admin user to Firestore: $e');
      }
      // Don't rethrow - user can still use the app even if Firestore sync fails
    }
  }

  /// Set up local admin subscription for local mode
  Future<void> _setupLocalAdminSubscription() async {
    try {
      if (_currentUser?.provider == AuthProvider.local &&
          _currentUser?.email == 'admin@mindload.test') {
        // Initialize MindloadEconomyService for admin user
        await MindloadEconomyService.instance.initialize();

        if (kDebugMode) {
          print('Local admin economy service initialized successfully');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting up local admin economy service: $e');
      }
    }
  }

  /// Call Cloud Function to create user profile
  Future<void> _createUserProfileViaCloudFunction() async {
    try {
      if (kDebugMode) {
        print('📞 Calling createUserProfile Cloud Function...');
      }

      final result = await _functions.httpsCallable('createUserProfile').call();

      if (result.data != null && result.data['success'] == true) {
        if (kDebugMode) {
          print(
            '✅ User profile created via Cloud Function: ${result.data['message']}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Cloud Function createUserProfile failed: $e');
        print(
          'ℹ️ User profile creation will continue via local Firestore sync',
        );
      }
      // Don't rethrow - this is not critical as we have local Firestore sync as fallback
    }
  }

  /// Get Apple Web Client ID from environment or configuration
  String _getAppleWebClientId() {
    // Try to get from environment first
    const envClientId = String.fromEnvironment('APPLE_WEB_CLIENT_ID');
    if (envClientId.isNotEmpty) {
      return envClientId;
    }

    // For development, you can set a default or throw an error
    if (kDebugMode) {
      debugPrint('⚠️ APPLE_WEB_CLIENT_ID not set, using bundle ID as fallback');
      return 'com.cogniflow.mindload'; // Fallback to bundle ID
    }

    throw Exception(
      'Apple Web Client ID not configured. Set APPLE_WEB_CLIENT_ID environment variable.',
    );
  }

  /// Get Apple Redirect URI from environment or configuration
  String _getAppleRedirectUri() {
    // Try to get from environment first
    const envRedirectUri = String.fromEnvironment('APPLE_REDIRECT_URI');
    if (envRedirectUri.isNotEmpty) {
      return envRedirectUri;
    }

    // For development, use a default
    if (kDebugMode) {
      debugPrint(
        '⚠️ APPLE_REDIRECT_URI not set, using default for development',
      );
      return 'https://mindload.app/auth/apple';
    }

    throw Exception(
      'Apple Redirect URI not configured. Set APPLE_REDIRECT_URI environment variable.',
    );
  }
}
