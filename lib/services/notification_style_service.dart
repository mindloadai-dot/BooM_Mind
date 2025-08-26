/// Service to handle notification styling based on user preferences
/// Provides different personality styles: mindful, coach, tough love, and cram
/// This is the core service for the most important feature of the application
class NotificationStyleService {
  static final NotificationStyleService _instance =
      NotificationStyleService._();
  static NotificationStyleService get instance => _instance;
  NotificationStyleService._();

  // Style constants
  static const String _mindfulStyle = 'mindful';
  static const String _coachStyle = 'coach';
  static const String _toughLoveStyle = 'toughlove';
  static const String _cramStyle = 'cram';

  /// Apply notification style to title and body
  static Map<String, String> applyStyle({
    required String baseTitle,
    required String baseBody,
    required String nickname,
    required String style,
    String? subject,
    String? deadline,
    int? streakDays,
    String? achievement,
    String? timeContext,
  }) {
    switch (style) {
      case _mindfulStyle:
        return _applyMindfulStyle(
          baseTitle: baseTitle,
          baseBody: baseBody,
          nickname: nickname,
          subject: subject,
          deadline: deadline,
          streakDays: streakDays,
          achievement: achievement,
          timeContext: timeContext,
        );
      case _coachStyle:
        return _applyCoachStyle(
          baseTitle: baseTitle,
          baseBody: baseBody,
          nickname: nickname,
          subject: subject,
          deadline: deadline,
          streakDays: streakDays,
          achievement: achievement,
          timeContext: timeContext,
        );
      case _toughLoveStyle:
        return _applyToughLoveStyle(
          baseTitle: baseTitle,
          baseBody: baseBody,
          nickname: nickname,
          subject: subject,
          deadline: deadline,
          streakDays: streakDays,
          achievement: achievement,
          timeContext: timeContext,
        );
      case _cramStyle:
        return _applyCramStyle(
          baseTitle: baseTitle,
          baseBody: baseBody,
          nickname: nickname,
          subject: subject,
          deadline: deadline,
          streakDays: streakDays,
          achievement: achievement,
          timeContext: timeContext,
        );
      default:
        return _applyDefaultStyle(
          baseTitle: baseTitle,
          baseBody: baseBody,
          nickname: nickname,
        );
    }
  }

  /// Apply mindful style - gentle, encouraging, mindfulness approach
  static Map<String, String> _applyMindfulStyle({
    required String baseTitle,
    required String baseBody,
    required String nickname,
    String? subject,
    String? deadline,
    int? streakDays,
    String? achievement,
    String? timeContext,
  }) {
    final mindfulPrefixes = [
      '🧘 Gentle reminder',
      '🌱 Mindful moment',
      '💭 Take a breath',
      '✨ Peaceful prompt',
      '🌿 Gentle nudge',
      '🕊️ Calm reminder',
      '🌸 Mindful attention',
      '🌅 Gentle awakening',
    ];

    final mindfulSuffixes = [
      'Take your time, $nickname',
      'You\'re doing great, $nickname',
      'Breathe and focus, $nickname',
      'Stay present, $nickname',
      'You\'ve got this, $nickname',
      'Trust the process, $nickname',
      'Be kind to yourself, $nickname',
      'Find your center, $nickname',
    ];

    final prefix =
        mindfulPrefixes[DateTime.now().millisecond % mindfulPrefixes.length];
    final suffix =
        mindfulSuffixes[DateTime.now().millisecond % mindfulSuffixes.length];

    String styledTitle = '$prefix: $baseTitle';
    String styledBody = '$baseBody\n\n$suffix';

    // Add context-specific mindful messages
    if (deadline != null) {
      styledBody +=
          '\n\n⏰ Remember: deadlines are opportunities for growth, not stress.';
    }
    if (streakDays != null && streakDays > 0) {
      styledBody +=
          '\n\n🔥 Your $streakDays-day streak shows incredible dedication.';
    }
    if (achievement != null) {
      styledBody += '\n\n🏆 Celebrate this achievement mindfully.';
    }

    return {
      'title': styledTitle,
      'body': styledBody,
    };
  }

