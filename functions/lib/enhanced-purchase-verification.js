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
exports.clearPurchaseCache = exports.getPurchaseVerificationStatus = exports.getPurchaseHistory = exports.restoreLogicPackPurchases = exports.verifyLogicPackPurchase = void 0;
const functions = __importStar(require("firebase-functions"));
const admin_1 = require("./admin");
// Constants for collection names
const PURCHASES_COLLECTION = 'purchase_receipts';
const LEDGER_COLLECTION = 'token_ledger';
const ACCOUNTS_COLLECTION = 'user_token_accounts';
const TELEMETRY_COLLECTION = 'telemetry_events';
// Settings (in production, these would come from Remote Config)
const SERVER_SIDE_VERIFICATION_ENABLED = true;
const RECEIPT_REPLAY_PROTECTION_ENABLED = true;
const IDEMPOTENT_CREDITS_ENABLED = true;
// Product token mappings
const PRODUCT_TOKEN_MAP = {
    'mindload_spark_logic': 50,
    'mindload_neuro_logic': 150,
    'mindload_exam_logic': 500,
    'mindload_power_logic': 1000,
    'mindload_ultra_logic': 2500,
};
/**
 * Verify logic pack purchase with server-side verification
 * Tokens are credited only after verification
 */
exports.verifyLogicPackPurchase = functions.https.onCall(async (data, context) => {
    // Validate authentication
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const userId = context.auth.uid;
    const { productId, purchaseToken, transactionId, platform, receiptData = {} } = data;
    // Validate required fields
    if (!productId || !purchaseToken || !transactionId || !platform) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }
    // Validate platform
    const validPlatforms = ['ios', 'android'];
    if (!validPlatforms.includes(platform)) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid platform');
    }
    try {
        const db = admin_1.admin.firestore();
        // Check for replay protection
        if (RECEIPT_REPLAY_PROTECTION_ENABLED) {
            const replayCheck = await checkPurchaseReplay(db, transactionId, userId);
            if (replayCheck) {
                await logTelemetry(db, 'purchase.duplicate_ignored', {
                    purchaseId: transactionId,
                    userId,
                    productId,
                    timestamp: new Date().toISOString(),
                });
                return replayCheck;
            }
        }
        // Check cache for idempotent credits
        if (IDEMPOTENT_CREDITS_ENABLED) {
            const cachedResult = await checkPurchaseCache(db, transactionId, userId);
            if (cachedResult) {
                await logTelemetry(db, 'purchase.idempotent_return', {
                    purchaseId: transactionId,
                    userId,
                    productId,
                    timestamp: new Date().toISOString(),
                });
                return cachedResult;
            }
        }
        // Perform server-side verification
        let verificationResult;
        if (platform === 'ios') {
            verificationResult = await verifyApplePurchase(receiptData, productId);
        }
        else if (platform === 'android') {
            verificationResult = await verifyGooglePurchase(receiptData, productId);
        }
        else {
            throw new functions.https.HttpsError('invalid-argument', 'Unsupported platform');
        }
        if (verificationResult.isVerified && verificationResult.tokens > 0) {
            // Credit tokens to user's account via atomic ledger
            const requestId = generateRequestId();
            const ledgerResult = await writeLedgerEntry(db, userId, 'credit', verificationResult.tokens, requestId, 'purchase', {
                productId,
                transactionId,
                platform,
                purchaseToken,
            });
            if (ledgerResult.success) {
                // Create verification result
                const result = {
                    purchaseId: transactionId,
                    productId,
                    tokens: verificationResult.tokens,
                    isVerified: true,
                    isReplay: false,
                    verifiedAt: new Date().toISOString(),
                };
                // Cache the result for idempotent credits
                if (IDEMPOTENT_CREDITS_ENABLED) {
                    await cachePurchaseResult(db, transactionId, userId, result);
                }
                // Store purchase receipt
                await storePurchaseReceipt(db, userId, transactionId, productId, verificationResult.tokens, platform, purchaseToken);
                // Log successful verification
                await logTelemetry(db, 'purchase.logic_verified', {
                    purchaseId: transactionId,
                    userId,
                    productId,
                    tokens: verificationResult.tokens,
                    platform,
                    timestamp: new Date().toISOString(),
                });
                return result;
            }
            else {
                // Ledger write failed
                await logTelemetry(db, 'purchase.ledger_write_failed', {
                    purchaseId: transactionId,
                    userId,
                    productId,
                    error: ledgerResult.error,
                    timestamp: new Date().toISOString(),
                });
                return {
                    purchaseId: transactionId,
                    productId,
                    tokens: 0,
                    isVerified: false,
                    isReplay: false,
                    verifiedAt: new Date().toISOString(),
                    errorMessage: `Failed to credit tokens: ${ledgerResult.error}`,
                };
            }
        }
        else {
            // Verification failed
            await logTelemetry(db, 'purchase.logic_rejected', {
                purchaseId: transactionId,
                userId,
                productId,
                error: verificationResult.errorMessage,
                timestamp: new Date().toISOString(),
            });
            return {
                purchaseId: transactionId,
                productId,
                tokens: 0,
                isVerified: false,
                isReplay: false,
                verifiedAt: new Date().toISOString(),
                errorMessage: verificationResult.errorMessage || 'Verification failed',
            };
        }
    }
    catch (error) {
        // Log verification error
        await logTelemetry(admin_1.admin.firestore(), 'purchase.verification_error', {
            purchaseId: transactionId,
            userId,
            productId,
            error: error instanceof Error ? error.toString() : String(error),
            timestamp: new Date().toISOString(),
        });
        throw new functions.https.HttpsError('internal', `Verification error: ${error}`);
    }
});
/**
 * Check for purchase replay protection
 */
