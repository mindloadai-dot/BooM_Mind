import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:mindload/models/pricing_models.dart';
import 'package:mindload/services/auth_service.dart';
import 'package:mindload/l10n/app_localizations.dart';
import 'dart:io';

// Telemetry events enum
enum TelemetryEvent {
  paywallView,
  paywallExit,
  purchaseInitiated,
  purchaseCompleted,
  purchaseFailed,
  restoreInitiated,
  restoreCompleted,
  restoreFailed,
  refundReceived,
  entitlementChanged,
  introStarted,
  introConverted,
  introRenewed,
  starterPackShown,
  starterPackBought,
  generationBlockedFree,
  generationBlockedBudget,
  budgetWarn,
  budgetLimit,
  budgetHardBlock,
  purchaseStart,
  purchaseSuccess,
  purchaseFail,
  restoreSuccess,
  themeApplied,
  themeApplicationFailed,
  themeFallbackTriggered,
  contrastAutoFixApplied,
  rtlEnabled,
  fontScale120Used,
  a11yViolationDetected,
  safeAreaViolationDetected,
  layoutOverflowFixed,
  keyboardInteractionDetected,
  themeTokenMissing,
  achievementEarned,
  achievementBonusGranted,
}

// Telemetry service for tracking conversion and usage events
class TelemetryService {
  static final TelemetryService _instance = TelemetryService._internal();
  factory TelemetryService() => _instance;
  static TelemetryService get instance => _instance;
  TelemetryService._internal();

  FirebaseAnalytics? _analytics;
  final AuthService _authService = AuthService.instance;

  bool _isEnabled = true;
  bool _isFirebaseAvailable = false;
  
  bool get isEnabled => _isEnabled;
  bool get isFirebaseAvailable => _isFirebaseAvailable;

