/**
 * Schedule a notification for future delivery
 */
export declare const scheduleNotification: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    success: boolean;
    scheduleId: string;
    scheduledTime: Date;
}>>;
/**
 * Send immediate notification to user
 */
export declare const sendNotification: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    success: boolean;
    successfulDeliveries: number;
    totalTokens: any;
    recordId: string;
}>>;
/**
 * Get user's notification preferences
 */
export declare const getNotificationPreferences: import("firebase-functions/v2/https").CallableFunction<any, Promise<FirebaseFirestore.DocumentData | undefined>>;
/**
 * Update user's notification preferences
 */
export declare const updateNotificationPreferences: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    success: boolean;
}>>;
/**
 * Register device token for push notifications
 */
export declare const registerDeviceToken: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    success: boolean;
}>>;
/**
 * Unregister device token
 */
export declare const unregisterDeviceToken: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    success: boolean;
}>>;
/**
 * Get notification history for user
 */
export declare const getNotificationHistory: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    notifications: {
        id: string;
    }[];
}>>;
/**
 * Mark notification as read/opened
 */
export declare const markNotificationRead: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    success: boolean;
}>>;
export declare const processNotificationQueue: import("firebase-functions/v2/scheduler").ScheduleFunction;
