import * as functions from 'firebase-functions';
/**
 * Verify logic pack purchase with server-side verification
 * Tokens are credited only after verification
 */
export declare const verifyLogicPackPurchase: functions.HttpsFunction & functions.Runnable<any>;
/**
 * Restore logic pack purchases for a user
 */
export declare const restoreLogicPackPurchases: functions.HttpsFunction & functions.Runnable<any>;
/**
 * Get purchase history for a user
 */
export declare const getPurchaseHistory: functions.HttpsFunction & functions.Runnable<any>;
/**
 * Get purchase verification status
 */
export declare const getPurchaseVerificationStatus: functions.HttpsFunction & functions.Runnable<any>;
/**
 * Clear purchase cache (admin function)
 */
export declare const clearPurchaseCache: functions.HttpsFunction & functions.Runnable<any>;
