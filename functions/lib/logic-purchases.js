"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.reconcilePurchaseLedger = exports.verifyLogicPackPurchase = void 0;
const functions = __importStar(require("firebase-functions"));
const admin_1 = require("./admin");
// Configuration for purchase verification
const PURCHASE_CONFIG = {
    VERIFICATION_ENABLED: true,
    REPLAY_PROTECTION: true,
    IDEMPOTENT_CREDITS: true,
};
// Telemetry logging
function logTelemetry(event, details) {
    const db = admin_1.admin.firestore();
    return db.collection('telemetry_events').add({
        event,
        details,
        timestamp: admin_1.admin.firestore.FieldValue.serverTimestamp(),
    });
}
// Verify iOS purchase via StoreKit
async function verifyIOSPurchase(productId, receiptData) {
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
    }
    catch (error) {
        console.error('iOS purchase verification failed', error);
        return {
            verified: false,
            message: 'Verification failed'
        };
    }
}
// Verify Android purchase via Google Play
async function verifyAndroidPurchase(productId, purchaseToken) {
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
    }
    catch (error) {
        console.error('Android purchase verification failed', error);
        return {
            verified: false,
            message: 'Verification failed'
        };
    }
}
// Map product ID to token amount
function getLogicTokens(productId) {
    const LOGIC_TOKENS = {
        'mindload_spark_logic': 50,
        'mindload_neuro_logic': 150,
        'mindload_exam_logic': 500,
        'mindload_power_logic': 1000,
        'mindload_ultra_logic': 2500,
    };
    return LOGIC_TOKENS[productId] || 0;
}
// Check if purchase receipt has been used before
async function checkPurchaseReplay(userId, productId, purchaseToken) {
    const db = admin_1.admin.firestore();
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
async function creditUserTokens(userId, productId, tokens, purchaseToken) {
    const db = admin_1.admin.firestore();
    // Atomic transaction to update token account and log purchase
    return db.runTransaction(async (transaction) => {
        const userTokenRef = db.collection('user_token_accounts').doc(userId);
        const purchaseReceiptRef = db.collection('purchase_receipts')
            .doc(`${userId}_${productId}`);
        // Increment monthly tokens
        transaction.update(userTokenRef, {
            monthlyTokens: admin_1.admin.firestore.FieldValue.increment(tokens)
        });
        // Log purchase receipt
        transaction.set(purchaseReceiptRef, {
            userId,
            productId,
            tokens,
            purchaseToken,
            timestamp: admin_1.admin.firestore.FieldValue.serverTimestamp()
        });
    });
}
// Main cloud function for logic pack purchase verification
exports.verifyLogicPackPurchase = functions.https.onCall(async (data, context) => {
    // Validate authentication
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Authentication required for purchase verification');
    }
    // Validate payload
    if (!data.productId || !data.receipt || !data.platform) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required purchase details');
    }
    // Verify purchase is for the authenticated user
    if (data.userId !== context.auth.uid) {
        throw new functions.https.HttpsError('permission-denied', 'Purchase user mismatch');
    }
    // Check for duplicate purchase
    const duplicatePurchase = await checkPurchaseReplay(data.userId, data.productId, data.transactionId);
    if (duplicatePurchase) {
        return duplicatePurchase;
    }
    // Verify purchase based on platform
    let verificationResult;
    if (data.platform === 'ios') {
        verificationResult = await verifyIOSPurchase(data.productId, data.receipt);
    }
    else if (data.platform === 'android') {
        verificationResult = await verifyAndroidPurchase(data.productId, data.transactionId);
    }
    else {
        throw new functions.https.HttpsError('invalid-argument', 'Unsupported platform');
    }
    // Handle verification result
    if (!verificationResult.verified) {
        // Log rejected purchase
        await logTelemetry('purchase.logic_rejected', {
            userId: data.userId,
            productId: data.productId,
            reason: verificationResult.message
        });
        throw new functions.https.HttpsError('invalid-argument', verificationResult.message || 'Purchase verification failed');
    }
    // Credit tokens
    await creditUserTokens(data.userId, data.productId, verificationResult.tokens || 0, data.transactionId);
    // Log successful purchase
    await logTelemetry('purchase.logic_verified', {
        userId: data.userId,
        productId: data.productId,
        tokens: verificationResult.tokens
    });
    return verificationResult;
});
// Periodic reconciliation job to verify token ledger integrity
exports.reconcilePurchaseLedger = functions.pubsub
    .schedule('every 24 hours')
    .onRun(async () => {
    const db = admin_1.admin.firestore();
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
            const totalPurchasedTokens = purchaseReceiptsSnapshot.docs.reduce((total, doc) => total + (doc.data().tokens || 0), 0);
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
    }
    catch (error) {
        console.error('Ledger reconciliation failed', error);
    }
});
//# sourceMappingURL=logic-purchases.js.map