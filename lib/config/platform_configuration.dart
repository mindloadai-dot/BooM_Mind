// Platform-specific configuration for international IAP compliance
// iOS and Android specific settings for Mindload

import 'package:flutter/foundation.dart';

// Web-safe platform detection helper
class WebSafePlatform {
  static bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  static bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get isWeb => kIsWeb;
  static bool get isMobile => isIOS || isAndroid;
}

class PlatformConfiguration {
  
  // ========================================
  // iOS PLATFORM CONFIGURATION
  // ========================================
  
  static const Map<String, dynamic> iOSConfig = {
    // App Store Connect Configuration
    'bundle_id': 'com.MindLoad.ios', // Update with actual bundle ID
    'app_store_id': 'TBD', // Update after app is created in App Store Connect
    'team_id': 'TBD', // Update with Apple Developer Team ID
    
    // StoreKit 2 Configuration
    'storekit_version': '2.0',
    'subscription_group_id': 'mindload_pro',
    'intro_offer_type': 'introductory_offer',
    'intro_eligibility': 'new_subscribers_only',
    
    // Product Configuration
    'products': {
      'com.mindload.pro.monthly': {
        'type': 'auto_renewable_subscription',
        'subscription_group': 'mindload_pro',
        'intro_offer': {
          'price': 0.99,
          'period': 'P1M', // 1 month
          'payment_mode': 'pay_as_you_go',
        },
      },
      'com.mindload.pro.annual': {
        'type': 'auto_renewable_subscription', 
        'subscription_group': 'mindload_pro',
        'intro_offer': {
          'price': 39.99,
          'period': 'P1Y', // 1 year
          'payment_mode': 'pay_up_front',
        },
      },
      'com.mindload.credits.starter100': {
        'type': 'consumable',
        'consumable_type': 'one_time_purchase',
      },
    },
    
    // App Store Configuration
    'territories': 'all_available',
    'price_tier_monthly': '6.99_tier',
    'price_tier_annual': '49.99_tier', 
    'price_tier_starter': '1.99_tier',
    'auto_renewable_subscription': true,
    'subscription_management': 'app_store',
    
    // Info.plist Requirements
    'required_permissions': [
      // No special permissions required for IAP
    ],
    'required_background_modes': [
      // None required for IAP
    ],
    'url_schemes': [
      // Optional: Deep linking for subscription management
      'mindload-subscription',
    ],
  };

  // ========================================
  // ANDROID PLATFORM CONFIGURATION
  // ========================================
  
  static const Map<String, dynamic> androidConfig = {
    // Google Play Console Configuration
    'package_name': 'com.MindLoad.android', // Update with actual package name
    'app_id': 'TBD', // Update after app is uploaded to Play Console
    'developer_id': 'TBD', // Update with Google Play Developer ID
    
    // Play Billing API Configuration
    'billing_api_version': '7.1.0',
    'billing_client_version': '7+',
    'acknowledgment_required': true,
    'obfuscated_account_id_required': false,
    
    // Product Configuration
    'products': {
      'com.mindload.pro.monthly': {
        'type': 'SUBS', // Subscription
        'billing_period': 'P1M', // 1 month
        'intro_pricing': {
          'price_amount_micros': 990000, // 0.99 USD
          'price_currency_code': 'USD',
          'billing_period': 'P1M',
          'billing_cycles_count': 1,
        },
      },
      'com.mindload.pro.annual': {
        'type': 'SUBS', // Subscription
        'billing_period': 'P1Y', // 1 year
        'intro_pricing': {
          'price_amount_micros': 39990000, // 39.99 USD
          'price_currency_code': 'USD',
          'billing_period': 'P1Y',
          'billing_cycles_count': 1,
        },
      },
      'com.mindload.credits.starter100': {
        'type': 'INAPP', // In-app product (managed)
        'consumable': true,
        'acknowledgment_required': true,
      },
    },
    
    // Play Console Configuration
    'countries': 'all_available',
    'pricing_template': 'worldwide_template',
    'subscription_management': 'google_play',
    'real_time_developer_notifications': true,
    'pub_sub_topic': 'projects/mindload-firebase/topics/rtdn-play-billing',
    
    // AndroidManifest.xml Requirements
    'required_permissions': [
      'com.android.vending.BILLING',
      'android.permission.INTERNET',
      'android.permission.ACCESS_NETWORK_STATE',
    ],
    'required_features': [
      // No hardware features required for IAP
    ],
    'intent_filters': [
      // Optional: Deep linking for subscription management
      {
        'action': 'android.intent.action.VIEW',
        'category': 'android.intent.category.DEFAULT',
        'category_browsable': 'android.intent.category.BROWSABLE',
        'data_scheme': 'mindload-subscription',
      },
    ],
  };

