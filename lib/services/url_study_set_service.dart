import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mindload/services/unified_storage_service.dart';

/// Service for generating study sets from URLs
/// Handles the complete flow from URL input to offline-ready study set
class UrlStudySetService {
  static final UrlStudySetService _instance = UrlStudySetService._internal();
  factory UrlStudySetService() => _instance;
  static UrlStudySetService get instance => _instance;
  UrlStudySetService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Generate a study set from a URL
  /// Returns the study set ID and metadata for offline sync
  Future<Map<String, dynamic>> generateStudySetFromUrl({
    required String url,
    String? title,
    int maxItems = 50,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      debugPrint('🚀 Starting study set generation for URL: $url');

      // Call the Firebase Function
      final callable = _functions.httpsCallable('generateStudySetFromUrl');
      final result = await callable.call({
        'url': url,
        'userId': user.uid,
        'title': title,
        'maxItems': maxItems,
      });

      final data = result.data as Map<String, dynamic>;

      if (data['success'] == true) {
        debugPrint('✅ Study set generated successfully: ${data['studySetId']}');

        // Save the generated items locally using unified storage
        final items = data['items'] as List<dynamic>?;
        if (items != null) {
          await UnifiedStorageService.instance.saveStudySetFromUrl(
            studySetId: data['studySetId'],
            title: data['title'],
            sourceUrl: url,
            preview: data['preview'],
            itemCount: data['itemCount'],
            userId: user.uid,
            items: items.cast<Map<String, dynamic>>(),
          );
        }

        return data;
      } else {
        throw Exception('Failed to generate study set');
      }
    } catch (e) {
      debugPrint('❌ Error generating study set: $e');
      rethrow;
    }
  }

  /// Preview URL content before generation
  /// Returns basic metadata about the URL content
  Future<Map<String, dynamic>> previewUrlContent(String url) async {
    try {
      debugPrint('🔍 Previewing URL content: $url');

      // For now, we'll do a basic validation
      // In a full implementation, you might want a separate preview function
      final uri = Uri.parse(url);
      if (!uri.hasScheme || !uri.hasAuthority) {
        throw Exception('Invalid URL format');
      }

      // Return basic preview info
      return {
        'url': url,
        'domain': uri.host,
        'isValid': true,
        'estimatedProcessingTime': '2-5 minutes',
        'estimatedItems': '40-60 items',
      };
    } catch (e) {
      debugPrint('❌ Error previewing URL: $e');
      rethrow;
    }
  }

  /// Sync study set to offline storage
  /// Downloads the study set and all items for offline use
  /// Note: This is now handled automatically in generateStudySetFromUrl
  Future<void> _syncStudySetToOffline(String studySetId) async {
    try {
      debugPrint('📱 Syncing study set to offline storage: $studySetId');

      // This method is now deprecated as items are saved locally
      // immediately after generation in generateStudySetFromUrl
      // Keeping for backward compatibility

      debugPrint('✅ Study set already synced for offline use: $studySetId');
    } catch (e) {
      debugPrint('❌ Error syncing study set to offline: $e');
    }
  }

  /// Get generation status
  /// Check if a study set is still being generated
  Future<Map<String, dynamic>> getGenerationStatus(String studySetId) async {
    try {
      // This would check the Firestore document to see if generation is complete
      // For now, we'll return a basic status
      return {
        'studySetId': studySetId,
        'status': 'completed',
        'completedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Error getting generation status: $e');
      rethrow;
    }
  }

  /// Cancel generation (if supported)
  Future<bool> cancelGeneration(String studySetId) async {
    try {
      debugPrint('❌ Canceling generation: $studySetId');
      // This would cancel the generation process
      // For now, we'll just return true
      return true;
    } catch (e) {
      debugPrint('❌ Error canceling generation: $e');
      return false;
    }
  }
}
