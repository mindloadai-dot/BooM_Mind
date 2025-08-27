export { generateFlashcards, generateQuiz, processWithAI } from './ai-processing';
export { youtubePreview, youtubeIngest, cleanupYouTubeRateLimit, resetUserRateLimits, getRateLimitStatus, cleanupYouTubeCache } from './youtube';
export { scheduleNotification, sendNotification, getNotificationPreferences, updateNotificationPreferences, registerDeviceToken, unregisterDeviceToken, getNotificationHistory, markNotificationRead, processNotificationQueue } from './notification-functions';
export { consumeTokens, cleanupActionHistory } from './token-consumption';
export { verifyLogicPackPurchase, } from './logic-purchases';
export { writeLedgerEntry, getLedgerEntries, getUserTokenAccount, reconcileUserLedger, dailyLedgerReconciliation, getLedgerStats, cleanupOldLedgerEntries } from './enhanced-ledger';
export { verifyLogicPackPurchase as verifyLogicPackPurchaseEnhanced, getPurchaseHistory, getPurchaseVerificationStatus, clearPurchaseCache } from './enhanced-purchase-verification';
/**
 * Simple test function to verify deployment
 */
export declare const helloWorld: import("firebase-functions/v2/https").HttpsFunction;
/**
 * Create user profile when they first sign up
 */
export declare const createUserProfile: import("firebase-functions/v1").BlockingFunction;
/**
 * Clean up user data when account is deleted
 * Note: beforeUserDeleted is not supported in Firebase Functions v2
 * This function is kept for future implementation using triggers
 */
export declare const deleteUserData: import("firebase-functions/v2/https").HttpsFunction;
/**
 * Update user stats when a quiz is completed
 */
export declare const updateUserStats: import("firebase-functions/v2/core").CloudFunction<import("firebase-functions/v2/firestore").FirestoreEvent<import("firebase-functions/v2/firestore").QueryDocumentSnapshot | undefined, {
    resultId: string;
}>>;
/**
 * Simple user data update function
 */
export declare const updateUserData: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    success: boolean;
}>>;