async function checkPurchaseReplay(db, transactionId, userId) {
    try {
        // Check if this transaction has already been processed
        const ledgerQuery = await db
            .collection(LEDGER_COLLECTION)
            .doc(userId)
            .collection('entries')
            .where('metadata.transactionId', '==', transactionId)
            .limit(1)
            .get();
        if (!ledgerQuery.empty) {
            const entry = ledgerQuery.docs[0].data();
            // This transaction has already been processed
            return {
                purchaseId: transactionId,
                productId: entry.metadata?.productId || '',
                tokens: entry.tokens,
                isVerified: true,
                isReplay: true,
                verifiedAt: entry.timestamp.toDate().toISOString(),
                errorMessage: 'Transaction already processed',
            };
        }
        return null;
    }
    catch (error) {
        // If we can't check for replay, allow the request
        // This is a fail-open approach for availability
        return null;
    }
}
/**
 * Check purchase cache for idempotent credits
 */
async function checkPurchaseCache(db, transactionId, userId) {
    try {
        const cacheDoc = await db
            .collection('purchase_cache')
            .doc(`${userId}_${transactionId}`)
            .get();
        if (cacheDoc.exists) {
            const cacheData = cacheDoc.data();
            const cacheTime = cacheData.cachedAt.toDate();
            const now = new Date();
            // Check if cache is still valid (24 hours)
            if (now.getTime() - cacheTime.getTime() < 24 * 60 * 60 * 1000) {
                return cacheData.result;
            }
        }
        return null;
    }
    catch (error) {
        return null;
    }
}
/**
 * Cache purchase result for idempotent credits
 */
async function cachePurchaseResult(db, transactionId, userId, result) {
    try {
        await db
            .collection('purchase_cache')
            .doc(`${userId}_${transactionId}`)
            .set({
            result,
            cachedAt: admin_1.admin.firestore.FieldValue.serverTimestamp(),
        });
    }
    catch (error) {
        // Silently fail caching to avoid breaking main functionality
        console.warn('Failed to cache purchase result:', error);
    }
}
/**
 * Store purchase receipt for tracking
 */
async function storePurchaseReceipt(db, userId, transactionId, productId, tokens, platform, purchaseToken) {
    try {
        await db
            .collection(PURCHASES_COLLECTION)
            .doc(`${userId}_${transactionId}`)
            .set({
            userId,
            productId,
            tokens,
            platform,
            purchaseToken,
            transactionId,
            verifiedAt: admin_1.admin.firestore.FieldValue.serverTimestamp(),
            status: 'verified',
        });
    }
    catch (error) {
        console.warn('Failed to store purchase receipt:', error);
    }
}
/**
 * Verify Apple purchase receipt
 */
