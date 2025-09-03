import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

import 'auth_service.dart';
import 'user_specific_storage_service.dart';

/// Service for handling biometric authentication
class BiometricAuthService extends ChangeNotifier {
  static final BiometricAuthService _instance =
      BiometricAuthService._internal();
  static BiometricAuthService get instance => _instance;
  BiometricAuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();

  // SharedPreferences keys
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricPromptShownKey = 'biometric_prompt_shown';
  static const String _biometricSetupCompletedKey = 'biometric_setup_completed';
  static const String _lastBiometricUserKey = 'last_biometric_user';
  static const String _biometricLoginEnabledKey = 'biometric_login_enabled';

  bool _isBiometricEnabled = false;
  bool _hasPromptBeenShown = false;
  bool _isSetupCompleted = false;
  String? _lastBiometricUser;
  bool _isBiometricLoginEnabled = false;

  // Getters
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get hasPromptBeenShown => _hasPromptBeenShown;
  bool get isSetupCompleted => _isSetupCompleted;
  String? get lastBiometricUser => _lastBiometricUser;
  bool get isBiometricLoginEnabled => _isBiometricLoginEnabled;

  /// Initialize the biometric service
  Future<void> initialize() async {
    try {
      // Initialize user-specific storage
      await UserSpecificStorageService.instance.initialize();

      // Check if user is authenticated for user-specific settings
      if (!AuthService.instance.isAuthenticated) {
        if (kDebugMode) {
          debugPrint(
              '⚠️ BiometricAuthService: No authenticated user, using defaults');
        }
        _resetToDefaults();
        return;
      }

      final userStorage = UserSpecificStorageService.instance;

      _isBiometricEnabled =
          (await userStorage.getBool(_biometricEnabledKey)) ?? false;
      _hasPromptBeenShown =
          (await userStorage.getBool(_biometricPromptShownKey)) ?? false;
      _isSetupCompleted =
          (await userStorage.getBool(_biometricSetupCompletedKey)) ?? false;
      _lastBiometricUser = await userStorage.getString(_lastBiometricUserKey);
      _isBiometricLoginEnabled =
          (await userStorage.getBool(_biometricLoginEnabledKey)) ?? false;

      if (kDebugMode) {
        debugPrint('✅ BiometricAuthService initialized');
        debugPrint('   Biometric enabled: $_isBiometricEnabled');
        debugPrint('   Biometric login enabled: $_isBiometricLoginEnabled');
        debugPrint('   Prompt shown: $_hasPromptBeenShown');
        debugPrint('   Setup completed: $_isSetupCompleted');
        debugPrint('   Last user: $_lastBiometricUser');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to initialize BiometricAuthService: $e');
      }
    }
  }

  /// Reset to default values for unauthenticated users
  void _resetToDefaults() {
    _isBiometricEnabled = false;
    _hasPromptBeenShown = false;
    _isSetupCompleted = false;
    _lastBiometricUser = null;
    _isBiometricLoginEnabled = false;
    notifyListeners();
  }

