import 'package:mindload/models/achievement_models.dart';

/// Enhanced Achievement Catalog with modern achievement types
/// Inspired by pub.dev's gamification and Flutter community patterns
class EnhancedAchievementsCatalog {
  static List<AchievementCatalog> getEnhancedCatalog() {
    return [
      // Streaks Category - Enhanced
      AchievementCatalog(
        id: 'streak_starter',
        title: 'Streak Starter',
        category: AchievementCategory.streaks,
        tier: AchievementTier.bronze,
        threshold: 3,
        description: 'Study for 3 consecutive days to build your learning habit',
        howTo: 'Complete at least one study session each day for 3 days in a row',
        icon: '🔥',
        sortOrder: 100,
      ),
      AchievementCatalog(
        id: 'week_warrior',
        title: 'Week Warrior',
        category: AchievementCategory.streaks,
        tier: AchievementTier.silver,
        threshold: 7,
        description: 'Maintain a perfect 7-day study streak',
        howTo: 'Study every day for a full week without missing a day',
        icon: '⚡',
        sortOrder: 101,
      ),
      AchievementCatalog(
        id: 'month_master',
        title: 'Month Master',
        category: AchievementCategory.streaks,
        tier: AchievementTier.gold,
        threshold: 30,
        description: 'Achieve an incredible 30-day study streak',
        howTo: 'Study consistently for 30 consecutive days',
        icon: '👑',
        sortOrder: 102,
      ),
      AchievementCatalog(
        id: 'legendary_learner',
        title: 'Legendary Learner',
        category: AchievementCategory.streaks,
        tier: AchievementTier.legendary,
        threshold: 100,
        description: 'The ultimate achievement: 100 days of continuous learning',
        howTo: 'Maintain a study streak for 100 consecutive days',
        icon: '🌟',
        sortOrder: 103,
      ),

      // Study Time Category - Enhanced
      AchievementCatalog(
        id: 'time_explorer',
        title: 'Time Explorer',
        category: AchievementCategory.studyTime,
        tier: AchievementTier.bronze,
        threshold: 60,
        description: 'Spend your first hour exploring knowledge',
        howTo: 'Accumulate 60 minutes of total study time',
        icon: '⏰',
        sortOrder: 200,
      ),
      AchievementCatalog(
        id: 'focused_scholar',
        title: 'Focused Scholar',
        category: AchievementCategory.studyTime,
        tier: AchievementTier.silver,
        threshold: 300,
        description: 'Dedicate 5 hours to focused learning',
        howTo: 'Accumulate 300 minutes (5 hours) of study time',
        icon: '📚',
        sortOrder: 201,
      ),
      AchievementCatalog(
        id: 'knowledge_seeker',
        title: 'Knowledge Seeker',
        category: AchievementCategory.studyTime,
        tier: AchievementTier.gold,
        threshold: 1200,
        description: 'Invest 20 hours in your learning journey',
        howTo: 'Accumulate 1200 minutes (20 hours) of study time',
        icon: '🎓',
        sortOrder: 202,
      ),
      AchievementCatalog(
        id: 'wisdom_guardian',
        title: 'Wisdom Guardian',
        category: AchievementCategory.studyTime,
        tier: AchievementTier.platinum,
        threshold: 3000,
        description: 'Achieve mastery with 50 hours of dedicated study',
        howTo: 'Accumulate 3000 minutes (50 hours) of study time',
        icon: '🧠',
        sortOrder: 203,
      ),

      // Cards Created Category - Enhanced
      AchievementCatalog(
        id: 'card_creator',
        title: 'Card Creator',
        category: AchievementCategory.cardsCreated,
        tier: AchievementTier.bronze,
        threshold: 25,
        description: 'Create your first set of flashcards',
        howTo: 'Generate or create 25 flashcards',
        icon: '📝',
        sortOrder: 300,
      ),
      AchievementCatalog(
        id: 'content_curator',
        title: 'Content Curator',
        category: AchievementCategory.cardsCreated,
        tier: AchievementTier.silver,
        threshold: 100,
        description: 'Build a substantial knowledge base',
        howTo: 'Create 100 flashcards across different topics',
        icon: '📋',
        sortOrder: 301,
      ),
      AchievementCatalog(
        id: 'knowledge_architect',
        title: 'Knowledge Architect',
        category: AchievementCategory.cardsCreated,
        tier: AchievementTier.gold,
        threshold: 500,
        description: 'Architect an impressive learning library',
        howTo: 'Create 500 flashcards to build comprehensive study materials',
        icon: '🏗️',
        sortOrder: 302,
      ),
      AchievementCatalog(
        id: 'master_builder',
        title: 'Master Builder',
        category: AchievementCategory.cardsCreated,
        tier: AchievementTier.legendary,
        threshold: 1000,
        description: 'Reach the pinnacle of content creation',
        howTo: 'Create 1000 flashcards - a true learning encyclopedia',
        icon: '🏰',
        sortOrder: 303,
      ),

      // Quiz Mastery Category - Enhanced
      AchievementCatalog(
        id: 'quiz_novice',
        title: 'Quiz Novice',
        category: AchievementCategory.quizMastery,
        tier: AchievementTier.bronze,
        threshold: 5,
        description: 'Complete your first few quizzes with confidence',
        howTo: 'Score 80% or higher on 5 quizzes',
        icon: '🎯',
        sortOrder: 400,
      ),
      AchievementCatalog(
        id: 'quiz_champion',
        title: 'Quiz Champion',
        category: AchievementCategory.quizMastery,
        tier: AchievementTier.silver,
        threshold: 20,
        description: 'Demonstrate consistent quiz excellence',
        howTo: 'Score 85% or higher on 20 quizzes',
        icon: '🏆',
        sortOrder: 401,
      ),
      AchievementCatalog(
        id: 'perfect_scorer',
        title: 'Perfect Scorer',
        category: AchievementCategory.quizMastery,
        tier: AchievementTier.gold,
        threshold: 10,
        description: 'Achieve perfection in quiz performance',
        howTo: 'Score 100% on 10 different quizzes',
        icon: '💯',
        sortOrder: 402,
      ),
      AchievementCatalog(
        id: 'quiz_legend',
        title: 'Quiz Legend',
        category: AchievementCategory.quizMastery,
        tier: AchievementTier.legendary,
        threshold: 100,
        description: 'Become a legendary quiz master',
        howTo: 'Score 90% or higher on 100 quizzes',
        icon: '🌟',
        sortOrder: 403,
      ),

      // Consistency Category - New Enhanced Achievements
      AchievementCatalog(
        id: 'morning_ritual',
        title: 'Morning Ritual',
        category: AchievementCategory.consistency,
        tier: AchievementTier.bronze,
        threshold: 7,
        description: 'Start your day with learning',
        howTo: 'Complete study sessions before 10 AM for 7 days',
        icon: '🌅',
        sortOrder: 500,
      ),
      AchievementCatalog(
        id: 'evening_scholar',
        title: 'Evening Scholar',
        category: AchievementCategory.consistency,
        tier: AchievementTier.bronze,
        threshold: 7,
        description: 'End your day with knowledge',
        howTo: 'Complete study sessions after 7 PM for 7 days',
        icon: '🌙',
        sortOrder: 501,
      ),
      AchievementCatalog(
        id: 'weekend_warrior',
        title: 'Weekend Warrior',
        category: AchievementCategory.consistency,
        tier: AchievementTier.silver,
        threshold: 8,
        description: 'Never let weekends break your momentum',
        howTo: 'Study on weekends for 4 consecutive weeks (8 weekend days)',
        icon: '⚔️',
        sortOrder: 502,
      ),
      AchievementCatalog(
        id: 'speed_learner',
        title: 'Speed Learner',
        category: AchievementCategory.consistency,
        tier: AchievementTier.gold,
        threshold: 50,
        description: 'Master the art of efficient learning',
        howTo: 'Complete 50 study sessions with average response time under 2 seconds',
        icon: '⚡',
        sortOrder: 503,
      ),

      // Creation Category - Enhanced
      AchievementCatalog(
        id: 'multi_format_master',
        title: 'Multi-Format Master',
        category: AchievementCategory.creation,
        tier: AchievementTier.silver,
        threshold: 3,
        description: 'Diversify your learning materials',
        howTo: 'Create study sets from PDFs, YouTube videos, and text input',
        icon: '🎨',
        sortOrder: 600,
      ),
      AchievementCatalog(
        id: 'ai_collaborator',
        title: 'AI Collaborator',
        category: AchievementCategory.creation,
        tier: AchievementTier.gold,
        threshold: 25,
        description: 'Harness the power of AI for learning',
        howTo: 'Successfully generate 25 study sets using AI assistance',
        icon: '🤖',
        sortOrder: 601,
      ),
      AchievementCatalog(
        id: 'quality_curator',
        title: 'Quality Curator',
        category: AchievementCategory.creation,
        tier: AchievementTier.platinum,
        threshold: 10,
        description: 'Create exceptional learning experiences',
        howTo: 'Create 10 study sets that you score 95% or higher on',
        icon: '✨',
        sortOrder: 602,
      ),

      // Ultra & Exports Category - Enhanced
      AchievementCatalog(
        id: 'sharing_scholar',
        title: 'Sharing Scholar',
        category: AchievementCategory.ultraExports,
        tier: AchievementTier.bronze,
        threshold: 3,
        description: 'Share your knowledge with the world',
        howTo: 'Export 3 study sets as PDFs',
        icon: '📤',
        sortOrder: 700,
      ),
      AchievementCatalog(
        id: 'ultra_explorer',
        title: 'Ultra Explorer',
        category: AchievementCategory.ultraExports,
        tier: AchievementTier.silver,
        threshold: 10,
        description: 'Dive deep with Ultra Mode',
        howTo: 'Complete 10 study sessions using Ultra Mode features',
        icon: '🚀',
        sortOrder: 701,
      ),
      AchievementCatalog(
        id: 'export_champion',
        title: 'Export Champion',
        category: AchievementCategory.ultraExports,
        tier: AchievementTier.gold,
        threshold: 15,
        description: 'Master the art of knowledge sharing',
        howTo: 'Export 15 different study sets in various formats',
        icon: '📊',
        sortOrder: 702,
      ),
    ];
  }

  /// Get achievements by category for better organization
  static List<AchievementCatalog> getAchievementsByCategory(AchievementCategory category) {
    return getEnhancedCatalog().where((achievement) => achievement.category == category).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Get achievements by tier for progression tracking
  static List<AchievementCatalog> getAchievementsByTier(AchievementTier tier) {
    return getEnhancedCatalog().where((achievement) => achievement.tier == tier).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Get beginner-friendly achievements (Bronze tier)
  static List<AchievementCatalog> getBeginnerAchievements() {
    return getAchievementsByTier(AchievementTier.bronze);
  }

  /// Get advanced achievements (Gold+ tier)
  static List<AchievementCatalog> getAdvancedAchievements() {
    return getEnhancedCatalog()
        .where((achievement) => 
            achievement.tier == AchievementTier.gold ||
            achievement.tier == AchievementTier.platinum ||
            achievement.tier == AchievementTier.legendary)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }
}
