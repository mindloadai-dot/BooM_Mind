import 'dart:developer' as developer;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindload/models/achievement_models.dart';
import 'package:mindload/services/telemetry_service.dart';
import 'package:mindload/services/mindload_economy_service.dart';


/// Achievement System Service - Fully Local
/// Handles achievement tracking, rewards, and progress calculation
/// All data is stored locally using SharedPreferences
class AchievementService extends ChangeNotifier {
  static final AchievementService _instance = AchievementService._internal();
  static AchievementService get instance => _instance;
  AchievementService._internal();

  static const String _catalogKey = 'achievements_catalog';
  static const String _userAchievementsKey = 'user_achievements';
  static const String _metaKey = 'achievements_meta';
  
  // Cache
  List<AchievementCatalog> _catalog = [];
  final Map<String, UserAchievement> _userAchievements = {};
  AchievementsMeta _meta = AchievementsMeta.empty();
  
  bool _isInitialized = false;
  bool _isLoading = false;
  
  // Getters
  List<AchievementCatalog> get catalog => _catalog;
  Map<String, UserAchievement> get userAchievements => _userAchievements;
  AchievementsMeta get meta => _meta;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;

  /// Initialize achievement system - Local only
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      await _loadLocalCatalog();
      await _loadLocalUserData();
      
