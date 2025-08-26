import 'package:flutter/foundation.dart';
import 'package:mindload/services/entitlement_service.dart';
import 'package:mindload/services/auth_service.dart';

/// TokenGuardService ensures entitlements exist before token-metered flows
/// Implements the guard requirement: "before any token-metered flow, auto-create missing entitlement with 20"
class TokenGuardService {
  static final TokenGuardService _instance = TokenGuardService._internal();
  factory TokenGuardService() => _instance;
  static TokenGuardService get instance => _instance;
  TokenGuardService._internal();

  /// Guard method to ensure entitlements exist before token-metered operations
  /// This should be called before any operation that consumes tokens
  Future<void> ensureEntitlementsBeforeOperation() async {
    try {
      final authService = AuthService.instance;
      if (authService.isAuthenticated && authService.currentUser != null) {
        final userId = authService.currentUser!.uid;
        
        // Auto-create missing entitlements with 20 tokens if they don't exist
        await EntitlementService.instance.ensureEntitlementsExist(userId);
        
        if (kDebugMode) {
          print('✅ Token guard: Entitlements ensured for user $userId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Token guard: Failed to ensure entitlements: $e');
      }
      // Don't rethrow - we want the operation to continue even if guard fails
    }
  }

  /// Guard method specifically for study set generation
  Future<void> guardStudySetGeneration() async {
    await ensureEntitlementsBeforeOperation();
  }

  /// Guard method specifically for document processing
  Future<void> guardDocumentProcessing() async {
    await ensureEntitlementsBeforeOperation();
  }

  /// Guard method specifically for AI operations
  Future<void> guardAIOperation() async {
    await ensureEntitlementsBeforeOperation();
  }

  /// Guard method specifically for quiz generation
  Future<void> guardQuizGeneration() async {
    await ensureEntitlementsBeforeOperation();
  }

  /// Guard method specifically for flashcard generation
  Future<void> guardFlashcardGeneration() async {
    await ensureEntitlementsBeforeOperation();
  }

  /// Guard method specifically for YouTube ingest operations
  Future<void> guardYouTubeIngest() async {
    await ensureEntitlementsBeforeOperation();
  }

  /// Guard method specifically for Ultra Mode operations
  Future<void> guardUltraModeOperation() async {
    await ensureEntitlementsBeforeOperation();
  }

  /// Check if user has sufficient tokens for an operation
  Future<bool> hasSufficientTokens(int requiredTokens) async {
    try {
      final authService = AuthService.instance;
      if (authService.isAuthenticated && authService.currentUser != null) {
        final userId = authService.currentUser!.uid;
        
        // Ensure entitlements exist first
        await EntitlementService.instance.ensureEntitlementsExist(userId);
        
        // Check if user can afford the operation
        return await EntitlementService.instance.canAffordTokens(requiredTokens);
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Token guard: Failed to check token sufficiency: $e');
      }
      return false;
    }
  }

  /// Get current token status for UI display
  Future<Map<String, dynamic>?> getCurrentTokenStatus() async {
    try {
      final authService = AuthService.instance;
      if (authService.isAuthenticated && authService.currentUser != null) {
        final userId = authService.currentUser!.uid;
        
        // Ensure entitlements exist first
        await EntitlementService.instance.ensureEntitlementsExist(userId);
        
        // Get current entitlement info
        return EntitlementService.instance.getEntitlementInfo();
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Token guard: Failed to get token status: $e');
      }
      return null;
    }
  }

  /// Consume tokens for an operation (with automatic guard)
  Future<bool> consumeTokensForOperation(int tokensToConsume, String operationType) async {
    try {
      final authService = AuthService.instance;
      if (authService.isAuthenticated && authService.currentUser != null) {
        final userId = authService.currentUser!.uid;
        
        // Ensure entitlements exist first
        await EntitlementService.instance.ensureEntitlementsExist(userId);
        
        // Consume the tokens
        return await EntitlementService.instance.consumeTokens(tokensToConsume);
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Token guard: Failed to consume tokens: $e');
      }
      return false;
    }
  }
}
