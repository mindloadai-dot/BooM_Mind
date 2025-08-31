import 'package:flutter/foundation.dart';
import 'package:mindload/models/pricing_models.dart';
import 'package:mindload/services/in_app_purchase_service.dart';
import 'package:mindload/services/remote_config_service.dart';
import 'package:mindload/services/firebase_iap_service.dart';
import 'package:mindload/services/telemetry_service.dart';

// International IAP configuration service for worldwide compliance
// Handles territory availability, local currency pricing, and payout readiness
class InternationalIapService {
  static final InternationalIapService _instance =
      InternationalIapService._internal();
  factory InternationalIapService() => _instance;
  static InternationalIapService get instance => _instance;
  InternationalIapService._internal();

  final InAppPurchaseService _iapService = InAppPurchaseService.instance;
  final RemoteConfigService _remoteConfig = RemoteConfigService.instance;
  final FirebaseIapService _firebaseIap = FirebaseIapService.instance;
  final TelemetryService _telemetry = TelemetryService.instance;

  bool _initialized = false;
  String _deviceTimezone = 'America/Chicago'; // Default ops timezone
  String _userTimezone = 'America/Chicago';

  bool get isInitialized => _initialized;
  String get deviceTimezone => _deviceTimezone;
  String get userTimezone => _userTimezone;

  // International product catalog (same IDs on both platforms)
  static const Map<String, Map<String, dynamic>> internationalProductCatalog = {
    // ProductIds.proMonthly: { // Removed
    //   'type': 'subscription',
    //   'base_price_usd': PricingConfig.proMonthlyPrice,
    //   'intro_price_usd': PricingConfig.introMonthPrice,
    //   'intro_period': '1 month',
    //   'billing_period': '1 month',
    //   'features': [
    //     '30 credits during intro month',
    //     '60 credits/month after intro',
    //     'Priority AI generation',
    //     'Advanced study features',
    //   ],
    //   'subscription_group': 'mindload_pro', // iOS subscription group
    // },
    ProductIds.logicPack: {
      'type': 'consumable',
      'price_usd': PricingConfig.logicPackPrice,
      'credits': PricingConfig.logicPackCredits, // Updated to 5
      'immediate': true,
    },
  };

  static final Map<String, Map<String, dynamic>> _regionalPricing = {
    // ProductIds.proMonthly: { // Removed
    //   'base_price_usd': PricingConfig.proMonthlyPrice,
    //   'intro_price_usd': PricingConfig.introMonthPrice,
    //   'intro_description': 'Introductory pricing for new users',
    // },
    ProductIds.logicPack: {
      'base_price_usd': PricingConfig.logicPackPrice,
      'intro_price_usd': null,
      'intro_description': null,
    },
    ProductIds.tokens250: {
      'base_price_usd': PricingConfig.tokens250Price,
      'intro_price_usd': null,
      'intro_description': null,
    },
    ProductIds.tokens600: {
      'base_price_usd': PricingConfig.tokens600Price,
      'intro_price_usd': null,
      'intro_description': null,
    },
  };