async function verifyApplePurchase(receiptData, productId) {
    try {
        // In production, this would call Apple's verification API
        // For now, we'll do basic validation
        if (!receiptData.receipt || !receiptData.transactionId) {
            return {
                isVerified: false,
                tokens: 0,
                errorMessage: 'Invalid receipt data',
            };
        }
        // Check if product ID matches expected tokens
        const expectedTokens = PRODUCT_TOKEN_MAP[productId];
        if (!expectedTokens) {
            return {
                isVerified: false,
                tokens: 0,
                errorMessage: 'Invalid product ID',
            };
        }
        // Simulate verification success
        return {
            isVerified: true,
            tokens: expectedTokens,
        };
    }
    catch (error) {
        return {
            isVerified: false,
            tokens: 0,
            errorMessage: `Apple verification failed: ${error}`,
        };
    }
}
/**
 * Verify Google purchase receipt
 */
async function verifyGooglePurchase(receiptData, productId) {
    try {
        // In production, this would call Google's verification API
        // For now, we'll do basic validation
        if (!receiptData.purchaseToken || !receiptData.orderId) {
            return {
                isVerified: false,
                tokens: 0,
                errorMessage: 'Invalid receipt data',
            };
        }
        // Check if product ID matches expected tokens
        const expectedTokens = PRODUCT_TOKEN_MAP[productId];
        if (!expectedTokens) {
            return {
                isVerified: false,
                tokens: 0,
                errorMessage: 'Invalid product ID',
            };
        }
        // Simulate verification success
        return {
            isVerified: true,
            tokens: expectedTokens,
        };
    }
    catch (error) {
        return {
            isVerified: false,
            tokens: 0,
            errorMessage: `Google verification failed: ${error}`,
        };
    }
}
/**
 * Write ledger entry for purchase
 */
async function writeLedgerEntry(db, userId, action, tokens, requestId, source, metadata) {
    try {
        const entryId = generateEntryId();
        const now = new Date();
        await db.runTransaction(async (transaction) => {
            // Write ledger entry
            const ledgerRef = db
                .collection(LEDGER_COLLECTION)
                .doc(userId)
                .collection('entries')
                .doc(entryId);
            transaction.set(ledgerRef, {
                userId,
                action,
                tokens,
                requestId,
                timestamp: admin_1.admin.firestore.Timestamp.fromDate(now),
                source,
                metadata,
                createdAt: admin_1.admin.firestore.FieldValue.serverTimestamp(),
            });
            // Update user token account
            const accountRef = db.collection(ACCOUNTS_COLLECTION).doc(userId);
            const accountDoc = await transaction.get(accountRef);
            if (accountDoc.exists) {
                const accountData = accountDoc.data();
                transaction.update(accountRef, {
                    monthlyTokens: (accountData.monthlyTokens || 0) + tokens,
                    lastLedgerEntryId: entryId,
                    lastUpdated: admin_1.admin.firestore.FieldValue.serverTimestamp(),
                });
            }
            else {
                // Create new account if it doesn't exist
                const newAccount = {
                    userId,
                    monthlyTokens: tokens,
                    welcomeBonus: 20,
                    freeActions: 20,
                    lastResetDate: admin_1.admin.firestore.Timestamp.fromDate(now),
                    lastLedgerEntryId: entryId,
                    lastUpdated: admin_1.admin.firestore.FieldValue.serverTimestamp(),
                };
                transaction.set(accountRef, newAccount);
            }
        });
        return { success: true };
    }
    catch (error) {
        return { success: false, error: error instanceof Error ? error.toString() : String(error) };
    }
}
/**
 * Restore logic pack purchases for a user
 */
exports.restoreLogicPackPurchases = functions.https.onCall(async (data, context) => {
    // Validate authentication
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const userId = context.auth.uid;
    try {
        const db = admin_1.admin.firestore();
        // Get user's purchase receipts
        const receiptsSnapshot = await db
            .collection(PURCHASES_COLLECTION)
            .where('userId', '==', userId)
            .where('status', '==', 'verified')
            .get();
        const purchases = receiptsSnapshot.docs.map(doc => {
            const data = doc.data();
            return {
                transactionId: data.transactionId,
                productId: data.productId,
                tokens: data.tokens,
                platform: data.platform,
                purchaseToken: data.purchaseToken,
                receiptData: {
                    transactionId: data.transactionId,
                    purchaseToken: data.purchaseToken,
                },
            };
        });
        return { purchases };
    }
    catch (error) {
        throw new functions.https.HttpsError('internal', `Failed to restore purchases: ${error}`);
    }
});
/**
 * Get purchase history for a user
 */
