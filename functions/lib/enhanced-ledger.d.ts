import * as functions from 'firebase-functions';
/**
 * Write a ledger entry atomically
 * Every debit/credit writes one immutable record
 */
export declare const writeLedgerEntry: functions.HttpsFunction & functions.Runnable<any>;
/**
 * Get user's ledger entries
 */
export declare const getLedgerEntries: functions.HttpsFunction & functions.Runnable<any>;
/**
 * Get user's current token account
 */
export declare const getUserTokenAccount: functions.HttpsFunction & functions.Runnable<any>;
/**
 * Perform daily reconciliation for a user
 */
export declare const reconcileUserLedger: functions.HttpsFunction & functions.Runnable<any>;
/**
 * Daily reconciliation job for all users
 * Runs at 2 AM Chicago time (7 AM UTC)
 */
export declare const dailyLedgerReconciliation: functions.CloudFunction<unknown>;
/**
 * Get ledger statistics for a user
 */
export declare const getLedgerStats: functions.HttpsFunction & functions.Runnable<any>;
/**
 * Clean up old ledger entries (admin function)
 */
export declare const cleanupOldLedgerEntries: functions.HttpsFunction & functions.Runnable<any>;