  /// Apply coach style - motivational, guidance-based, positive reinforcement
  static Map<String, String> _applyCoachStyle({
    required String baseTitle,
    required String baseBody,
    required String nickname,
    String? subject,
    String? deadline,
    int? streakDays,
    String? achievement,
    String? timeContext,
  }) {
    final coachPrefixes = [
      '🏆 Come on',
      '🚀 Let\'s go',
      '💪 You\'re ready',
      '🎯 Time to shine',
      '⭐ You\'ve got this',
      '🔥 Let\'s crush it',
      '🌟 Your moment',
      '⚡ Game time',
    ];

    final coachSuffixes = [
      '$nickname! You\'re absolutely crushing it!',
      '$nickname! This is your time to excel!',
      '$nickname! You\'re built for this challenge!',
      '$nickname! Let\'s show them what you\'re made of!',
      '$nickname! You\'re a natural at this!',
      '$nickname! Time to level up!',
      '$nickname! You\'re unstoppable!',
      '$nickname! Let\'s make it happen!',
    ];

    final prefix =
        coachPrefixes[DateTime.now().millisecond % coachPrefixes.length];
    final suffix =
        coachSuffixes[DateTime.now().millisecond % coachSuffixes.length];

    String styledTitle = '$prefix, $nickname! $baseTitle';
    String styledBody = '$baseBody\n\n$suffix';

    // Add coach-specific motivational content
    if (deadline != null) {
      styledBody +=
          '\n\n⏰ Deadline approaching! This is your chance to prove what you\'re capable of!';
    }
    if (streakDays != null && streakDays > 0) {
      styledBody +=
          '\n\n🔥 $streakDays days strong! You\'re building an incredible habit!';
    }
    if (achievement != null) {
      styledBody +=
          '\n\n🏆 Achievement unlocked! This is just the beginning of your greatness!';
    }
    if (subject != null) {
      styledBody += '\n\n📚 $subject is your domain now! Own it!';
    }

    return {
      'title': styledTitle,
      'body': styledBody,
    };
  }

  /// Apply tough love style - direct, challenging, pushing limits
  static Map<String, String> _applyToughLoveStyle({
    required String baseTitle,
    required String baseBody,
    required String nickname,
    String? subject,
    String? deadline,
    int? streakDays,
    String? achievement,
    String? timeContext,
  }) {
    final toughLovePrefixes = [
      '💪 Listen up',
      '🚨 Wake up call',
      '⚡ Reality check',
      '🔥 No excuses',
      '💀 Stop procrastinating',
      '⚔️ Time to fight',
      '💣 Drop the excuses',
      '🦾 Get serious',
    ];

    final toughLoveSuffixes = [
      '$nickname, stop making excuses and get to work!',
      '$nickname, you\'re better than this!',
      '$nickname, time to stop playing and start winning!',
      '$nickname, you\'re wasting your potential!',
      '$nickname, get off your butt and make it happen!',
      '$nickname, this is your life - take control!',
      '$nickname, stop being average when you can be exceptional!',
      '$nickname, you\'re capable of so much more!',
    ];

    final prefix = toughLovePrefixes[
        DateTime.now().millisecond % toughLovePrefixes.length];
    final suffix = toughLoveSuffixes[
        DateTime.now().millisecond % toughLoveSuffixes.length];

    String styledTitle = '$prefix, $nickname! $baseTitle';
    String styledBody = '$baseBody\n\n$suffix';

    // Add tough love specific challenging content
    if (deadline != null) {
      styledBody +=
          '\n\n⏰ Deadline is coming fast! Are you going to let it beat you?';
    }
    if (streakDays != null && streakDays > 0) {
      styledBody +=
          '\n\n🔥 $streakDays days? That\'s nothing! Let\'s make it $streakDays+!';
    }
    if (achievement != null) {
      styledBody +=
          '\n\n🏆 Achievement unlocked? Good. Now go get another one!';
    }
    if (subject != null) {
      styledBody +=
          '\n\n📚 $subject won\'t learn itself! Get in there and dominate!';
    }

    return {
      'title': styledTitle,
      'body': styledBody,
    };
  }

