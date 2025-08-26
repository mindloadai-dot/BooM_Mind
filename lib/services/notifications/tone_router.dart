class ToneRouterInput {
  final int streak;
  final DateTime? lastOpenedAt;
  final double openRate30d;
  final Duration? timeToDeadline; // null if none
  final List<String> preferredTones;

  ToneRouterInput({
    required this.streak,
    this.lastOpenedAt,
    this.openRate30d = 0.0,
    this.timeToDeadline,
    this.preferredTones = const ['coach', 'mindful'],
  });
}

class ToneRouter {
  static List<String> route(ToneRouterInput input, Map<String, int> perToneCaps) {
    final List<String> candidates = [];
    final lowEngagement = input.openRate30d < 0.2 || input.lastOpenedAt == null || input.streak <= 1;
    final imminent = input.timeToDeadline != null && input.timeToDeadline!.inHours <= 24;

    if (imminent) {
      // Allow pushy tones, but respect caps
      _pushIfCap(candidates, 'toughLove', perToneCaps);
      _pushIfCap(candidates, 'cram', perToneCaps);
    }

    if (lowEngagement) {
      _pushIfCap(candidates, 'coach', perToneCaps);
      _pushIfCap(candidates, 'mindful', perToneCaps);
    }

    if (input.streak >= 5) {
      _pushIfCap(candidates, 'coach', perToneCaps);
    }

    // Respect user preference ordering
    for (final t in input.preferredTones) {
      _pushIfCap(candidates, t, perToneCaps);
    }

    // Fallback ensure at least something
    for (final t in ['coach', 'mindful', 'toughLove', 'cram']) {
      if (!candidates.contains(t)) _pushIfCap(candidates, t, perToneCaps);
    }
    return candidates.toSet().toList();
  }

  static void _pushIfCap(List<String> out, String tone, Map<String, int> caps) {
    if ((caps[tone] ?? 0) > 0) out.add(tone);
  }
}


