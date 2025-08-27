import 'dart:developer' as developer;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindload/services/achievement_service.dart';
import 'package:mindload/models/achievement_models.dart';

/// Achievement Tracker Service - Local Storage
/// Handles tracking user actions and updating achievement progress
/// All tracking data is stored locally using SharedPreferences
class AchievementTrackerService {
  static final AchievementTrackerService _instance =
      AchievementTrackerService._internal();
  static AchievementTrackerService get instance => _instance;
  AchievementTrackerService._internal();

  static const String _trackingDataKey = 'achievement_tracking_data';
  bool _isInitialized = false;

  // Tracking state
  int _currentStreak = 0;
  int _totalStudyMinutes = 0;
  int _totalCardsCreated = 0;
  int _totalCardsReviewed = 0;
  int _quizzes85PercentOrHigher = 0;
  int _fivePerWeekCounter = 0;
  int _distractionFreeSessionsCount = 0;
  int _totalSetsMade = 0;
  int _efficientSetsInWindow = 0;
  int _ultraSessionsCount = 0;
  int _totalExports = 0;

  /// Initialize tracker with local data
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadTrackingData();
      _isInitialized = true;
      developer.log('Achievement tracker initialized with local data',
          name: 'AchievementTracker');
    } catch (e) {
      developer.log('Failed to initialize achievement tracker: $e',
          name: 'AchievementTracker', level: 900);
      _isInitialized = true; // Continue with default values
    }
  }

  /// Load tracking data from local storage
  Future<void> _loadTrackingData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trackingJson = prefs.getString(_trackingDataKey);

      if (trackingJson != null) {
        final trackingData = jsonDecode(trackingJson) as Map<String, dynamic>;
        _currentStreak = trackingData['currentStreak'] ?? 0;
        _totalStudyMinutes = trackingData['totalStudyMinutes'] ?? 0;
        _totalCardsCreated = trackingData['totalCardsCreated'] ?? 0;
        _totalCardsReviewed = trackingData['totalCardsReviewed'] ?? 0;
        _quizzes85PercentOrHigher =
            trackingData['quizzes85PercentOrHigher'] ?? 0;
        _fivePerWeekCounter = trackingData['fivePerWeekCounter'] ?? 0;
        _distractionFreeSessionsCount =
            trackingData['distractionFreeSessionsCount'] ?? 0;
        _totalSetsMade = trackingData['totalSetsMade'] ?? 0;
        _efficientSetsInWindow = trackingData['efficientSetsInWindow'] ?? 0;
        _ultraSessionsCount = trackingData['ultraSessionsCount'] ?? 0;
        _totalExports = trackingData['totalExports'] ?? 0;

        developer.log('Loaded tracking data from local storage',
            name: 'AchievementTracker');
      }
    } catch (e) {
      developer.log('Failed to load tracking data: $e',
          name: 'AchievementTracker', level: 900);
    }
  }

  /// Save tracking data to local storage
  Future<void> _saveTrackingData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trackingData = {
        'currentStreak': _currentStreak,
        'totalStudyMinutes': _totalStudyMinutes,
        'totalCardsCreated': _totalCardsCreated,
        'totalCardsReviewed': _totalCardsReviewed,
        'quizzes85PercentOrHigher': _quizzes85PercentOrHigher,
        'fivePerWeekCounter': _fivePerWeekCounter,
        'distractionFreeSessionsCount': _distractionFreeSessionsCount,
        'totalSetsMade': _totalSetsMade,
        'efficientSetsInWindow': _efficientSetsInWindow,
        'ultraSessionsCount': _ultraSessionsCount,
        'totalExports': _totalExports,
      };

      await prefs.setString(_trackingDataKey, jsonEncode(trackingData));
    } catch (e) {
      developer.log('Failed to save tracking data: $e',
          name: 'AchievementTracker', level: 900);
    }
  }

  /// Track study session with enhanced tracking
  Future<void> trackStudySession({
    int? durationMinutes,
    String? studyType,
    int? itemsStudied,
    double? accuracyRate,
  }) async {
    try {
      await initialize();

      // Check if this is a new day for streak tracking
      final now = DateTime.now();
      final lastStudyDate = await _getLastStudyDate();

      if (lastStudyDate != null) {
        final daysDifference = now.difference(lastStudyDate).inDays;

        if (daysDifference == 1) {
          // Consecutive day - increment streak
          _currentStreak += 1;
        } else if (daysDifference > 1) {
          // Missed a day - reset streak to 1
          _currentStreak = 1;
        }
        // If daysDifference == 0, it's the same day, don't change streak
      } else {
        // First study session ever
        _currentStreak = 1;
      }

      // Update last study date
      await _setLastStudyDate(now);

      // Track additional metrics if provided
      if (durationMinutes != null) {
        _totalStudyMinutes += durationMinutes;
      }

      // Save data locally
      await _saveTrackingData();

      // Update all relevant achievements
      await _updateStreakAchievements();
      if (durationMinutes != null) {
        await _updateStudyTimeAchievements();
      }

      // Track weekly study pattern for 5-per-week achievements
      await _updateWeeklyStudyPattern();

      developer.log(
          'Study session tracked, streak: $_currentStreak, duration: ${durationMinutes ?? 'N/A'} min',
          name: 'AchievementTracker');
    } catch (e) {
      developer.log('Failed to track study session: $e',
          name: 'AchievementTracker', level: 900);
    }
  }

  /// Track study time in minutes with enhanced tracking
  Future<void> trackStudyTime(int minutes, {String? context}) async {
    try {
      await initialize();

      _totalStudyMinutes += minutes;

      // Save data locally
      await _saveTrackingData();

      // Update study time achievements
      await _updateStudyTimeAchievements();

      // Track distraction-free sessions if context indicates focus
      if (context == 'ultra_mode' || context == 'focused_study') {
        _distractionFreeSessionsCount += 1;
        await _updateDistractionFreeAchievements();
      }

      developer.log(
          'Study time tracked: $minutes min (total: $_totalStudyMinutes, context: $context)',
          name: 'AchievementTracker');
    } catch (e) {
      developer.log('Failed to track study time: $e',
          name: 'AchievementTracker', level: 900);
    }
  }

  /// Track cards created with enhanced tracking
  Future<void> trackCardsCreated(int count, {String? cardType}) async {
    try {
      await initialize();

      _totalCardsCreated += count;

      // Save data locally
      await _saveTrackingData();

      // Update cards created achievements
      await _updateCardsCreatedAchievements();

      // Track efficient set creation if multiple cards created at once
      if (count >= 10) {
        _efficientSetsInWindow += 1;
        await _updateEfficientSetAchievements();
      }

      developer.log(
          'Cards created tracked: $count (total: $_totalCardsCreated, type: $cardType)',
          name: 'AchievementTracker');
    } catch (e) {
      developer.log('Failed to track cards created: $e',
          name: 'AchievementTracker', level: 900);
    }
  }

  /// Track quiz started for achievements
  Future<void> trackQuizStarted({
    required String quizId,
    required String quizType,
    required int questionCount,
  }) async {
    try {
      await initialize();

      // Track quiz start activity
      // This could be used for future achievements related to quiz participation

      developer.log(
          'Quiz started tracked: $quizId ($questionCount questions, type: $quizType)',
          name: 'AchievementTracker');
    } catch (e) {
      developer.log('Failed to track quiz started: $e',
          name: 'AchievementTracker', level: 900);
    }
  }

  /// Track quiz completion with enhanced tracking
  Future<void> trackQuizCompleted(
    double scorePercent, {
    int? totalQuestions,
    String? quizType,
    Duration? timeTaken,
  }) async {
    try {
      await initialize();

      if (scorePercent >= 0.85) {
        // 85% or higher
        _quizzes85PercentOrHigher += 1;

        // Save data locally
        await _saveTrackingData();

        // Update quiz mastery achievements
        await _updateQuizMasteryAchievements();
      }

      // Track all quiz attempts for comprehensive analytics
      if (totalQuestions != null) {
        // Additional tracking could be added here
      }

      developer.log(
          'Quiz completed: ${(scorePercent * 100).toInt()}% (mastery count: $_quizzes85PercentOrHigher, type: $quizType)',
          name: 'AchievementTracker');
    } catch (e) {
      developer.log('Failed to track quiz completion: $e',
          name: 'AchievementTracker', level: 900);
    }
  }

  /// Track Ultra Mode session with enhanced tracking
  Future<void> trackUltraSession({
    int? durationMinutes,
    bool? wasCompleted,
    int? focusBreaks,
  }) async {
    try {
      await initialize();

      _ultraSessionsCount += 1;

      // Track distraction-free sessions if completed without breaks
      if (wasCompleted == true && (focusBreaks ?? 0) <= 1) {
        _distractionFreeSessionsCount += 1;
        await _updateDistractionFreeAchievements();
      }

      // Save data locally
      await _saveTrackingData();

      // Update ultra achievements
      await _updateUltraAchievements();

      developer.log(
          'Ultra session tracked: $_ultraSessionsCount (duration: ${durationMinutes ?? 'N/A'} min, completed: $wasCompleted)',
          name: 'AchievementTracker');
    } catch (e) {
      developer.log('Failed to track ultra session: $e',
          name: 'AchievementTracker', level: 900);
    }
  }

  /// Track ultra session completion with duration tracking
  Future<void> trackUltraSessionCompletion(int durationMinutes) async {
    try {
      await initialize();

      // Track the session first using existing method
      await trackUltraSession();

      // Additional duration-based tracking could be added here
      // For now, we'll use the existing ultra session tracking

      developer.log('Ultra session completed: ${durationMinutes}min',
          name: 'AchievementTracker');
    } catch (e) {
      developer.log('Failed to track ultra session completion: $e',
          name: 'AchievementTracker', level: 900);
    }
  }

  /// Track content creation for achievements
  Future<void> trackContentCreation({
    required String contentType,
    required int contentLength,
    required String title,
  }) async {
    try {
      await initialize();

      // Track content creation activity
      // This could be used for future achievements related to content creation

      developer.log(
          'Content creation tracked: $title ($contentLength chars, type: $contentType)',
          name: 'AchievementTracker');
    } catch (e) {
      developer.log('Failed to track content creation: $e',
          name: 'AchievementTracker', level: 900);
    }
  }

  /// Track export with enhanced tracking
  Future<void> trackExport({
    String? exportType,
    int? itemCount,
    String? format,
  }) async {
    try {
      await initialize();

      _totalExports += 1;

      // Save data locally
      await _saveTrackingData();

      // Update export achievements
      await _updateExportAchievements();

      developer.log(
          'Export tracked: $_totalExports (type: $exportType, count: $itemCount, format: $format)',
          name: 'AchievementTracker');
    } catch (e) {
      developer.log('Failed to track export: $e',
          name: 'AchievementTracker', level: 900);
    }
  }

  /// Track study set creation with enhanced tracking
  Future<void> trackStudySetCreated({
    int? cardCount,
    String? setType,
    bool? isPublic,
  }) async {
    try {
      await initialize();

      _totalSetsMade += 1;

      // Save data locally
      await _saveTrackingData();

      // Update creation achievements
      await _updateCreationAchievements();

      // Track efficient set creation if multiple cards
      if (cardCount != null && cardCount >= 20) {
        _efficientSetsInWindow += 1;
        await _updateEfficientSetAchievements();
      }

      developer.log(
          'Study set created tracked: $_totalSetsMade (cards: $cardCount, type: $setType)',
          name: 'AchievementTracker');
    } catch (e) {
      developer.log('Failed to track study set creation: $e',
          name: 'AchievementTracker', level: 900);
    }
  }

  /// Update streak achievements
  Future<void> _updateStreakAchievements() async {
    final updates = <String, int>{};

    // Map streak count to achievement progress
    updates[AchievementConstants.focusedFive] = _currentStreak;
    updates[AchievementConstants.steadyTen] = _currentStreak;
    updates[AchievementConstants.relentlessThirty] = _currentStreak;
    updates[AchievementConstants.quarterBrain] = _currentStreak;
    updates[AchievementConstants.yearOfCortex] = _currentStreak;

    await AchievementService.instance.bulkUpdateProgress(updates);
  }

  /// Update study time achievements
  Future<void> _updateStudyTimeAchievements() async {
    final updates = <String, int>{};

    // Map study minutes to achievement progress
    updates[AchievementConstants.warmUp] = _totalStudyMinutes;
    updates[AchievementConstants.deepDiver] = _totalStudyMinutes;
    updates[AchievementConstants.grinder] = _totalStudyMinutes;
    updates[AchievementConstants.scholar] = _totalStudyMinutes;
    updates[AchievementConstants.marathonMind] = _totalStudyMinutes;

    await AchievementService.instance.bulkUpdateProgress(updates);
  }

  /// Update cards created achievements
  Future<void> _updateCardsCreatedAchievements() async {
    final updates = <String, int>{};

    // Map card count to achievement progress
    updates[AchievementConstants.forge250] = _totalCardsCreated;
    updates[AchievementConstants.forge1k] = _totalCardsCreated;
    updates[AchievementConstants.forge25k] = _totalCardsCreated;
    updates[AchievementConstants.forge5k] = _totalCardsCreated;
    updates[AchievementConstants.forge10k] = _totalCardsCreated;

    await AchievementService.instance.bulkUpdateProgress(updates);
  }

  /// Update quiz mastery achievements
  Future<void> _updateQuizMasteryAchievements() async {
    final updates = <String, int>{};

    // Map quiz mastery count to achievement progress
    updates[AchievementConstants.ace10] = _quizzes85PercentOrHigher;
    updates[AchievementConstants.ace25] = _quizzes85PercentOrHigher;
    updates[AchievementConstants.ace50] = _quizzes85PercentOrHigher;
    updates[AchievementConstants.ace100] = _quizzes85PercentOrHigher;
    updates[AchievementConstants.ace250] = _quizzes85PercentOrHigher;

    await AchievementService.instance.bulkUpdateProgress(updates);
  }

  /// Update ultra achievements
  Future<void> _updateUltraAchievements() async {
    final updates = <String, int>{};

    // Map ultra session count to achievement progress
    updates[AchievementConstants.ultraRuns10] = _ultraSessionsCount;
    updates[AchievementConstants.ultraRuns30] = _ultraSessionsCount;
    updates[AchievementConstants.ultraRuns75] = _ultraSessionsCount;
    updates[AchievementConstants.ultraRuns150] = _ultraSessionsCount;

    await AchievementService.instance.bulkUpdateProgress(updates);
  }

  /// Update export achievements
  Future<void> _updateExportAchievements() async {
    final updates = <String, int>{};

    // Map export count to achievement progress
    updates[AchievementConstants.shipIt5] = _totalExports;
    updates[AchievementConstants.shipIt20] = _totalExports;
    updates[AchievementConstants.shipIt50] = _totalExports;
    updates[AchievementConstants.shipIt100] = _totalExports;

    await AchievementService.instance.bulkUpdateProgress(updates);
  }

  /// Update creation achievements
  Future<void> _updateCreationAchievements() async {
    final updates = <String, int>{};

    // Map set creation count to achievement progress
    updates[AchievementConstants.setBuilder20] = _totalSetsMade;
    updates[AchievementConstants.setBuilder50] = _totalSetsMade;
    updates[AchievementConstants.setBuilder100] = _totalSetsMade;

    await AchievementService.instance.bulkUpdateProgress(updates);
  }

  /// Update weekly study pattern for 5-per-week achievements
  Future<void> _updateWeeklyStudyPattern() async {
    try {
      // This would track study sessions per week
      // For now, we'll use a simple counter
      _fivePerWeekCounter += 1;

      if (_fivePerWeekCounter >= 5) {
        // Reset counter weekly (this is simplified - in production you'd track actual weeks)
        _fivePerWeekCounter = 0;

        // Update weekly study achievements
        final updates = <String, int>{};
        updates[AchievementConstants.fivePerWeek] =
            1; // Mark as achieved for this week

        await AchievementService.instance.bulkUpdateProgress(updates);
      }
    } catch (e) {
      developer.log('Failed to update weekly study pattern: $e',
          name: 'AchievementTracker', level: 900);
    }
  }

  /// Update distraction-free session achievements
  Future<void> _updateDistractionFreeAchievements() async {
    try {
      final updates = <String, int>{};

      // Map distraction-free count to achievement progress
      updates[AchievementConstants.distractionFree] =
          _distractionFreeSessionsCount;

      await AchievementService.instance.bulkUpdateProgress(updates);
    } catch (e) {
      developer.log('Failed to update distraction-free achievements: $e',
          name: 'AchievementTracker', level: 900);
    }
  }

  /// Update efficient set creation achievements
  Future<void> _updateEfficientSetAchievements() async {
    try {
      final updates = <String, int>{};

      // Map efficient set count to achievement progress
      updates[AchievementConstants.efficientCreator] = _efficientSetsInWindow;

      await AchievementService.instance.bulkUpdateProgress(updates);
    } catch (e) {
      developer.log('Failed to update efficient set achievements: $e',
          name: 'AchievementTracker', level: 900);
    }
  }

  /// Reset all tracking data (for testing)
  Future<void> resetTrackingData() async {
    _currentStreak = 0;
    _totalStudyMinutes = 0;
    _totalCardsCreated = 0;
    _totalCardsReviewed = 0;
    _quizzes85PercentOrHigher = 0;
    _fivePerWeekCounter = 0;
    _distractionFreeSessionsCount = 0;
    _totalSetsMade = 0;
    _efficientSetsInWindow = 0;
    _ultraSessionsCount = 0;
    _totalExports = 0;

    // Save reset data locally
    await _saveTrackingData();

    developer.log('Achievement tracking data reset',
        name: 'AchievementTracker');
  }

  /// Get current tracking stats (for debugging)
  Map<String, dynamic> getTrackingStats() {
    return {
      'currentStreak': _currentStreak,
      'totalStudyMinutes': _totalStudyMinutes,
      'totalCardsCreated': _totalCardsCreated,
      'totalCardsReviewed': _totalCardsReviewed,
      'quizzes85PercentOrHigher': _quizzes85PercentOrHigher,
      'ultraSessionsCount': _ultraSessionsCount,
      'totalExports': _totalExports,
      'totalSetsMade': _totalSetsMade,
    };
  }

  /// Simulate achievement progress for demo
  Future<void> simulateProgress() async {
    try {
      developer.log('Simulating achievement progress for demo',
          name: 'AchievementTracker');

      // Simulate various activities
      await trackStudySession(); // 1 day streak
      await trackStudyTime(60); // 1 hour study time
      await trackCardsCreated(50); // 50 cards created
      await trackQuizCompleted(0.90); // 90% quiz score
      await trackStudySetCreated(); // 1 set created
      await trackUltraSession(); // 1 ultra session
      await trackExport(); // 1 export

      developer.log('Achievement progress simulation complete',
          name: 'AchievementTracker');
    } catch (e) {
      developer.log('Failed to simulate achievement progress: $e',
          name: 'AchievementTracker', level: 900);
    }
  }

  /// Track document upload for achievements
  Future<void> trackDocumentUpload({
    required String fileName,
    required int fileSize,
    required String fileExtension,
  }) async {
    try {
      await initialize();

      // Track document upload activity
      // This could be used for future achievements related to document management

      developer.log(
          'Document upload tracked: $fileName ($fileSize bytes, .$fileExtension)',
          name: 'AchievementTracker');
    } catch (e) {
      developer.log('Failed to track document upload: $e',
          name: 'AchievementTracker', level: 900);
    }
  }

  /// Track document processing success for achievements
  Future<void> trackDocumentProcessed({
    required String fileName,
    required int pageCount,
    required DateTime processingTime,
  }) async {
    try {
      await initialize();

      // Track document processing success
      // This could be used for future achievements related to document processing

      developer.log('Document processed tracked: $fileName ($pageCount pages)',
          name: 'AchievementTracker');
    } catch (e) {
      developer.log('Failed to track document processing: $e',
          name: 'AchievementTracker', level: 900);
    }
  }

  /// Track study set creation from document
  Future<void> trackStudySetFromDocument({
    required String documentName,
    required int cardCount,
    required String documentType,
  }) async {
    try {
      await initialize();

      // Track study set creation from document
      await trackStudySetCreated(
        cardCount: cardCount,
        setType: 'document_import',
        isPublic: false,
      );

      developer.log(
          'Study set from document tracked: $documentName ($cardCount cards, $documentType)',
          name: 'AchievementTracker');
    } catch (e) {
      developer.log('Failed to track study set from document: $e',
          name: 'AchievementTracker', level: 900);
    }
  }

  /// Track flashcard review for achievements
  Future<void> trackFlashcardReview({
    required int cardCount,
    required int correctAnswers,
    required Duration reviewTime,
  }) async {
    try {
      await initialize();

      _totalCardsReviewed += cardCount;

      // Save data locally
      await _saveTrackingData();

      // Update review achievements
      await _updateReviewAchievements();

      developer.log(
          'Flashcard review tracked: $cardCount cards, $correctAnswers correct, ${reviewTime.inMinutes}min',
          name: 'AchievementTracker');
    } catch (e) {
      developer.log('Failed to track flashcard review: $e',
          name: 'AchievementTracker', level: 900);
    }
  }

  /// Update review achievements
  Future<void> _updateReviewAchievements() async {
    try {
      final updates = <String, int>{};

      // Map review count to achievement progress
      updates[AchievementConstants.reviewMaster] = _totalCardsReviewed;

      await AchievementService.instance.bulkUpdateProgress(updates);
    } catch (e) {
      developer.log('Failed to update review achievements: $e',
          name: 'AchievementTracker', level: 900);
    }
  }

  /// Get the last study date from local storage
  Future<DateTime?> _getLastStudyDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('last_study_date');
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      developer.log('Failed to get last study date: $e',
          name: 'AchievementTracker', level: 900);
      return null;
    }
  }

  /// Set the last study date in local storage
  Future<void> _setLastStudyDate(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_study_date', date.millisecondsSinceEpoch);
    } catch (e) {
      developer.log('Failed to set last study date: $e',
          name: 'AchievementTracker', level: 900);
    }
  }
}
