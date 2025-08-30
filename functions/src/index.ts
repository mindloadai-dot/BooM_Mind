import {onRequest, onCall, HttpsError} from 'firebase-functions/v2/https';
import {onDocumentCreated} from 'firebase-functions/v2/firestore';
import * as logger from 'firebase-functions/logger';
import { admin, db } from './admin';

// Import YouTube functions
import { 
  youtubePreview, 
  youtubeIngest, 
  cleanupYouTubeRateLimit, 
  resetUserRateLimits, 
  getRateLimitStatus, 
  cleanupYouTubeCache 
} from './youtube';

// Import and export OpenAI functions
export { generateFlashcards, generateQuiz, generateStudyMaterial, testOpenAI } from './openai';
// Import and export AI processing functions (keeping processWithAI from ai-processing)
export { processWithAI } from './ai-processing';

// Import and export YouTube functions
export { 
  youtubePreview, 
  youtubeIngest, 
  cleanupYouTubeRateLimit, 
  resetUserRateLimits, 
  getRateLimitStatus, 
  cleanupYouTubeCache 
} from './youtube';

// Import and export notification functions
export { 
  scheduleNotification,
  sendNotification,
  getNotificationPreferences,
  updateNotificationPreferences,
  registerDeviceToken,
  unregisterDeviceToken,
  getNotificationHistory,
  markNotificationRead,
  processNotificationQueue
} from './notification-functions';

// Export new token consumption cloud functions
export { 
  consumeTokens, 
  cleanupActionHistory 
} from './token-consumption';

// Export new logic pack purchase verification cloud functions
export {
  verifyLogicPackPurchase,
} from './logic-purchases';

// Enhanced Atomic Ledger System
export { 
  writeLedgerEntry, 
  getLedgerEntries, 
  getUserTokenAccount, 
  reconcileUserLedger, 
  dailyLedgerReconciliation,
  getLedgerStats,
  cleanupOldLedgerEntries 
} from './enhanced-ledger';

// Enhanced Purchase Verification System
export { 
  verifyLogicPackPurchase as verifyLogicPackPurchaseEnhanced, 
  getPurchaseHistory, 
  getPurchaseVerificationStatus,
  clearPurchaseCache 
} from './enhanced-purchase-verification';

// Firebase Admin is already initialized in other files
// const db = admin.firestore(); // This line is removed as per the new_code

/**
 * Simple test function to verify deployment
 */
export const helloWorld = onRequest((request, response) => {
  logger.info("Hello logs!", {structuredData: true});
  response.send("Hello from Firebase!");
});

/**
 * Create user profile - Callable function instead of blocking function
 * This avoids GCIP configuration requirements
 */
export const createUserProfile = onCall(async (request) => {
  const { auth } = request;
  
  if (!auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated');
  }

  const user = auth;
  
  try {
    // Check if user profile already exists
    const existingProfile = await db.collection('users').doc(user.uid).get();
    if (existingProfile.exists) {
      logger.info(`User profile already exists for ${user.uid}`);
      return { success: true, message: 'Profile already exists' };
    }

    await db.collection('users').doc(user.uid).set({
      uid: user.uid,
      email: user.token?.email || '',
      displayName: user.token?.name || 'User',
      photoURL: user.token?.picture || null,
      tier: 'free',
      credits: 3,
      xp: 0,
      streak: 0,
      totalStudySessions: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Initialize user progress
    await db.collection('user_progress').doc(user.uid).set({
      userId: user.uid,
      totalQuizzes: 0,
      averageScore: 0,
      studyStreak: 0,
      lastStudyDate: null,
      achievements: [],
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Initialize notification preferences
    await db.collection('notification_preferences').doc(user.uid).set({
      uid: user.uid,
      dailyReminders: true,
      streakReminders: true,
      quizNotifications: true,
      studyTips: true,
      style: 'friendly',
      frequency: 'daily',
      time: '18:00',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    logger.info(`User profile created for ${user.uid}`);
    return { success: true, message: 'Profile created successfully' };
  } catch (error) {
    logger.error(`Error creating user profile for ${user.uid}:`, error);
    throw new HttpsError('internal', 'Failed to create user profile');
  }
});

/**
 * Clean up user data when account is deleted
 * Note: beforeUserDeleted is not supported in Firebase Functions v2
 * This function is kept for future implementation using triggers
 */
export const deleteUserData = onRequest(async (request, response) => {
  // This function will be implemented using Firestore triggers
  // when user documents are deleted
  response.status(501).send('Not implemented - use Firestore triggers instead');
});

/**
 * Update user stats when a quiz is completed
 */
export const updateUserStats = onDocumentCreated('quiz_results/{resultId}', async (event) => {
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

      const userRef = db.collection('users').doc(userId);
      const progressRef = db.collection('user_progress').doc(userId);

      await db.runTransaction(async (transaction) => {
        const userDoc = await transaction.get(userRef);
        const progressDoc = await transaction.get(progressRef);

        if (!userDoc.exists || !progressDoc.exists) {
          logger.error(`User or progress doc not found for ${userId}`);
          return;
        }

        const userData = userDoc.data()!;
        const progressData = progressDoc.data()!;

        // Calculate XP gained
        const baseXP = 10;
        const bonusXP = Math.floor(result.percentage * 0.5); // Up to 50 bonus XP for perfect score
        const xpGained = baseXP + bonusXP;

        // Update user stats
        transaction.update(userRef, {
          xp: admin.firestore.FieldValue.increment(xpGained),
          totalStudySessions: admin.firestore.FieldValue.increment(1),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Update progress
        const newTotalQuizzes = (progressData.totalQuizzes || 0) + 1;
        const currentAverage = progressData.averageScore || 0;
        const newAverage = ((currentAverage * (newTotalQuizzes - 1)) + result.percentage) / newTotalQuizzes;

        transaction.update(progressRef, {
          totalQuizzes: newTotalQuizzes,
          averageScore: newAverage,
          lastStudyDate: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      logger.info(`Updated stats for user ${userId} after quiz completion`);
    } catch (error) {
      logger.error('Error updating user stats:', error);
    }
  });

/**
 * Simple user data update function
 */
export const updateUserData = onCall(async (request) => {
  const {data, auth} = request;
  if (!auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated');
  }

  const uid = auth.uid;
  const { credits, tier } = data;

  try {
    await db.collection('users').doc(uid).update({
      ...(credits !== undefined && { credits }),
      ...(tier !== undefined && { tier }),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true };
  } catch (error) {
    logger.error('Error updating user data:', error);
    throw new HttpsError('internal', 'Failed to update user data');
  }
});