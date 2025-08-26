import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import { getMessaging } from 'firebase-admin/messaging';
import { initializeApp, getApp } from 'firebase-admin/app';

// Initialize Firebase Admin
try {
  getApp();
} catch {
  initializeApp();
}

const db = getFirestore();
const auth = getAuth();
const messaging = getMessaging();

// Notification scheduling and delivery functions

/**
 * Schedule a notification for future delivery
 */
export const scheduleNotification = onCall(
  { 
    maxInstances: 10,
    timeoutSeconds: 60,
    memory: '256MiB'
  },
  async (request) => {
    try {
      const { uid, title, body, scheduledTime, style, category, deepLink, metadata } = request.data;
      
      if (!uid || !title || !body || !scheduledTime) {
        throw new HttpsError('invalid-argument', 'Missing required fields');
      }

      // Validate scheduled time (must be in the future)
      const scheduledDate = new Date(scheduledTime);
      if (scheduledDate <= new Date()) {
        throw new HttpsError('invalid-argument', 'Scheduled time must be in the future');
      }

      // Create notification schedule document
      const scheduleRef = await db.collection('notification_schedules').add({
        uid,
        title,
        body,
        scheduledTime: scheduledDate,
        style: style || 'coach',
        category: category || 'studyNow',
        deepLink,
        metadata,
        status: 'scheduled',
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp()
      });

      logger.info(`Notification scheduled for user ${uid} at ${scheduledDate}`, {
        scheduleId: scheduleRef.id,
        uid,
        scheduledTime: scheduledDate
      });

      return {
        success: true,
        scheduleId: scheduleRef.id,
        scheduledTime: scheduledDate
      };

    } catch (error) {
      logger.error('Error scheduling notification:', error);
      throw new HttpsError('internal', 'Failed to schedule notification');
    }
  }
);

/**
 * Send immediate notification to user
 */
export const sendNotification = onCall(
  { 
    maxInstances: 20,
    timeoutSeconds: 30,
    memory: '256MiB'
  },
  async (request) => {
    try {
      const { uid, title, body, style, category, deepLink, metadata, priority } = request.data;
      
      if (!uid || !title || !body) {
        throw new HttpsError('invalid-argument', 'Missing required fields');
      }

      // Get user's notification preferences
      const userPrefs = await db.collection('user_notification_preferences').doc(uid).get();
      if (!userPrefs.exists) {
        throw new HttpsError('not-found', 'User notification preferences not found');
      }

      const prefs = userPrefs.data()!;
      
      // Check if notifications are enabled for this category
      if (category && prefs.enabledCategories && !prefs.enabledCategories.includes(category)) {
        throw new HttpsError('permission-denied', 'Notifications disabled for this category');
      }

      // Check frequency limits
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);

      const todayNotifications = await db.collection('notification_records')
        .where('uid', '==', uid)
        .where('sentAt', '>=', today)
        .where('sentAt', '<', tomorrow)
        .count()
        .get();

      if (todayNotifications.data().count >= prefs.frequencyPerDay) {
        throw new HttpsError('resource-exhausted', 'Daily notification limit reached');
      }

      // Check quiet hours
      if (prefs.quietHours && prefs.quietStart && prefs.quietEnd) {
        const now = new Date();
        const currentTime = now.getHours() * 60 + now.getMinutes();
        const startTime = prefs.quietStart.hour * 60 + prefs.quietStart.minute;
        const endTime = prefs.quietEnd.hour * 60 + prefs.quietEnd.minute;
        
        if (startTime <= endTime) {
          if (currentTime >= startTime && currentTime <= endTime) {
            throw new HttpsError('permission-denied', 'Quiet hours active');
          }
        } else {
          // Quiet hours span midnight
          if (currentTime >= startTime || currentTime <= endTime) {
            throw new HttpsError('permission-denied', 'Quiet hours active');
          }
        }
      }

      // Get user's device tokens
      const userDoc = await db.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        throw new HttpsError('not-found', 'User not found');
      }

      const userData = userDoc.data()!;
      const deviceTokens = userData.deviceTokens || [];

      if (deviceTokens.length === 0) {
        throw new HttpsError('failed-precondition', 'No device tokens found for user');
      }

      // Send push notification
      const message = {
        notification: {
          title,
          body
        },
        data: {
          category: category || 'studyNow',
          style: style || 'coach',
          deepLink: deepLink || '',
          metadata: metadata ? JSON.stringify(metadata) : '',
          timestamp: Date.now().toString()
        },
        android: {
          priority: (priority === 'high' ? 'high' : 'normal') as 'high' | 'normal',
          notification: {
            channelId: _getChannelId(category || 'studyNow'),
            priority: (priority === 'high' ? 'max' : 'default') as 'max' | 'default'
          }
        },
        apns: {
          payload: {
            aps: {
              category: category || 'studyNow',
              'mutable-content': 1
            }
          }
        },
        tokens: deviceTokens
      };

      const response = await messaging.sendMulticast(message);
      
      // Record successful deliveries
      const successfulTokens = response.responses
        .map((resp, idx) => resp.success ? deviceTokens[idx] : null)
        .filter(token => token !== null);

      // Record notification in history
      const notificationRecordRef = await db.collection('notification_records').add({
        uid,
        title,
        body,
        style: style || 'coach',
        category: category || 'studyNow',
        sentAt: FieldValue.serverTimestamp(),
        deepLink,
        metadata,
        platform: 'firebase',
        deliveryStatus: 'sent',
        successfulTokens,
        failedTokens: deviceTokens.filter((token: string) => !successfulTokens.includes(token))
      });

      // Update user's notification analytics
      await _updateNotificationAnalytics(uid, category || 'studyNow', style || 'coach');

      logger.info(`Notification sent to user ${uid}`, {
        uid,
        title,
        successfulDeliveries: successfulTokens.length,
        totalTokens: deviceTokens.length
      });

              return {
          success: true,
          successfulDeliveries: successfulTokens.length,
          totalTokens: deviceTokens.length,
          recordId: notificationRecordRef.id
        };

    } catch (error) {
      logger.error('Error sending notification:', error);
      throw new HttpsError('internal', 'Failed to send notification');
    }
  }
);

