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
exports.cleanupOldLedgerEntries = exports.getLedgerStats = exports.dailyLedgerReconciliation = exports.reconcileUserLedger = exports.getUserTokenAccount = exports.getLedgerEntries = exports.writeLedgerEntry = void 0;
const functions = __importStar(require("firebase-functions"));
const admin_1 = require("./admin");
// Constants for collection names
const LEDGER_COLLECTION = 'token_ledger';
const ACCOUNTS_COLLECTION = 'user_token_accounts';
const RECONCILIATION_COLLECTION = 'ledger_reconciliations';
const TELEMETRY_COLLECTION = 'telemetry_events';
// Settings (in production, these would come from Remote Config)
const ATOMIC_WRITES_ENABLED = true;
const DAILY_RECONCILE_ENABLED = true;
const ALERT_ON_MISMATCH_ENABLED = true;
/**
 * Write a ledger entry atomically
 * Every debit/credit writes one immutable record
 */
exports.writeLedgerEntry = functions.https.onCall(async (data, context) => {
    // Validate authentication
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const userId = context.auth.uid;
    const { action, tokens, requestId, source, metadata = {}, setId } = data;
    // Validate required fields
    if (!action || !tokens || !requestId || !source) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }
    // Validate action type
    const validActions = ['credit', 'debit', 'reset', 'transfer'];
    if (!validActions.includes(action)) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid action type');
    }
    // Validate source type
    const validSources = ['purchase', 'generate', 'regenerate', 'reOrganize', 'freeAction', 'welcomeBonus', 'monthlyReset', 'refund', 'adjustment'];
    if (!validSources.includes(source)) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid source type');
    }
    try {
        const db = admin_1.admin.firestore();
        const entryId = generateEntryId();
        const now = new Date();
        // Check for duplicate request (fast dedupe - 60s)
        if (await isDuplicateRequest(db, requestId, userId)) {
            await logTelemetry(db, 'abuse.duplicate_request_blocked', {
                requestId,
                userId,
                timestamp: now.toISOString(),
            });
            throw new functions.https.HttpsError('already-exists', 'Duplicate request detected');
        }
        // Perform atomic transaction
        if (ATOMIC_WRITES_ENABLED) {
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
                    const updatedAccount = updateAccountBalance(accountData, action, tokens);
                    transaction.update(accountRef, {
                        ...updatedAccount,
                        lastLedgerEntryId: entryId,
                        lastUpdated: admin_1.admin.firestore.FieldValue.serverTimestamp(),
                    });
                }
                else {
                    // Create new account if it doesn't exist
                    // Check if user is admin and give them 1000 tokens instead of 20
                    const userDoc = await transaction.get(db.collection('users').doc(userId));
                    const isAdmin = userDoc.exists && userDoc.data()?.email === 'admin@mindload.test';
                    const welcomeBonus = isAdmin ? 1000 : 20;
                    const freeActions = isAdmin ? 1000 : 20;
                    const newAccount = {
                        userId,
                        monthlyTokens: action === 'credit' ? tokens : 0,
                        welcomeBonus: welcomeBonus,
                        freeActions: freeActions,
                        lastResetDate: admin_1.admin.firestore.Timestamp.fromDate(now),
                        lastLedgerEntryId: entryId,
                        lastUpdated: admin_1.admin.firestore.Timestamp.fromDate(now),
                    };
                    transaction.set(accountRef, newAccount);
                }
            });
        }
        else {
            // Non-atomic fallback (not recommended for production)
            await db
                .collection(LEDGER_COLLECTION)
                .doc(userId)
                .collection('entries')
                .doc(entryId)
                .set({
                userId,
                action,
                tokens,
                requestId,
                timestamp: admin_1.admin.firestore.Timestamp.fromDate(now),
                source,
                metadata,
                createdAt: admin_1.admin.firestore.FieldValue.serverTimestamp(),
            });
            await updateAccountBalanceNonAtomic(db, userId, action, tokens, entryId);
        }
        // Log successful ledger entry
        await logTelemetry(db, 'ledger.entry_written', {
            entryId,
            userId,
            action,
            tokens,
            requestId,
            source,
            timestamp: now.toISOString(),
        });
        return {
            success: true,
            entryId,
            timestamp: now.toISOString(),
        };
    }
    catch (error) {
        // Log error and return failure
        await logTelemetry(admin_1.admin.firestore(), 'ledger.write_error', {
            userId,
            action,
            tokens,
            requestId,
            error: error instanceof Error ? error.toString() : String(error),
            timestamp: new Date().toISOString(),
        });
        throw new functions.https.HttpsError('internal', `Failed to write ledger entry: ${error}`);
    }
});
/**
 * Check for duplicate requests within 60 seconds
 */
