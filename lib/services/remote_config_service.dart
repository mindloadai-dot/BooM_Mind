import 'package:flutter/foundation.dart';
import 'package:mindload/services/storage_service.dart';
import 'package:mindload/l10n/app_localizations.dart';
import 'dart:io';

// Remote config service for feature flags and A/B testing
class RemoteConfigService extends ChangeNotifier {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  static RemoteConfigService get instance => _instance;
  RemoteConfigService._internal();

  // Default values as specified in requirements with regional controls
  Map<String, dynamic> _config = {
    'intro_enabled': true,
    'logic_pack_enabled': true,
    'efficient_mode_enabled': false,
    'paywall_copy_variant': 'A',
    // Regional feature controls
    'intro_enabled_eu': true,
    'intro_enabled_apac': true,
    'intro_enabled_latam': true,
    'logic_pack_enabled_eu': true,
    'logic_pack_enabled_apac': true,
    'logic_pack_enabled_latam': true,
    // Country-specific free quota overrides
    'free_quota_override_country_US': 0,
    'free_quota_override_country_CA': 0,
    'free_quota_override_country_UK': 0,
    'free_quota_override_country_DE': 0,
    'free_quota_override_country_FR': 0,
    'free_quota_override_country_BR': 0,
    'free_quota_override_country_MX': 0,
    'free_quota_override_country_IN': 0,
    'free_quota_override_country_JP': 0,
    'free_quota_override_country_KR': 0,
    'free_quota_override_country_AU': 0,
    'free_quota_override_country_SA': 0,
    'free_quota_override_country_ZA': 0,

    // Pricing knobs (optional; 0 means use defaults in app)
    'pricing_pro_monthly_usd': 0.0,
    'pricing_logic_pack_usd': 0.0,
    'tokens_free_monthly': 0,
    'tokens_pro_monthly': 0,
    'tokens_intro_month': 0,
    'tokens_logic_pack_bonus': 0,

    // New MindLoad Logic Pack pricing (optional; 0 means use defaults)
    'pricing_spark_pack_usd': 0.0,
    'pricing_neuro_burst_usd': 0.0,
    'pricing_exam_surge_usd': 0.0,
    'pricing_cognitive_boost_usd': 0.0,
    'pricing_synaptic_storm_usd': 0.0,

    // MindLoad Logic Pack feature flags
    'spark_pack_enabled': true,
    'neuro_burst_enabled': true,
    'exam_surge_enabled': true,
    'cognitive_boost_enabled': true,
    'synaptic_storm_enabled': true,

    // MindLoad Logic Pack descriptions
    'logic_packs_description':
        'One-time purchases to boost your learning with immediate ML Tokens',
  };

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    try {
      await _loadConfigFromStorage();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing remote config: $e');
      _isInitialized = true; // Use defaults
    }
  }

  // Core flag getters with regional awareness
  bool get introEnabled => _getRegionalFlag('intro_enabled');
  bool get logicPackEnabled => _getRegionalFlag('logic_pack_enabled');
  bool get efficientModeEnabled => getBool('efficient_mode_enabled');
  String get paywallCopyVariant => getString('paywall_copy_variant');

  // MindLoad Logic Pack feature flags
  bool get sparkPackEnabled => getBool('spark_pack_enabled');
  bool get neuroBurstEnabled => getBool('neuro_burst_enabled');
  bool get cortexPackEnabled => getBool('cortex_pack_enabled');

  bool get quantumPackEnabled => getBool('quantum_pack_enabled');

  // MindLoad Logic Pack descriptions
  String get logicPacksDescription => getString('logic_packs_description');

  // Get free quota with country override
  int get freeQuotaForUser {
    final countryCode = _getCountryCode();
    final override = getInt('free_quota_override_country_$countryCode');
    if (override > 0) return override;
    return 3; // Default free quota
  }

  // Generic getters
  bool getBool(String key) => _config[key] as bool? ?? false;
  String getString(String key) => _config[key] as String? ?? '';
  int getInt(String key) => _config[key] as int? ?? 0;
  double getDouble(String key) => _config[key] as double? ?? 0.0;

  // Update config values (for testing or admin overrides)
  Future<void> setConfig(Map<String, dynamic> newConfig) async {
    _config = {..._config, ...newConfig};
    await _saveConfigToStorage();
    notifyListeners();
  }

  Future<void> setBool(String key, bool value) async {
    _config[key] = value;
    await _saveConfigToStorage();
    notifyListeners();
  }

  Future<void> setString(String key, String value) async {
    _config[key] = value;
    await _saveConfigToStorage();
    notifyListeners();
  }

  // Enable efficient mode (can be triggered by budget control)
  Future<void> enableEfficientMode() async {
    await setBool('efficient_mode_enabled', true);
  }

  Future<void> disableEfficientMode() async {
    await setBool('efficient_mode_enabled', false);
  }

  // Paywall copy variants for A/B testing
  Map<String, dynamic> getPaywallCopy() {
    switch (paywallCopyVariant) {
      case 'A':
        return {
          'header': 'Unlock Pro for Focused Wins',
          'monthly_badge': '\$2.99 first month',
          'monthly_subtitle': 'then \$6.99/month, cancel anytime',
          'monthly_bullets': [
            '30 intro ML Tokens',
            'Priority generation',
            'Adaptive reminders',
          ],
          'annual_title': '\$49.99/year — Save 28%',
          'annual_subtitle': 'Best value with annual savings',
          'primary_button': 'Start Pro',
          'secondary_button': 'Restore Purchases',
        };
      case 'B':
        return {
          'header': 'Supercharge Your Study Game',
          'monthly_badge': '\$2.99 Trial Month',
          'monthly_subtitle': 'then \$6.99/month, cancel anytime',
          'monthly_bullets': [
            '30 AI-powered ML Tokens',
            'Skip the queue',
            'Smart notifications',
          ],
          'annual_title': '\$49.99/year — Save \$34',
          'annual_subtitle': 'Ultimate value package',
          'primary_button': 'Get Pro Now',
          'secondary_button': 'Restore',
        };
      default:
        return getPaywallCopy(); // Fallback to variant A
    }
  }

  // Exit intent copy
  Map<String, String> getExitIntentCopy() {
    return {
      'title': 'Not ready to subscribe?',
      'body': 'Logic Pack \$2.99 → +50 tokens',
      'primary_button': 'Buy Logic Pack',
      'secondary_button': 'Maybe Later',
    };
  }

  Future<void> _loadConfigFromStorage() async {
    try {
      final stored = await StorageService.instance.getRemoteConfig();
      if (stored != null) {
        _config = {..._config, ...stored};
      }
    } catch (e) {
      debugPrint('Error loading config from storage: $e');
    }
  }

  Future<void> _saveConfigToStorage() async {
    try {
      await StorageService.instance.saveRemoteConfig(_config);
    } catch (e) {
      debugPrint('Error saving config to storage: $e');
    }
  }

  // For development/testing - reset to defaults
  Future<void> resetToDefaults() async {
    _config = {
      'intro_enabled': true,
      'logic_pack_enabled': true,
      'efficient_mode_enabled': false,
      'paywall_copy_variant': 'A',
    };
    await _saveConfigToStorage();
    notifyListeners();
  }

  // Get regional flag with fallback to global
  bool _getRegionalFlag(String baseFlag) {
    final region = _getUserRegion();
    final regionalFlag = '${baseFlag}_${region.toLowerCase()}';

    // Try regional override first, fallback to global
    if (_config.containsKey(regionalFlag)) {
      return getBool(regionalFlag);
    }
    return getBool(baseFlag);
  }

  // Determine user region based on country
  String _getUserRegion() {
    final country = _getCountryCode();

    // EU countries
    const euCountries = [
      'DE',
      'FR',
      'IT',
      'ES',
      'NL',
      'BE',
      'AT',
      'CH',
      'DK',
      'SE',
      'NO',
      'FI',
      'PL',
      'CZ',
      'HU',
      'PT',
      'IE',
      'GR',
      'RO',
      'BG',
      'HR',
      'LT',
      'LV',
      'EE',
      'SI',
      'SK',
      'CY',
      'MT',
      'LU',
      'UK'
    ];
    if (euCountries.contains(country)) return 'EU';

    // APAC countries
    const apacCountries = [
      'JP',
      'KR',
      'CN',
      'IN',
      'SG',
      'MY',
      'TH',
      'PH',
      'VN',
      'ID',
      'AU',
      'NZ',
      'TW',
      'HK'
    ];
    if (apacCountries.contains(country)) return 'APAC';

    // LATAM countries
    const latamCountries = [
      'BR',
      'MX',
      'AR',
      'CL',
      'CO',
      'PE',
      'VE',
      'EC',
      'BO',
      'PY',
      'UY',
      'GY',
      'SR',
      'FK'
    ];
    if (latamCountries.contains(country)) return 'LATAM';

    // Default to global settings
    return 'GLOBAL';
  }

  // Get country code from system locale
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
        case 'en':
          return 'US';
        case 'es':
          return 'ES';
        case 'pt':
          return 'BR';
        case 'fr':
          return 'FR';
        case 'de':
          return 'DE';
        case 'it':
          return 'IT';
        case 'ja':
          return 'JP';
        case 'ko':
          return 'KR';
        case 'zh':
          return 'CN';
        case 'ar':
          return 'SA';
        case 'hi':
          return 'IN';
        default:
          return 'US';
      }
    } catch (e) {
      return 'US';
    }
  }

  // Get localized paywall copy
  Map<String, dynamic> getLocalizedPaywallCopy(AppLocalizations l10n) {
    return {
      'header': l10n.paywallHeader,
      'monthly_badge': l10n.monthlyBadge,
      'monthly_subtitle': l10n.monthlySubtitle,
      'monthly_bullets': [
        l10n.introCredits,
        l10n.priorityGeneration,
        l10n.adaptiveReminders,
      ],
      'annual_title': l10n.annualTitle,
      'annual_subtitle': 'Best value with annual savings',
      'primary_button': l10n.primaryButton,
      'secondary_button': l10n.secondaryButton,
    };
  }

  // Get localized exit intent copy
  Map<String, String> getLocalizedExitIntentCopy(AppLocalizations l10n) {
    return {
      'title': l10n.exitIntentTitle,
      'body': l10n.exitIntentBody,
      'primary_button': l10n.exitIntentBuy,
      'secondary_button': l10n.exitIntentMaybe,
    };
  }
}
