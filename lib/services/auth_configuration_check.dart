import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

/// Configuration checker for Google and Apple Sign In
class AuthConfigurationCheck {
  /// Check all authentication configurations
  static Map<String, dynamic> checkConfiguration() {
    final Map<String, dynamic> config = {
      'timestamp': DateTime.now().toIso8601String(),
      'platform': _getPlatform(),
      'google_signin': {},
      'apple_signin': {},
      'firebase': {},
      'issues': [],
      'recommendations': [],
    };

    // Platform detection
    config['platform_details'] = {
      'is_ios': Platform.isIOS,
      'is_android': Platform.isAndroid,
      'is_web': kIsWeb,
      'is_macos': Platform.isMacOS,
      'operating_system': Platform.operatingSystem,
      'version': Platform.version,
    };

    // Check iOS configuration
    if (Platform.isIOS) {
      config['ios_checks'] = _checkIOSConfiguration();
    }

    // Check Android configuration
    if (Platform.isAndroid) {
      config['android_checks'] = _checkAndroidConfiguration();
    }

    // Generate recommendations
    config['recommendations'] = _generateRecommendations(config);

    return config;
  }

  static String _getPlatform() {
    if (kIsWeb) return 'Web';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }

  static Map<String, dynamic> _checkIOSConfiguration() {
    return {
      'requirements': [
        '✅ GoogleService-Info.plist added to iOS project',
        '✅ URL Schemes configured in Info.plist',
        '✅ Sign in with Apple capability enabled in Runner.entitlements',
        '✅ Bundle ID matches Firebase configuration',
        '✅ Associated domains configured for universal links',
      ],
      'google_signin_setup': {
        'url_scheme':
            'com.googleusercontent.apps.884947669542-qp3ijvvdd9vacvpjp6ldp5r9pf8okejk',
        'client_id':
            '884947669542-qp3ijvvdd9vacvpjp6ldp5r9pf8okejk.apps.googleusercontent.com',
        'bundle_id': 'com.cogniflow.mindload',
      },
      'apple_signin_setup': {
        'capability': 'com.apple.developer.applesignin',
        'service_id': 'com.cogniflow.mindload',
        'enabled': true,
      },
    };
  }

  static Map<String, dynamic> _checkAndroidConfiguration() {
    return {
      'requirements': [
        '✅ google-services.json added to android/app',
        '✅ Google Services plugin applied in build.gradle',
        '✅ SHA-1 and SHA-256 certificates added to Firebase',
        '✅ Package name matches Firebase configuration',
        '✅ Internet permission in AndroidManifest.xml',
      ],
      'google_signin_setup': {
        'package_name': 'com.MindLoad.android',
        'client_id':
            '884947669542-qp3ijvvdd9vacvpjp6ldp5r9pf8okejk.apps.googleusercontent.com',
      },
      'apple_signin_setup': {
        'method': 'Web-based redirect',
        'supported': true,
        'note': 'Apple Sign In on Android uses web authentication flow',
      },
      'debug_keystore': {
        'location': '~/.android/debug.keystore',
        'command':
            'keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android',
        'note': 'Add SHA-1 and SHA-256 to Firebase Console',
      },
    };
  }

  static List<String> _generateRecommendations(Map<String, dynamic> config) {
    final List<String> recommendations = [];

    if (Platform.isIOS) {
      recommendations.addAll([
        '1. Ensure your Apple Developer account has Sign in with Apple configured',
        '2. Test on a real iOS device for best results',
        '3. Check that push notifications are configured if using them',
      ]);
    }

    if (Platform.isAndroid) {
      recommendations.addAll([
        '1. Add your debug and release SHA certificates to Firebase Console',
        '2. For release builds, use the release keystore SHA certificates',
        '3. Enable Google Sign-In in Firebase Authentication settings',
        '4. Test Apple Sign In on Android using web redirect flow',
      ]);
    }

    if (kIsWeb) {
      recommendations.addAll([
        '1. Add authorized domains to Firebase Authentication',
        '2. Configure OAuth redirect URIs in Google Cloud Console',
        '3. Set up Apple Services ID for web authentication',
        '4. Enable popup windows in browser for authentication',
      ]);
    }

    recommendations
        .add('Always test authentication on real devices before release');

    return recommendations;
  }

  /// Print configuration report
  static void printConfigurationReport() {
    final config = checkConfiguration();

    final separator = '=' * 60;
    debugPrint('\n$separator');
    debugPrint('🔐 AUTHENTICATION CONFIGURATION REPORT');
    debugPrint(separator);

    debugPrint('\n📱 Platform: ${config['platform']}');
    debugPrint('⏰ Generated: ${config['timestamp']}');

    if (config['platform_details'] != null) {
      debugPrint('\n📋 Platform Details:');
      config['platform_details'].forEach((key, value) {
        debugPrint('  • $key: $value');
      });
    }

    if (config['ios_checks'] != null) {
      debugPrint('\n🍎 iOS Configuration:');
      final iosChecks = config['ios_checks'];

      debugPrint('\n  Requirements:');
      for (final req in iosChecks['requirements']) {
        debugPrint('    $req');
      }

      debugPrint('\n  Google Sign-In:');
      iosChecks['google_signin_setup'].forEach((key, value) {
        debugPrint('    • $key: $value');
      });

      debugPrint('\n  Apple Sign-In:');
      iosChecks['apple_signin_setup'].forEach((key, value) {
        debugPrint('    • $key: $value');
      });
    }

    if (config['android_checks'] != null) {
      debugPrint('\n🤖 Android Configuration:');
      final androidChecks = config['android_checks'];

      debugPrint('\n  Requirements:');
      for (final req in androidChecks['requirements']) {
        debugPrint('    $req');
      }

      debugPrint('\n  Google Sign-In:');
      androidChecks['google_signin_setup'].forEach((key, value) {
        debugPrint('    • $key: $value');
      });

      debugPrint('\n  Apple Sign-In:');
      androidChecks['apple_signin_setup'].forEach((key, value) {
        debugPrint('    • $key: $value');
      });

      debugPrint('\n  Debug Keystore:');
      androidChecks['debug_keystore'].forEach((key, value) {
        debugPrint('    • $key: $value');
      });
    }

    if (config['recommendations'].isNotEmpty) {
      debugPrint('\n💡 Recommendations:');
      for (final rec in config['recommendations']) {
        debugPrint('  $rec');
      }
    }

    debugPrint('\n$separator');
    debugPrint('✅ Configuration check complete!');
    debugPrint('$separator\n');
  }

  /// Get SHA certificates command for current platform
  static String getSHACommand() {
    if (Platform.isAndroid) {
      return '''
To get SHA certificates for Firebase:

Debug keystore:
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

Release keystore:
keytool -list -v -keystore [path-to-your-keystore] -alias [your-alias]

Add both SHA-1 and SHA-256 to Firebase Console > Project Settings > Your Android App
      ''';
    }
    return 'SHA certificates are only needed for Android apps';
  }
}
