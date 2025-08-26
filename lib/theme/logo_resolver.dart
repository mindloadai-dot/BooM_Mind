import 'package:flutter/material.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/theme/contrast.dart';

class LogoDecision {
  final String asset;
  final LogoStyle style; // none|halo|outline|scrim
  final double minWidth;
  const LogoDecision(this.asset, this.style, {this.minWidth = 24});
}

enum LogoStyle { none, halo, outline, scrim }

class LogoResolver {
  static LogoDecision resolve({
    required Color background,
    required AppTheme theme,
    required bool highContrastMode,
    bool alwaysReadableLogos = false,
  }) {
    // Candidate assets per theme
    final assets = _assetsForTheme(theme);
    const minRatio = 4.5;

    // Prefer full-color
    if (!alwaysReadableLogos) {
      if (contrastRatio(assets.color.fgColor, background) >= minRatio) {
        return LogoDecision(assets.color.path, LogoStyle.none);
      }
    }
    // Try light/dark variants
    if (contrastRatio(assets.light.fgColor, background) >= minRatio) {
      return LogoDecision(assets.light.path, LogoStyle.none);
    }
    if (contrastRatio(assets.dark.fgColor, background) >= minRatio) {
      return LogoDecision(assets.dark.path, LogoStyle.none);
    }
    // Fallback: monotone with halo or scrim depending on luminance
    final mono = assets.mono;
    final needsHalo = contrastRatio(mono.fgColor, background) < minRatio;
    final useScrim = computeLuminance(background) > 0.6; // bright bg ⇒ scrim
    return LogoDecision(
      mono.path,
      highContrastMode || useScrim ? LogoStyle.scrim : (needsHalo ? LogoStyle.halo : LogoStyle.none),
    );
  }

  static _LogoSet _assetsForTheme(AppTheme theme) {
    // Paths are examples; ensure these exist under assets/images/
    return _LogoSet(
      color: _LogoAsset('assets/images/Brain_logo.png', Colors.white),
      light: _LogoAsset('assets/images/Brain_logo.png', Colors.black),
      dark: _LogoAsset('assets/images/Brain_logo.png', Colors.white),
      mono: _LogoAsset('assets/images/Brain_logo.png', Colors.white),
    );
  }
}

class _LogoSet {
  final _LogoAsset color;
  final _LogoAsset light;
  final _LogoAsset dark;
  final _LogoAsset mono;
  const _LogoSet({required this.color, required this.light, required this.dark, required this.mono});
}

class _LogoAsset {
  final String path;
  final Color fgColor;
  const _LogoAsset(this.path, this.fgColor);
}