  // ========================================
  // FIREBASE CONFIGURATION
  // ========================================
  
  static const Map<String, dynamic> firebaseConfig = {
    // Cloud Functions Configuration
    'functions': {
      'region': 'us-central1',
      'runtime': 'nodejs20',
      'timeout': '60s',
      'memory': '512MB',
      'environment_variables': {
        'TZ': 'America/Chicago',
        'NODE_ENV': 'production',
      },
    },
    
    // Firestore Configuration
    'firestore': {
      'region': 'us-central',
      'security_rules': 'production_ready',
      'indexes': [
        // User queries
        'users by uid',
        'users by tier',
        
        // Entitlement queries
        'entitlements by uid',
        'entitlements by status',
        
        // IAP event queries
        'iapEvents by transactionId',
        'iapEvents by uid',
        'iapEvents by platform',
        'iapEvents by type',
        'iapEvents by processedAt',
        
        // Credit ledger queries
        'creditLedger by uid',
        'creditLedger by createdAt',
        
        // Receipt queries
        'receipts by uid',
        'receipts by lastVerifiedAt',
      ],
    },
    
    // Remote Config Configuration
    'remote_config': {
      'parameters': [
        'intro_enabled',
        'annual_intro_enabled',
        'starter_pack_enabled',
        'iap_only_mode',
        'manage_links_enabled',
        'apple_payout_ready',
        'google_payout_ready',
      ],
      'conditions': [
        // Territory-specific configurations if needed
        'ios_users',
        'android_users',
        'beta_users',
      ],
    },
    
    // Secret Manager Configuration
    'secret_manager': {
      'required_secrets': [
        'APPLE_ISSUER_ID',
        'APPLE_KEY_ID', 
        'APPLE_PRIVATE_KEY',
        'APPLE_BUNDLE_ID',
        'GOOGLE_SERVICE_ACCOUNT_JSON',
        'GOOGLE_PACKAGE_NAME',
        'PLAY_PUBSUB_TOPIC',
      ],
      'access_control': 'cloud_functions_only',
    },
  };

  // ========================================
  // WEBHOOK CONFIGURATION
  // ========================================
  
  static const Map<String, dynamic> webhookConfig = {
    // Apple App Store Server Notifications
    'apple_webhook': {
      'endpoint': 'https://us-central1-<project-id>.cloudfunctions.net/processAppleWebhook',
      'notification_types': [
        'SUBSCRIBED',
        'DID_RENEW', 
        'EXPIRED',
        'DID_FAIL_TO_RENEW',
        'REFUND',
        'REVOKE',
        'PRICE_INCREASE_CONSENT',
      ],
      'version': 'V2',
      'include_bundle_id': true,
      'include_product_id': true,
    },
    
    // Google Play Real-time Developer Notifications
    'google_webhook': {
      'pub_sub_topic': 'projects/mindload-firebase/topics/rtdn-play-billing',
      'cloud_function': 'processGoogleWebhook',
      'notification_types': [
        'SUBSCRIPTION_PURCHASED',
        'SUBSCRIPTION_RENEWED',
        'SUBSCRIPTION_CANCELED',
        'SUBSCRIPTION_EXPIRED',
        'SUBSCRIPTION_REVOKED',
        'SUBSCRIPTION_PAUSED',
        'SUBSCRIPTION_RESUMED',
        'SUBSCRIPTION_PRICE_CHANGE_CONFIRMED',
      ],
      'version': '1.3',
      'acknowledgment_deadline': '60s',
    },
  };