async function isDuplicateRequest(db, requestId, userId) {
    try {
        const now = new Date();
        const cutoff = new Date(now.getTime() - 60 * 1000); // 60 seconds ago
        const query = await db
            .collection(LEDGER_COLLECTION)
            .doc(userId)
            .collection('entries')
            .where('requestId', '==', requestId)
            .where('timestamp', '>', admin_1.admin.firestore.Timestamp.fromDate(cutoff))
            .limit(1)
            .get();
        return !query.empty;
    }
    catch (error) {
        // If we can't check for duplicates, allow the request
        // This is a fail-open approach for availability
        return false;
    }
}
/**
 * Update account balance based on action type
 */
function updateAccountBalance(accountData, action, tokens) {
    switch (action) {
        case 'credit':
            return {
                ...accountData,
                monthlyTokens: (accountData.monthlyTokens || 0) + tokens,
            };
        case 'debit':
            return debitFromAccount(accountData, tokens);
        case 'reset':
            // Check if user is admin and give them 1000 tokens instead of 20
            const isAdmin = accountData.email === 'admin@mindload.test';
            const resetAmount = isAdmin ? 1000 : 20;
            return {
                ...accountData,
                monthlyTokens: tokens,
                freeActions: resetAmount,
                welcomeBonus: resetAmount,
            };
        default:
            return accountData;
    }
}
/**
 * Debit tokens following consumption order: Free → Welcome Bonus → Monthly
 */
function debitFromAccount(accountData, tokens) {
    let remaining = tokens;
    let fromFree = 0;
    let fromWelcome = 0;
    let fromMonthly = 0;
    const currentFree = accountData.freeActions || 0;
    const currentWelcome = accountData.welcomeBonus || 0;
    const currentMonthly = accountData.monthlyTokens || 0;
    // Consume from free actions first
    if (currentFree >= remaining) {
        fromFree = remaining;
        remaining = 0;
    }
    else {
        fromFree = currentFree;
        remaining -= currentFree;
    }
    // Then from welcome bonus
    if (remaining > 0 && currentWelcome >= remaining) {
        fromWelcome = remaining;
        remaining = 0;
    }
    else if (remaining > 0) {
        fromWelcome = currentWelcome;
        remaining -= currentWelcome;
    }
    // Finally from monthly tokens
    if (remaining > 0) {
        fromMonthly = remaining;
    }
    return {
        ...accountData,
        freeActions: currentFree - fromFree,
        welcomeBonus: currentWelcome - fromWelcome,
        monthlyTokens: currentMonthly - fromMonthly,
    };
}
/**
 * Non-atomic account balance update (fallback)
 */
async function updateAccountBalanceNonAtomic(db, userId, action, tokens, entryId) {
    const accountRef = db.collection(ACCOUNTS_COLLECTION).doc(userId);
    await db.runTransaction(async (transaction) => {
        const accountDoc = await transaction.get(accountRef);
        if (accountDoc.exists) {
            const accountData = accountDoc.data();
            const updatedAccount = updateAccountBalance(accountData, action, tokens);
            transaction.update(accountRef, {
                ...updatedAccount,
                lastLedgerEntryId: entryId,
                lastUpdated: admin_1.admin.firestore.FieldValue.serverTimestamp(),
            });
        }
    });
}
/**
 * Get user's ledger entries
 */
exports.getLedgerEntries = functions.https.onCall(async (data, context) => {
    // Validate authentication
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const userId = context.auth.uid;
    const { limit = 100, since } = data;
    try {
        const db = admin_1.admin.firestore();
        let query = db
            .collection(LEDGER_COLLECTION)
            .doc(userId)
            .collection('entries')
            .orderBy('timestamp', 'desc')
            .limit(limit);
        if (since) {
            const sinceDate = new Date(since);
            query = query.where('timestamp', '>', admin_1.admin.firestore.Timestamp.fromDate(sinceDate));
        }
        const snapshot = await query.get();
        const entries = snapshot.docs.map(doc => ({
            entryId: doc.id,
            ...doc.data(),
        }));
        return { entries };
    }
    catch (error) {
        throw new functions.https.HttpsError('internal', `Failed to get ledger entries: ${error}`);
    }
});
/**
 * Get user's current token account
 */
exports.getUserTokenAccount = functions.https.onCall(async (data, context) => {
    // Validate authentication
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const userId = context.auth.uid;
    try {
        const db = admin_1.admin.firestore();
        const doc = await db.collection(ACCOUNTS_COLLECTION).doc(userId).get();
        if (doc.exists) {
            return { account: doc.data() };
        }
        return { account: null };
    }
    catch (error) {
        throw new functions.https.HttpsError('internal', `Failed to get token account: ${error}`);
    }
});
/**
 * Perform daily reconciliation for a user
 */
