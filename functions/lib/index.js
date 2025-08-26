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
exports.updateUserData = exports.updateUserStats = exports.deleteUserData = exports.createUserProfile = exports.helloWorld = exports.clearPurchaseCache = exports.getPurchaseVerificationStatus = exports.getPurchaseHistory = exports.verifyLogicPackPurchaseEnhanced = exports.cleanupOldLedgerEntries = exports.getLedgerStats = exports.dailyLedgerReconciliation = exports.reconcileUserLedger = exports.getUserTokenAccount = exports.getLedgerEntries = exports.writeLedgerEntry = exports.verifyLogicPackPurchase = exports.cleanupActionHistory = exports.consumeTokens = exports.processNotificationQueue = exports.markNotificationRead = exports.getNotificationHistory = exports.unregisterDeviceToken = exports.registerDeviceToken = exports.updateNotificationPreferences = exports.getNotificationPreferences = exports.sendNotification = exports.scheduleNotification = exports.processWithAI = exports.generateQuiz = exports.generateFlashcards = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-functions/v2/firestore");
const identity_1 = require("firebase-functions/v2/identity");
const logger = __importStar(require("firebase-functions/logger"));
const admin_1 = require("./admin");
// Import YouTube functions
require("./youtube");
// Import and export AI processing functions
var ai_processing_1 = require("./ai-processing");
Object.defineProperty(exports, "generateFlashcards", { enumerable: true, get: function () { return ai_processing_1.generateFlashcards; } });
Object.defineProperty(exports, "generateQuiz", { enumerable: true, get: function () { return ai_processing_1.generateQuiz; } });
Object.defineProperty(exports, "processWithAI", { enumerable: true, get: function () { return ai_processing_1.processWithAI; } });
// Import and export notification functions
var notification_functions_1 = require("./notification-functions");
Object.defineProperty(exports, "scheduleNotification", { enumerable: true, get: function () { return notification_functions_1.scheduleNotification; } });
Object.defineProperty(exports, "sendNotification", { enumerable: true, get: function () { return notification_functions_1.sendNotification; } });
Object.defineProperty(exports, "getNotificationPreferences", { enumerable: true, get: function () { return notification_functions_1.getNotificationPreferences; } });
Object.defineProperty(exports, "updateNotificationPreferences", { enumerable: true, get: function () { return notification_functions_1.updateNotificationPreferences; } });
Object.defineProperty(exports, "registerDeviceToken", { enumerable: true, get: function () { return notification_functions_1.registerDeviceToken; } });
Object.defineProperty(exports, "unregisterDeviceToken", { enumerable: true, get: function () { return notification_functions_1.unregisterDeviceToken; } });
Object.defineProperty(exports, "getNotificationHistory", { enumerable: true, get: function () { return notification_functions_1.getNotificationHistory; } });
Object.defineProperty(exports, "markNotificationRead", { enumerable: true, get: function () { return notification_functions_1.markNotificationRead; } });
Object.defineProperty(exports, "processNotificationQueue", { enumerable: true, get: function () { return notification_functions_1.processNotificationQueue; } });
// Export new token consumption cloud functions
var token_consumption_1 = require("./token-consumption");
Object.defineProperty(exports, "consumeTokens", { enumerable: true, get: function () { return token_consumption_1.consumeTokens; } });
Object.defineProperty(exports, "cleanupActionHistory", { enumerable: true, get: function () { return token_consumption_1.cleanupActionHistory; } });
// Export new logic pack purchase verification cloud functions
var logic_purchases_1 = require("./logic-purchases");
Object.defineProperty(exports, "verifyLogicPackPurchase", { enumerable: true, get: function () { return logic_purchases_1.verifyLogicPackPurchase; } });
// Enhanced Atomic Ledger System
var enhanced_ledger_1 = require("./enhanced-ledger");
Object.defineProperty(exports, "writeLedgerEntry", { enumerable: true, get: function () { return enhanced_ledger_1.writeLedgerEntry; } });
Object.defineProperty(exports, "getLedgerEntries", { enumerable: true, get: function () { return enhanced_ledger_1.getLedgerEntries; } });
Object.defineProperty(exports, "getUserTokenAccount", { enumerable: true, get: function () { return enhanced_ledger_1.getUserTokenAccount; } });
Object.defineProperty(exports, "reconcileUserLedger", { enumerable: true, get: function () { return enhanced_ledger_1.reconcileUserLedger; } });
Object.defineProperty(exports, "dailyLedgerReconciliation", { enumerable: true, get: function () { return enhanced_ledger_1.dailyLedgerReconciliation; } });
Object.defineProperty(exports, "getLedgerStats", { enumerable: true, get: function () { return enhanced_ledger_1.getLedgerStats; } });
Object.defineProperty(exports, "cleanupOldLedgerEntries", { enumerable: true, get: function () { return enhanced_ledger_1.cleanupOldLedgerEntries; } });
// Enhanced Purchase Verification System
var enhanced_purchase_verification_1 = require("./enhanced-purchase-verification");
Object.defineProperty(exports, "verifyLogicPackPurchaseEnhanced", { enumerable: true, get: function () { return enhanced_purchase_verification_1.verifyLogicPackPurchase; } });
Object.defineProperty(exports, "getPurchaseHistory", { enumerable: true, get: function () { return enhanced_purchase_verification_1.getPurchaseHistory; } });
Object.defineProperty(exports, "getPurchaseVerificationStatus", { enumerable: true, get: function () { return enhanced_purchase_verification_1.getPurchaseVerificationStatus; } });
Object.defineProperty(exports, "clearPurchaseCache", { enumerable: true, get: function () { return enhanced_purchase_verification_1.clearPurchaseCache; } });
// Firebase Admin is already initialized in other files
// const db = admin.firestore(); // This line is removed as per the new_code
/**
 * Simple test function to verify deployment
 */
