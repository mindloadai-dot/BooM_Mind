import 'dart:math' as math;
import 'package:flutter/material.dart';

double computeLuminance(Color color) {
  // Convert sRGB to linear
  double channel(double c) {
    c = c / 255.0;
    return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  }
  final r = channel(color.red.toDouble());
  final g = channel(color.green.toDouble());
  final b = channel(color.blue.toDouble());
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double contrastRatio(Color fg, Color bg) {
  final l1 = computeLuminance(fg) + 0.05;
  final l2 = computeLuminance(bg) + 0.05;
  final ratio = l1 > l2 ? l1 / l2 : l2 / l1;
  return double.parse(ratio.toStringAsFixed(2));
}

Color pickReadableFg(Color bg, {
  required List<Color> options,
  double minRatio = 4.5,
}) {
  // Try provided options first
  Color? best;
  double bestRatio = 0;
  for (final c in options) {
    final r = contrastRatio(c, bg);
    if (r >= minRatio) {
      return c;
    }
    if (r > bestRatio) {
      bestRatio = r;
      best = c;
    }
  }
  // Fallback: choose the most contrasting among options
  return best ?? (computeLuminance(bg) > 0.5 ? Colors.black : Colors.white);
}

({Color fg, bool useHalo}) pickReadableOnAccent(Color accentBg, {
  required List<Color> candidates,
  double minRatio = 4.5,
}) {
  final chosen = pickReadableFg(accentBg, options: candidates, minRatio: minRatio);
  final ok = contrastRatio(chosen, accentBg) >= minRatio;
  return (fg: chosen, useHalo: !ok);
}

({Color fg, bool needsHalo}) ensureContrast(Color fg, Color bg, {double minRatio = 4.5}) {
  final ratio = contrastRatio(fg, bg);
  if (ratio >= minRatio) return (fg: fg, needsHalo: false);
  // If fail, attempt white/black
  final alt = pickReadableFg(bg, options: [fg, Colors.white, Colors.black], minRatio: minRatio);
  final ok = contrastRatio(alt, bg) >= minRatio;
  return (fg: alt, needsHalo: !ok);
}


