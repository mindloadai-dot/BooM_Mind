import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mindload/services/auth_service.dart';

/// Enhanced Password Reset Service
class PasswordResetService extends ChangeNotifier {
  static final PasswordResetService _instance =
      PasswordResetService._internal();
  static PasswordResetService get instance => _instance;
  PasswordResetService._internal();

  bool _isResetting = false;
  String? _lastResetEmail;
  DateTime? _lastResetTime;

  // Getters
  bool get isResetting => _isResetting;
  String? get lastResetEmail => _lastResetEmail;
  DateTime? get lastResetTime => _lastResetTime;

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      setState(() {
        _isResetting = true;
      });

      if (kDebugMode) {
        debugPrint('📧 Sending password reset email to: $email');
      }

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      final success = true;

      if (success) {
        _lastResetEmail = email;
        _lastResetTime = DateTime.now();

        if (kDebugMode) {
          debugPrint('✅ Password reset email sent successfully');
        }

        notifyListeners();
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Failed to send password reset email');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error sending password reset email: $e');
      }
      return false;
    } finally {
      setState(() {
        _isResetting = false;
      });
    }
  }

  /// Change password for authenticated user
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      setState(() {
        _isResetting = true;
      });

      if (kDebugMode) {
        debugPrint('🔐 Changing password for authenticated user');
      }

      // Verify current password first
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      // Re-authenticate with current password
      final credential = EmailAuthProvider.credential(
        email: currentUser.email,
        password: currentPassword,
      );
      
      await FirebaseAuth.instance.currentUser!.reauthenticateWithCredential(credential);

      // Change password
      await FirebaseAuth.instance.currentUser!.updatePassword(newPassword);
      final success = true;

      if (success) {
        if (kDebugMode) {
          debugPrint('✅ Password changed successfully');
        }

        notifyListeners();
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Failed to change password');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error changing password: $e');
      }
      rethrow;
    } finally {
      setState(() {
        _isResetting = false;
      });
    }
  }

  /// Check if password reset is available (rate limiting)
  bool canSendResetEmail() {
    if (_lastResetTime == null) return true;

    // Allow one reset email per 5 minutes
    final timeSinceLastReset = DateTime.now().difference(_lastResetTime!);
    return timeSinceLastReset.inMinutes >= 5;
  }

  /// Get time remaining until next reset email can be sent
  Duration? getTimeUntilNextReset() {
    if (_lastResetTime == null) return null;

    final timeSinceLastReset = DateTime.now().difference(_lastResetTime!);
    final timeRemaining = Duration(minutes: 5) - timeSinceLastReset;

    if (timeRemaining.isNegative) return null;
    return timeRemaining;
  }

  /// Validate password strength
  static PasswordStrength validatePasswordStrength(String password) {
    int score = 0;
    final issues = <String>[];

    // Length check
    if (password.length >= 8) {
      score += 1;
    } else {
      issues.add('At least 8 characters');
    }

    // Uppercase check
    if (password.contains(RegExp(r'[A-Z]'))) {
      score += 1;
    } else {
      issues.add('At least one uppercase letter');
    }

    // Lowercase check
    if (password.contains(RegExp(r'[a-z]'))) {
      score += 1;
    } else {
      issues.add('At least one lowercase letter');
    }

    // Number check
    if (password.contains(RegExp(r'[0-9]'))) {
      score += 1;
    } else {
      issues.add('At least one number');
    }

    // Special character check
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      score += 1;
    } else {
      issues.add('At least one special character');
    }

    // Determine strength
    if (score >= 5) {
      return PasswordStrength.strong;
    } else if (score >= 3) {
      return PasswordStrength.medium;
    } else {
      return PasswordStrength.weak;
    }
  }

  /// Get password strength description
  static String getPasswordStrengthDescription(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 'Weak password';
      case PasswordStrength.medium:
        return 'Medium strength password';
      case PasswordStrength.strong:
        return 'Strong password';
    }
  }

  /// Get password strength color
  static String getPasswordStrengthColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 'error';
      case PasswordStrength.medium:
        return 'warning';
      case PasswordStrength.strong:
        return 'success';
    }
  }

  /// Clear reset history (useful for testing)
  void clearResetHistory() {
    _lastResetEmail = null;
    _lastResetTime = null;
    notifyListeners();

    if (kDebugMode) {
      debugPrint('🧹 Password reset history cleared');
    }
  }

  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }
}

/// Password strength enum
enum PasswordStrength {
  weak,
  medium,
  strong,
}