exports.helloWorld = (0, https_1.onRequest)((request, response) => {
    logger.info("Hello logs!", { structuredData: true });
    response.send("Hello from Firebase!");
});
/**
 * Create user profile when they first sign up
 */
exports.createUserProfile = (0, identity_1.beforeUserCreated)(async (event) => {
    const user = event.data;
    try {
        await admin_1.db.collection('users').doc(user.uid).set({
            uid: user.uid,
            email: user.email,
            displayName: user.displayName || 'User',
            photoURL: user.photoURL || null,
            tier: 'free',
            credits: 3,
            xp: 0,
            streak: 0,
            totalStudySessions: 0,
            createdAt: admin_1.admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin_1.admin.firestore.FieldValue.serverTimestamp(),
        });
        // Initialize user progress
        await admin_1.db.collection('user_progress').doc(user.uid).set({
            userId: user.uid,
            totalQuizzes: 0,
            averageScore: 0,
            studyStreak: 0,
            lastStudyDate: null,
            achievements: [],
            createdAt: admin_1.admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin_1.admin.firestore.FieldValue.serverTimestamp(),
        });
        // Initialize notification preferences
        await admin_1.db.collection('notification_preferences').doc(user.uid).set({
            uid: user.uid,
            dailyReminders: true,
            streakReminders: true,
            quizNotifications: true,
            studyTips: true,
            style: 'friendly',
            frequency: 'daily',
            time: '18:00',
            createdAt: admin_1.admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin_1.admin.firestore.FieldValue.serverTimestamp(),
        });
        logger.info(`User profile created for ${user.uid}`);
    }
    catch (error) {
        logger.error(`Error creating user profile for ${user.uid}:`, error);
    }
});
/**
 * Clean up user data when account is deleted
 * Note: beforeUserDeleted is not supported in Firebase Functions v2
 * This function is kept for future implementation using triggers
 */
exports.deleteUserData = (0, https_1.onRequest)(async (request, response) => {
    // This function will be implemented using Firestore triggers
    // when user documents are deleted
    response.status(501).send('Not implemented - use Firestore triggers instead');
});
/**
 * Update user stats when a quiz is completed
 */
exports.updateUserStats = (0, firestore_1.onDocumentCreated)('quiz_results/{resultId}', async (event) => {
    const snap = event.data;
    if (!snap) {
        logger.error('No data associated with the event');
        return;
    }
    try {
        const result = snap.data();
        const userId = result.userId;
        if (!userId) {
            logger.error('Quiz result missing userId');
            return;
        }
        const userRef = admin_1.db.collection('users').doc(userId);
        const progressRef = admin_1.db.collection('user_progress').doc(userId);
        await admin_1.db.runTransaction(async (transaction) => {
            const userDoc = await transaction.get(userRef);
            const progressDoc = await transaction.get(progressRef);
            if (!userDoc.exists || !progressDoc.exists) {
                logger.error(`User or progress doc not found for ${userId}`);
                return;
            }
            const userData = userDoc.data();
            const progressData = progressDoc.data();
            // Calculate XP gained
            const baseXP = 10;
            const bonusXP = Math.floor(result.percentage * 0.5); // Up to 50 bonus XP for perfect score
            const xpGained = baseXP + bonusXP;
            // Update user stats
            transaction.update(userRef, {
                xp: admin_1.admin.firestore.FieldValue.increment(xpGained),
                totalStudySessions: admin_1.admin.firestore.FieldValue.increment(1),
                updatedAt: admin_1.admin.firestore.FieldValue.serverTimestamp(),
            });
            // Update progress
            const newTotalQuizzes = (progressData.totalQuizzes || 0) + 1;
            const currentAverage = progressData.averageScore || 0;
            const newAverage = ((currentAverage * (newTotalQuizzes - 1)) + result.percentage) / newTotalQuizzes;
            transaction.update(progressRef, {
                totalQuizzes: newTotalQuizzes,
                averageScore: newAverage,
                lastStudyDate: admin_1.admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin_1.admin.firestore.FieldValue.serverTimestamp(),
            });
        });
        logger.info(`Updated stats for user ${userId} after quiz completion`);
    }
    catch (error) {
        logger.error('Error updating user stats:', error);
    }
});
/**
 * Simple user data update function
 */
exports.updateUserData = (0, https_1.onCall)(async (request) => {
    const { data, auth } = request;
    if (!auth) {
        throw new https_1.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const uid = auth.uid;
    const { credits, tier } = data;
    try {
        await admin_1.db.collection('users').doc(uid).update({
            ...(credits !== undefined && { credits }),
            ...(tier !== undefined && { tier }),
            updatedAt: admin_1.admin.firestore.FieldValue.serverTimestamp(),
        });
        return { success: true };
    }
    catch (error) {
        logger.error('Error updating user data:', error);
        throw new https_1.HttpsError('internal', 'Failed to update user data');
    }
});
//# sourceMappingURL=index.js.map