  /// Check if biometric authentication is available on the device
  Future<bool> isBiometricAvailable() async {
    try {
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking biometric availability: $e');
      }
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting available biometrics: $e');
      }
      return [];
    }
  }

  /// Get a user-friendly description of available biometrics
  Future<String> getBiometricDescription() async {
    try {
      final biometrics = await getAvailableBiometrics();
      if (biometrics.isEmpty) return 'Biometric authentication';

      if (biometrics.contains(BiometricType.face)) {
        return 'Face ID';
      } else if (biometrics.contains(BiometricType.fingerprint)) {
        return 'Fingerprint';
      } else if (biometrics.contains(BiometricType.iris)) {
        return 'Iris scan';
      } else {
        return 'Biometric authentication';
      }
    } catch (e) {
      return 'Biometric authentication';
    }
  }

  /// Check if the user should be prompted for biometric setup
  /// Returns true if:
  /// 1. Biometric is available
  /// 2. User hasn't been prompted before OR is a different user
  /// 3. User is authenticated
  /// 4. Biometric is not already enabled
  Future<bool> shouldShowBiometricPrompt() async {
    try {
      // Must be authenticated first
      if (!AuthService.instance.isAuthenticated) {
        if (kDebugMode) {
          debugPrint('🔒 Biometric prompt: User not authenticated');
        }
        return false;
      }

      // Check if biometric is available
      if (!await isBiometricAvailable()) {
        if (kDebugMode) {
          debugPrint('🔒 Biometric prompt: Biometric not available');
        }
        return false;
      }

      // Check if we've already shown the prompt for this user
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        if (kDebugMode) {
          debugPrint('🔒 Biometric prompt: No current user');
        }
        return false;
      }

      // If biometric is already enabled for this user, don't show prompt
      if (_isBiometricEnabled && _lastBiometricUser == currentUser.uid) {
        if (kDebugMode) {
          debugPrint('🔒 Biometric prompt: Already enabled for current user');
        }
        return false;
      }

      // If prompt was shown for a different user, show it again
      if (_lastBiometricUser != null && _lastBiometricUser != currentUser.uid) {
        if (kDebugMode) {
          debugPrint('🔒 Biometric prompt: Different user, showing prompt');
        }
        return true;
      }

      // Show if prompt hasn't been shown and setup isn't completed
      final shouldShow = !_hasPromptBeenShown && !_isSetupCompleted;
      if (kDebugMode) {
        debugPrint(
            '🔒 Biometric prompt: Should show = $shouldShow (prompt shown: $_hasPromptBeenShown, setup completed: $_isSetupCompleted)');
      }
      return shouldShow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking if should show biometric prompt: $e');
      }
      return false;
    }
  }

  /// Check if biometric login should be used for app startup
  /// Returns true if:
  /// 1. Biometric is enabled
  /// 2. Biometric login is enabled
  /// 3. User is authenticated
  /// 4. Biometric is available
  Future<bool> shouldUseBiometricLogin() async {
    try {
      // Must be authenticated first
      if (!AuthService.instance.isAuthenticated) {
        return false;
      }

      // Check if biometric is enabled and login is enabled
      if (!_isBiometricEnabled || !_isBiometricLoginEnabled) {
        return false;
      }

      // Check if biometric is available
      if (!await isBiometricAvailable()) {
        return false;
      }

      // Check if this is the same user who enabled biometric
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null || _lastBiometricUser != currentUser.uid) {
        return false;
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking if should use biometric login: $e');
      }
      return false;
    }
  }

  /// Mark that the biometric prompt has been shown
  Future<void> markPromptShown() async {
    try {
      final currentUser = AuthService.instance.currentUser;

      if (currentUser != null) {
        final userStorage = UserSpecificStorageService.instance;
        await userStorage.setBool(_biometricPromptShownKey, true);
        await userStorage.setString(_lastBiometricUserKey, currentUser.uid);

        _hasPromptBeenShown = true;
        _lastBiometricUser = currentUser.uid;

        notifyListeners();

        if (kDebugMode) {
          debugPrint(
              '✅ Biometric prompt marked as shown for user: ${currentUser.uid}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to mark prompt as shown: $e');
      }
    }
  }

  /// Enable biometric authentication
  Future<bool> enableBiometric() async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        if (kDebugMode) {
          debugPrint('❌ Cannot enable biometric: No authenticated user');
        }
        return false;
      }

      // Check if biometric is available
      if (!await isBiometricAvailable()) {
        if (kDebugMode) {
          debugPrint('❌ Cannot enable biometric: Not available on device');
        }
        return false;
      }

      // Authenticate with biometric to confirm it works
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to enable biometric login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        final userStorage = UserSpecificStorageService.instance;
        await userStorage.setBool(_biometricEnabledKey, true);
        await userStorage.setBool(_biometricSetupCompletedKey, true);
        await userStorage.setBool(_biometricLoginEnabledKey, true);
        await userStorage.setString(_lastBiometricUserKey, currentUser.uid);

        _isBiometricEnabled = true;
        _isSetupCompleted = true;
        _isBiometricLoginEnabled = true;
        _lastBiometricUser = currentUser.uid;

        notifyListeners();

        if (kDebugMode) {
          debugPrint(
              '✅ Biometric authentication enabled for user: ${currentUser.uid}');
        }

        return true;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Biometric authentication failed during setup');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error enabling biometric authentication: $e');
      }
      return false;
    }
  }

  /// Disable biometric authentication
  Future<void> disableBiometric() async {
    try {
      final userStorage = UserSpecificStorageService.instance;
      await userStorage.setBool(_biometricEnabledKey, false);
      await userStorage.setBool(_biometricLoginEnabledKey, false);

      _isBiometricEnabled = false;
      _isBiometricLoginEnabled = false;

      notifyListeners();

      if (kDebugMode) {
        debugPrint('✅ Biometric authentication disabled');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to disable biometric authentication: $e');
      }
    }
  }

  /// Skip biometric setup (user chose not to enable it)
  Future<void> skipBiometricSetup() async {
    try {
      final currentUser = AuthService.instance.currentUser;

      if (currentUser != null) {
        final userStorage = UserSpecificStorageService.instance;
        await userStorage.setBool(_biometricPromptShownKey, true);
        await userStorage.setBool(_biometricSetupCompletedKey, true);
        await userStorage.setString(_lastBiometricUserKey, currentUser.uid);

        _hasPromptBeenShown = true;
        _isSetupCompleted = true;
        _lastBiometricUser = currentUser.uid;

        notifyListeners();

        if (kDebugMode) {
          debugPrint('✅ Biometric setup skipped for user: ${currentUser.uid}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to skip biometric setup: $e');
      }
    }
  }

  /// Authenticate using biometrics for login
  Future<bool> authenticateWithBiometric({
    String reason = 'Please authenticate to access your account',
  }) async {
    try {
      if (!_isBiometricEnabled) {
        if (kDebugMode) {
          debugPrint('❌ Biometric authentication not enabled');
        }
        return false;
      }

      if (!await isBiometricAvailable()) {
        if (kDebugMode) {
          debugPrint('❌ Biometric authentication not available');
        }
        return false;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (kDebugMode) {
        debugPrint('🔐 Biometric authentication result: $didAuthenticate');
      }

      return didAuthenticate;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Biometric authentication error: $e');
      }
      return false;
    }
  }

  /// Toggle biometric login (enable/disable for future app launches)
  Future<void> toggleBiometricLogin(bool enabled) async {
    try {
      final userStorage = UserSpecificStorageService.instance;
      await userStorage.setBool(_biometricLoginEnabledKey, enabled);

      _isBiometricLoginEnabled = enabled;

      notifyListeners();

      if (kDebugMode) {
        debugPrint('✅ Biometric login ${enabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to toggle biometric login: $e');
      }
    }
  }

  /// Reset biometric settings (useful for testing or user request)
  Future<void> resetBiometricSettings() async {
    try {
      final userStorage = UserSpecificStorageService.instance;
      await userStorage.remove(_biometricEnabledKey);
      await userStorage.remove(_biometricPromptShownKey);
      await userStorage.remove(_biometricSetupCompletedKey);
      await userStorage.remove(_lastBiometricUserKey);
      await userStorage.remove(_biometricLoginEnabledKey);

      _isBiometricEnabled = false;
      _hasPromptBeenShown = false;
      _isSetupCompleted = false;
      _lastBiometricUser = null;
      _isBiometricLoginEnabled = false;

      notifyListeners();

      if (kDebugMode) {
        debugPrint('✅ Biometric settings reset');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to reset biometric settings: $e');
      }
    }
  }
}