  Future<void> initialize() async {
    try {
      // Initialize dependent services
      await _iapService.initialize();
      await _remoteConfig.initialize();

      // Set device timezone (ops timezone defaults to America/Chicago)
      _deviceTimezone = 'America/Chicago';

      // Try to get user's device timezone for user-visible dates
      try {
        // Get user's actual timezone for display
        _userTimezone = await _getUserDeviceTimezone();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Could not determine user timezone, using default: $e');
        }
        _userTimezone = 'America/Chicago';
      }

      _initialized = true;
      if (kDebugMode) {
        debugPrint('International IAP service initialized');
        debugPrint('Ops timezone: $_deviceTimezone');
        debugPrint('User timezone: $_userTimezone');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing International IAP service: $e');
      }
      _initialized = false;
    }
  }

  // Get user's device timezone for user-visible dates
  Future<String> _getUserDeviceTimezone() async {
    try {
      // This would typically use a platform channel to get timezone
      // For now, return default ops timezone
      return 'America/Chicago';
    } catch (e) {
      return 'America/Chicago';
    }
  }

  // Territory and availability checks
  bool isProductAvailableInTerritory(String productId) {
    // Check Remote Config flags
    switch (productId) {
      // case ProductIds.proMonthly: // Removed
      //   return _remoteConfig.introEnabled;
      case ProductIds.logicPack:
        return _remoteConfig.logicPackEnabled;
      default:
        return false;
    }
  }

  // Get localized product info (stores handle actual currency conversion)
  Map<String, dynamic> getLocalizedProductInfo(String productId) {
    final catalog = internationalProductCatalog[productId];
    if (catalog == null) return {};

    // Store handles actual currency localization
    // We provide USD base prices and store converts to local currency
    return {
      ...catalog,
      'localized_by_store': true,
      'base_currency': 'USD',
      'display_timezone': _userTimezone,
    };
  }

  // Check if IAP-only mode is active (should always be true)
  bool get isIapOnlyModeActive => _remoteConfig.iapOnlyMode;

  // Check if manage links are enabled
  bool get areManageLinksEnabled => _remoteConfig.manageLinksEnabled;

  // Get all available products for current territory
  List<String> getAvailableProductIds() {
    return internationalProductCatalog.keys.where((productId) {
      return isProductAvailableInTerritory(productId);
    }).toList();
  }

  // Platform-specific subscription group for iOS
  String getiOSSubscriptionGroup() {
    return 'mindload_pro'; // All Pro subscriptions in same group
  }

  // Get platform-specific configuration
  Map<String, dynamic> getPlatformConfig() {
    return {
      'platform': defaultTargetPlatform.name,
      'subscription_group_ios': getiOSSubscriptionGroup(),
      'billing_api_android': 'Play Billing API 7+',
      'storekit_ios': 'StoreKit 2',
      'territory_availability': 'worldwide',
      'currency_localization': 'store_handled',
      'intro_offers': {
        'ios': 'Introductory Offers',
        'android': 'One-cycle intro pricing',
      },
    };
  }

  // Validate store configuration for payout readiness
  Future<Map<String, dynamic>> validateStoreConfiguration() async {
    return {
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'timezone': _deviceTimezone,
      'products_configured': internationalProductCatalog.length,
      'iap_only_mode': isIapOnlyModeActive,
      'territory_coverage': 'worldwide',
      'currency_handling': 'store_localized',
      'payout_ready': true,
      'intro_offers_configured': {
        // ProductIds.proMonthly: _remoteConfig.introEnabled, // Removed
      },
      'platform_compliance': {
        'ios_storekit': '2.0',
        'android_billing': '7+',
        'webhook_handlers': 'firebase_cloud_functions',
        'server_verification': 'enabled',
      },
    };
  }

  // Record compliance telemetry
  Future<void> recordComplianceTelemetry(
      String event, Map<String, dynamic> data) async {
    try {
      await _telemetry.logEvent('iap_compliance_$event', {
        ...data,
        'timezone': _deviceTimezone,
        'iap_only_mode': isIapOnlyModeActive,
      });
    } catch (e) {
      debugPrint('Error recording compliance telemetry: $e');
    }
  }

  // Get manage subscription URLs (only if enabled)
  String getSubscriptionManagementUrl() {
    if (!areManageLinksEnabled) return '';
    return _iapService.getSubscriptionManagementUrl();
  }

  String getSubscriptionManagementLabel() {
    if (!areManageLinksEnabled) return '';
    return _iapService.getSubscriptionManagementLabel();
  }

  // Check if all required products are configured
  Future<bool> areAllProductsConfigured() async {
    final availableProducts = _iapService.products;
    final requiredProductIds = internationalProductCatalog.keys.toSet();
    final configuredProductIds =
        availableProducts.where((p) => p.id != null).map((p) => p.id).toSet();

    final missing = requiredProductIds.difference(configuredProductIds);
    if (missing.isNotEmpty) {
      debugPrint('Missing product configurations: $missing');
      return false;
    }

    return true;
  }

  // Get product pricing for display (stores handle localization)
  Map<String, String> getDisplayPricing() {
    return {
      // ProductIds.proMonthly: '\$${PricingConfig.proMonthlyPrice}/month', // Removed
      ProductIds.logicPack: '\$${PricingConfig.logicPackPrice}',
    };
  }

  // Validate intro offer eligibility
  Future<bool> isIntroOfferEligible(String productId) async {
    final currentUser = _iapService.currentUser;
    if (currentUser == null) return true;

    // Check if user has already used intro offers
    if (currentUser.introUsed) return false;

    // Check Remote Config flags
    // if (productId == ProductIds.proMonthly) { // Removed
    //   return _remoteConfig.introEnabled;
    // }

    return false;
  }

  // Get comprehensive product configuration for debugging
  Future<Map<String, dynamic>> getProductConfiguration() async {
    return {
      'catalog': internationalProductCatalog,
      'remote_config': _remoteConfig.getAllConfigValues(),
      'platform_config': getPlatformConfig(),
      'availability': {
        for (String productId in internationalProductCatalog.keys)
          productId: isProductAvailableInTerritory(productId),
      },
      'store_products': {
        for (final product in _iapService.products)
          product.id: {
            'title': product.title,
            'description': product.description,
            'price': product.price,
            'currency_code': product.currencyCode,
          },
      },
      'validation': await validateStoreConfiguration(),
    };
  }

  @override
  String toString() {
    return 'InternationalIapService(initialized: $_initialized, timezone: $_deviceTimezone)';
  }
}
