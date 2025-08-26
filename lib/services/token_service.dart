import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:mindload/models/pricing_models.dart';
import 'package:mindload/services/auth_service.dart';
import 'package:mindload/services/abuse_prevention_service.dart';

class TokenService {
  static final TokenService _instance = TokenService._internal();
  static TokenService get instance => _instance;

  TokenService._internal();

  // Anti-abuse tracking
  final AbusePrevention _abusePrevention = AbusePrevention.instance;

  // Token consumption tracking
  Future<bool> canPerformAction({
    required String actionType,
    required int requiredTokens,
    String? setId,
    Map<String, dynamic>? deviceInfo,
  }) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return false;

    // Check with abuse prevention service
    if (deviceInfo != null) {
      final canProceed = await _abusePrevention.canPerformAction(
        userId: user.uid, 
        actionType: actionType,
        deviceInfo: deviceInfo,
      );
      if (!canProceed) {
        _logSecurityEvent(
          userId: user.uid, 
          actionType: actionType, 
          reason: 'Abuse prevention blocked action',
        );
        return false;
      }
    }

    // Fetch user's token account
    final tokenAccount = await fetchUserTokenAccount(user.uid);
    
    // Check if user can afford the action
    return tokenAccount.canAffordAction(requiredTokens);
  }

  Future<bool> performAction({
    required String actionType,
    required int requiredTokens,
    String? setId,
    String? requestId,
    Map<String, dynamic>? deviceInfo,
  }) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return false;

    // Validate request
    if (!await canPerformAction(
      actionType: actionType, 
      requiredTokens: requiredTokens,
      setId: setId,
      deviceInfo: deviceInfo,
    )) {
      return false;
    }

    // Fetch and update token account
    final tokenAccount = await fetchUserTokenAccount(user.uid);
    tokenAccount.deductTokens(requiredTokens);
    
    // Save updated account
    await _saveUserTokenAccount(user.uid, tokenAccount);

    // Log action and emit telemetry
    _logTokenAction(
      userId: user.uid, 
      actionType: actionType, 
      tokensCost: requiredTokens,
      requestId: requestId,
    );

    return true;
  }

  void _logTokenAction({
    required String userId, 
    required String actionType, 
    required int tokensCost,
    String? requestId,
  }) {
    // Log to Firestore
    FirebaseFirestore.instance.collection('token_actions').add({
      'userId': userId,
      'actionType': actionType,
      'tokensCost': tokensCost,
      'requestId': requestId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Emit telemetry event
    _emitTelemetryEvent(
      event: 'token_action',
      parameters: {
        'userId': userId,
        'actionType': actionType,
        'tokensCost': tokensCost,
        'requestId': requestId,
      },
    );
  }

  void _logSecurityEvent({
    required String userId, 
    required String actionType, 
    required String reason,
  }) {
    // Log to Firestore
    FirebaseFirestore.instance.collection('security_logs').add({
      'userId': userId,
      'actionType': actionType,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Emit telemetry event
    _emitTelemetryEvent(
      event: 'security_block',
      parameters: {
        'userId': userId,
        'actionType': actionType,
        'reason': reason,
      },
    );
  }

  void _emitTelemetryEvent({
    required String event, 
    required Map<String, dynamic> parameters,
  }) {
    FirebaseFirestore.instance.collection('telemetry_events').add({
      'event': event,
      'parameters': parameters,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<UserTokenAccount> fetchUserTokenAccount(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection('user_token_accounts')
        .doc(userId)
        .get();

    if (!doc.exists) {
      // Create new account with welcome bonus
      final newAccount = UserTokenAccount();
      await _saveUserTokenAccount(userId, newAccount);
      return newAccount;
    }

    final data = doc.data() ?? {};
    return UserTokenAccount(
      monthlyTokens: data['monthlyTokens'] ?? 0,
      welcomeBonus: data['welcomeBonus'] ?? 20,
      freeActions: data['freeActions'] ?? 20,
      lastResetDate: (data['lastResetDate'] as Timestamp?)?.toDate(),
    );
  }

  Future<void> _saveUserTokenAccount(String userId, UserTokenAccount account) async {
    await FirebaseFirestore.instance
        .collection('user_token_accounts')
        .doc(userId)
        .set({
      'monthlyTokens': account.monthlyTokens,
      'welcomeBonus': account.welcomeBonus,
      'freeActions': account.freeActions,
      'lastResetDate': account.lastResetDate,
    }, SetOptions(merge: true));
  }

  // Monthly reset method to be called periodically
  Future<void> resetMonthlyTokens() async {
    final users = await FirebaseFirestore.instance
        .collection('users')
        .get();

    for (var userDoc in users.docs) {
      final userId = userDoc.id;
      final tokenAccount = await fetchUserTokenAccount(userId);
      
      // Determine user's current tier (you might want to fetch this from user's subscription)
      final tier = TokenTier.tiers.firstWhere(
        (t) => t.name == (userDoc.data()['currentTier'] ?? 'Dendrite'),
        orElse: () => TokenTier.tiers.first,
      );

      tokenAccount.resetMonthlyTokens(tier);
      await _saveUserTokenAccount(userId, tokenAccount);
    }
  }
}
