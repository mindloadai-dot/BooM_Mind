import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mindload/models/pricing_models.dart';
import 'package:mindload/models/iap_firebase_models.dart';
import 'package:mindload/services/telemetry_service.dart';
import 'package:mindload/services/auth_service.dart';
import 'package:mindload/services/firebase_iap_service.dart';
import 'package:mindload/services/firebase_remote_config_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Enhanced IAP-only payment service with Firebase backend verification
class InAppPurchaseService extends ChangeNotifier {
  static final InAppPurchaseService _instance =
      InAppPurchaseService._internal();
  factory InAppPurchaseService() => _instance;
  static InAppPurchaseService get instance => _instance;
  InAppPurchaseService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final TelemetryService _telemetry = TelemetryService.instance;
  final AuthService _authService = AuthService.instance;
  final FirebaseIapService _firebaseIap = FirebaseIapService.instance;
  final FirebaseRemoteConfigService _remoteConfig =
      FirebaseRemoteConfigService.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  final List<PurchaseDetails> _purchases = [];
  bool _purchasePending = false;
  FirebaseUser? _currentUser;
  UserEntitlement? _currentEntitlement;

  bool get isAvailable => _isAvailable;
  List<ProductDetails> get products => _products;
  bool get purchasePending => _purchasePending;
  FirebaseUser? get currentUser => _currentUser;
  UserEntitlement? get currentEntitlement => _currentEntitlement;

