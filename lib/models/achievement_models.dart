import 'package:flutter/foundation.dart';

// Achievement Categories
enum AchievementCategory {
  streaks('streaks'),
  studyTime('study_time'),
  cardsCreated('cards_created'),
  cardsReviewed('cards_reviewed'),
  quizMastery('quiz_mastery'),
  consistency('consistency'),
  creation('creation'),
  ultraExports('ultra_exports');

  const AchievementCategory(this.id);
  final String id;
  
  static AchievementCategory fromId(String id) {
    return values.firstWhere((cat) => cat.id == id, orElse: () => streaks);
  }
}

// Achievement Tiers
enum AchievementTier {
  bronze('bronze', 'Bronze'),
  silver('silver', 'Silver'),
  gold('gold', 'Gold'),
  platinum('platinum', 'Platinum'),
  legendary('legendary', 'Legendary');

  const AchievementTier(this.id, this.displayName);
  final String id;
  final String displayName;
  
  static AchievementTier fromId(String id) {
    return values.firstWhere((tier) => tier.id == id, orElse: () => bronze);
  }
}

// Achievement Status
enum AchievementStatus {
  locked('locked'),
  inProgress('in_progress'), 
  earned('earned');

  const AchievementStatus(this.id);
  final String id;
  
  static AchievementStatus fromId(String id) {
    return values.firstWhere((status) => status.id == id, orElse: () => locked);
  }
}

// Achievement Catalog Entry (Firestore: /achievements/catalog/{id})
@immutable
class AchievementCatalog {
  final String id;
  final String title;
  final AchievementCategory category;
  final AchievementTier tier;
  final int threshold;
  final String description;
  final String howTo;
  final String icon;
  final int sortOrder;
  
  const AchievementCatalog({
    required this.id,
    required this.title,
    required this.category,
    required this.tier,
    required this.threshold,
    required this.description,
    required this.howTo,
    required this.icon,
    required this.sortOrder,
  });
  
  factory AchievementCatalog.fromJson(Map<String, dynamic> json) {
    return AchievementCatalog(
      id: json['id'] as String,
      title: json['title'] as String,
      category: AchievementCategory.fromId(json['category'] as String),
      tier: AchievementTier.fromId(json['tier'] as String),
      threshold: json['threshold'] as int,
      description: json['description'] as String,
      howTo: json['howTo'] as String,
      icon: json['icon'] as String,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category.id,
      'tier': tier.id,
      'threshold': threshold,
      'description': description,
      'howTo': howTo,
      'icon': icon,
      'sortOrder': sortOrder,
    };
  }
  
  AchievementCatalog copyWith({
    String? id,
    String? title,
    AchievementCategory? category,
    AchievementTier? tier,
    int? threshold,
    String? description,
    String? howTo,
    String? icon,
    int? sortOrder,
  }) {
    return AchievementCatalog(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      tier: tier ?? this.tier,
      threshold: threshold ?? this.threshold,
      description: description ?? this.description,
      howTo: howTo ?? this.howTo,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AchievementCatalog &&
        other.id == id &&
        other.title == title &&
        other.category == category &&
        other.tier == tier &&
        other.threshold == threshold &&
        other.description == description &&
        other.howTo == howTo &&
        other.icon == icon &&
        other.sortOrder == sortOrder;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, category, tier, threshold, description, howTo, icon, sortOrder);
  }

  @override
  String toString() {
    return 'AchievementCatalog(id: $id, title: $title, category: ${category.id}, tier: ${tier.id}, threshold: $threshold)';
  }
}

// User Achievement State (Firestore: /users/{uid}/achievements/{id})
@immutable 
class UserAchievement {
  final String id;
  final AchievementStatus status;
  final int progress;
  final DateTime? earnedAt;
  final bool rewardGranted;
  final DateTime lastUpdated;
  
  const UserAchievement({
    required this.id,
    required this.status,
    required this.progress,
    this.earnedAt,
    required this.rewardGranted,
    required this.lastUpdated,
  });

  /// Create a locked user achievement
  factory UserAchievement.locked(String id) {
    return UserAchievement(
      id: id,
      status: AchievementStatus.locked,
      progress: 0,
      rewardGranted: false,
      lastUpdated: DateTime.now(),
    );
  }
  
  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      id: json['id'] as String,
      status: AchievementStatus.fromId(json['status'] as String),
      progress: json['progress'] as int,
      earnedAt: json['earnedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['earnedAt'] as int)
          : null,
      rewardGranted: json['rewardGranted'] as bool? ?? false,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(json['lastUpdated'] as int),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status.id,
      'progress': progress,
      'earnedAt': earnedAt?.millisecondsSinceEpoch,
      'rewardGranted': rewardGranted,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }
  
