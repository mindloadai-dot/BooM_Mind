import 'package:flutter/foundation.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:mindload/services/unified_storage_service.dart';
import 'package:mindload/models/pricing_models.dart';

/// PricingService centralizes all MindLoad pricing and token quotas.
/// Values come from RemoteConfig when present, with safe defaults.
/// Update Remote Config (or call applyOverrides) to change pricing without an app release.
class PricingService extends ChangeNotifier {
  static final PricingService _instance = PricingService._internal();
  static PricingService get instance => _instance;
  PricingService._internal();

  // Remote Config Keys
  // static const String _kProMonthlyPrice = 'pricing_pro_monthly_usd'; // Removed
  static const String _kStarterPackPrice = 'pricing_starter_pack_usd';
  static const String _kTokens250Price = 'pricing_tokens_250_usd';
  static const String _kTokens600Price = 'pricing_tokens_600_usd';

  // New MindLoad Starter Pack Remote Config Keys
  static const String _kSparkLogicPrice = 'pricing_spark_logic_usd';
  static const String _kNeuroLogicPrice = 'pricing_neuro_logic_usd';
  static const String _kCortexLogicPrice = 'pricing_cortex_logic_usd';

  static const String _kQuantumLogicPrice = 'pricing_quantum_logic_usd';

  // Default prices (fallback when remote config is not available)
  // double _proMonthlyPrice = PricingConfig.proMonthlyPrice; // Removed
  double _starterPackPrice = PricingConfig.logicPackPrice;
  double _tokens250Price = PricingConfig.tokens250Price;
  double _tokens600Price = PricingConfig.tokens600Price;

  // New MindLoad Logic Pack prices
  double _sparkLogicPrice = PricingConfig.sparkLogicPrice;
  double _neuroLogicPrice = PricingConfig.neuroLogicPrice;
  double _cortexLogicPrice = PricingConfig.cortexLogicPrice;

  double _quantumLogicPrice = PricingConfig.quantumLogicPrice;

  // Public getters
  // double get proMonthlyPrice => _proMonthlyPrice; // Removed
  double get starterPackPrice => _starterPackPrice;
  double get tokens250Price => _tokens250Price;
  double get tokens600Price => _tokens600Price;

  // New MindLoad Logic Pack getters
  double get sparkLogicPrice => _sparkLogicPrice;
  double get neuroLogicPrice => _neuroLogicPrice;
  double get cortexLogicPrice => _cortexLogicPrice;

  double get quantumLogicPrice => _quantumLogicPrice;

  Future<void> initialize() async {
    try {
      // Load persisted overrides first (if any)
      final saved = await UnifiedStorageService.instance
          .getJsonData('pricing_overrides');
      if (saved != null) {
        applyOverrides(saved, persist: false);
      }

      // Pull from Remote Config (if available)
      try {
        final remoteConfig = FirebaseRemoteConfig.instance;
        await remoteConfig.fetchAndActivate();

        // Pro Monthly removed

        final starterPackRemote = remoteConfig.getDouble(_kStarterPackPrice);
        if (starterPackRemote > 0) _starterPackPrice = starterPackRemote;

        final tokens250Remote = remoteConfig.getDouble(_kTokens250Price);
        if (tokens250Remote > 0) _tokens250Price = tokens250Remote;

        final tokens600Remote = remoteConfig.getDouble(_kTokens600Price);
        if (tokens600Remote > 0) _tokens600Price = tokens600Remote;

        // Fetch new MindLoad Logic Pack prices from Remote Config
        final sparkLogicRemote = remoteConfig.getDouble(_kSparkLogicPrice);
        if (sparkLogicRemote > 0) _sparkLogicPrice = sparkLogicRemote;

        final neuroLogicRemote = remoteConfig.getDouble(_kNeuroLogicPrice);
        if (neuroLogicRemote > 0) _neuroLogicPrice = neuroLogicRemote;

        final cortexLogicRemote = remoteConfig.getDouble(_kCortexLogicPrice);
        if (cortexLogicRemote > 0) _cortexLogicPrice = cortexLogicRemote;

        final quantumLogicRemote = remoteConfig.getDouble(_kQuantumLogicPrice);
        if (quantumLogicRemote > 0) _quantumLogicPrice = quantumLogicRemote;
      } catch (e) {
        debugPrint('Error fetching pricing from Remote Config: $e');
      }

      notifyListeners();
    } catch (_) {
      // Ignore errors; defaults remain
    }
  }

  /// Apply overrides programmatically (e.g., admin/dev panel) and optionally persist.
  Future<void> applyOverrides(Map<String, dynamic> overrides,
      {bool persist = true}) async {
    // Pro Monthly removed
    if (overrides.containsKey(_kStarterPackPrice)) {
      _starterPackPrice = (overrides[_kStarterPackPrice] as num).toDouble();
    }
    if (overrides.containsKey(_kTokens250Price)) {
      _tokens250Price = (overrides[_kTokens250Price] as num).toDouble();
    }
    if (overrides.containsKey(_kTokens600Price)) {
      _tokens600Price = (overrides[_kTokens600Price] as num).toDouble();
    }

    // Apply new MindLoad Logic Pack price overrides
    if (overrides.containsKey(_kSparkLogicPrice)) {
      _sparkLogicPrice = (overrides[_kSparkLogicPrice] as num).toDouble();
    }
    if (overrides.containsKey(_kNeuroLogicPrice)) {
      _neuroLogicPrice = (overrides[_kNeuroLogicPrice] as num).toDouble();
    }
    if (overrides.containsKey(_kCortexLogicPrice)) {
      _cortexLogicPrice = (overrides[_kCortexLogicPrice] as num).toDouble();
    }

    if (overrides.containsKey(_kQuantumLogicPrice)) {
      _quantumLogicPrice = (overrides[_kQuantumLogicPrice] as num).toDouble();
    }

    if (persist) {
      await UnifiedStorageService.instance
          .saveJsonData('pricing_overrides', overrides);
    }
    notifyListeners();
  }
}
