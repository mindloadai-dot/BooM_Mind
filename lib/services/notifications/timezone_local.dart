class TimezoneLocal {
  // Parse HH:mm local time
  static DateTime todayAt(String hhmm) {
    final parts = hhmm.split(':');
    final now = DateTime.now();
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    return DateTime(now.year, now.month, now.day, h, m);
  }

  static bool withinQuietHours(DateTime now, String start, String end) {
    final s = _h(start);
    final e = _h(end);
    final n = now.hour * 60 + now.minute;
    if (s <= e) return n >= s && n <= e; // same day
    // crosses midnight
    return n >= s || n <= e;
  }

  static int _h(String hhmm) {
    final p = hhmm.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }
}


