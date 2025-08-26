import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mindload/models/iap_firebase_models.dart';
import 'package:mindload/services/auth_service.dart';

class FirebaseIapService {
  static final FirebaseIapService _instance = FirebaseIapService._internal();
  factory FirebaseIapService() => _instance;
  static FirebaseIapService get instance => _instance;
  FirebaseIapService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService.instance;

  bool _initialized = false;

  /// Initialize the service
  Future<void> initialize() async {
    try {
      await FirebaseAppCheck.instance.activate(
        webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );
      
      _initialized = true;
      
      if (kDebugMode) {
        debugPrint('Firebase IAP Service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to initialize Firebase IAP Service: $e');
      }
      rethrow;
    }
  }

  // Cloud Function: iapVerifyPurchase
  // Purpose: Client sends purchase token/transaction; server verifies with Apple/Google; updates entitlements/credits
  // Requires Firebase Auth and App Check
  Future<Map<String, dynamic>?> verifyPurchase({
    required String platform, // 'ios' or 'android'
    required String transactionId,
    String? purchaseToken, // Required for Android
    required String productId,
  }) async {
    if (!_initialized) {
      throw Exception('Firebase IAP Service not initialized');
    }

    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated');
    }

    try {
      final callable = _functions.httpsCallable('iapVerifyPurchase');
      final result = await callable.call({
        'platform': platform,
        'transactionId': transactionId,
        'purchaseToken': purchaseToken,
        'productId': productId,
        'uid': user.uid,
      });

      return result.data as Map<String, dynamic>?;
    } catch (e) {
      rethrow;
    }
  }

  // Cloud Function: iapRestoreEntitlements  
  // Purpose: Rebuild entitlements from store status (Apple/Google query) for signed-in user
  Future<Map<String, dynamic>?> restoreEntitlements() async {
    if (!_initialized) {
      throw Exception('Firebase IAP Service not initialized');
    }

    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated');
    }

    try {
      final callable = _functions.httpsCallable('iapRestoreEntitlements');
      final result = await callable.call({
        'uid': user.uid,
      });

      return result.data as Map<String, dynamic>?;
    } catch (e) {
      rethrow;
    }
  }

  // Get user's current Firebase data
  Future<FirebaseUser?> getCurrentUserData() async {
    final user = _authService.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return FirebaseUser.fromMap(doc.data()!, user.uid);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get user's current entitlement
  Future<UserEntitlement?> getCurrentEntitlement() async {
    final user = _authService.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('entitlements').doc(user.uid).get();
      if (doc.exists) {
        return UserEntitlement.fromMap(doc.data()!, user.uid);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get user's credit ledger (recent entries)
  Future<List<CreditLedgerEntry>> getCreditLedger({int limit = 50}) async {
    final user = _authService.currentUser;
    if (user == null) return [];

    try {
      final query = await _firestore
          .collection('creditLedger')
          .doc(user.uid)
          .collection('entries')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) {
        return CreditLedgerEntry.fromMap(doc.data(), doc.id, user.uid);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Stream user data for real-time updates
  Stream<FirebaseUser?> streamUserData() {
    final user = _authService.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return _firestore.collection('users').doc(user.uid).snapshots().map((doc) {
      if (doc.exists) {
        return FirebaseUser.fromMap(doc.data()!, user.uid);
      }
      return null;
    });
  }

  // Stream entitlement data for real-time updates
  Stream<UserEntitlement?> streamEntitlement() {
    final user = _authService.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return _firestore.collection('entitlements').doc(user.uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserEntitlement.fromMap(doc.data()!, user.uid);
      }
      return null;
    });
  }

  // Create or update user document (for new users)
  Future<void> createUserIfNeeded() async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        final newUser = FirebaseUser(
          uid: user.uid,
          tier: UserTier.free,
          credits: CreditQuotas.free,
          platform: Platform.unknown,
          introUsed: false,
          countryCode: 'US', // Default - will be updated by device locale
          languageCode: 'en', // Default - will be updated by device locale  
          timezone: 'America/Chicago', // Default ops timezone as specified
        );
        
        await docRef.set(newUser.toMap());
      }
    } catch (e) {
      // No debugPrint here as per new_code
    }
  }

  // Manual sync to trigger reconciliation (for debugging)
  Future<void> triggerReconciliation() async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      final callable = _functions.httpsCallable('iapReconcileUser');
      await callable.call({
        'uid': user.uid,
      });
      
    } catch (e) {
      // No debugPrint here as per new_code
    }
  }

  // Get IAP telemetry for debugging
  Future<List<IapTelemetryData>> getTelemetryEvents({int limit = 100}) async {
    final user = _authService.currentUser;
    if (user == null) return [];

    try {
      final query = await _firestore
          .collection('telemetry')
          .where('uid', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return IapTelemetryData(
          event: IapTelemetryEvent.values.firstWhere(
            (e) => e.name == data['event'],
            orElse: () => IapTelemetryEvent.purchaseStart,
          ),
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          parameters: data['parameters'] ?? {},
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Record telemetry event (non-PII)
  Future<void> recordTelemetryEvent(IapTelemetryEvent event, Map<String, dynamic> parameters) async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      final telemetryData = IapTelemetryData(
        event: event,
        timestamp: DateTime.now(),
        parameters: {
          ...parameters,
          'uid': user.uid, // Only for server-side processing, not stored in telemetry
        },
      );

      await _firestore.collection('telemetry').add(telemetryData.toMap());
    } catch (e) {
      // No debugPrint here as per new_code
    }
  }
}