  // Initialize Firebase Analytics safely
  void _initializeAnalytics() {
    try {
      _analytics = FirebaseAnalytics.instance;
      _isFirebaseAvailable = true;
    } catch (e) {
      print('⚠️ Firebase Analytics not available: $e');
      _analytics = null;
      _isFirebaseAvailable = false;
    }
  }

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (_analytics == null && enabled) {
      _initializeAnalytics();
    }
    if (_isFirebaseAvailable && _analytics != null) {
      _analytics!.setAnalyticsCollectionEnabled(enabled);
    }
  }

  // Track paywall events with locale context
  Future<void> trackPaywallView({
    String? variant,
    String? trigger,
    String? userId,
  }) async {
    final locale = _getDeviceLocale();
    final country = _getCountryCode();
    
    await _trackEvent(TelemetryEvent.paywallView, {
      'variant': variant ?? 'A',
      'trigger': trigger ?? 'unknown',
      'user_id': userId ?? _authService.currentUser?.uid,
      'locale': locale.toString(),
      'country': country,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> trackPaywallExit({
    String? action,
    int? timeSpentMs,
    String? userId,
  }) async {
    final locale = _getDeviceLocale();
    final country = _getCountryCode();
    
    await _trackEvent(TelemetryEvent.paywallExit, {
      'action': action ?? 'close',
      'time_spent_ms': timeSpentMs ?? 0,
      'user_id': userId ?? _authService.currentUser?.uid,
      'locale': locale.toString(),
      'country': country,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Track subscription events
  Future<void> trackIntroStarted({
    required SubscriptionType subscriptionType,
    String? userId,
  }) async {
    await _trackEvent(TelemetryEvent.introStarted, {
      'subscription_type': subscriptionType.name,
      'user_id': userId ?? _authService.currentUser?.uid,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> trackIntroConverted({
    required SubscriptionType subscriptionType,
    required double paidAmount,
    String? userId,
  }) async {
    await _trackEvent(TelemetryEvent.introConverted, {
      'subscription_type': subscriptionType.name,
      'paid_amount': paidAmount,
      'user_id': userId ?? _authService.currentUser?.uid,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> trackIntroRenewed({
    required SubscriptionType subscriptionType,
    required double paidAmount,
    String? userId,
  }) async {
    await _trackEvent(TelemetryEvent.introRenewed, {
      'subscription_type': subscriptionType.name,
      'paid_amount': paidAmount,
      'user_id': userId ?? _authService.currentUser?.uid,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Track starter pack events
  Future<void> trackStarterPackShown({
    String? trigger,
    int? creditsRemaining,
    String? userId,
  }) async {
    await _trackEvent(TelemetryEvent.starterPackShown, {
      'trigger': trigger ?? 'low_credits',
      'credits_remaining': creditsRemaining ?? 0,
      'user_id': userId ?? _authService.currentUser?.uid,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> trackStarterPackBought({
    required int creditsAdded,
    required double paidAmount,
    String? userId,
  }) async {
    await _trackEvent(TelemetryEvent.starterPackBought, {
      'credits_added': creditsAdded,
      'paid_amount': paidAmount,
      'user_id': userId ?? _authService.currentUser?.uid,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Track generation blocks
  Future<void> trackGenerationBlockedFree({
    required int creditsRemaining,
    required String contentType,
    String? userId,
  }) async {
    await _trackEvent(TelemetryEvent.generationBlockedFree, {
      'credits_remaining': creditsRemaining,
      'content_type': contentType,
      'user_id': userId ?? _authService.currentUser?.uid,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> trackGenerationBlockedBudget({
    required double budgetUsagePercent,
    required String contentType,
    String? userId,
  }) async {
    await _trackEvent(TelemetryEvent.generationBlockedBudget, {
      'budget_usage_percent': budgetUsagePercent,
      'content_type': contentType,
      'user_id': userId ?? _authService.currentUser?.uid,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Track budget events
  Future<void> trackBudgetWarn({
    required double budgetUsagePercent,
    required double monthlySpent,
  }) async {
    await _trackEvent(TelemetryEvent.budgetWarn, {
      'budget_usage_percent': budgetUsagePercent,
      'monthly_spent_usd': monthlySpent,
      'threshold': 'warn_70_percent',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> trackBudgetLimit({
    required double budgetUsagePercent,
    required double monthlySpent,
  }) async {
    await _trackEvent(TelemetryEvent.budgetLimit, {
      'budget_usage_percent': budgetUsagePercent,
      'monthly_spent_usd': monthlySpent,
      'threshold': 'limit_90_percent',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> trackBudgetHardBlock({
    required double budgetUsagePercent,
    required double monthlySpent,
  }) async {
    await _trackEvent(TelemetryEvent.budgetHardBlock, {
      'budget_usage_percent': budgetUsagePercent,
      'monthly_spent_usd': monthlySpent,
      'threshold': 'hard_100_percent',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Generic event tracking
  Future<void> _trackEvent(TelemetryEvent event, Map<String, dynamic> parameters) async {
    if (!_isEnabled) return;

    try {
      // Initialize analytics if needed
      if (_analytics == null) {
        _initializeAnalytics();
      }

      // Remove sensitive data and ensure non-PII params only
      final cleanParams = _sanitizeParameters(parameters);
      
      // Track to Firebase Analytics if available
      if (_isFirebaseAvailable && _analytics != null) {
        await _analytics!.logEvent(
          name: event.name,
          parameters: Map<String, Object>.from(cleanParams),
        );
      } else {
        // Fallback: just log to console if Firebase isn't available
        debugPrint('Telemetry (offline): ${event.name} -> $cleanParams');
      }

      if (kDebugMode) {
        debugPrint('Telemetry: ${event.name} -> $cleanParams');
      }
    } catch (e) {
      debugPrint('Error tracking telemetry event: $e');
    }
  }

  // Remove PII and sanitize parameters
  Map<String, dynamic> _sanitizeParameters(Map<String, dynamic> params) {
    final sanitized = <String, dynamic>{};
    
    params.forEach((key, value) {
      // Skip null values
      if (value == null) return;
      
      // Hash user ID if present
      if (key == 'user_id' && value is String) {
        sanitized['user_hash'] = value.hashCode.toString();
        return;
      }
      
      // Only include allowed parameter types
      if (value is String || value is int || value is double || value is bool) {
        sanitized[key] = value;
      }
    });
    
    return sanitized;
  }

  // Custom events for specific business logic
  Future<void> trackCustomEvent(String eventName, Map<String, dynamic> parameters) async {
    if (!_isEnabled) return;

    try {
      if (_analytics == null) {
        _initializeAnalytics();
      }
      
      final cleanParams = _sanitizeParameters(parameters);
      
      if (_isFirebaseAvailable && _analytics != null) {
        await _analytics!.logEvent(name: eventName, parameters: Map<String, Object>.from(cleanParams));
      } else {
        debugPrint('Telemetry (offline): $eventName -> $cleanParams');
      }
    } catch (e) {
      debugPrint('Error tracking custom event: $e');
    }
  }

  /// General event tracking method with parameters
  /// Compatible with ultra mode screen and other custom tracking needs
  Future<void> trackEvent(String eventName, {Map<String, dynamic>? parameters}) async {
    if (!_isEnabled) return;
    
    try {
      if (_analytics == null) {
        _initializeAnalytics();
      }
      
      final cleanParams = _sanitizeParameters(parameters ?? {});
      debugPrint('Tracking event: $eventName with parameters: $cleanParams');
      
      if (_isFirebaseAvailable && _analytics != null) {
        await _analytics!.logEvent(
          name: eventName, 
          parameters: Map<String, Object>.from(cleanParams)
        );
      } else {
        debugPrint('Telemetry (offline): $eventName -> $cleanParams');
      }
    } catch (e) {
      debugPrint('Error tracking event $eventName: $e');
    }
  }

  // User property setters (non-PII)
  Future<void> setUserProperty(String name, String value) async {
    try {
      if (_analytics == null) {
        _initializeAnalytics();
      }
      
      if (_isFirebaseAvailable && _analytics != null) {
        await _analytics!.setUserProperty(name: name, value: value);
      } else {
        debugPrint('Telemetry (offline): Set user property $name -> $value');
      }
    } catch (e) {
      debugPrint('Error setting user property: $e');
    }
  }

  // Set user subscription tier for analytics
  Future<void> setUserTier(SubscriptionType tier) async {
    await setUserProperty('subscription_tier', tier.name);
  }

  // Set user onboarding completed
  Future<void> setUserOnboarded() async {
    await setUserProperty('onboarding_complete', 'true');
  }

  // New international purchase lifecycle events
  Future<void> trackPurchaseStart({
    required String productId,
    required SubscriptionType subscriptionType,
    String? userId,
  }) async {
    final locale = _getDeviceLocale();
    final country = _getCountryCode();
    
    await _trackEvent(TelemetryEvent.purchaseStart, {
      'product_id': productId,
      'subscription_type': subscriptionType.name,
      'user_id': userId ?? _authService.currentUser?.uid,
      'locale': locale.toString(),
      'country': country,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> trackPurchaseSuccess({
    required String productId,
    required SubscriptionType subscriptionType,
    required String transactionId,
    String? localizedPrice,
    String? userId,
  }) async {
    final locale = _getDeviceLocale();
    final country = _getCountryCode();
    
    await _trackEvent(TelemetryEvent.purchaseSuccess, {
      'product_id': productId,
      'subscription_type': subscriptionType.name,
      'transaction_id': transactionId.hashCode.toString(), // Hash for privacy
      'localized_price': localizedPrice ?? 'unknown',
      'user_id': userId ?? _authService.currentUser?.uid,
      'locale': locale.toString(),
      'country': country,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> trackPurchaseFail({
    required String productId,
    required String errorCode,
    String? errorMessage,
    String? userId,
  }) async {
    final locale = _getDeviceLocale();
    final country = _getCountryCode();
    
    await _trackEvent(TelemetryEvent.purchaseFail, {
      'product_id': productId,
      'error_code': errorCode,
      'error_message': errorMessage ?? 'unknown',
      'user_id': userId ?? _authService.currentUser?.uid,
      'locale': locale.toString(),
      'country': country,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> trackRestoreSuccess({
    required List<String> restoredProducts,
    String? userId,
  }) async {
    final locale = _getDeviceLocale();
    final country = _getCountryCode();
    
    await _trackEvent(TelemetryEvent.restoreSuccess, {
      'restored_count': restoredProducts.length,
      'restored_products': restoredProducts.join(','),
      'user_id': userId ?? _authService.currentUser?.uid,
      'locale': locale.toString(),
      'country': country,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> trackRefundReceived({
    required String productId,
    required String reason,
    String? userId,
  }) async {
    final locale = _getDeviceLocale();
    final country = _getCountryCode();
    
    await _trackEvent(TelemetryEvent.refundReceived, {
      'product_id': productId,
      'refund_reason': reason,
      'user_id': userId ?? _authService.currentUser?.uid,
      'locale': locale.toString(),
      'country': country,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> trackEntitlementChanged({
    required String oldTier,
    required String newTier,
    required int newCredits,
    String? userId,
  }) async {
    final locale = _getDeviceLocale();
    final country = _getCountryCode();
    
    await _trackEvent(TelemetryEvent.entitlementChanged, {
      'old_tier': oldTier,
      'new_tier': newTier,
      'new_credits': newCredits,
      'user_id': userId ?? _authService.currentUser?.uid,
      'locale': locale.toString(),
      'country': country,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Generic event logging method
  Future<void> logEvent(String eventName, Map<String, dynamic> parameters) async {
    if (!_isEnabled || _analytics == null) return;
    
    try {
      final cleanParams = _sanitizeParameters(parameters);
      await _analytics!.logEvent(
        name: eventName,
        parameters: Map<String, Object>.from(cleanParams),
      );
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }


  // Get device locale
  Locale _getDeviceLocale() {
    try {
      return AppLocalizations.getSystemLocale();
    } catch (e) {
      return const Locale('en');
    }
  }

  // Get country code from locale or system
  String _getCountryCode() {
    try {
      final locale = Platform.localeName;
      final parts = locale.split('_');
      if (parts.length >= 2) {
        return parts[1].toUpperCase();
      }
      
      // Fallback mapping based on language
      final lang = parts[0];
      switch (lang) {
        case 'en': return 'US';
        case 'es': return 'ES';
        case 'pt': return 'BR';
        case 'fr': return 'FR';
        case 'de': return 'DE';
        case 'it': return 'IT';
        case 'ja': return 'JP';
        case 'ko': return 'KR';
        case 'zh': return 'CN';
        case 'ar': return 'SA';
        case 'hi': return 'IN';
        default: return 'US';
      }
    } catch (e) {
      return 'US';
    }
  }

  @override
  String toString() => 'TelemetryService(enabled: $_isEnabled)';
}