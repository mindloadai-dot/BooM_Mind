import * as functions from 'firebase-functions';
import { admin } from './admin';

// Configuration for purchase verification
const PURCHASE_CONFIG = {
  VERIFICATION_ENABLED: true,
  REPLAY_PROTECTION: true,
  IDEMPOTENT_CREDITS: true,
};

// Interface for logic pack purchase payload
interface LogicPackPurchasePayload {
  userId: string;
  productId: string;
  transactionId: string;
  receipt: string;
  platform: 'ios' | 'android';
  purchaseTime: number;
  originalTransactionId?: string;
}

// Interface for purchase verification result
interface PurchaseVerificationResult {
  verified: boolean;
  tokens?: number;
  message?: string;
  previousResult?: any;
}

// Telemetry logging
function logTelemetry(
  event: 'purchase.logic_verified' | 'purchase.logic_rejected' | 'purchase.duplicate_ignored' | 'ledger.reconcile_mismatch',
  details: Record<string, any>
) {
  const db = admin.firestore();
  return db.collection('telemetry_events').add({
    event,
    details,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
}

// Verify iOS purchase via StoreKit
async function verifyIOSPurchase(
  productId: string, 
  receiptData: string
): Promise<PurchaseVerificationResult> {
  try {
    // TODO: Implement actual StoreKit receipt validation
    // This would typically involve:
    // 1. Send receipt to Apple's verification endpoint
    // 2. Validate receipt details match expected product
    // 3. Check if receipt has been used before

    // Placeholder implementation
    return {
      verified: true,
      tokens: getLogicTokens(productId)
    };
  } catch (error) {
    console.error('iOS purchase verification failed', error);
    return { 
      verified: false, 
      message: 'Verification failed' 
    };
  }
}

// Verify Android purchase via Google Play
async function verifyAndroidPurchase(
  productId: string, 
  purchaseToken: string
): Promise<PurchaseVerificationResult> {
  try {
    // TODO: Implement actual Google Play purchase verification
    // This would typically involve:
    // 1. Use Google Play Billing Library or Google API Client
    // 2. Verify purchase details match expected product
    // 3. Check purchase state and consumption status

    // Placeholder implementation
    return {
      verified: true,
      tokens: getLogicTokens(productId)
    };
  } catch (error) {
    console.error('Android purchase verification failed', error);
    return { 
      verified: false, 
      message: 'Verification failed' 
    };
  }
}

// Map product ID to token amount
function getLogicTokens(productId: string): number {
  const LOGIC_TOKENS: {[key: string]: number} = {
    'mindload_spark_logic': 50,
    'mindload_neuro_logic': 150,
    'mindload_exam_logic': 500,
    'mindload_power_logic': 1000,
    'mindload_ultra_logic': 2500,
  };

  return LOGIC_TOKENS[productId] || 0;
}

// Check if purchase receipt has been used before
async function checkPurchaseReplay(
  userId: string, 
  productId: string, 
  purchaseToken: string
): Promise<PurchaseVerificationResult | null> {
  const db = admin.firestore();
  const purchaseRef = db.collection('purchase_receipts')
    .doc(`${userId}_${productId}`);

  const purchaseDoc = await purchaseRef.get();

  if (purchaseDoc.exists) {
    const existingPurchase = purchaseDoc.data();
    
    // If replay protection is enabled and receipt matches
    if (PURCHASE_CONFIG.REPLAY_PROTECTION && 
        existingPurchase?.purchaseToken === purchaseToken) {
      
      // Log duplicate purchase attempt
      await logTelemetry('purchase.duplicate_ignored', {
        userId,
        productId,
        purchaseToken
      });

      // Return previous result if idempotent credits are enabled
      return PURCHASE_CONFIG.IDEMPOTENT_CREDITS 
        ? { 
            verified: true, 
            tokens: existingPurchase.tokens,
            previousResult: existingPurchase 
          }
        : null;
    }
  }

  return null;
}

// Credit tokens to user's account
async function creditUserTokens(
  userId: string, 
  productId: string, 
  tokens: number,
  purchaseToken: string
) {
  const db = admin.firestore();

  // Atomic transaction to update token account and log purchase
  return db.runTransaction(async (transaction) => {
    const userTokenRef = db.collection('user_token_accounts').doc(userId);
    const purchaseReceiptRef = db.collection('purchase_receipts')
      .doc(`${userId}_${productId}`);

    // Increment monthly tokens
    transaction.update(userTokenRef, {
      monthlyTokens: admin.firestore.FieldValue.increment(tokens)
    });

    // Log purchase receipt
    transaction.set(purchaseReceiptRef, {
      userId,
      productId,
      tokens,
      purchaseToken,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
  });
}

// Main cloud function for logic pack purchase verification
export const verifyLogicPackPurchase = functions.https.onCall(
  async (data: LogicPackPurchasePayload, context) => {
    // Validate authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated', 
        'Authentication required for purchase verification'
      );
    }

    // Validate payload
    if (!data.productId || !data.receipt || !data.platform) {
      throw new functions.https.HttpsError(
        'invalid-argument', 
        'Missing required purchase details'
      );
    }

    // Verify purchase is for the authenticated user
    if (data.userId !== context.auth.uid) {
      throw new functions.https.HttpsError(
        'permission-denied', 
        'Purchase user mismatch'
      );
    }

    // Check for duplicate purchase
    const duplicatePurchase = await checkPurchaseReplay(
      data.userId, 
      data.productId, 
      data.transactionId
    );

    if (duplicatePurchase) {
      return duplicatePurchase;
    }

    // Verify purchase based on platform
    let verificationResult: PurchaseVerificationResult;
    if (data.platform === 'ios') {
      verificationResult = await verifyIOSPurchase(
        data.productId, 
        data.receipt
      );
    } else if (data.platform === 'android') {
      verificationResult = await verifyAndroidPurchase(
        data.productId, 
        data.transactionId
      );
    } else {
      throw new functions.https.HttpsError(
        'invalid-argument', 
        'Unsupported platform'
      );
    }

    // Handle verification result
    if (!verificationResult.verified) {
      // Log rejected purchase
      await logTelemetry('purchase.logic_rejected', {
        userId: data.userId,
        productId: data.productId,
        reason: verificationResult.message
      });

      throw new functions.https.HttpsError(
        'invalid-argument', 
        verificationResult.message || 'Purchase verification failed'
      );
    }

    // Credit tokens
    await creditUserTokens(
      data.userId, 
      data.productId, 
      verificationResult.tokens || 0,
      data.transactionId
    );

    // Log successful purchase
    await logTelemetry('purchase.logic_verified', {
      userId: data.userId,
      productId: data.productId,
      tokens: verificationResult.tokens
    });

    return verificationResult;
  }
);

// Periodic reconciliation job to verify token ledger integrity
export const reconcilePurchaseLedger = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async () => {
    const db = admin.firestore();

    try {
      // Fetch all user token accounts
      const userTokensSnapshot = await db.collection('user_token_accounts').get();

      // Reconcile each user's token balance
      for (const userDoc of userTokensSnapshot.docs) {
        const userId = userDoc.id;
        const userData = userDoc.data();

        // Calculate total tokens from purchase receipts
        const purchaseReceiptsSnapshot = await db.collection('purchase_receipts')
          .where('userId', '==', userId)
          .get();

        const totalPurchasedTokens = purchaseReceiptsSnapshot.docs.reduce(
          (total, doc) => total + (doc.data().tokens || 0), 
          0
        );

        // Compare with user's current token balance
        if (Math.abs(totalPurchasedTokens - (userData.monthlyTokens || 0)) > 0) {
          // Log reconciliation mismatch
          await logTelemetry('ledger.reconcile_mismatch', {
            userId,
            expectedTokens: totalPurchasedTokens,
            actualTokens: userData.monthlyTokens
          });

          // Optional: Trigger alert or manual review process
          console.warn(`Token ledger mismatch for user ${userId}`);
        }
      }
    } catch (error) {
      console.error('Ledger reconciliation failed', error);
    }
  });