/**
 * Get user's notification preferences
 */
export const getNotificationPreferences = onCall(
  { 
    maxInstances: 10,
    timeoutSeconds: 30,
    memory: '256MiB'
  },
  async (request) => {
    try {
      const { uid } = request.data;
      
      if (!uid) {
        throw new HttpsError('invalid-argument', 'User ID required');
      }

      const prefsDoc = await db.collection('user_notification_preferences').doc(uid).get();
      
      if (!prefsDoc.exists) {
        // Create default preferences
        const defaultPrefs = _createDefaultPreferences(uid);
        await db.collection('user_notification_preferences').doc(uid).set(defaultPrefs);
        return defaultPrefs;
      }

      return prefsDoc.data();

    } catch (error) {
      logger.error('Error getting notification preferences:', error);
      throw new HttpsError('internal', 'Failed to get notification preferences');
    }
  }
);

/**
 * Update user's notification preferences
 */
export const updateNotificationPreferences = onCall(
  { 
    maxInstances: 10,
    timeoutSeconds: 30,
    memory: '256MiB'
  },
  async (request) => {
    try {
      const { uid, updates } = request.data;
      
      if (!uid || !updates) {
        throw new HttpsError('invalid-argument', 'User ID and updates required');
      }

      const updateData = {
        ...updates,
        updatedAt: FieldValue.serverTimestamp()
      };

      await db.collection('user_notification_preferences').doc(uid).update(updateData);

      logger.info(`Notification preferences updated for user ${uid}`);

      return { success: true };

    } catch (error) {
      logger.error('Error updating notification preferences:', error);
      throw new HttpsError('internal', 'Failed to update notification preferences');
    }
  }
);

/**
 * Register device token for push notifications
 */
export const registerDeviceToken = onCall(
  { 
    maxInstances: 20,
    timeoutSeconds: 30,
    memory: '256MiB'
  },
  async (request) => {
    try {
      const { uid, deviceToken, platform } = request.data;
      
      if (!uid || !deviceToken) {
        throw new HttpsError('invalid-argument', 'User ID and device token required');
      }

      // Add token to user's device tokens
      await db.collection('users').doc(uid).update({
        deviceTokens: FieldValue.arrayUnion([deviceToken]),
        [`deviceTokens.${deviceToken}`]: {
          platform: platform || 'unknown',
          registeredAt: FieldValue.serverTimestamp(),
          lastSeen: FieldValue.serverTimestamp()
        }
      });

      logger.info(`Device token registered for user ${uid}`);

      return { success: true };

    } catch (error) {
      logger.error('Error registering device token:', error);
      throw new HttpsError('internal', 'Failed to register device token');
    }
  }
);

/**
 * Unregister device token
 */
export const unregisterDeviceToken = onCall(
  { 
    maxInstances: 20,
    timeoutSeconds: 30,
    memory: '256MiB'
  },
  async (request) => {
    try {
      const { uid, deviceToken } = request.data;
      
      if (!uid || !deviceToken) {
        throw new HttpsError('invalid-argument', 'User ID and device token required');
      }

      // Remove token from user's device tokens
      await db.collection('users').doc(uid).update({
        deviceTokens: FieldValue.arrayRemove([deviceToken])
      });

      logger.info(`Device token unregistered for user ${uid}`);

      return { success: true };

    } catch (error) {
      logger.error('Error unregistering device token:', error);
      throw new HttpsError('internal', 'Failed to unregister device token');
    }
  }
);

/**
 * Get notification history for user
 */
export const getNotificationHistory = onCall(
  { 
    maxInstances: 10,
    timeoutSeconds: 30,
    memory: '256MiB'
  },
  async (request) => {
    try {
      const { uid, limit = 50, offset = 0 } = request.data;
      
      if (!uid) {
        throw new HttpsError('invalid-argument', 'User ID required');
      }

      const notificationsQuery = await db.collection('notification_records')
        .where('uid', '==', uid)
        .orderBy('sentAt', 'desc')
        .limit(limit)
        .offset(offset)
        .get();

      const notifications = notificationsQuery.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));

      return { notifications };

    } catch (error) {
      logger.error('Error getting notification history:', error);
      throw new HttpsError('internal', 'Failed to get notification history');
    }
  }
);