  /// Apply cram style - high-intensity, urgent, maximum focus
  static Map<String, String> _applyCramStyle({
    required String baseTitle,
    required String baseBody,
    required String nickname,
    String? subject,
    String? deadline,
    int? streakDays,
    String? achievement,
    String? timeContext,
  }) {
    final cramPrefixes = [
      '🚨 URGENT',
      '⚡ CRITICAL',
      '💥 EMERGENCY',
      '🔥 MAXIMUM FOCUS',
      '💀 DO OR DIE',
      '⚔️ BATTLE MODE',
      '💣 EXPLOSIVE',
      '🦾 OVERDRIVE',
    ];

    final cramSuffixes = [
      '$nickname! This is CRITICAL!',
      '$nickname! MAXIMUM INTENSITY NOW!',
      '$nickname! GO INTO OVERDRIVE!',
      '$nickname! THIS IS YOUR MOMENT!',
      '$nickname! PUSH YOUR LIMITS!',
      '$nickname! BREAK THROUGH!',
      '$nickname! UNLEASH YOUR POWER!',
      '$nickname! DOMINATE THIS!',
    ];

    final prefix =
        cramPrefixes[DateTime.now().millisecond % cramPrefixes.length];
    final suffix =
        cramSuffixes[DateTime.now().millisecond % cramSuffixes.length];

    String styledTitle = '$prefix: $baseTitle - $nickname!';
    String styledBody = '$baseBody\n\n$suffix';

    // Add cram-specific urgent content
    if (deadline != null) {
      styledBody += '\n\n⏰ DEADLINE IMMINENT! EVERY SECOND COUNTS!';
    }
    if (streakDays != null && streakDays > 0) {
      styledBody += '\n\n🔥 $streakDays DAYS OF POWER! DON\'T BREAK THE CHAIN!';
    }
    if (achievement != null) {
      styledBody += '\n\n🏆 ACHIEVEMENT UNLOCKED! NOW GO GET MORE!';
    }
    if (subject != null) {
      styledBody += '\n\n📚 $subject IS YOUR BATTLEFIELD! CONQUER IT!';
    }

    return {
      'title': styledTitle,
      'body': styledBody,
    };
  }

  /// Apply default style - balanced, neutral approach
  static Map<String, String> _applyDefaultStyle({
    required String baseTitle,
    required String baseBody,
    required String nickname,
  }) {
    return {
      'title': '$baseTitle - $nickname',
      'body': baseBody,
    };
  }

  /// Get style-specific emoji for different notification types
  static String getStyleEmoji(String style, String notificationType) {
    switch (style) {
      case _mindfulStyle:
        return _getMindfulEmoji(notificationType);
      case _coachStyle:
        return _getCoachEmoji(notificationType);
      case _toughLoveStyle:
        return _getToughLoveEmoji(notificationType);
      case _cramStyle:
        return _getCramEmoji(notificationType);
      default:
        return _getDefaultEmoji(notificationType);
    }
  }

  /// Get mindful style emojis
  static String _getMindfulEmoji(String notificationType) {
    switch (notificationType) {
      case 'study_reminder':
        return '🧘';
      case 'pop_quiz':
        return '🌱';
      case 'streak_reminder':
        return '🌸';
      case 'achievement':
        return '✨';
      case 'deadline':
        return '🌿';
      case 'session_reminder':
        return '🕊️';
      default:
        return '🧘';
    }
  }

  /// Get coach style emojis
  static String _getCoachEmoji(String notificationType) {
    switch (notificationType) {
      case 'study_reminder':
        return '🏆';
      case 'pop_quiz':
        return '🚀';
      case 'streak_reminder':
        return '🔥';
      case 'achievement':
        return '⭐';
      case 'deadline':
        return '🎯';
      case 'session_reminder':
        return '💪';
      default:
        return '🏆';
    }
  }