exports.reconcileUserLedger = functions.https.onCall(async (data, context) => {
    // Validate authentication
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const userId = context.auth.uid;
    try {
        const db = admin_1.admin.firestore();
        // Get all ledger entries for the user
        const entriesSnapshot = await db
            .collection(LEDGER_COLLECTION)
            .doc(userId)
            .collection('entries')
            .orderBy('timestamp', 'desc')
            .limit(10000)
            .get();
        // Calculate expected balance from ledger
        let expectedBalance = 0;
        const mismatchedEntries = [];
        entriesSnapshot.docs.forEach(doc => {
            const entry = doc.data();
            switch (entry.action) {
                case 'credit':
                    expectedBalance += entry.tokens;
                    break;
                case 'debit':
                    expectedBalance -= entry.tokens;
                    break;
                case 'reset':
                    expectedBalance = entry.tokens;
                    break;
            }
        });
        // Get actual balance from account
        const accountDoc = await db.collection(ACCOUNTS_COLLECTION).doc(userId).get();
        const actualBalance = accountDoc.exists ?
            (accountDoc.data().monthlyTokens || 0) + (accountDoc.data().welcomeBonus || 0) + (accountDoc.data().freeActions || 0) : 0;
        // Calculate difference
        const difference = Math.abs(expectedBalance - actualBalance);
        const isBalanced = difference === 0;
        // Create reconciliation result
        const result = {
            userId,
            expectedBalance,
            actualBalance,
            difference,
            isBalanced,
            mismatchedEntries,
            reconciledAt: new Date().toISOString(),
        };
        // Log reconciliation result
        if (isBalanced) {
            await logTelemetry(db, 'ledger.reconcile_ok', {
                userId,
                expectedBalance,
                actualBalance,
                timestamp: new Date().toISOString(),
            });
        }
        else {
            await logTelemetry(db, 'ledger.reconcile_mismatch', {
                userId,
                expectedBalance,
                actualBalance,
                difference,
                timestamp: new Date().toISOString(),
            });
            // Store reconciliation result for review
            await db.collection(RECONCILIATION_COLLECTION).add(result);
        }
        return result;
    }
    catch (error) {
        throw new functions.https.HttpsError('internal', `Reconciliation failed: ${error}`);
    }
});
/**
 * Helper function for reconciliation (used internally)
 */
async function performUserReconciliation(userId) {
    try {
        const db = admin_1.admin.firestore();
        // Get all ledger entries for the user
        const entriesSnapshot = await db
            .collection(LEDGER_COLLECTION)
            .doc(userId)
            .collection('entries')
            .orderBy('timestamp', 'desc')
            .limit(10000)
            .get();
        // Calculate expected balance from ledger
        let expectedBalance = 0;
        const mismatchedEntries = [];
        entriesSnapshot.docs.forEach(doc => {
            const entry = doc.data();
            switch (entry.action) {
                case 'credit':
                    expectedBalance += entry.tokens;
                    break;
                case 'debit':
                    expectedBalance -= entry.tokens;
                    break;
                case 'reset':
                    expectedBalance = entry.tokens;
                    break;
            }
        });
        // Get actual balance from account
        const accountDoc = await db.collection(ACCOUNTS_COLLECTION).doc(userId).get();
        const actualBalance = accountDoc.exists ?
            (accountDoc.data().monthlyTokens || 0) + (accountDoc.data().welcomeBonus || 0) + (accountDoc.data().freeActions || 0) : 0;
        // Calculate difference
        const difference = Math.abs(expectedBalance - actualBalance);
        const isBalanced = difference === 0;
        // Create reconciliation result
        const result = {
            userId,
            expectedBalance,
            actualBalance,
            difference,
            isBalanced,
            mismatchedEntries,
            reconciledAt: new Date().toISOString(),
        };
        // Log reconciliation result
        if (isBalanced) {
            await logTelemetry(db, 'ledger.reconcile_ok', {
                userId,
                expectedBalance,
                actualBalance,
                timestamp: new Date().toISOString(),
            });
        }
        else {
            await logTelemetry(db, 'ledger.reconcile_mismatch', {
                userId,
                expectedBalance,
                actualBalance,
                difference,
                timestamp: new Date().toISOString(),
            });
            // Store reconciliation result for review
            await db.collection(RECONCILIATION_COLLECTION).add(result);
        }
        return result;
    }
    catch (error) {
        throw new Error(`Reconciliation failed: ${error}`);
    }
}
/**
 * Daily reconciliation job for all users
 * Runs at 2 AM Chicago time (7 AM UTC)
 */