  UserAchievement copyWith({
    String? id,
    AchievementStatus? status,
    int? progress,
    DateTime? earnedAt,
    bool? rewardGranted,
    DateTime? lastUpdated,
  }) {
    return UserAchievement(
      id: id ?? this.id,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      earnedAt: earnedAt ?? this.earnedAt,
      rewardGranted: rewardGranted ?? this.rewardGranted,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserAchievement &&
        other.id == id &&
        other.status == status &&
        other.progress == progress &&
        other.earnedAt == earnedAt &&
        other.rewardGranted == rewardGranted &&
        other.lastUpdated == lastUpdated;
  }

  @override
  int get hashCode {
    return Object.hash(id, status, progress, earnedAt, rewardGranted, lastUpdated);
  }

  @override
  String toString() {
    return 'UserAchievement(id: $id, status: ${status.id}, progress: $progress, earnedAt: $earnedAt, rewardGranted: $rewardGranted)';
  }
}

// Achievement Metadata (Firestore: /users/{uid}/achievementsMeta)
@immutable
class AchievementsMeta {
  final int bonusCounter;
  final List<String> lastNudges;
  final DateTime lastBonusGranted;
  final int monthlyBonusCount;
  final DateTime lastMonthlyReset;
  
  const AchievementsMeta({
    required this.bonusCounter,
    required this.lastNudges,
    required this.lastBonusGranted,
    required this.monthlyBonusCount,
    required this.lastMonthlyReset,
  });
  
  factory AchievementsMeta.empty() {
    return AchievementsMeta(
      bonusCounter: 0,
      lastNudges: [],
      lastBonusGranted: DateTime.fromMillisecondsSinceEpoch(0),
      monthlyBonusCount: 0,
      lastMonthlyReset: DateTime.now(),
    );
  }
  
  factory AchievementsMeta.fromJson(Map<String, dynamic> json) {
    return AchievementsMeta(
      bonusCounter: json['bonusCounter'] as int? ?? 0,
      lastNudges: (json['lastNudges'] as List<dynamic>?)?.cast<String>() ?? [],
      lastBonusGranted: json['lastBonusGranted'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['lastBonusGranted'] as int)
          : DateTime.fromMillisecondsSinceEpoch(0),
      monthlyBonusCount: json['monthlyBonusCount'] as int? ?? 0,
      lastMonthlyReset: json['lastMonthlyReset'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['lastMonthlyReset'] as int)
          : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'bonusCounter': bonusCounter,
      'lastNudges': lastNudges,
      'lastBonusGranted': lastBonusGranted.millisecondsSinceEpoch,
      'monthlyBonusCount': monthlyBonusCount,
      'lastMonthlyReset': lastMonthlyReset.millisecondsSinceEpoch,
    };
  }
  
  AchievementsMeta copyWith({
    int? bonusCounter,
    List<String>? lastNudges,
    DateTime? lastBonusGranted,
    int? monthlyBonusCount,
    DateTime? lastMonthlyReset,
  }) {
    return AchievementsMeta(
      bonusCounter: bonusCounter ?? this.bonusCounter,
      lastNudges: lastNudges ?? this.lastNudges,
      lastBonusGranted: lastBonusGranted ?? this.lastBonusGranted,
      monthlyBonusCount: monthlyBonusCount ?? this.monthlyBonusCount,
      lastMonthlyReset: lastMonthlyReset ?? this.lastMonthlyReset,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AchievementsMeta &&
        other.bonusCounter == bonusCounter &&
        listEquals(other.lastNudges, lastNudges) &&
        other.lastBonusGranted == lastBonusGranted &&
        other.monthlyBonusCount == monthlyBonusCount &&
        other.lastMonthlyReset == lastMonthlyReset;
  }

  @override
  int get hashCode {
    return Object.hash(bonusCounter, Object.hashAll(lastNudges), lastBonusGranted, monthlyBonusCount, lastMonthlyReset);
  }

  @override
  String toString() {
    return 'AchievementsMeta(bonusCounter: $bonusCounter, lastNudges: ${lastNudges.length}, monthlyBonusCount: $monthlyBonusCount)';
  }
}

// Combined view for UI display
@immutable
class AchievementDisplay {
  final AchievementCatalog catalog;
  final UserAchievement userState;
  