  // ========================================
  // COMPLIANCE CONFIGURATION
  // ========================================
  
  static const Map<String, dynamic> complianceConfig = {
    // Store Policy Compliance
    'store_policies': {
      'apple_app_store': {
        'guideline_compliance': '3.1.1', // In-App Purchase
        'subscription_management': '3.1.2',
        'pricing_transparency': '3.1.3(b)',
        'restore_functionality': '3.1.2',
      },
      'google_play': {
        'policy_compliance': 'Payments',
        'subscription_management': 'Play Billing API',
        'pricing_transparency': 'Store Listing',
        'acknowledgment_required': true,
      },
    },
    
    // International Requirements
    'international': {
      'currency_support': 'store_localized',
      'territory_availability': 'worldwide',
      'tax_compliance': 'store_handled',
      'payout_requirements': 'banking_complete',
    },
    
    // Privacy and Data Protection
    'privacy': {
      'data_collection': 'minimal_anonymous',
      'user_data_storage': 'firebase_firestore',
      'analytics_compliance': 'non_pii_only',
      'gdpr_compliance': 'user_consent',
      'ccpa_compliance': 'opt_out_available',
    },
  };

  // ========================================
  // HELPER METHODS
  // ========================================
  
  // Get platform-specific configuration
  static Map<String, dynamic> getCurrentPlatformConfig() {
    if (WebSafePlatform.isIOS) {
      return iOSConfig;
    } else if (WebSafePlatform.isAndroid) {
      return androidConfig;
    } else {
      return {}; // Return empty config for web
    }
  }
  
  // Get required permissions for current platform
  static List<String> getRequiredPermissions() {
    final config = getCurrentPlatformConfig();
    return List<String>.from(config['required_permissions'] ?? []);
  }
  
  // Get product configuration for current platform
  static Map<String, dynamic> getProductConfiguration() {
    final config = getCurrentPlatformConfig();
    return Map<String, dynamic>.from(config['products'] ?? {});
  }
  
  // Validate configuration completeness
  static Map<String, bool> validateConfiguration() {
    return {
      'ios_configured': _validateiOSConfig(),
      'android_configured': _validateAndroidConfig(),
      'firebase_configured': _validateFirebaseConfig(),
      'webhooks_configured': _validateWebhookConfig(),
      'compliance_ready': _validateCompliance(),
    };
  }
  
  static bool _validateiOSConfig() {
    // Check if iOS configuration is complete
    final config = iOSConfig;
    return config['bundle_id'] != 'TBD' &&
           config['team_id'] != 'TBD' &&
           config['app_store_id'] != 'TBD';
  }
  
  static bool _validateAndroidConfig() {
    // Check if Android configuration is complete
    final config = androidConfig;
    return config['package_name'] != 'TBD' &&
           config['app_id'] != 'TBD' &&
           config['developer_id'] != 'TBD';
  }
  
  static bool _validateFirebaseConfig() {
    // This would check Firebase project configuration
    // For now, return false until setup is complete
    return false;
  }
  
  static bool _validateWebhookConfig() {
    // This would check webhook configuration
    // For now, return false until setup is complete
    return false;
  }
  
  static bool _validateCompliance() {
    // Check overall compliance readiness
    return _validateiOSConfig() && 
           _validateAndroidConfig() && 
           _validateFirebaseConfig() && 
           _validateWebhookConfig();
  }
  
  // Get configuration summary for debugging
  static Map<String, dynamic> getConfigurationSummary() {
    return {
      'platform': WebSafePlatform.isWeb ? 'web' : (WebSafePlatform.isIOS ? 'ios' : (WebSafePlatform.isAndroid ? 'android' : 'unknown')),
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'ios_config': iOSConfig,
      'android_config': androidConfig,
      'firebase_config': firebaseConfig,
      'webhook_config': webhookConfig,
      'compliance_config': complianceConfig,
      'validation': validateConfiguration(),
    };
  }
}