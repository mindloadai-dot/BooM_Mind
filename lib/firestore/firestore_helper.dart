import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase Helper Utilities for Mindload App
/// 
/// Provides utility functions for common Firebase operations,
/// error handling, and data transformations.
class FirestoreHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // MARK: - Error Handling

  /// Handle Firestore errors with user-friendly messages
  static String handleFirestoreError(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'You don\'t have permission to access this data';
        case 'unavailable':
          return 'Service is currently unavailable. Please try again later';
        case 'deadline-exceeded':
          return 'Request timed out. Please check your internet connection';
        case 'resource-exhausted':
          return 'Too many requests. Please try again in a moment';
        case 'failed-precondition':
          return 'Operation failed. Please refresh and try again';
        case 'aborted':
          return 'Operation was interrupted. Please try again';
        case 'out-of-range':
          return 'Invalid request parameters';
        case 'unimplemented':
          return 'This feature is not yet implemented';
        case 'internal':
          return 'Internal server error. Please try again later';
        case 'not-found':
          return 'Requested data not found';
        case 'already-exists':
          return 'This data already exists';
        case 'invalid-argument':
          return 'Invalid data provided';
        case 'unauthenticated':
          return 'Please sign in to continue';
        default:
          return 'An unexpected error occurred: ${error.message}';
      }
    }
    return 'An unexpected error occurred: ${error.toString()}';
  }

  // MARK: - Data Transformation

  /// Convert Timestamp to DateTime safely
  static DateTime? timestampToDateTime(dynamic timestamp) {
    if (timestamp == null) return null;
    
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    
    if (timestamp is DateTime) {
      return timestamp;
    }
    
    return null;
  }

  /// Convert DateTime to Timestamp
  static Timestamp? dateTimeToTimestamp(DateTime? dateTime) {
    return dateTime != null ? Timestamp.fromDate(dateTime) : null;
  }

  /// Safely get string value from document data
  static String safeGetString(Map<String, dynamic> data, String key, [String defaultValue = '']) {
    final value = data[key];
    return value is String ? value : defaultValue;
  }

  /// Safely get int value from document data
  static int safeGetInt(Map<String, dynamic> data, String key, [int defaultValue = 0]) {
    final value = data[key];
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Safely get double value from document data
  static double safeGetDouble(Map<String, dynamic> data, String key, [double defaultValue = 0.0]) {
    final value = data[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Safely get bool value from document data
  static bool safeGetBool(Map<String, dynamic> data, String key, [bool defaultValue = false]) {
    final value = data[key];
    return value is bool ? value : defaultValue;
  }

  /// Safely get List value from document data
  static List<T> safeGetList<T>(Map<String, dynamic> data, String key, [List<T> defaultValue = const []]) {
    final value = data[key];
    if (value is List) {
      return value.cast<T>();
    }
    return List<T>.from(defaultValue);
  }

  /// Safely get Map value from document data
  static Map<String, dynamic> safeGetMap(Map<String, dynamic> data, String key, [Map<String, dynamic> defaultValue = const {}]) {
    final value = data[key];
    if (value is Map<String, dynamic>) {
      return value;
    }
    return Map<String, dynamic>.from(defaultValue);
  }

  // MARK: - Query Builders

  /// Build query for user-specific data
  static Query<Map<String, dynamic>> buildUserQuery(String collection, String userId) {
    return _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId);
  }

  /// Build query with pagination
  static Query<Map<String, dynamic>> buildPaginatedQuery(
    String collection, 
    String orderByField, {
    bool descending = true,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(collection)
        .orderBy(orderByField, descending: descending)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query;
  }

  /// Build compound query for user data with ordering
  static Query<Map<String, dynamic>> buildUserOrderedQuery(
    String collection,
    String userId,
    String orderByField, {
    bool descending = true,
    int limit = 50,
  }) {
    return _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .orderBy(orderByField, descending: descending)
        .limit(limit);
  }

  // MARK: - Batch Operations

  /// Create a new batch for multiple operations
  static WriteBatch createBatch() {
    return _firestore.batch();
  }

  /// Execute batch with error handling
  static Future<bool> executeBatch(WriteBatch batch) async {
    try {
      await batch.commit();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Batch operation failed: ${handleFirestoreError(e)}');
      }
      return false;
    }
  }

  // MARK: - Transaction Helpers

  /// Execute a transaction with retry logic
  static Future<T?> executeTransaction<T>(
    Future<T> Function(Transaction transaction) updateFunction, {
    int maxAttempts = 5,
  }) async {
    int attempts = 0;
    
    while (attempts < maxAttempts) {
      try {
        return await _firestore.runTransaction(updateFunction);
      } catch (e) {
        attempts++;
        if (attempts >= maxAttempts) {
          if (kDebugMode) {
            debugPrint('Transaction failed after $maxAttempts attempts: ${handleFirestoreError(e)}');
          }
          return null;
        }
        
        // Exponential backoff
        await Future.delayed(Duration(milliseconds: 100 * attempts));
      }
    }
    
    return null;
  }

  // MARK: - Cache Management

  /// Clear Firestore cache
  static Future<void> clearCache() async {
    try {
      await _firestore.clearPersistence();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to clear Firestore cache: $e');
      }
    }
  }

  /// Enable offline persistence
  static Future<void> enableOfflinePersistence() async {
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

  /// Disable network (for testing offline functionality)
  static Future<void> disableNetwork() async {
    try {
      await _firestore.disableNetwork();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to disable network: $e');
      }
    }
  }

  /// Enable network
  static Future<void> enableNetwork() async {
    try {
      await _firestore.enableNetwork();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to enable network: $e');
      }
    }
  }

  // MARK: - Document Utilities

  /// Check if document exists
  static Future<bool> documentExists(String collection, String documentId) async {
    try {
      final doc = await _firestore.collection(collection).doc(documentId).get();
      return doc.exists;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to check document existence: ${handleFirestoreError(e)}');
      }
      return false;
    }
  }

  /// Get document with error handling
  static Future<DocumentSnapshot?> getDocument(String collection, String documentId) async {
    try {
      return await _firestore.collection(collection).doc(documentId).get();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to get document: ${handleFirestoreError(e)}');
      }
      return null;
    }
  }

  /// Update document with merge option
  static Future<bool> updateDocument(
    String collection, 
    String documentId, 
    Map<String, dynamic> data, {
    bool merge = true,
  }) async {
    try {
      await _firestore
          .collection(collection)
          .doc(documentId)
          .set(data, SetOptions(merge: merge));
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to update document: ${handleFirestoreError(e)}');
      }
      return false;
    }
  }

  /// Delete document with error handling
  static Future<bool> deleteDocument(String collection, String documentId) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to delete document: ${handleFirestoreError(e)}');
      }
      return false;
    }
  }

  // MARK: - Authentication Helpers

  /// Get current user ID
  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Check if user is authenticated
  static bool isUserAuthenticated() {
    return _auth.currentUser != null;
  }

  /// Get current user email
  static String? getCurrentUserEmail() {
    return _auth.currentUser?.email;
  }

  // MARK: - Field Value Helpers

  /// Create server timestamp
  static FieldValue serverTimestamp() {
    return FieldValue.serverTimestamp();
  }

  /// Create increment value
  static FieldValue increment(num value) {
    return FieldValue.increment(value);
  }

  /// Create array union
  static FieldValue arrayUnion(List elements) {
    return FieldValue.arrayUnion(elements);
  }

  /// Create array remove
  static FieldValue arrayRemove(List elements) {
    return FieldValue.arrayRemove(elements);
  }

  /// Create delete field value
  static FieldValue deleteField() {
    return FieldValue.delete();
  }

  // MARK: - Security Rules Helpers

  /// Validate user ownership of document
  static bool validateUserOwnership(Map<String, dynamic> documentData, String userId) {
    final docUserId = documentData['userId'];
    return docUserId == userId;
  }

  /// Validate required fields
  static bool validateRequiredFields(Map<String, dynamic> data, List<String> requiredFields) {
    for (final field in requiredFields) {
      if (!data.containsKey(field) || data[field] == null) {
        return false;
      }
    }
    return true;
  }

  // MARK: - Performance Helpers

  /// Log query performance
  static void logQueryPerformance(String queryName, DateTime startTime) {
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    if (kDebugMode) {
      debugPrint('Query "$queryName" took ${duration.inMilliseconds}ms');
    }
  }

  /// Create optimized listener with error handling
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>> createOptimizedListener(
    Query<Map<String, dynamic>> query,
    void Function(QuerySnapshot<Map<String, dynamic>>) onData, {
    void Function(FirebaseException)? onError,
    bool includeMetadataChanges = false,
  }) {
    return query.snapshots(includeMetadataChanges: includeMetadataChanges).listen(
      onData,
      onError: onError ?? (error) {
        if (kDebugMode) {
          debugPrint('Stream error: ${handleFirestoreError(error)}');
        }
      },
    );
  }
}

/// Extension methods for Firestore operations
extension DocumentSnapshotExtensions on DocumentSnapshot {
  /// Safely get data with null check
  Map<String, dynamic>? get safeData {
    return exists ? data() as Map<String, dynamic>? : null;
  }

  /// Get field value safely
  T? getField<T>(String field) {
    final data = safeData;
    if (data == null || !data.containsKey(field)) return null;
    
    final value = data[field];
    return value is T ? value : null;
  }
}

extension QuerySnapshotExtensions on QuerySnapshot {
  /// Check if snapshot has real data changes (not just metadata)
  bool get hasRealChanges {
    return docChanges.any((change) => !change.doc.metadata.hasPendingWrites);
  }

  /// Get documents that are not from cache
  List<DocumentSnapshot> get freshDocuments {
    return docs.where((doc) => !doc.metadata.isFromCache).toList();
  }
}