      _isInitialized = true;
      developer.log('Achievement service initialized locally', name: 'AchievementService');
    } catch (e) {
      developer.log('Failed to initialize achievement service: $e', name: 'AchievementService', level: 900);
      // Don't rethrow - create default data instead
      await _createDefaultData();
      _isInitialized = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load achievement catalog from local storage
  Future<void> _loadLocalCatalog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final catalogJson = prefs.getString(_catalogKey);
      
      if (catalogJson == null) {
        // Create default catalog if none exists
        await _createDefaultCatalog();
        return;
      }
      
      final catalogData = jsonDecode(catalogJson) as List<dynamic>;
      _catalog = catalogData
          .map((item) => AchievementCatalog.fromJson(item as Map<String, dynamic>))
          .toList();
      
      developer.log('Loaded ${_catalog.length} achievements from local catalog', name: 'AchievementService');
    } catch (e) {
      developer.log('Failed to load local achievement catalog: $e', name: 'AchievementService', level: 900);
      await _createDefaultCatalog();
    }
  }

  /// Load user achievement data from local storage
  Future<void> _loadLocalUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load user achievements
      final achievementsJson = prefs.getString(_userAchievementsKey);
      if (achievementsJson != null) {
        final achievementsData = jsonDecode(achievementsJson) as Map<String, dynamic>;
        _userAchievements.clear();
        for (final entry in achievementsData.entries) {
          _userAchievements[entry.key] = UserAchievement.fromJson(entry.value as Map<String, dynamic>);
        }
      }
      
      // Load achievements meta
      final metaJson = prefs.getString(_metaKey);
      if (metaJson != null) {
        _meta = AchievementsMeta.fromJson(jsonDecode(metaJson) as Map<String, dynamic>);
      } else {
        _meta = AchievementsMeta.empty();
        await _saveLocalMeta();
      }
      
      // Initialize missing achievements
      await _initializeMissingAchievements();
      
      developer.log('Loaded user achievements locally: ${_userAchievements.length}', name: 'AchievementService');
    } catch (e) {
      developer.log('Failed to load local user achievement data: $e', name: 'AchievementService', level: 900);
      // Initialize with empty data if loading fails
      _meta = AchievementsMeta.empty();
      await _initializeMissingAchievements();
    }
  }

  /// Initialize missing achievements for user - Local version
  Future<void> _initializeMissingAchievements() async {
    bool hasChanges = false;
    
    for (final catalogItem in _catalog) {
      if (!_userAchievements.containsKey(catalogItem.id)) {
        final userAchievement = UserAchievement(
          id: catalogItem.id,
          status: AchievementStatus.locked,
          progress: 0,
          rewardGranted: false,
          lastUpdated: DateTime.now(),
        );
        
        _userAchievements[catalogItem.id] = userAchievement;
        hasChanges = true;
      }
    }
    
    if (hasChanges) {
      await _saveLocalUserAchievements();
      developer.log('Initialized missing achievements locally', name: 'AchievementService');
    }
  }

  /// Update achievement progress - Local version
  Future<void> updateProgress(String achievementId, int newProgress) async {
    try {
      if (!_isInitialized) {
        developer.log('Service not initialized, skipping progress update', name: 'AchievementService', level: 900);
        return;
      }
      
      AchievementCatalog? catalogItem;
      try {
        catalogItem = _catalog.firstWhere(
          (item) => item.id == achievementId,
        );
      } catch (e) {
        developer.log('Achievement not found: $achievementId', name: 'AchievementService', level: 900);
        return;
      }
      
      final currentAchievement = _userAchievements[achievementId];
      
      if (currentAchievement == null) {
        developer.log('User achievement state not found: $achievementId', name: 'AchievementService', level: 900);
        return;
      }
      if (currentAchievement.status == AchievementStatus.earned) return; // Already earned
      // Calculate new status
      AchievementStatus newStatus = currentAchievement.status;
      DateTime? earnedAt = currentAchievement.earnedAt;
      
      if (newProgress >= catalogItem.threshold && currentAchievement.status != AchievementStatus.earned) {
        newStatus = AchievementStatus.earned;
        earnedAt = DateTime.now();
      } else if (newProgress > 0) {
        newStatus = AchievementStatus.inProgress;
      }
      
      // Update user achievement
      final updatedAchievement = currentAchievement.copyWith(
        status: newStatus,
        progress: newProgress,
        earnedAt: earnedAt,
        lastUpdated: DateTime.now(),
      );
      
      _userAchievements[achievementId] = updatedAchievement;
      
      // Save locally
      await _saveLocalUserAchievements();
      
      // Check if this is a new achievement earn
      if (newStatus == AchievementStatus.earned && currentAchievement.status != AchievementStatus.earned) {
        await _handleAchievementEarned(catalogItem, updatedAchievement);
      }
      
      notifyListeners();
    } catch (e) {
      developer.log('Failed to update achievement progress: $e', name: 'AchievementService', level: 900);
      // Don't rethrow for local version - just log the error
    }
  }

  /// Handle achievement earned - check for bonus credits and trigger notifications
  Future<void> _handleAchievementEarned(AchievementCatalog catalogItem, UserAchievement achievement) async {
    try {
      // Emit telemetry
      TelemetryService.instance.logEvent(
        TelemetryEvent.achievementEarned.name,
        {
          'achievement_id': catalogItem.id,
          'achievement_title': catalogItem.title,
          'category': catalogItem.category.id,
          'tier': catalogItem.tier.id,
        },
      );
      
      // Update bonus counter
      final updatedMeta = _meta.copyWith(bonusCounter: _meta.bonusCounter + 1);
      _meta = updatedMeta;
      
      // Check if bonus credit should be granted
      if (_meta.bonusCounter % AchievementConstants.rewardEveryN == 0) {
        await _grantBonusCredit(catalogItem.id);
      }
      
      await _saveLocalMeta();
      
      // Trigger achievement notification automatically
      await _triggerAchievementNotification(catalogItem);
      
      developer.log('Achievement earned: ${catalogItem.title}', name: 'AchievementService');
    } catch (e) {
      developer.log('Failed to handle achievement earned: $e', name: 'AchievementService', level: 900);
    }
  }

  /// Trigger achievement notification automatically
  Future<void> _triggerAchievementNotification(AchievementCatalog achievement) async {
    try {
      // Achievement unlocked - event bus removed for unified notification system
      // Notifications are now handled directly by WorkingNotificationService
      
      developer.log('✅ Achievement notification event emitted: ${achievement.title}', name: 'AchievementService');
    } catch (e) {
      developer.log('❌ Failed to trigger achievement notification: $e', name: 'AchievementService', level: 900);
    }
  }

  /// Get notification service dynamically
  Future<dynamic> _getNotificationService() async {
    // TODO: Implement proper notification service access
    // For now, return null to avoid circular dependencies
    return null;
  }

  /// Grant bonus credit with safety checks - Local version
  Future<void> _grantBonusCredit(String achievementId) async {
    try {
      // Check monthly cap
      final now = DateTime.now();
      final isNewMonth = now.month != _meta.lastMonthlyReset.month || 
                        now.year != _meta.lastMonthlyReset.year;
      
      if (isNewMonth) {
        _meta = _meta.copyWith(
          monthlyBonusCount: 0,
          lastMonthlyReset: now,
        );
      }
      
      if (_meta.monthlyBonusCount >= AchievementConstants.maxMonthlyBonusCredits) {
        developer.log('Monthly bonus credit cap reached', name: 'AchievementService', level: 800);
        return;
      }
      
      // Grant credit through economy service
      // Note: Adding credits manually via direct economy service manipulation
      // This is a simplified implementation for achievement rewards
      final economyService = MindloadEconomyService.instance;
      if (economyService.userEconomy != null) {
        final updatedEconomy = economyService.userEconomy!.copyWith(
          creditsRemaining: economyService.userEconomy!.creditsRemaining + 1,
        );
        // Update the user economy with the bonus credit
        await economyService.updateUserTier(updatedEconomy.tier);
      }
      
      // Update meta
      _meta = _meta.copyWith(
        lastBonusGranted: now,
        monthlyBonusCount: _meta.monthlyBonusCount + 1,
      );
      
      // Emit telemetry (if available)
      try {
        TelemetryService.instance.logEvent(
          TelemetryEvent.achievementBonusGranted.name,
          {
            'achievement_id': achievementId,
            'bonus_counter': _meta.bonusCounter,
            'monthly_count': _meta.monthlyBonusCount,
          },
        );
      } catch (e) {
        // Telemetry failure shouldn't block achievement system
        developer.log('Telemetry failed for achievement bonus: $e', name: 'AchievementService', level: 400);
      }
      
      developer.log('Bonus credit granted for achievement: $achievementId', name: 'AchievementService');
    } catch (e) {
      developer.log('Failed to grant bonus credit: $e', name: 'AchievementService', level: 900);
    }
  }

  /// Save meta to local storage
  Future<void> _saveLocalMeta() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_metaKey, jsonEncode(_meta.toJson()));
    } catch (e) {
      developer.log('Failed to save local achievement meta: $e', name: 'AchievementService', level: 900);
    }
  }

  /// Save user achievements to local storage
  Future<void> _saveLocalUserAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final achievementsMap = <String, dynamic>{};
      for (final entry in _userAchievements.entries) {
        achievementsMap[entry.key] = entry.value.toJson();
      }
      await prefs.setString(_userAchievementsKey, jsonEncode(achievementsMap));
    } catch (e) {
      developer.log('Failed to save local user achievements: $e', name: 'AchievementService', level: 900);
    }
  }

  /// Save catalog to local storage
  Future<void> _saveLocalCatalog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final catalogJson = _catalog.map((item) => item.toJson()).toList();
      await prefs.setString(_catalogKey, jsonEncode(catalogJson));
    } catch (e) {
      developer.log('Failed to save local catalog: $e', name: 'AchievementService', level: 900);
    }
  }

  /// Get achievements by category
  List<AchievementDisplay> getAchievementsByCategory(AchievementCategory category) {
    try {
      if (!_isInitialized) {
        developer.log('Service not initialized, returning empty list', name: 'AchievementService', level: 900);
        return [];
      }
      
      return _catalog
          .where((item) => item.category == category)
          .map((catalog) {
            try {
              final userState = _userAchievements[catalog.id] ?? UserAchievement(
                id: catalog.id,
                status: AchievementStatus.locked,
                progress: 0,
                rewardGranted: false,
                lastUpdated: DateTime.now(),
              );
              return AchievementDisplay(catalog: catalog, userState: userState);
            } catch (e) {
              developer.log('Error creating achievement display for ${catalog.id}: $e', name: 'AchievementService', level: 1000);
              return null;
            }
          })
          .where((achievement) => achievement != null)
          .cast<AchievementDisplay>()
          .toList()
        ..sort((a, b) {
          try {
            return a.catalog.sortOrder.compareTo(b.catalog.sortOrder);
          } catch (e) {
            developer.log('Error sorting achievements: $e', name: 'AchievementService', level: 1000);
            return 0;
          }
        });
    } catch (e) {
      developer.log('Error getting achievements by category: $e', name: 'AchievementService', level: 1000);
      return [];
    }
  }

  /// Get achievements by status
  List<AchievementDisplay> getAchievementsByStatus(AchievementStatus status) {
    try {
      if (!_isInitialized) {
        developer.log('Service not initialized, returning empty list', name: 'AchievementService', level: 900);
        return [];
      }
      
      return _catalog
          .where((catalog) => _userAchievements[catalog.id]?.status == status)
          .map((catalog) {
            try {
              final userState = _userAchievements[catalog.id];
              if (userState == null) {
                developer.log('Missing user state for achievement: ${catalog.id}', name: 'AchievementService', level: 900);
                return null;
              }
              return AchievementDisplay(
                    catalog: catalog, 
                    userState: userState,
                  );
            } catch (e) {
              developer.log('Error creating achievement display for ${catalog.id}: $e', name: 'AchievementService', level: 1000);
              return null;
            }
          })
          .where((achievement) => achievement != null)
          .cast<AchievementDisplay>()
          .toList()
        ..sort((a, b) {
          try {
            return a.catalog.sortOrder.compareTo(b.catalog.sortOrder);
          } catch (e) {
            developer.log('Error sorting achievements: $e', name: 'AchievementService', level: 1000);
            return 0;
          }
        });
    } catch (e) {
      developer.log('Error getting achievements by status: $e', name: 'AchievementService', level: 1000);
      return [];
    }
  }

  /// Get next closest achievements to unlock (for "Next Up" strip)
  List<AchievementDisplay> getNextClosestAchievements({int limit = 3}) {
    try {
      if (!_isInitialized) {
        developer.log('Service not initialized, returning empty list', name: 'AchievementService', level: 900);
        return [];
      }
      
      final inProgress = getAchievementsByStatus(AchievementStatus.inProgress);
      
      if (inProgress.isEmpty) {
        return [];
      }
      
      inProgress.sort((a, b) {
        try {
          final aPercent = a.progressPercent;
          final bPercent = b.progressPercent;
          return bPercent.compareTo(aPercent); // Highest progress first
        } catch (e) {
          developer.log('Error sorting achievements by progress: $e', name: 'AchievementService', level: 1000);
          return 0;
        }
      });
      
      return inProgress.take(limit).toList();
    } catch (e) {
      developer.log('Error getting next closest achievements: $e', name: 'AchievementService', level: 1000);
      return [];
    }
  }

  /// Get achievement by ID
  AchievementDisplay? getAchievementById(String id) {
    AchievementCatalog? catalog;
    try {
      catalog = _catalog.firstWhere((item) => item.id == id);
    } catch (e) {
      developer.log('Achievement not found: $id', name: 'AchievementService', level: 900);
      return null;
    }
    
    final userState = _userAchievements[id];
    if (userState == null) return null;
    
    return AchievementDisplay(catalog: catalog, userState: userState);
  }

  /// Bulk update progress (for efficient batch operations) - Local version
  Future<void> bulkUpdateProgress(Map<String, int> progressUpdates) async {
    try {
      bool hasChanges = false;
      
      for (final entry in progressUpdates.entries) {
        final achievementId = entry.key;
        final newProgress = entry.value;
        
        AchievementCatalog? catalogItem;
        try {
          catalogItem = _catalog.firstWhere((item) => item.id == achievementId);
        } catch (e) {
          developer.log('Achievement not found in bulk update: $achievementId', name: 'AchievementService', level: 900);
          continue;
        }
        final currentAchievement = _userAchievements[achievementId];
        
        if (currentAchievement == null || currentAchievement.status == AchievementStatus.earned) continue;
        
        // Calculate new status
        AchievementStatus newStatus = currentAchievement.status;
        DateTime? earnedAt = currentAchievement.earnedAt;
        
        if (newProgress >= catalogItem.threshold && currentAchievement.status != AchievementStatus.earned) {
          newStatus = AchievementStatus.earned;
          earnedAt = DateTime.now();
        } else if (newProgress > 0) {
          newStatus = AchievementStatus.inProgress;
        }
        
        // Update user achievement
        final updatedAchievement = currentAchievement.copyWith(
          status: newStatus,
          progress: newProgress,
          earnedAt: earnedAt,
          lastUpdated: DateTime.now(),
        );
        
        _userAchievements[achievementId] = updatedAchievement;
        hasChanges = true;
        
        // Handle new achievements
        if (newStatus == AchievementStatus.earned && currentAchievement.status != AchievementStatus.earned) {
          await _handleAchievementEarned(catalogItem, updatedAchievement);
        }
      }
      
      if (hasChanges) {
        await _saveLocalUserAchievements();
        notifyListeners();
      }
    } catch (e) {
      developer.log('Failed to bulk update achievement progress: $e', name: 'AchievementService', level: 900);
      // Don't rethrow for local version
    }
  }

  /// Create default achievement catalog - Local version
  Future<void> _createDefaultCatalog() async {
    developer.log('Creating default achievement catalog locally', name: 'AchievementService');
    
    final achievements = [
      // Streaks
      AchievementCatalog(
        id: AchievementConstants.focusedFive,
        title: 'Focused Five',
        category: AchievementCategory.streaks,
        tier: AchievementTier.bronze,
        threshold: 5,
        description: 'Study 5 days in a row',
        howTo: 'Complete any study session for 5 consecutive days',
        icon: '🔥',
        sortOrder: 100,
      ),
      AchievementCatalog(
        id: AchievementConstants.steadyTen,
        title: 'Steady Ten',
        category: AchievementCategory.streaks,
        tier: AchievementTier.silver,
        threshold: 10,
        description: 'Study 10 days in a row',
        howTo: 'Complete any study session for 10 consecutive days',
        icon: '🔥',
        sortOrder: 101,
      ),
      AchievementCatalog(
        id: AchievementConstants.relentlessThirty,
        title: 'Relentless Thirty',
        category: AchievementCategory.streaks,
        tier: AchievementTier.gold,
        threshold: 30,
        description: 'Study 30 days in a row',
        howTo: 'Complete any study session for 30 consecutive days',
        icon: '🔥',
        sortOrder: 102,
      ),
      AchievementCatalog(
        id: AchievementConstants.quarterBrain,
        title: 'Quarter Brain',
        category: AchievementCategory.streaks,
        tier: AchievementTier.platinum,
        threshold: 90,
        description: 'Study 90 days in a row',
        howTo: 'Complete any study session for 90 consecutive days',
        icon: '🔥',
        sortOrder: 103,
      ),
      AchievementCatalog(
        id: AchievementConstants.yearOfCortex,
        title: 'Year of Cortex',
        category: AchievementCategory.streaks,
        tier: AchievementTier.legendary,
        threshold: 365,
        description: 'Study 365 days in a row',
        howTo: 'Complete any study session for 365 consecutive days',
        icon: '🔥',
        sortOrder: 104,
      ),
      
      // Study Time (active minutes)
      AchievementCatalog(
        id: AchievementConstants.warmUp,
        title: 'Warm-Up',
        category: AchievementCategory.studyTime,
        tier: AchievementTier.bronze,
        threshold: 300, // 5 hours in minutes
        description: 'Study for 5 hours total',
        howTo: 'Accumulate 5 hours of active study time',
        icon: '⏱️',
        sortOrder: 200,
      ),
      AchievementCatalog(
        id: AchievementConstants.deepDiver,
        title: 'Deep Diver',
        category: AchievementCategory.studyTime,
        tier: AchievementTier.silver,
        threshold: 1200, // 20 hours in minutes
        description: 'Study for 20 hours total',
        howTo: 'Accumulate 20 hours of active study time',
        icon: '⏱️',
        sortOrder: 201,
      ),
      AchievementCatalog(
        id: AchievementConstants.grinder,
        title: 'Grinder',
        category: AchievementCategory.studyTime,
        tier: AchievementTier.gold,
        threshold: 3000, // 50 hours in minutes
        description: 'Study for 50 hours total',
        howTo: 'Accumulate 50 hours of active study time',
        icon: '⏱️',
        sortOrder: 202,
      ),
      AchievementCatalog(
        id: AchievementConstants.scholar,
        title: 'Scholar',
        category: AchievementCategory.studyTime,
        tier: AchievementTier.platinum,
        threshold: 7200, // 120 hours in minutes
        description: 'Study for 120 hours total',
        howTo: 'Accumulate 120 hours of active study time',
        icon: '⏱️',
        sortOrder: 203,
      ),
      AchievementCatalog(
        id: AchievementConstants.marathonMind,
        title: 'Marathon Mind',
        category: AchievementCategory.studyTime,
        tier: AchievementTier.legendary,
        threshold: 18000, // 300 hours in minutes
        description: 'Study for 300 hours total',
        howTo: 'Accumulate 300 hours of active study time',
        icon: '⏱️',
        sortOrder: 204,
      ),
      
      // Cards Created
      AchievementCatalog(
        id: AchievementConstants.forge250,
        title: 'Forge 250',
        category: AchievementCategory.cardsCreated,
        tier: AchievementTier.bronze,
        threshold: 250,
        description: 'Create 250 flashcards',
        howTo: 'Generate flashcards from any source',
        icon: '🎴',
        sortOrder: 300,
      ),
      AchievementCatalog(
        id: AchievementConstants.forge1k,
        title: 'Forge 1K',
        category: AchievementCategory.cardsCreated,
        tier: AchievementTier.silver,
        threshold: 1000,
        description: 'Create 1,000 flashcards',
        howTo: 'Generate flashcards from any source',
        icon: '🎴',
        sortOrder: 301,
      ),
      AchievementCatalog(
        id: AchievementConstants.forge25k,
        title: 'Forge 2.5K',
        category: AchievementCategory.cardsCreated,
        tier: AchievementTier.gold,
        threshold: 2500,
        description: 'Create 2,500 flashcards',
        howTo: 'Generate flashcards from any source',
        icon: '🎴',
        sortOrder: 302,
      ),
      AchievementCatalog(
        id: AchievementConstants.forge5k,
        title: 'Forge 5K',
        category: AchievementCategory.cardsCreated,
        tier: AchievementTier.platinum,
        threshold: 5000,
        description: 'Create 5,000 flashcards',
        howTo: 'Generate flashcards from any source',
        icon: '🎴',
        sortOrder: 303,
      ),
      AchievementCatalog(
        id: AchievementConstants.forge10k,
        title: 'Forge 10K',
        category: AchievementCategory.cardsCreated,
        tier: AchievementTier.legendary,
        threshold: 10000,
        description: 'Create 10,000 flashcards',
        howTo: 'Generate flashcards from any source',
        icon: '🎴',
        sortOrder: 304,
      ),
      
      // Quiz Mastery (≥85% score)
      AchievementCatalog(
        id: AchievementConstants.ace10,
        title: 'Ace 10',
        category: AchievementCategory.quizMastery,
        tier: AchievementTier.bronze,
        threshold: 10,
        description: 'Score ≥85% on 10 quizzes',
        howTo: 'Complete quizzes with 85% or higher accuracy',
        icon: '🎯',
        sortOrder: 400,
      ),
      AchievementCatalog(
        id: AchievementConstants.ace25,
        title: 'Ace 25',
        category: AchievementCategory.quizMastery,
        tier: AchievementTier.silver,
        threshold: 25,
        description: 'Score ≥85% on 25 quizzes',
        howTo: 'Complete quizzes with 85% or higher accuracy',
        icon: '🎯',
        sortOrder: 401,
      ),
      AchievementCatalog(
        id: AchievementConstants.ace50,
        title: 'Ace 50',
        category: AchievementCategory.quizMastery,
        tier: AchievementTier.gold,
        threshold: 50,
        description: 'Score ≥85% on 50 quizzes',
        howTo: 'Complete quizzes with 85% or higher accuracy',
        icon: '🎯',
        sortOrder: 402,
      ),
      AchievementCatalog(
        id: AchievementConstants.ace100,
        title: 'Ace 100',
        category: AchievementCategory.quizMastery,
        tier: AchievementTier.platinum,
        threshold: 100,
        description: 'Score ≥85% on 100 quizzes',
        howTo: 'Complete quizzes with 85% or higher accuracy',
        icon: '🎯',
        sortOrder: 403,
      ),
      AchievementCatalog(
        id: AchievementConstants.ace250,
        title: 'Ace 250',
        category: AchievementCategory.quizMastery,
        tier: AchievementTier.legendary,
        threshold: 250,
        description: 'Score ≥85% on 250 quizzes',
        howTo: 'Complete quizzes with 85% or higher accuracy',
        icon: '🎯',
        sortOrder: 404,
      ),
    ];
    
    // Save locally
    _catalog = achievements;
    await _saveLocalCatalog();
    developer.log('Default achievement catalog created locally', name: 'AchievementService');
  }

  /// Refresh data from local storage
  Future<void> refresh() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _loadLocalCatalog();
      await _loadLocalUserData();
    } catch (e) {
      developer.log('Failed to refresh local achievement data: $e', name: 'AchievementService', level: 900);
      // Don't rethrow for local version
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create default data when initialization fails
  Future<void> _createDefaultData() async {
    try {
      await _createDefaultCatalog();
      _meta = AchievementsMeta.empty();
      await _saveLocalMeta();
      await _initializeMissingAchievements();
      developer.log('Created default achievement data locally', name: 'AchievementService');
    } catch (e) {
      developer.log('Failed to create default achievement data: $e', name: 'AchievementService', level: 900);
    }
  }


  /// Reset achievement service (for logout)
  void reset() {
    _catalog.clear();
    _userAchievements.clear();
    _meta = AchievementsMeta.empty();
    _isInitialized = false;
    _isLoading = false;
    notifyListeners();
  }
}