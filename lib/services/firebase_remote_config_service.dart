import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:mindload/models/iap_firebase_models.dart';

class FirebaseRemoteConfigService {
  static final FirebaseRemoteConfigService _instance = FirebaseRemoteConfigService._internal();
  factory FirebaseRemoteConfigService() => _instance;
  static FirebaseRemoteConfigService get instance => _instance;
  FirebaseRemoteConfigService._internal();

  FirebaseRemoteConfig? _remoteConfig;
  bool _initialized = false;

  Future<void> initialize() async {
    try {
      _remoteConfig = FirebaseRemoteConfig.instance;
      
      // Set configuration settings
      await _remoteConfig!.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 1),
      ));

      // Set default values for international IAP compliance
      await _remoteConfig!.setDefaults(RemoteConfigKeys.defaults);

      // Fetch and activate
      await _remoteConfig!.fetchAndActivate();
      _initialized = true;
      
      debugPrint('Remote Config initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Remote Config: $e');
      _initialized = false;
    }
  }

  Future<void> fetchAndActivate() async {
    if (_remoteConfig == null) return;
    
    try {
      await _remoteConfig!.fetchAndActivate();
    } catch (e) {
      debugPrint('Error fetching Remote Config: $e');
    }
  }

  // Getter methods for each config value
  bool get introEnabled {
    if (!_initialized || _remoteConfig == null) return true;
    return _remoteConfig!.getBool(RemoteConfigKeys.introEnabled);
  }

  bool get logicPackEnabled {
    if (!_initialized || _remoteConfig == null) return true;
    return _remoteConfig!.getBool(RemoteConfigKeys.logicPackEnabled);
  }

  bool get iapOnlyMode {
    if (!_initialized || _remoteConfig == null) return true;
    return _remoteConfig!.getBool(RemoteConfigKeys.iapOnlyMode);
  }

  bool get manageLinksEnabled {
    if (!_initialized || _remoteConfig == null) return true;
    return _remoteConfig!.getBool(RemoteConfigKeys.manageLinksEnabled);
  }

  // Get all config values for debugging
  Map<String, dynamic> getAllConfigValues() {
    if (!_initialized || _remoteConfig == null) {
      return RemoteConfigKeys.defaults;
    }

    return {
      RemoteConfigKeys.introEnabled: _remoteConfig!.getBool(RemoteConfigKeys.introEnabled),
      RemoteConfigKeys.logicPackEnabled: _remoteConfig!.getBool(RemoteConfigKeys.logicPackEnabled),
      RemoteConfigKeys.iapOnlyMode: _remoteConfig!.getBool(RemoteConfigKeys.iapOnlyMode),
      RemoteConfigKeys.manageLinksEnabled: _remoteConfig!.getBool(RemoteConfigKeys.manageLinksEnabled),
    };
  }
}