/**
 * Mark notification as read/opened
 */
export const markNotificationRead = onCall(
  { 
    maxInstances: 20,
    timeoutSeconds: 30,
    memory: '256MiB'
  },
  async (request) => {
    try {
      const { notificationId } = request.data;
      
      if (!notificationId) {
        throw new HttpsError('invalid-argument', 'Notification ID required');
      }

      await db.collection('notification_records').doc(notificationId).update({
        openedAt: FieldValue.serverTimestamp(),
        status: 'read'
      });

      return { success: true };

    } catch (error) {
      logger.error('Error marking notification as read:', error);
      throw new HttpsError('internal', 'Failed to mark notification as read');
    }
  }
);

// Scheduled function to process notification queue
export const processNotificationQueue = onSchedule(
  {
    schedule: 'every 1 minutes',
    region: 'us-central1',
    timeoutSeconds: 300,
    memory: '512MiB'
  },
  async (event) => {
    try {
      logger.info('Processing notification queue...');
      
      const now = new Date();
      const fiveMinutesFromNow = new Date(now.getTime() + 5 * 60 * 1000);

      // Get notifications scheduled for the next 5 minutes
      // Using a simpler query that doesn't require complex indexing
      const scheduledNotifications = await db.collection('notification_schedules')
        .where('status', '==', 'scheduled')
        .get();
      
      // Filter by time in memory to avoid complex index requirements
      const readyNotifications = scheduledNotifications.docs.filter(doc => {
        const scheduledTime = doc.data().scheduledTime?.toDate?.() || new Date(doc.data().scheduledTime);
        return scheduledTime <= fiveMinutesFromNow;
      });

      logger.info(`Found ${scheduledNotifications.size} total scheduled notifications, ${readyNotifications.length} ready to process`);

      for (const doc of readyNotifications) {
        const notification = doc.data();
        
        try {
          // Send the notification
          await _sendScheduledNotification(notification);
          
          // Mark as sent
          await doc.ref.update({
            status: 'sent',
            sentAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp()
          });

          logger.info(`Scheduled notification sent: ${doc.id}`);
        } catch (error) {
          logger.error(`Failed to send scheduled notification ${doc.id}:`, error);
          
          // Mark as failed
          await doc.ref.update({
            status: 'failed',
            error: error instanceof Error ? error.message : 'Unknown error',
            updatedAt: FieldValue.serverTimestamp()
          });
        }
      }

    } catch (error) {
      logger.error('Error processing notification queue:', error);
    }
  }
);

// Helper functions

function _getChannelId(category: string): string {
  switch (category) {
    case 'examAlert':
      return 'deadlines';
    case 'popQuiz':
      return 'pop_quiz';
    case 'achievement':
      return 'achievements';
    case 'system':
      return 'system';
    default:
      return 'study_reminders';
  }
}

function _createDefaultPreferences(uid: string) {
  return {
    uid,
    notificationStyle: 'coach',
    frequencyPerDay: 5,
    enabledCategories: ['studyNow', 'streakSave', 'examAlert', 'achievement'],
    selectedDayparts: ['morning', 'afternoon', 'evening'],
    quietHours: true,
    quietStart: { hour: 22, minute: 0 },
    quietEnd: { hour: 7, minute: 0 },
    eveningDigest: true,
    digestTime: { hour: 20, minute: 30 },
    timezone: 'America/Chicago',
    exams: [],
    analytics: {
      totalSent: 0,
      totalOpened: 0,
      lastSent: null,
      lastOpened: null
    },
    pushTokens: [],
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp()
  };
}

async function _sendScheduledNotification(notification: any) {
  const { uid, title, body, style, category, deepLink, metadata } = notification;

  // Get user's device tokens
  const userDoc = await db.collection('users').doc(uid).get();
  if (!userDoc.exists) {
    throw new Error('User not found');
  }

  const userData = userDoc.data()!;
  const deviceTokens = userData.deviceTokens || [];

  if (deviceTokens.length === 0) {
    throw new Error('No device tokens found');
  }

  // Send push notification
  const message = {
    notification: { title, body },
    data: {
      category: category || 'studyNow',
      style: style || 'coach',
      deepLink: deepLink || '',
      metadata: metadata ? JSON.stringify(metadata) : '',
      timestamp: Date.now().toString()
    },
    android: {
      notification: {
        channelId: _getChannelId(category || 'studyNow')
      }
    },
    tokens: deviceTokens
  };

  await messaging.sendMulticast(message);
}

async function _updateNotificationAnalytics(uid: string, category: string, style: string) {
  const prefsRef = db.collection('user_notification_preferences').doc(uid);
  
  await prefsRef.update({
    'analytics.totalSent': FieldValue.increment(1),
    'analytics.lastSent': FieldValue.serverTimestamp(),
    [`analytics.categoryBreakdown.${category}`]: FieldValue.increment(1),
    [`analytics.styleBreakdown.${style}`]: FieldValue.increment(1)
  });
}