  // Get product details for localized pricing display
  ProductDetails? getProductDetails(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      debugPrint('Product details not found for $productId: $e');
      return null;
    }
  }

  // Get all products mapped by ID for easy access
  Map<String, ProductDetails> get productDetailsMap {
    final map = <String, ProductDetails>{};
    for (final product in _products) {
      map[product.id] = product;
    }
    return map;
  }

  // Product IDs for the products
  static const Set<String> _productIds = {
    // Legacy products (being replaced by new logic packs)
    ProductIds.logicPack,
    ProductIds.tokens250,
    ProductIds.tokens600,

    // New MindLoad Logic Pack product IDs
    ProductIds.sparkPack,
    ProductIds.neuroBurst,
    ProductIds.cortexLogic,

    ProductIds.quantumLogic,
  };

  static final List<String> _subscriptionProductIds = [
    ProductIds.axonMonthly,
    ProductIds.neuronMonthly,
    ProductIds.cortexMonthly,
    ProductIds.singularityMonthly,
    // ProductIds.proMonthly, // Removed
  ];

  Future<void> initialize() async {
    try {
      // Initialize Firebase services first
      await _firebaseIap.initialize();
      await _remoteConfig.initialize();

      _isAvailable = await _inAppPurchase.isAvailable();
      if (_isAvailable) {
        await _loadProducts();
        _listenToPurchaseUpdates();
        await _loadUserData();
        // Auto-restore on initialize
        await restoreEntitlements();
      }
      debugPrint('IAP-only payment service initialized: $_isAvailable');
    } catch (e) {
      debugPrint('Error initializing IAP service: $e');
      _isAvailable = false;
    }
  }

  Future<void> _loadProducts() async {
    try {
      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(_productIds);

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Products not found: ${response.notFoundIDs}');
      }

      // Filter products based on Remote Config
      _products = response.productDetails.where((product) {
        if (product.id == ProductIds.logicPack) {
          return _remoteConfig.logicPackEnabled;
        }
        return true;
      }).toList();

      debugPrint('Loaded ${_products.length} products');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading products: $e');
    }
  }

  void _listenToPurchaseUpdates() {
    _inAppPurchase.purchaseStream.listen(
      (List<PurchaseDetails> purchaseDetailsList) {
        _handlePurchaseUpdates(purchaseDetailsList);
      },
      onDone: () {},
      onError: (error) {
        debugPrint('Purchase stream error: $error');
      },
    );
  }

  Future<void> _handlePurchaseUpdates(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _purchasePending = true;
        await _recordTelemetry(IapTelemetryEvent.purchaseStart, {
          'productId': purchaseDetails.productID,
        });
        notifyListeners();
      } else {
        _purchasePending = false;

        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint('Purchase error: ${purchaseDetails.error}');
          await _recordTelemetry(IapTelemetryEvent.purchaseFail, {
            'productId': purchaseDetails.productID,
            'error': purchaseDetails.error?.message ?? 'unknown',
          });
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          // Verify purchase with Firebase backend
          await _verifyPurchaseWithFirebase(purchaseDetails);
        }

        // Complete the purchase
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }

        notifyListeners();
      }
    }
  }

  Future<void> _verifyPurchaseWithFirebase(
      PurchaseDetails purchaseDetails) async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        debugPrint('No authenticated user for purchase verification');
        return;
      }

      debugPrint(
          'Verifying purchase with Firebase: ${purchaseDetails.productID}');

      // Determine platform
      final platform =
          defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

      // Get transaction details
      String transactionId;
      String? purchaseToken;

      if (platform == 'ios') {
        transactionId = purchaseDetails.purchaseID ?? '';
      } else {
        transactionId = purchaseDetails.purchaseID ?? '';
        purchaseToken =
            purchaseDetails.purchaseID; // Android uses purchase token
      }

      // Verify with Firebase Cloud Functions
      final result = await _firebaseIap.verifyPurchase(
        platform: platform,
        transactionId: transactionId,
        purchaseToken: purchaseToken,
        productId: purchaseDetails.productID,
      );

      if (result != null && result['status'] == 'processed') {
        await _recordTelemetry(IapTelemetryEvent.purchaseSuccess, {
          'productId': purchaseDetails.productID,
          'platform': platform,
        });

        // Refresh user data
        await _loadUserData();

        debugPrint(
            'Purchase verified successfully: ${purchaseDetails.productID}');
      } else {
        debugPrint('Purchase verification failed: $result');
        await _recordTelemetry(IapTelemetryEvent.purchaseFail, {
          'productId': purchaseDetails.productID,
          'reason': 'verification_failed',
        });
      }
    } catch (e) {
      debugPrint('Error verifying purchase with Firebase: $e');
      await _recordTelemetry(IapTelemetryEvent.purchaseFail, {
        'productId': purchaseDetails.productID,
        'error': e.toString(),
      });
    }
  }

  // Load current user data from Firebase
  Future<void> _loadUserData() async {
    try {
      _currentUser = await _firebaseIap.getCurrentUserData();
      _currentEntitlement = await _firebaseIap.getCurrentEntitlement();

      // Create user document if needed
      if (_currentUser == null) {
        await _firebaseIap.createUserIfNeeded();
        _currentUser = await _firebaseIap.getCurrentUserData();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // Get filtered subscription plans based on Remote Config
  List<SubscriptionPlan> getAvailablePlans() {
    return SubscriptionPlan.availablePlans.where((plan) {
      return true;
    }).toList();
  }

  // Purchase subscription with intro offer handling
  Future<bool> purchaseSubscription(SubscriptionPlan plan) async {
    if (!_isAvailable) {
      throw PurchaseException('In-app purchases are not available',
          code: 'unavailable');
    }

    // Check if IAP-only mode is enabled
    if (!_remoteConfig.iapOnlyMode) {
      throw PurchaseException('IAP-only mode is disabled', code: 'disabled');
    }

    try {
      final product = _products.firstWhere(
        (p) => p.id == plan.productId,
        orElse: () =>
            throw PurchaseException('Product not found: ${plan.productId}'),
      );

      // Record paywall telemetry
      await _recordTelemetry(IapTelemetryEvent.paywallView, {
        'productId': plan.productId,
        'planType': plan.type,
        'hasIntro': plan.hasIntroOffer,
      });

      final purchaseParam = PurchaseParam(productDetails: product);

      final purchaseResult =
          await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

      return purchaseResult;
    } catch (e) {
      debugPrint('Purchase failed: $e');
      await _recordTelemetry(IapTelemetryEvent.purchaseFail, {
        'productId': plan.productId,
        'error': e.toString(),
      });
      throw PurchaseException(e.toString());
    }
  }

  // Purchase credit pack (consumable)
  Future<bool> purchaseLogicPack() async {
    if (!_isAvailable) {
      throw PurchaseException('In-app purchases are not available',
          code: 'unavailable');
    }

    // Check if logic pack is enabled
    if (!_remoteConfig.logicPackEnabled) {
      throw PurchaseException('Logic pack is disabled', code: 'disabled');
    }

    try {
      final product = _products.firstWhere(
        (p) => p.id == ProductIds.logicPack,
        orElse: () => throw PurchaseException('Logic pack not found'),
      );

      await _recordTelemetry(IapTelemetryEvent.paywallView, {
        'productId': ProductIds.logicPack,
        'credits': CreditQuotas.free,
      });

      final purchaseParam = PurchaseParam(productDetails: product);
      final result =
          await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      return result;
    } catch (e) {
      debugPrint('Logic pack purchase failed: $e');
      await _recordTelemetry(IapTelemetryEvent.purchaseFail, {
        'productId': ProductIds.logicPack,
        'error': e.toString(),
      });
      throw PurchaseException(e.toString());
    }
  }

  // Purchase MindLoad Logic Packs (consumable)
  Future<bool> purchaseSparkLogic() async {
    return _purchaseLogicPack(ProductIds.sparkPack, 'Spark Pack');
  }

  Future<bool> purchaseNeuroLogic() async {
    return _purchaseLogicPack(ProductIds.neuroBurst, 'Neuro Pack');
  }

  Future<bool> purchaseCortexLogic() async {
    return _purchaseLogicPack(ProductIds.cortexLogic, 'Cortex Pack');
  }

  Future<bool> purchaseQuantumLogic() async {
    return _purchaseLogicPack(ProductIds.quantumLogic, 'Quantum Pack');
  }

  // Generic logic pack purchase method
  Future<bool> _purchaseLogicPack(String productId, String productName) async {
    if (!_isAvailable) {
      throw PurchaseException('In-app purchases are not available',
          code: 'unavailable');
    }

    try {
      final product = _products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw PurchaseException('$productName not found'),
      );

      await _recordTelemetry(IapTelemetryEvent.paywallView, {
        'productId': productId,
        'productName': productName,
      });

      final purchaseParam = PurchaseParam(productDetails: product);
      final result =
          await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      return result;
    } catch (e) {
      debugPrint('$productName purchase failed: $e');
      await _recordTelemetry(IapTelemetryEvent.purchaseFail, {
        'productId': productId,
        'productName': productName,
        'error': e.toString(),
      });
      throw PurchaseException(e.toString());
    }
  }

  // Purchase 250 tokens pack
  Future<bool> purchaseTokens250() async {
    if (!_isAvailable) {
      throw PurchaseException('In-app purchases are not available',
          code: 'unavailable');
    }

    try {
      final product = _products.firstWhere(
        (p) => p.id == ProductIds.tokens250,
        orElse: () => throw PurchaseException('250 tokens pack not found'),
      );

      await _recordTelemetry(IapTelemetryEvent.paywallView, {
        'productId': ProductIds.tokens250,
        'credits': 250,
      });

      final purchaseParam = PurchaseParam(productDetails: product);
      final result =
          await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      return result;
    } catch (e) {
      debugPrint('250 tokens purchase failed: $e');
      await _recordTelemetry(IapTelemetryEvent.purchaseFail, {
        'productId': ProductIds.tokens250,
        'error': e.toString(),
      });
      throw PurchaseException(e.toString());
    }
  }

  // Purchase 600 tokens pack
  Future<bool> purchaseTokens600() async {
    if (!_isAvailable) {
      throw PurchaseException('In-app purchases are not available',
          code: 'unavailable');
    }

    try {
      final product = _products.firstWhere(
        (p) => p.id == ProductIds.tokens600,
        orElse: () => throw PurchaseException('600 tokens pack not found'),
      );

      await _recordTelemetry(IapTelemetryEvent.paywallView, {
        'productId': ProductIds.tokens600,
        'credits': 600,
      });

      final purchaseParam = PurchaseParam(productDetails: product);
      final result =
          await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      return result;
    } catch (e) {
      debugPrint('600 tokens purchase failed: $e');
      await _recordTelemetry(IapTelemetryEvent.purchaseFail, {
        'productId': ProductIds.tokens600,
        'error': e.toString(),
      });
      throw PurchaseException(e.toString());
    }
  }

  // Restore entitlements from Firebase (server-side restore)
  Future<bool> restoreEntitlements() async {
    if (!_isAvailable) return false;

    try {
      // Use Firebase IAP service for server-side restore
      final result = await _firebaseIap.restoreEntitlements();

      if (result != null) {
        await _recordTelemetry(IapTelemetryEvent.restoreSuccess, {
          'restoredCount': result['restoredCount'] ?? 0,
        });

        // Refresh user data after restore
        await _loadUserData();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Restore entitlements failed: $e');
      return false;
    }
  }

  // Legacy restore for local purchases (backup)
  Future<bool> restorePurchases() async {
    if (!_isAvailable) return false;

    try {
      await _inAppPurchase.restorePurchases();
      return true;
    } catch (e) {
      debugPrint('Restore purchases failed: $e');
      return false;
    }
  }

  // Platform-specific subscription management URLs (only if enabled)
  String getSubscriptionManagementUrl() {
    if (!_remoteConfig.manageLinksEnabled) return '';

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'itms-apps://apps.apple.com/account/subscriptions';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'https://play.google.com/store/account/subscriptions';
    }
    return '';
  }

  String getSubscriptionManagementLabel() {
    if (!_remoteConfig.manageLinksEnabled) return '';

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'Manage in App Store';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'Manage in Google Play';
    }
    return 'Manage Subscription';
  }

  // Check if manage links are enabled
  bool get canManageSubscriptions => _remoteConfig.manageLinksEnabled;

  // Get product by ID
  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }

  // Helper: Record telemetry event
  Future<void> _recordTelemetry(
      IapTelemetryEvent event, Map<String, dynamic> parameters) async {
    try {
      await _firebaseIap.recordTelemetryEvent(event, parameters);
    } catch (e) {
      debugPrint('Error recording telemetry: $e');
    }
  }

  // Get user's remaining credits
  int get remainingCredits => _currentUser?.credits ?? 0;

  // Check if user has Pro subscription
  bool get isProUser {
    return false; // Pro Monthly removed
  }

  // Get subscription renewal date
  DateTime? get renewalDate => _currentUser?.renewalDate;

  // Stream user data changes
  Stream<FirebaseUser?> get userDataStream => _firebaseIap.streamUserData();

  // Stream entitlement changes
  Stream<UserEntitlement?> get entitlementStream =>
      _firebaseIap.streamEntitlement();

  bool _hasIntroOffer(SubscriptionPlan plan) {
    if (!plan.hasIntroOffer) return false;

    // Pro Monthly intro removed
    return false;
  }
}

class PurchaseException implements Exception {
  final String message;
  final String code;

  const PurchaseException(this.message, {this.code = 'unknown'});

  @override
  String toString() => 'PurchaseException: $message';
}
