// import 'dart:math';
// import 'package:flutter/foundation.dart';
import 'package:mindload/services/notifications/state_store.dart';
import 'package:mindload/services/notifications/phrase_picker.dart';
import 'package:mindload/services/notifications/tone_router.dart';
import 'package:mindload/services/notifications/timezone_local.dart';
import 'package:mindload/services/notification_service.dart';

class OfflineScheduler {
  static Future<void> initialize() async {
    await PhrasePicker.initialize();
    await LocalStateStore.loadPrefs();
    await LocalStateStore.loadMetrics();
  }

  static Future<void> sendTest() async {
    final p = PhrasePicker.pick('coach');
    await NotificationService.instance.sendImmediateNotification('Mindload Test', p.text);
    await _recordSend('coach', p.key);
  }

  static Future<void> tick() async {
    final prefs = await LocalStateStore.loadPrefs();
    final metrics = await LocalStateStore.loadMetrics();
    final now = DateTime.now();

    // Quiet hours
    if (prefs.quietEnabled && TimezoneLocal.withinQuietHours(now, prefs.quietStart, prefs.quietEnd)) {
      return;
    }

    // Fatigue min gap
    if (metrics.lastSentAt != null) {
      final last = DateTime.tryParse(metrics.lastSentAt!);
      if (last != null && now.difference(last).inMinutes < prefs.minGapMinutes) return;
    }

    // Daily/weekly caps
    if ((metrics.sentDay['total'] ?? 0) >= prefs.globalMaxPerDay) return;
    if (metrics.weekTotal >= prefs.maxPerWeek) return;

    // Tone routing (simplified; deadlines omitted in MVP)
    final input = ToneRouterInput(
      streak: metrics.streak,
      lastOpenedAt: metrics.lastOpenedAt != null ? DateTime.tryParse(metrics.lastOpenedAt!) : null,
      openRate30d: metrics.openRate30d,
      timeToDeadline: null,
      preferredTones: prefs.preferredTones,
    );
    final tones = ToneRouter.route(input, prefs.perToneMax);
    if (tones.isEmpty) return;

    // Pick first valid tone within per-tone caps
    String? toneToSend;
    for (final t in tones) {
      final sentForTone = metrics.sentDay[t] ?? 0;
      final maxForTone = prefs.perToneMax[t] ?? 0;
      if (sentForTone < maxForTone) { toneToSend = t; break; }
    }
    if (toneToSend == null) return;

    // Phrase selection with de-dupe
    final picked = PhrasePicker.pick(toneToSend);
    if (metrics.recentKeys.contains(picked.key)) return;

    // Jitter +/- up to 15 minutes (MVP: immediate send is fine)
    await NotificationService.instance.sendImmediateNotification('Mindload', picked.text);
    await _recordSend(toneToSend, picked.key);
  }

  static Future<void> _recordSend(String tone, String key) async {
    final metrics = await LocalStateStore.loadMetrics();
    final now = DateTime.now();
    metrics.lastSentAt = now.toIso8601String();
    metrics.sentDay[tone] = (metrics.sentDay[tone] ?? 0) + 1;
    metrics.sentDay['total'] = (metrics.sentDay['total'] ?? 0) + 1;
    metrics.weekTotal += 1;
    metrics.recentKeys.insert(0, key);
    while (metrics.recentKeys.length > 10) { metrics.recentKeys.removeLast(); }
    await LocalStateStore.saveMetrics(metrics);
  }
}


