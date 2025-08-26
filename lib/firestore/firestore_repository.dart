import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:mindload/firestore/firestore_data_schema.dart';
import 'package:mindload/models/mindload_economy_models.dart';

/// Repository pattern for Firestore operations
/// Handles all database interactions for the CogniFlow app
class FirestoreRepository {
  static FirestoreRepository? _instance;
  static FirestoreRepository get instance {
    _instance ??= FirestoreRepository._internal();
    return _instance!;
  }

  FirestoreRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // MARK: - User Management

  /// Create or update user profile
  Future<void> createOrUpdateUser(UserProfileFirestore user) async {
    try {
      await _firestore
          .collection(FirestoreSchema.usersCollection)
          .doc(user.uid)
          .set(user.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to create/update user: $e');
    }
  }

  /// Get user profile
  Future<UserProfileFirestore?> getUser(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirestoreSchema.usersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserProfileFirestore.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  /// Update user's last login time
  Future<void> updateUserLastLogin(String userId) async {
    try {
      await _firestore
          .collection(FirestoreSchema.usersCollection)
          .doc(userId)
          .update({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user last login: $e');
    }
  }

  /// Delete user account and all associated data
  Future<void> deleteUser(String userId) async {
    final batch = _firestore.batch();

    try {
      if (kDebugMode) {
        print('🗑️ Starting Firestore data deletion for user: $userId');
      }

      // Delete user document
      batch.delete(
          _firestore.collection(FirestoreSchema.usersCollection).doc(userId));

      // Delete all user's study sets
      final studySets = await _firestore
          .collection(FirestoreSchema.studySetsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in studySets.docs) {
        batch.delete(doc.reference);
      }

      // Delete all user's quiz results
      final quizResults = await _firestore
          .collection(FirestoreSchema.quizResultsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in quizResults.docs) {
        batch.delete(doc.reference);
      }

      // Delete user progress
      batch.delete(_firestore
          .collection(FirestoreSchema.userProgressCollection)
          .doc(userId));

      // Delete credit usage data
      final creditUsage = await _firestore
          .collection(FirestoreSchema.creditUsageCollection)
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in creditUsage.docs) {
        batch.delete(doc.reference);
      }

      // Delete notification preferences
      batch.delete(_firestore
          .collection(FirestoreSchema.notificationsCollection)
          .doc(userId));

      // Delete user preferences (including promotional consent)
      batch.delete(_firestore.collection('user_preferences').doc(userId));

      // Delete promotional logs
      final promotionalLogs = await _firestore
          .collection('promotional_logs')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in promotionalLogs.docs) {
        batch.delete(doc.reference);
      }

      // Delete device tokens
      final deviceTokens = await _firestore
          .collection('device_tokens')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in deviceTokens.docs) {
        batch.delete(doc.reference);
      }

      // Delete any analytics or telemetry data
      final analyticsData = await _firestore
          .collection('user_analytics')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in analyticsData.docs) {
        batch.delete(doc.reference);
      }

      // Delete any subscription data
      final subscriptionData = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in subscriptionData.docs) {
        batch.delete(doc.reference);
      }

      // Commit all deletions
      await batch.commit();

      if (kDebugMode) {
        print('✅ Firestore data deletion completed for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to delete user data: $e');
      }
      throw Exception('Failed to delete user data: $e');
    }
  }

  // MARK: - Study Sets Management

  /// Create a new study set
  Future<void> createStudySet(StudySetFirestore studySet) async {
    try {
      await _firestore
          .collection(FirestoreSchema.studySetsCollection)
          .doc(studySet.id)
          .set(studySet.toFirestore());
    } catch (e) {
      throw Exception('Failed to create study set: $e');
    }
  }

  /// Get user's study sets ordered by last studied (most recent first)
  Stream<List<StudySetFirestore>> getUserStudySets(String userId) {
    return _firestore
        .collection(FirestoreSchema.studySetsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('lastStudied', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudySetFirestore.fromFirestore(doc))
            .toList());
  }

  /// Get a specific study set
  Future<StudySetFirestore?> getStudySet(String studySetId) async {
    try {
      final doc = await _firestore
          .collection(FirestoreSchema.studySetsCollection)
          .doc(studySetId)
          .get();

      if (doc.exists) {
        return StudySetFirestore.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get study set: $e');
    }
  }

  /// Update study set (mark as studied, add progress, etc.)
  Future<void> updateStudySet(
      String studySetId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore
          .collection(FirestoreSchema.studySetsCollection)
          .doc(studySetId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update study set: $e');
    }
  }

  /// Delete a study set
  Future<void> deleteStudySet(String studySetId) async {
    try {
      await _firestore
          .collection(FirestoreSchema.studySetsCollection)
          .doc(studySetId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete study set: $e');
    }
  }

  /// Update study set's last studied time
  Future<void> markStudySetAsStudied(String studySetId) async {
    try {
      await _firestore
          .collection(FirestoreSchema.studySetsCollection)
          .doc(studySetId)
          .update({
        'lastStudied': FieldValue.serverTimestamp(),
        'studyCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to mark study set as studied: $e');
    }
  }

  // MARK: - Quiz Results Management

  /// Save quiz result
  Future<void> saveQuizResult(QuizResultFirestore result) async {
    try {
      await _firestore
          .collection(FirestoreSchema.quizResultsCollection)
          .doc(result.id)
          .set(result.toFirestore());
    } catch (e) {
      throw Exception('Failed to save quiz result: $e');
    }
  }

  /// Get user's quiz results
  Stream<List<QuizResultFirestore>> getUserQuizResults(String userId,
      {int limit = 50}) {
    return _firestore
        .collection(FirestoreSchema.quizResultsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('completedDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QuizResultFirestore.fromFirestore(doc))
            .toList());
  }

  /// Get quiz results for a specific study set
  Future<List<QuizResultFirestore>> getStudySetQuizResults(
      String studySetId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestoreSchema.quizResultsCollection)
          .where('studySetId', isEqualTo: studySetId)
          .orderBy('completedDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => QuizResultFirestore.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get study set quiz results: $e');
    }
  }

  // MARK: - User Progress Management

  /// Get or create user progress
  Future<UserProgressFirestore> getUserProgress(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirestoreSchema.userProgressCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserProgressFirestore.fromFirestore(doc);
      } else {
        // Create new progress document
        final newProgress = UserProgressFirestore(
          userId: userId,
          currentStreak: 0,
          longestStreak: 0,
          totalXP: 0,
          totalStudyTime: 0,
          lastStudyDate: DateTime.now(),
          subjectXP: {},
        );
        await _firestore
            .collection(FirestoreSchema.userProgressCollection)
            .doc(userId)
            .set(newProgress.toFirestore());
        return newProgress;
      }
    } catch (e) {
      throw Exception('Failed to get user progress: $e');
    }
  }

  /// Update user progress
  Future<void> updateUserProgress(
      String userId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore
          .collection(FirestoreSchema.userProgressCollection)
          .doc(userId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update user progress: $e');
    }
  }

  /// Add XP and update user progress
  Future<void> addXP(String userId, int xpAmount, {String? subject}) async {
    try {
      final updates = <String, dynamic>{
        'totalXP': FieldValue.increment(xpAmount),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (subject != null) {
        updates['subjectXP.$subject'] = FieldValue.increment(xpAmount);
      }

      await _firestore
          .collection(FirestoreSchema.userProgressCollection)
          .doc(userId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to add XP: $e');
    }
  }

  /// Update user's study streak
  Future<void> updateStreak(
      String userId, int newStreak, int longestStreak) async {
    try {
      await _firestore
          .collection(FirestoreSchema.userProgressCollection)
          .doc(userId)
          .update({
        'currentStreak': newStreak,
        'longestStreak': longestStreak,
        'lastStudyDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update streak: $e');
    }
  }

  // MARK: - Credit Usage Management

  /// Get or create today's credit usage
  Future<CreditUsageFirestore> getTodaysCredits(String userId) async {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    try {
      final doc = await _firestore
          .collection(FirestoreSchema.creditUsageCollection)
          .doc('${userId}_$todayStr')
          .get();

      if (doc.exists) {
        return CreditUsageFirestore.fromFirestore(doc);
      } else {
        // Create today's credit document
        final newCredits = CreditUsageFirestore(
          userId: userId,
          date: today,
          creditsUsed: 0,
          dailyQuota: 20, // Default for free plan
          subscriptionPlan: 'free',
          transactions: [],
          remainingCredits: 20,
        );
        await _firestore
            .collection(FirestoreSchema.creditUsageCollection)
            .doc('${userId}_$todayStr')
            .set(newCredits.toFirestore());
        return newCredits;
      }
    } catch (e) {
      throw Exception('Failed to get today\'s credits: $e');
    }
  }

  /// Use credits for an AI operation
  Future<bool> useCredits(
      String userId, int creditsNeeded, String operation) async {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    try {
      final docRef = _firestore
          .collection(FirestoreSchema.creditUsageCollection)
          .doc('${userId}_$todayStr');

      return await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        CreditUsageFirestore credits;
        if (doc.exists) {
          credits = CreditUsageFirestore.fromFirestore(doc);
        } else {
          credits = CreditUsageFirestore(
            userId: userId,
            date: today,
            creditsUsed: 0,
            dailyQuota: 20,
            subscriptionPlan: 'free',
            transactions: [],
            remainingCredits: 20,
          );
        }

        if (credits.remainingCredits >= creditsNeeded) {
          // Update credits
          final updatedTransactions =
              List<Map<String, dynamic>>.from(credits.transactions);
          updatedTransactions.add({
            'operation': operation,
            'creditsUsed': creditsNeeded,
            'timestamp': FieldValue.serverTimestamp(),
          });

          final updatedCredits = CreditUsageFirestore(
            userId: credits.userId,
            date: credits.date,
            creditsUsed: credits.creditsUsed + creditsNeeded,
            dailyQuota: credits.dailyQuota,
            subscriptionPlan: credits.subscriptionPlan,
            transactions: updatedTransactions,
            remainingCredits: credits.remainingCredits - creditsNeeded,
            quotaResetTime: credits.quotaResetTime,
          );

          transaction.set(docRef, updatedCredits.toFirestore());
          return true;
        } else {
          return false; // Not enough credits
        }
      });
    } catch (e) {
      throw Exception('Failed to use credits: $e');
    }
  }

  /// Get credit usage history for a user
  Future<List<CreditUsageFirestore>> getCreditHistory(String userId,
      {int days = 30}) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      final snapshot = await _firestore
          .collection(FirestoreSchema.creditUsageCollection)
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CreditUsageFirestore.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get credit history: $e');
    }
  }

  /// Reset daily credits with custom amount (for admin accounts)
  Future<void> resetDailyCredits(String userId, int newQuota) async {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    try {
      final adminCredits = CreditUsageFirestore(
        userId: userId,
        date: today,
        creditsUsed: 0,
        dailyQuota: newQuota,
        subscriptionPlan: 'admin',
        transactions: [],
        remainingCredits: newQuota,
        quotaResetTime: DateTime.now().add(const Duration(days: 1)),
      );

      await _firestore
          .collection(FirestoreSchema.creditUsageCollection)
          .doc('${userId}_$todayStr')
          .set(adminCredits.toFirestore());
    } catch (e) {
      throw Exception('Failed to reset daily credits: $e');
    }
  }

  // MARK: - Notification Management

  /// Get or create notification preferences
  Future<NotificationFirestore> getNotificationPreferences(
      String userId) async {
    try {
      final doc = await _firestore
          .collection(FirestoreSchema.notificationsCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return NotificationFirestore.fromFirestore(doc);
      } else {
        // Create default notification preferences
        final defaultPrefs = NotificationFirestore(userId: userId);
        await _firestore
            .collection(FirestoreSchema.notificationsCollection)
            .doc(userId)
            .set(defaultPrefs.toFirestore());
        return defaultPrefs;
      }
    } catch (e) {
      throw Exception('Failed to get notification preferences: $e');
    }
  }

  /// Update notification preferences
  Future<void> updateNotificationPreferences(
      String userId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore
          .collection(FirestoreSchema.notificationsCollection)
          .doc(userId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update notification preferences: $e');
    }
  }

  /// Add device token for push notifications
  Future<void> addDeviceToken(String userId, String deviceToken) async {
    try {
      final docRef = _firestore
          .collection(FirestoreSchema.notificationsCollection)
          .doc(userId);
      // Use set with merge to create the doc if it doesn't exist
      await docRef.set({
        'deviceTokens': FieldValue.arrayUnion([deviceToken]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to add device token: $e');
    }
  }

  /// Remove device token
  Future<void> removeDeviceToken(String userId, String deviceToken) async {
    try {
      final docRef = _firestore
          .collection(FirestoreSchema.notificationsCollection)
          .doc(userId);
      // If the document doesn't exist, there's nothing to remove; ignore
      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        return;
      }
      await docRef.update({
        'deviceTokens': FieldValue.arrayRemove([deviceToken]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to remove device token: $e');
    }
  }

  // MARK: - Utility Methods

  /// Check if Firestore is available and connected
  Future<bool> isConnected() async {
    try {
      await _firestore.doc('test/connection').get();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Enable offline persistence
  Future<void> enableOfflinePersistence() async {
    try {
      // Offline persistence is enabled by default on mobile
      // For web, you can uncomment the line below if needed
      // await _firestore.enablePersistence();
      if (kDebugMode) {
        debugPrint('Offline persistence is enabled by default');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to enable offline persistence: $e');
      }
    }
  }

  /// Clear offline persistence
  Future<void> clearPersistence() async {
    try {
      await _firestore.clearPersistence();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to clear persistence: $e');
      }
    }
  }

  // MARK: - Mindload Economy System

  /// Get user's economy data
  Future<MindloadUserEconomy?> getUserEconomy(String userId) async {
    try {
      final doc =
          await _firestore.collection('mindload_economy').doc(userId).get();

      if (doc.exists) {
        return MindloadUserEconomy.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user economy: $e');
    }
  }

  /// Update user's economy data
  Future<void> updateUserEconomy(MindloadUserEconomy economy) async {
    try {
      await _firestore
          .collection('mindload_economy')
          .doc(economy.userId)
          .set(economy.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update user economy: $e');
    }
  }

  /// Get global budget controller state
  Future<MindloadBudgetController?> getBudgetController() async {
    try {
      final doc = await _firestore
          .collection('mindload_system')
          .doc('budget_controller')
          .get();

      if (doc.exists) {
        return MindloadBudgetController.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get budget controller: $e');
    }
  }

  /// Update global budget controller state
  Future<void> updateBudgetController(
      MindloadBudgetController controller) async {
    try {
      await _firestore
          .collection('mindload_system')
          .doc('budget_controller')
          .set(controller.toJson());
    } catch (e) {
      throw Exception('Failed to update budget controller: $e');
    }
  }

  // MARK: - User Entitlements Management

  /// Get user entitlements
  Future<Map<String, dynamic>?> getUserEntitlements(String userId) async {
    try {
      final doc =
          await _firestore.collection('user_entitlements').doc(userId).get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user entitlements: $e');
    }
  }

  /// Save user entitlements
  Future<void> saveUserEntitlements(
      String userId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('user_entitlements')
          .doc(userId)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save user entitlements: $e');
    }
  }

  /// Record budget usage transaction
  Future<void> recordBudgetUsage(
      String userId, double costUsd, String operation) async {
    try {
      await _firestore.collection('mindload_budget_usage').add({
        'userId': userId,
        'costUsd': costUsd,
        'operation': operation,
        'timestamp': FieldValue.serverTimestamp(),
        'month': DateTime.now().toIso8601String().substring(0, 7), // YYYY-MM
      });
    } catch (e) {
      throw Exception('Failed to record budget usage: $e');
    }
  }

  /// Get monthly budget usage
  Future<double> getMonthlyBudgetUsage([String? month]) async {
    try {
      final targetMonth =
          month ?? DateTime.now().toIso8601String().substring(0, 7);

      final snapshot = await _firestore
          .collection('mindload_budget_usage')
          .where('month', isEqualTo: targetMonth)
          .get();

      double totalUsage = 0.0;
      for (var doc in snapshot.docs) {
        totalUsage += doc.data()['costUsd'] as double? ?? 0.0;
      }

      return totalUsage;
    } catch (e) {
      throw Exception('Failed to get monthly budget usage: $e');
    }
  }
}