exports.dailyLedgerReconciliation = functions.pubsub
    .schedule('0 7 * * *')
    .timeZone('America/Chicago')
    .onRun(async (context) => {
    try {
        const db = admin_1.admin.firestore();
        // Get all user token accounts
        const usersSnapshot = await db.collection(ACCOUNTS_COLLECTION).get();
        const results = [];
        for (const userDoc of usersSnapshot.docs) {
            try {
                // Call reconciliation for each user
                const reconciliationData = await performUserReconciliation(userDoc.id);
                if (reconciliationData && typeof reconciliationData === 'object') {
                    results.push(reconciliationData);
                }
            }
            catch (error) {
                // Continue with other users if one fails
                console.warn(`Reconciliation failed for user ${userDoc.id}:`, error);
            }
        }
        // Log summary
        const balancedCount = results.filter(r => r && r.isBalanced).length;
        const mismatchedCount = results.filter(r => r && !r.isBalanced).length;
        await logTelemetry(db, 'ledger.daily_reconciliation_complete', {
            totalUsers: results.length,
            balancedCount,
            mismatchedCount,
            timestamp: new Date().toISOString(),
        });
        console.log(`Daily reconciliation complete: ${balancedCount} balanced, ${mismatchedCount} mismatched`);
        return { success: true, results };
    }
    catch (error) {
        console.error('Daily reconciliation failed:', error);
        throw error;
    }
});
/**
 * Get ledger statistics for a user
 */
exports.getLedgerStats = functions.https.onCall(async (data, context) => {
    // Validate authentication
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const userId = context.auth.uid;
    try {
        const db = admin_1.admin.firestore();
        const now = new Date();
        const thisMonth = new Date(now.getFullYear(), now.getMonth(), 1);
        // Get ledger entries for this month
        const entriesSnapshot = await db
            .collection(LEDGER_COLLECTION)
            .doc(userId)
            .collection('entries')
            .where('timestamp', '>', admin_1.admin.firestore.Timestamp.fromDate(thisMonth))
            .get();
        // Calculate statistics
        let totalCredits = 0;
        let totalDebits = 0;
        let totalResets = 0;
        entriesSnapshot.docs.forEach(doc => {
            const entry = doc.data();
            switch (entry.action) {
                case 'credit':
                    totalCredits += entry.tokens;
                    break;
                case 'debit':
                    totalDebits += entry.tokens;
                    break;
                case 'reset':
                    totalResets += entry.tokens;
                    break;
            }
        });
        return {
            totalEntries: entriesSnapshot.size,
            totalCredits,
            totalDebits,
            totalResets,
            netChange: totalCredits - totalDebits,
            period: 'this_month',
            periodStart: thisMonth.toISOString(),
            periodEnd: now.toISOString(),
        };
    }
    catch (error) {
        throw new functions.https.HttpsError('internal', `Failed to get ledger stats: ${error}`);
    }
});
/**
 * Clean up old ledger entries (admin function)
 */
exports.cleanupOldLedgerEntries = functions.https.onCall(async (data, context) => {
    // Validate authentication and admin role
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    // In production, check if user has admin role
    // if (!context.auth.token.admin) {
    //   throw new functions.https.HttpsError('permission-denied', 'Admin access required');
    // }
    const { olderThan = 90 } = data; // days
    try {
        const db = admin_1.admin.firestore();
        const cutoffDate = new Date();
        cutoffDate.setDate(cutoffDate.getDate() - olderThan);
        // Get all users
        const usersSnapshot = await db.collection(ACCOUNTS_COLLECTION).get();
        let totalDeleted = 0;
        for (const userDoc of usersSnapshot.docs) {
            const userId = userDoc.id;
            // Get old entries
            const entriesQuery = await db
                .collection(LEDGER_COLLECTION)
                .doc(userId)
                .collection('entries')
                .where('timestamp', '<', admin_1.admin.firestore.Timestamp.fromDate(cutoffDate))
                .get();
            // Delete old entries in batches
            const batch = db.batch();
            let batchCount = 0;
            entriesQuery.docs.forEach(entryDoc => {
                batch.delete(entryDoc.ref);
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
        }
        // Log cleanup completion
        await logTelemetry(db, 'ledger.cleanup_complete', {
            totalDeleted,
            olderThan,
            timestamp: new Date().toISOString(),
        });
        return { success: true, totalDeleted, olderThan };
    }
    catch (error) {
        throw new functions.https.HttpsError('internal', `Cleanup failed: ${error}`);
    }
});
/**
 * Generate unique entry ID
 */
function generateEntryId() {
    const timestamp = Date.now();
    const random = generateRandomString(8);
    return `entry_${timestamp}_${random}`;
}
/**
 * Generate random string for entry ID
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
//# sourceMappingURL=enhanced-ledger.js.map