  /// Get tough love style emojis
  static String _getToughLoveEmoji(String notificationType) {
    switch (notificationType) {
      case 'study_reminder':
        return '💪';
      case 'pop_quiz':
        return '⚡';
      case 'streak_reminder':
        return '🔥';
      case 'achievement':
        return '⚔️';
      case 'deadline':
        return '💀';
      case 'session_reminder':
        return '💣';
      default:
        return '💪';
    }
  }

  /// Get cram style emojis
  static String _getCramEmoji(String notificationType) {
    switch (notificationType) {
      case 'study_reminder':
        return '🚨';
      case 'pop_quiz':
        return '⚡';
      case 'streak_reminder':
        return '💥';
      case 'achievement':
        return '🔥';
      case 'deadline':
        return '💀';
      case 'session_reminder':
        return '🦾';
      default:
        return '🚨';
    }
  }

  /// Get default emojis
  static String _getDefaultEmoji(String notificationType) {
    switch (notificationType) {
      case 'study_reminder':
        return '📚';
      case 'pop_quiz':
        return '🧠';
      case 'streak_reminder':
        return '🔥';
      case 'achievement':
        return '🏆';
      case 'deadline':
        return '⏰';
      case 'session_reminder':
        return '🎯';
      default:
        return '📱';
    }
  }

  /// Get style-specific urgency level
  static int getStyleUrgency(String style) {
    switch (style) {
      case _mindfulStyle:
        return 1; // Low urgency
      case _coachStyle:
        return 2; // Medium urgency
      case _toughLoveStyle:
        return 3; // High urgency
      case _cramStyle:
        return 4; // Maximum urgency
      default:
        return 2; // Default medium
    }
  }

  /// Get style-specific priority
  static bool getStylePriority(String style) {
    switch (style) {
      case _mindfulStyle:
        return false; // Low priority
      case _coachStyle:
        return false; // Medium priority
      case _toughLoveStyle:
        return true; // High priority
      case _cramStyle:
        return true; // Maximum priority
      default:
        return false; // Default medium
    }
  }

  /// Get style-specific channel type
  static String getStyleChannel(String style, String baseChannel) {
    switch (style) {
      case _mindfulStyle:
        return 'mindful_$baseChannel';
      case _coachStyle:
        return 'coach_$baseChannel';
      case _toughLoveStyle:
        return 'toughlove_$baseChannel';
      case _cramStyle:
        return 'cram_$baseChannel';
      default:
        return baseChannel;
    }
  }

  /// Get comprehensive style information
  static Map<String, dynamic> getStyleInfo(String style) {
    switch (style) {
      case _mindfulStyle:
        return {
          'name': 'Mindful',
          'emoji': '🧘',
          'description':
              'Gentle, encouraging reminders with mindfulness approach',
          'urgency': 1,
          'priority': false,
          'tone': 'calm',
          'intensity': 'low',
        };
      case _coachStyle:
        return {
          'name': 'Coach',
          'emoji': '🏆',
          'description': 'Motivational guidance with positive reinforcement',
          'urgency': 2,
          'priority': false,
          'tone': 'motivational',
          'intensity': 'medium',
        };
      case _toughLoveStyle:
        return {
          'name': 'Tough Love',
          'emoji': '💪',
          'description': 'Direct, challenging messages to push your limits',
          'urgency': 3,
          'priority': true,
          'tone': 'challenging',
          'intensity': 'high',
        };
      case _cramStyle:
        return {
          'name': 'Cram',
          'emoji': '🚨',
          'description':
              'High-intensity, urgent notifications for maximum focus',
          'urgency': 4,
          'priority': true,
          'tone': 'urgent',
          'intensity': 'maximum',
        };
      default:
        return {
          'name': 'Default',
          'emoji': '📱',
          'description': 'Balanced notification style',
          'urgency': 2,
          'priority': false,
          'tone': 'neutral',
          'intensity': 'medium',
        };
    }
  }
}