  const AchievementDisplay({
    required this.catalog,
    required this.userState,
  });
  
  // Computed properties
  double get progressPercent => 
      catalog.threshold > 0 ? (userState.progress / catalog.threshold).clamp(0.0, 1.0) : 0.0;
  
  bool get isLocked => userState.status == AchievementStatus.locked;
  bool get isInProgress => userState.status == AchievementStatus.inProgress;
  bool get isEarned => userState.status == AchievementStatus.earned;
  
  int get remainingProgress => (catalog.threshold - userState.progress).clamp(0, catalog.threshold);
  
  String get progressText => '${userState.progress}/${catalog.threshold}';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AchievementDisplay &&
        other.catalog == catalog &&
        other.userState == userState;
  }

  @override
  int get hashCode => Object.hash(catalog, userState);

  @override
  String toString() {
    return 'AchievementDisplay(${catalog.title}: ${userState.progress}/${catalog.threshold}, ${userState.status.id})';
  }
}

// Achievement Constants
class AchievementConstants {
  static const int rewardEveryN = 2; // 1 free credit for every 2 achievements
  static const int maxMonthlyBonusCredits = 10; // Safety cap
  
  // Categories display names
  static const Map<AchievementCategory, String> categoryNames = {
    AchievementCategory.streaks: 'Streaks',
    AchievementCategory.studyTime: 'Study Time',
    AchievementCategory.cardsCreated: 'Cards Created',
    AchievementCategory.cardsReviewed: 'Cards Reviewed', 
    AchievementCategory.quizMastery: 'Quiz Mastery',
    AchievementCategory.consistency: 'Consistency & Focus',
    AchievementCategory.creation: 'Creation Discipline',
    AchievementCategory.ultraExports: 'Ultra & Exports',
  };
  
  // Tier colors (semantic token references)
  static const Map<AchievementTier, String> tierColorKeys = {
    AchievementTier.bronze: 'bronze',    // Maps to theme token
    AchievementTier.silver: 'silver',    // Maps to theme token
    AchievementTier.gold: 'gold',        // Maps to theme token
    AchievementTier.platinum: 'platinum', // Maps to theme token
    AchievementTier.legendary: 'legendary', // Maps to theme token
  };
  
  // Achievement IDs (for easy reference)
  static const String focusedFive = 'focused_five';
  static const String steadyTen = 'steady_ten';
  static const String relentlessThirty = 'relentless_thirty';
  static const String quarterBrain = 'quarter_brain';
  static const String yearOfCortex = 'year_of_cortex';
  
  static const String warmUp = 'warm_up';
  static const String deepDiver = 'deep_diver';
  static const String grinder = 'grinder';
  static const String scholar = 'scholar';
  static const String marathonMind = 'marathon_mind';
  
  static const String forge250 = 'forge_250';
  static const String forge1k = 'forge_1k';
  static const String forge25k = 'forge_25k';
  static const String forge5k = 'forge_5k';
  static const String forge10k = 'forge_10k';
  
  static const String review1k = 'review_1k';
  static const String review5k = 'review_5k';
  static const String review10k = 'review_10k';
  static const String review25k = 'review_25k';
  static const String review50k = 'review_50k';
  
  static const String ace10 = 'ace_10';
  static const String ace25 = 'ace_25';
  static const String ace50 = 'ace_50';
  static const String ace100 = 'ace_100';
  static const String ace250 = 'ace_250';
  
  static const String fiveAWeek = 'five_a_week';
  static const String distractionFree = 'distraction_free';
  
  // Additional constants for enhanced tracking
  static const String fivePerWeek = 'five_per_week';
  static const String efficientCreator = 'efficient_creator';
  static const String reviewMaster = 'review_master';
  
  static const String setBuilder20 = 'set_builder_20';
  static const String setBuilder50 = 'set_builder_50';
  static const String setBuilder100 = 'set_builder_100';
  static const String efficiencySage = 'efficiency_sage';
  
  static const String ultraRuns10 = 'ultra_runs_10';
  static const String ultraRuns30 = 'ultra_runs_30';
  static const String ultraRuns75 = 'ultra_runs_75';
  static const String ultraRuns150 = 'ultra_runs_150';
  
  static const String shipIt5 = 'ship_it_5';
  static const String shipIt20 = 'ship_it_20';
  static const String shipIt50 = 'ship_it_50';
  static const String shipIt100 = 'ship_it_100';
}