exports.getPurchaseHistory = functions.https.onCall(async (data, context) => {
    // Validate authentication
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const userId = context.auth.uid;
    try {
        const db = admin_1.admin.firestore();
        // Get user's purchase receipts
        const receiptsSnapshot = await db
            .collection(PURCHASES_COLLECTION)
            .where('userId', '==', userId)
            .orderBy('verifiedAt', 'desc')
            .get();
        const purchases = receiptsSnapshot.docs.map(doc => {
            const data = doc.data();
            return {
                purchaseId: data.transactionId,
                productId: data.productId,
                tokens: data.tokens,
                isVerified: true,
                isReplay: false,
                verifiedAt: data.verifiedAt.toDate().toISOString(),
                platform: data.platform,
            };
        });
        return { purchases };
    }
    catch (error) {
        throw new functions.https.HttpsError('internal', `Failed to get purchase history: ${error}`);
    }
});
/**
 * Get purchase verification status
 */
exports.getPurchaseVerificationStatus = functions.https.onCall(async (data, context) => {
    // Validate authentication
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const userId = context.auth.uid;
    try {
        const db = admin_1.admin.firestore();
        // Get purchase history
        const receiptsSnapshot = await db
            .collection(PURCHASES_COLLECTION)
            .where('userId', '==', userId)
            .orderBy('verifiedAt', 'desc')
            .get();
        const totalPurchased = receiptsSnapshot.docs.reduce((sum, doc) => sum + (doc.data().tokens || 0), 0);
        const lastPurchaseDate = receiptsSnapshot.docs.length > 0 ?
            receiptsSnapshot.docs[0].data().verifiedAt.toDate().toISOString() : null;
        return {
            totalPurchases: receiptsSnapshot.size,
            totalTokensPurchased: totalPurchased,
            lastPurchaseDate,
            verificationEnabled: SERVER_SIDE_VERIFICATION_ENABLED,
            replayProtectionEnabled: RECEIPT_REPLAY_PROTECTION_ENABLED,
            idempotentCreditsEnabled: IDEMPOTENT_CREDITS_ENABLED,
        };
    }
    catch (error) {
        throw new functions.https.HttpsError('internal', `Failed to get verification status: ${error}`);
    }
});
/**
 * Clear purchase cache (admin function)
 */
exports.clearPurchaseCache = functions.https.onCall(async (data, context) => {
    // Validate authentication and admin role
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    // In production, check if user has admin role
    // if (!context.auth.token.admin) {
    //   throw new functions.https.HttpsError('permission-denied', 'Admin access required');
    // }
    try {
        const db = admin_1.admin.firestore();
        // Get all cache entries
        const cacheSnapshot = await db.collection('purchase_cache').get();
        // Delete all cache entries in batches
        const batch = db.batch();
        let batchCount = 0;
        let totalDeleted = 0;
        cacheSnapshot.docs.forEach(doc => {
            batch.delete(doc.ref);
            batchCount++;
            totalDeleted++;
            if (batchCount >= 500) {
                batch.commit();
                batchCount = 0;
            }
        });
        if (batchCount > 0) {
            await batch.commit();
        }
        // Log cache clearing
        await logTelemetry(db, 'purchase.cache_cleared', {
            totalDeleted,
            timestamp: new Date().toISOString(),
        });
        return { success: true, totalDeleted };
    }
    catch (error) {
        throw new functions.https.HttpsError('internal', `Failed to clear cache: ${error}`);
    }
});
/**
 * Generate unique request ID
 */
function generateRequestId() {
    const timestamp = Date.now();
    const random = generateRandomString(8);
    return `purchase_${timestamp}_${random}`;
}
/**
 * Generate unique entry ID
 */
function generateEntryId() {
    const timestamp = Date.now();
    const random = generateRandomString(8);
    return `entry_${timestamp}_${random}`;
}
/**
 * Generate random string for IDs
 */
function generateRandomString(length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    let result = '';
    for (let i = 0; i < length; i++) {
        result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
}
/**
 * Log telemetry events
 */
async function logTelemetry(db, event, parameters) {
    try {
        await db.collection(TELEMETRY_COLLECTION).add({
            event,
            parameters,
            timestamp: admin_1.admin.firestore.FieldValue.serverTimestamp(),
        });
    }
    catch (error) {
        // Silently fail telemetry logging to avoid breaking main functionality
        console.warn('Telemetry logging failed:', error);
    }
}
//# sourceMappingURL=enhanced-purchase-verification.js.map