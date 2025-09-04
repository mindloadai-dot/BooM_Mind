import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindload/services/unified_storage_service.dart';
import 'package:mindload/services/user_specific_storage_service.dart';
import 'package:mindload/services/auth_service.dart';
import 'package:mindload/services/telemetry_service.dart';
import 'dart:developer' as developer;

// Exact theme IDs as specified
enum AppTheme {
  classic('classic'),
  matrix('matrix'),
  retro('retro'),
  cyberNeon('cyber_neon'), // renamed to match requirement
  darkMode('dark_mode'), // renamed to match requirement
  minimal('minimal'),
  purpleNeon('purple_neon'), // New Purple Neon theme
  oceanDepths('ocean_depths'), // New Ocean Depths theme
  sunsetGlow('sunset_glow'), // New Sunset Glow theme
  forestNight('forest_night'); // New Forest Night theme

  const AppTheme(this.id);
  final String id;

  static AppTheme fromId(String id) {
    return AppTheme.values
        .firstWhere((theme) => theme.id == id, orElse: () => AppTheme.classic);
  }
}

// Enhanced Semantic Token System - Complete accessibility-first design tokens
class SemanticTokens {
  // Brand/Hero tokens (WCAG AAA requirements)
  final Color brandTitle;
  final Color brandSubtitle;
  final Color heroBackground;
  final Color heroOverlay;
  final Color shadowBrandSubtitle;

  // Navigation tokens (your specified requirements)
  final Color navIcon;
  final Color navIconPressed;
  final Color navText;
  final Color headerBg;

  // Border tokens (your specified requirements)
  final Color borderDefault;
  final Color borderFocus;
  final Color borderMuted;

  // Surface tokens (your specified requirements)
  final Color surface;
  final Color surfaceAlt;

  // Text tokens (your specified requirements)
  final Color textPrimary;
  final Color textInverse;
  final Color textSecondary;
  final Color textTertiary;
  final Color shadow;

  // Achievement System - Neon Cortex tokens (semantic only)
  final Color achieveBackground;
  final Color achieveGrid;
  final Color achieveNeon;
  final Color badgeBackground;
  final Color badgeRing;
  final Color textEmphasis;
  final Color textMuted;
  final Color focusRing;
  // Achievement tier colors
  final Color tierBronze;
  final Color tierSilver;
  final Color tierGold;
  final Color tierPlatinum;
  final Color tierLegendary;

  // Legacy core semantic roles (preserved for compatibility)
  final Color bg;
  final Color elevatedSurface;
  final Color primary;
  final Color onPrimary;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color muted;
  final Color onMuted;
  final Color accent;
  final Color onAccent;
  final Color success;
  final Color warning;
  final Color error;
  final Color outline;
  final Color divider;
  final Color overlayDim;
  final Color overlayGlow;

  // Additional compatibility aliases for enhanced screens
  Color get backgroundPrimary => bg;
  Color get backgroundSecondary => elevatedSurface;
  Color get borderPrimary => borderDefault;

  const SemanticTokens({
    // Brand/Hero tokens
    required this.brandTitle,
    required this.brandSubtitle,
    required this.heroBackground,
    required this.heroOverlay,
    required this.shadowBrandSubtitle,

    // Navigation tokens
    required this.navIcon,
    required this.navIconPressed,
    required this.navText,
    required this.headerBg,

    // Border tokens
    required this.borderDefault,
    required this.borderFocus,
    required this.borderMuted,

    // Surface tokens
    required this.surface,
    required this.surfaceAlt,

    // Text tokens
    required this.textPrimary,
    required this.textInverse,
    required this.textSecondary,
    required this.textTertiary,
    required this.shadow,

    // Achievement tokens
    required this.achieveBackground,
    required this.achieveGrid,
    required this.achieveNeon,
    required this.badgeBackground,
    required this.badgeRing,
    required this.textEmphasis,
    required this.textMuted,
    required this.focusRing,
    // Tiers
    required this.tierBronze,
    required this.tierSilver,
    required this.tierGold,
    required this.tierPlatinum,
    required this.tierLegendary,

    // Legacy tokens (preserved for compatibility)
    required this.bg,
    required this.elevatedSurface,
    required this.primary,
    required this.onPrimary,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.muted,
    required this.onMuted,
    required this.accent,
    required this.onAccent,
    required this.success,
    required this.warning,
    required this.error,
    required this.outline,
    required this.divider,
    required this.overlayDim,
    required this.overlayGlow,
  });
}

class ThemeManager extends ChangeNotifier {
  static final ThemeManager _instance = ThemeManager._internal();
  static ThemeManager get instance => _instance;
  ThemeManager._internal();

  AppTheme _currentTheme = AppTheme.classic;
  AppTheme get currentTheme => _currentTheme;

  // Runtime safety flags
  bool _isInFallbackMode = false;
  bool get isInFallbackMode => _isInFallbackMode;

  // Development diagnostics
  bool _isDiagnosticsModeEnabled = false;
  bool get isDiagnosticsModeEnabled => _isDiagnosticsModeEnabled;

  void toggleDiagnosticsMode() {
    _isDiagnosticsModeEnabled = !_isDiagnosticsModeEnabled;
    notifyListeners();
  }

  Future<void> loadTheme() async {
    try {
      String? savedTheme;

      // Try user-specific storage first (for authenticated users)
      if (AuthService.instance.isAuthenticated) {
        savedTheme = await UserSpecificStorageService.instance
            .getString('selected_theme');
      }

      // Fallback to global storage for backward compatibility
      savedTheme ??= await UnifiedStorageService.instance.getSelectedTheme();

      if (savedTheme != null) {
        _currentTheme = _parseThemeFromString(savedTheme);

        // If we loaded from global storage and user is authenticated, migrate to user-specific
        if (AuthService.instance.isAuthenticated) {
          await UserSpecificStorageService.instance
              .setString('selected_theme', savedTheme);
        }
      }

      // Theme validation removed - contrast feature no longer needed
      notifyListeners();
    } catch (e) {
      // Fallback to classic on error
      _triggerFallback(_currentTheme);
    }
  }

  Future<void> setTheme(AppTheme theme) async {
    try {
      // Theme validation removed - contrast feature no longer needed
      _currentTheme = theme;
      _isInFallbackMode = false;

      // Save to user-specific storage if authenticated
      if (AuthService.instance.isAuthenticated) {
        await UserSpecificStorageService.instance
            .setString('selected_theme', theme.id);
      } else {
        // Fallback to global storage for unauthenticated users
        await UnifiedStorageService.instance.saveSelectedTheme(theme.id);
      }

      // Emit telemetry
      TelemetryService.instance.logEvent(
        TelemetryEvent.themeApplied.name,
        {
          'theme_id': theme.id,
          'is_fallback': _isInFallbackMode,
          'user_specific': AuthService.instance.isAuthenticated
        },
      );

      notifyListeners();
    } catch (e) {
      _triggerFallback(theme);
    }
  }

  void _triggerFallback(AppTheme failedTheme) {
    _currentTheme = AppTheme.classic;
    _isInFallbackMode = true;

    TelemetryService.instance.logEvent(
      TelemetryEvent.themeFallbackTriggered.name,
      {'failed_theme_id': failedTheme.id},
    );

    developer.log(
      'Theme fallback triggered for theme: ${failedTheme.id}',
      name: 'ThemeManager',
      level: 800, // Warning level
    );

    notifyListeners();
  }

  ThemeData get lightTheme => _buildTheme(_currentTheme, Brightness.light);
  ThemeData get darkTheme => _buildTheme(_currentTheme, Brightness.dark);

  String getThemeDisplayName(AppTheme theme) {
    switch (theme) {
      case AppTheme.classic:
        return 'Scholar\'s Haven';
      case AppTheme.purpleNeon:
        return 'Neon Dreams';
      case AppTheme.matrix:
        return 'Digital Rain';
      case AppTheme.retro:
        return 'Synthwave Nights';
      case AppTheme.cyberNeon:
        return 'Electric Pulse';
      case AppTheme.darkMode:
        return 'Midnight Focus';
      case AppTheme.minimal:
        return 'Pure Zen';
      case AppTheme.oceanDepths:
        return 'Abyssal Depths';
      case AppTheme.sunsetGlow:
        return 'Golden Hour';
      case AppTheme.forestNight:
        return 'Emerald Shadows';
    }
  }

  IconData getThemeIcon(AppTheme theme) {
    switch (theme) {
      case AppTheme.classic:
        return Icons.lightbulb_outline;
      case AppTheme.purpleNeon:
        return Icons.auto_awesome;
      case AppTheme.matrix:
        return Icons.code;
      case AppTheme.retro:
        return Icons.radio;
      case AppTheme.cyberNeon:
        return Icons.flash_on;
      case AppTheme.darkMode:
        return Icons.dark_mode;
      case AppTheme.minimal:
        return Icons.circle_outlined;
      case AppTheme.oceanDepths:
        return Icons.waves;
      case AppTheme.sunsetGlow:
        return Icons.wb_sunny;
      case AppTheme.forestNight:
        return Icons.forest;
    }
  }

  AppTheme _parseThemeFromString(String themeString) {
    switch (themeString) {
      case 'classic':
        return AppTheme.classic;
      case 'purple_neon':
        return AppTheme.purpleNeon;
      case 'matrix':
        return AppTheme.matrix;
      case 'retro':
        return AppTheme.retro;
      case 'cyber_neon':
        return AppTheme.cyberNeon;
      case 'dark_mode':
        return AppTheme.darkMode;
      case 'minimal':
        return AppTheme.minimal;
      case 'ocean_depths':
        return AppTheme.oceanDepths;
      case 'sunset_glow':
        return AppTheme.sunsetGlow;
      case 'forest_night':
        return AppTheme.forestNight;
      default:
        return AppTheme.classic; // Fallback to classic
    }
  }

  SemanticTokens get currentTokens {
    try {
      return _getSemanticTokens(_currentTheme);
    } catch (e) {
      // Fallback to classic tokens if theme access fails during initialization
      return _classicTokens;
    }
  }

  // Public method to get tokens for any theme (needed for theme selector previews)
  SemanticTokens getSemanticTokens(AppTheme theme) => _getSemanticTokens(theme);

  SemanticTokens _getSemanticTokens(AppTheme theme) {
    switch (theme) {
      case AppTheme.classic:
        return _classicTokens;
      case AppTheme.purpleNeon:
        return _purpleNeonTokens;
      case AppTheme.matrix:
        return _matrixTokens;
      case AppTheme.retro:
        return _retroTokens;
      case AppTheme.cyberNeon:
        return _cyberNeonTokens;
      case AppTheme.darkMode:
        return _darkModeTokens;
      case AppTheme.minimal:
        return _minimalTokens;
      case AppTheme.oceanDepths:
        return _oceanDepthsTokens;
      case AppTheme.sunsetGlow:
        return _sunsetGlowTokens;
      case AppTheme.forestNight:
        return _forestNightTokens;
    }
  }
}

// Classic theme: clean white background with high contrast dark text for perfect readability
const SemanticTokens _classicTokens = SemanticTokens(
  // Brand/Hero tokens - WCAG AAA compliant with maximum readability
  brandTitle: Color(0xFF1565C0), // Deep blue for title
  brandSubtitle: Color(0xFF000000), // Pure black for maximum contrast on white
  heroBackground: Color(0xFFFFFFFF), // Pure white background
  heroOverlay: Color(0x0A000000), // 4% black overlay for subtle depth
  shadowBrandSubtitle: Color(0xFF666666), // Medium gray shadow

  // Navigation tokens - high contrast on white background
  navIcon: Color(0xFF000000), // Pure black for maximum visibility
  navIconPressed: Color(0xFF1565C0), // Deep blue when pressed
  navText: Color(0xFF000000), // Pure black for maximum readability
  headerBg: Color(0xFFFFFFFF), // Pure white header

  // Border tokens - visible gray borders on white
  borderDefault: Color(0xFF666666), // Medium gray for visibility
  borderFocus: Color(0xFF1565C0), // Deep blue focus ring
  borderMuted: Color(0xFF999999), // Medium gray muted border

  // Surface tokens - clean white surfaces
  surface: Color(0xFFFAFAFA), // Very light gray surface
  surfaceAlt: Color(0xFFFFFFFF), // Pure white alternative

  // Text tokens - high contrast black text on white
  textPrimary: Color(0xFF000000), // Pure black for maximum readability
  textInverse: Color(0xFFFFFFFF), // White for dark backgrounds
  textSecondary: Color(0xFF333333), // Dark gray for secondary text
  textTertiary: Color(0xFF666666), // Medium gray for tertiary text
  shadow: Color(0x1A000000), // Medium shadow

  // Achievement System - Light achievement area with high contrast
  achieveBackground: Color(0xFFF5F5F5), // Light gray surface for achievements
  achieveGrid: Color(0xFFE0E0E0), // Light gray grid lines
  achieveNeon: Color(0xFF1565C0), // Deep blue neon accents
  badgeBackground: Color(0xFFE8E8E8), // Light gray badge background
  badgeRing: Color(0xFF1565C0), // Deep blue ring
  textEmphasis: Color(0xFF000000), // Pure black emphasis text for contrast
  textMuted: Color(0xFF666666), // Dark gray muted text for contrast
  focusRing: Color(0xFF1565C0), // Deep blue focus ring
  tierBronze: Color(0xFFCD7F32),
  tierSilver: Color(0xFFC0C0C0),
  tierGold: Color(0xFFFFD700),
  tierPlatinum: Color(0xFFE5E4E2),
  tierLegendary: Color(0xFFFF6B35),

  // Legacy tokens - high contrast classic theme
  bg: Color(0xFFFFFFFF), // Pure white background
  elevatedSurface: Color(0xFFFFFFFF),
  primary: Color(0xFF1565C0),
  onPrimary: Color(0xFFFFFFFF),
  onPrimaryContainer: Color(0xFF000000),
  secondary: Color(0xFF666666),
  onSecondary: Color(0xFFFFFFFF),
  muted: Color(0xFF999999),
  onMuted: Color(0xFF000000),
  accent: Color(0xFF2E7D32),
  onAccent: Color(0xFFFFFFFF),
  success: Color(0xFF2E7D32),
  warning: Color(0xFFEF6C00),
  error: Color(0xFFD32F2F),
  outline: Color(0xFF999999),
  divider: Color(0xFFE0E0E0),
  overlayDim: Color(0xCC000000),
  overlayGlow: Color(0x1A1565C0),
);

// Matrix theme: pure black with bright green neon accents and perfect readability
const SemanticTokens _matrixTokens = SemanticTokens(
  // Brand/Hero tokens - WCAG AAA compliant Matrix theme with maximum readability
  brandTitle: Color(0xFF00FF00), // Bright neon green for Matrix title glow
  brandSubtitle: Color(0xFFFFFFFF), // Pure white for maximum contrast
  heroBackground: Color(0xFF000000), // Pure black background
  heroOverlay: Color(0x1A00FF00), // 10% green overlay for Matrix aesthetic
  shadowBrandSubtitle: Color(0xFF80FF80), // Light green shadow

  // Navigation tokens - bright green and white for maximum visibility
  navIcon: Color(0xFFFFFFFF), // Pure white for maximum visibility
  navIconPressed: Color(0xFF00FF00), // Bright green when pressed
  navText: Color(0xFFFFFFFF), // Pure white for maximum readability
  headerBg: Color(0xFF000000), // Pure black header

  // Border tokens - bright green Matrix borders
  borderDefault: Color(0xFF00FF00), // Bright green for visibility
  borderFocus: Color(0xFF80FF80), // Lighter green focus ring
  borderMuted: Color(0xFF00FF00), // Bright green muted border

  // Surface tokens - true black Matrix surfaces
  surface: Color(0xFF0A0A0A), // Very dark surface
  surfaceAlt: Color(0xFF1A1A1A), // Slightly lighter alternative

  // Text tokens - high contrast white text with green accents
  textPrimary: Color(0xFFFFFFFF), // Pure white for maximum readability
  textInverse: Color(0xFF000000), // Black for bright backgrounds
  textSecondary: Color(0xFF80FF80), // Light green for secondary text
  textTertiary: Color(0xFFE0E0E0), // Light gray for tertiary text
  shadow: Color(0x1A00FF00), // Bright green shadow

  // Achievement System - Matrix Neon Cortex style with high contrast
  achieveBackground: Color(0xFF0A0A0A), // Softer dark surface for achievements
  achieveGrid: Color(0xFF006600), // Dark green grid lines
  achieveNeon: Color(0xFF00FF00), // Bright neon green accents
  badgeBackground: Color(0xFF003300), // Dark green badge background
  badgeRing: Color(0xFF80FF80), // Light green ring
  textEmphasis: Color(0xFFFFFFFF), // Pure white emphasis text
  textMuted: Color(0xFF99FF99), // Light green muted text
  focusRing: Color(0xFF00FF00), // Bright green focus ring
  tierBronze: Color(0xFFCD7F32),
  tierSilver: Color(0xFFC0C0C0),
  tierGold: Color(0xFFFFD700),
  tierPlatinum: Color(0xFFE5E4E2),
  tierLegendary: Color(0xFFFF6B35),

  // Legacy tokens - high contrast Matrix theme
  bg: Color(0xFF000000), // Pure black background
  elevatedSurface: Color(0xFF1A1A1A),
  primary: Color(0xFF00FF00),
  onPrimary: Color(0xFF000000),
  onPrimaryContainer: Color(0xFFFFFFFF),
  secondary: Color(0xFF80FF80),
  onSecondary: Color(0xFF000000),
  muted: Color(0xFF006600),
  onMuted: Color(0xFFFFFFFF),
  accent: Color(0xFF00FF00),
  onAccent: Color(0xFF000000),
  success: Color(0xFF00CC00),
  warning: Color(0xFFFFFF00),
  error: Color(0xFFFF4444),
  outline: Color(0xFF00FF00),
  divider: Color(0xFF006600),
  overlayDim: Color(0xE6000000),
  overlayGlow: Color(0x8000FF00),
);

// Retro theme: warm beige background with dark brown text for perfect vintage readability
const SemanticTokens _retroTokens = SemanticTokens(
  // Brand/Hero tokens - WCAG AAA compliant retro with enhanced readability
  brandTitle: Color(0xFFB8860B), // Dark goldenrod for retro title
  brandSubtitle: Color(0xFF000000), // Pure black for maximum contrast on beige
  heroBackground: Color(0xFFF5F5DC), // Classic beige background
  heroOverlay: Color(0x0A8B4513), // 4% brown overlay for subtle warmth
  shadowBrandSubtitle: Color(0xFF8B4513), // Saddle brown shadow

  // Navigation tokens - dark brown for retro feel with high contrast
  navIcon: Color(0xFF000000), // Pure black for maximum visibility
  navIconPressed: Color(0xFF8B4513), // Saddle brown when pressed
  navText: Color(0xFF000000), // Pure black for maximum readability
  headerBg: Color(0xFFF5F5DC), // Beige header

  // Border tokens - dark brown retro borders
  borderDefault: Color(0xFF8B4513), // Saddle brown for visibility
  borderFocus: Color(0xFF000000), // Black focus ring for contrast
  borderMuted: Color(0xFFD2B48C), // Light tan muted border

  // Surface tokens - warm retro surfaces
  surface: Color(0xFFFAF0E6), // Linen surface
  surfaceAlt: Color(0xFFFFE4B5), // Moccasin alternative

  // Text tokens - high contrast dark brown text for perfect readability
  textPrimary: Color(0xFF000000), // Pure black for maximum readability
  textInverse: Color(0xFFFFFFFF), // White for dark backgrounds
  textSecondary: Color(0xFF2F1B14), // Very dark brown for secondary text
  textTertiary: Color(0xFF654321), // Medium brown for tertiary text
  shadow: Color(0x0A8B4513), // Saddle brown shadow

  // Achievement System - Dark retro achievement area
  achieveBackground:
      Color(0xFF2F1B14), // Dark brown retro background (kept themed)
  achieveGrid: Color(0xFF8B4513), // Saddle brown grid lines
  achieveNeon: Color(0xFFFFD700), // Gold neon accents for retro feel
  badgeBackground: Color(0xFF3C2415), // Dark brown badge background
  badgeRing: Color(0xFFFFD700), // Gold ring for vintage feel
  textEmphasis: Color(0xFFFFFFFF), // Pure white emphasis text
  textMuted: Color(0xFFE6C189), // Light tan muted text
  focusRing: Color(0xFFFFD700), // Gold focus ring
  tierBronze: Color(0xFFCD7F32),
  tierSilver: Color(0xFFC0C0C0),
  tierGold: Color(0xFFFFD700),
  tierPlatinum: Color(0xFFE5E4E2),
  tierLegendary: Color(0xFFFF6B35),

  // Legacy tokens - high contrast retro theme
  bg: Color(0xFFF5F5DC), // Beige background
  elevatedSurface: Color(0xFFFFE4B5),
  primary: Color(0xFF8B4513),
  onPrimary: Color(0xFFFFFFFF),
  onPrimaryContainer: Color(0xFF000000),
  secondary: Color(0xFFA0522D),
  onSecondary: Color(0xFFFFFFFF),
  muted: Color(0xFFD2B48C),
  onMuted: Color(0xFF000000),
  accent: Color(0xFFFFD700),
  onAccent: Color(0xFF000000),
  success: Color(0xFF228B22),
  warning: Color(0xFFFF8C00),
  error: Color(0xFF8B0000),
  outline: Color(0xFF8B4513),
  divider: Color(0xFFDDD0C0),
  overlayDim: Color(0xCC000000),
  overlayGlow: Color(0x40FFD700),
);

// Cyber Neon theme: pure black background with bright cyan neon and perfect readability
const SemanticTokens _cyberNeonTokens = SemanticTokens(
  // Brand/Hero tokens - WCAG AAA compliant cyber with maximum readability
  brandTitle: Color(0xFF00FFFF), // Bright cyan neon for title glow
  brandSubtitle: Color(0xFFFFFFFF), // Pure white for maximum contrast
  heroBackground: Color(0xFF000000), // Pure black background
  heroOverlay: Color(0x1A00FFFF), // 10% cyan overlay for cyber depth
  shadowBrandSubtitle: Color(0xFF80FFFF), // Light cyan shadow

  // Navigation tokens - bright cyan and white for maximum visibility
  navIcon: Color(0xFFFFFFFF), // Pure white for maximum visibility
  navIconPressed: Color(0xFF00FFFF), // Bright cyan when pressed
  navText: Color(0xFFFFFFFF), // Pure white for maximum readability
  headerBg: Color(0xFF000000), // Pure black header

  // Border tokens - bright cyan cyber borders
  borderDefault: Color(0xFF00FFFF), // Bright cyan for visibility
  borderFocus: Color(0xFF80FFFF), // Lighter cyan focus ring
  borderMuted: Color(0xFF00FFFF), // Bright cyan muted border

  // Surface tokens - true black cyber surfaces
  surface: Color(0xFF0A0A0A), // Very dark surface
  surfaceAlt: Color(0xFF1A1A1A), // Slightly lighter alternative

  // Text tokens - high contrast white text with cyan accents
  textPrimary: Color(0xFFFFFFFF), // Pure white for maximum readability
  textInverse: Color(0xFF000000), // Black for bright backgrounds
  textSecondary: Color(0xFF80FFFF), // Light cyan for secondary text
  textTertiary: Color(0xFFE0E0E0), // Light gray for tertiary text
  shadow: Color(0x1A00FFFF), // Bright cyan shadow

  // Achievement System - Cyber Neon Cortex style with high contrast
  achieveBackground: Color(0xFF0A0A0A), // Softer dark surface for achievements
  achieveGrid: Color(0xFF006666), // Dark cyan grid lines
  achieveNeon: Color(0xFF00FFFF), // Bright cyan neon accents
  badgeBackground: Color(0xFF003333), // Dark cyan badge background
  badgeRing: Color(0xFF80FFFF), // Light cyan ring
  textEmphasis: Color(0xFFFFFFFF), // Pure white emphasis text
  textMuted: Color(0xFF99FFFF), // Light cyan muted text
  focusRing: Color(0xFF00FFFF), // Bright cyan focus ring
  tierBronze: Color(0xFFCD7F32),
  tierSilver: Color(0xFFC0C0C0),
  tierGold: Color(0xFFFFD700),
  tierPlatinum: Color(0xFFE5E4E2),
  tierLegendary: Color(0xFFFF6B35),

  // Legacy tokens - high contrast cyber theme
  bg: Color(0xFF000000), // Pure black background
  elevatedSurface: Color(0xFF1A1A1A),
  primary: Color(0xFF00FFFF),
  onPrimary: Color(0xFF000000),
  onPrimaryContainer: Color(0xFFFFFFFF),
  secondary: Color(0xFF80FFFF),
  onSecondary: Color(0xFF000000),
  muted: Color(0xFF006666),
  onMuted: Color(0xFFFFFFFF),
  accent: Color(0xFF00FFFF),
  onAccent: Color(0xFF000000),
  success: Color(0xFF00FF80),
  warning: Color(0xFFFFFF00),
  error: Color(0xFFFF4444),
  outline: Color(0xFF00FFFF),
  divider: Color(0xFF006666),
  overlayDim: Color(0xE6000000),
  overlayGlow: Color(0x8000FFFF),
);

// Dark Mode theme: truly dark bg with high contrast text for perfect readability
const SemanticTokens _darkModeTokens = SemanticTokens(
  // Brand/Hero tokens - WCAG AAA compliant dark with maximum readability
  brandTitle: Color(0xFF60A5FA), // Light blue for title glow
  brandSubtitle: Color(0xFFFFFFFF), // Pure white for maximum contrast on dark
  heroBackground: Color(0xFF000000), // Pure black for truly dark theme
  heroOverlay: Color(0x1AFFFFFF), // 10% white overlay for subtle depth
  shadowBrandSubtitle: Color(0xFF9CA3AF), // Light gray shadow

  // Navigation tokens - bright elements for dark theme with high contrast
  navIcon: Color(0xFFFFFFFF), // Pure white for maximum visibility
  navIconPressed: Color(0xFF60A5FA), // Light blue when pressed
  navText: Color(0xFFFFFFFF), // Pure white for maximum readability
  headerBg: Color(0xFF000000), // Pure black header

  // Border tokens - high contrast on dark surfaces
  borderDefault: Color(0xFF9CA3AF), // Light gray for visibility
  borderFocus: Color(0xFF60A5FA), // Light blue focus ring
  borderMuted: Color(0xFF6B7280), // Medium gray muted border

  // Surface tokens - truly dark surfaces
  surface: Color(0xFF0A0A0A), // Very dark gray surface
  surfaceAlt: Color(0xFF1A1A1A), // Slightly lighter alternative

  // Text tokens - high contrast white text on dark backgrounds
  textPrimary: Color(0xFFFFFFFF), // Pure white for maximum readability
  textInverse: Color(0xFF000000), // Black for bright backgrounds
  textSecondary: Color(0xFFE5E7EB), // Very light gray for secondary text
  textTertiary: Color(0xFFD1D5DB), // Light gray for tertiary text
  shadow: Color(0x1AFFFFFF), // White shadow

  // Achievement System - Dark Mode Neon Cortex style with high contrast
  achieveBackground: Color(0xFF0A0A0A), // Softer dark surface for achievements
  achieveGrid: Color(0xFF374151), // Gray grid lines
  achieveNeon: Color(0xFF60A5FA), // Light blue neon accents
  badgeBackground: Color(0xFF1F2937), // Dark gray badge background
  badgeRing: Color(0xFF60A5FA), // Light blue ring
  textEmphasis: Color(0xFFFFFFFF), // Pure white emphasis text
  textMuted: Color(0xFFD1D5DB), // Light gray muted text
  focusRing: Color(0xFF60A5FA), // Light blue focus ring
  tierBronze: Color(0xFFCD7F32),
  tierSilver: Color(0xFFC0C0C0),
  tierGold: Color(0xFFFFD700),
  tierPlatinum: Color(0xFFE5E4E2),
  tierLegendary: Color(0xFFFF6B35),

  // Legacy tokens - high contrast dark theme
  bg: Color(0xFF000000), // Pure black background
  elevatedSurface: Color(0xFF1A1A1A),
  primary: Color(0xFF60A5FA),
  onPrimary: Color(0xFF000000),
  onPrimaryContainer: Color(0xFFFFFFFF),
  secondary: Color(0xFF9CA3AF),
  onSecondary: Color(0xFF000000),
  muted: Color(0xFF6B7280),
  onMuted: Color(0xFFFFFFFF),
  accent: Color(0xFF34D399),
  onAccent: Color(0xFF000000),
  success: Color(0xFF10B981),
  warning: Color(0xFFFBBF24),
  error: Color(0xFFEF4444),
  outline: Color(0xFF9CA3AF),
  divider: Color(0xFF374151),
  overlayDim: Color(0xE6000000), // Darker overlay
  overlayGlow: Color(0x8060A5FA),
);

// Minimal theme: ultra-clean design with maximum contrast for perfect readability
const SemanticTokens _minimalTokens = SemanticTokens(
  // Brand/Hero tokens - WCAG AAA compliant minimal with maximum readability
  brandTitle: Color(0xFF000000), // Pure black for maximum contrast
  brandSubtitle: Color(0xFF000000), // Pure black for maximum contrast on white
  heroBackground: Color(0xFFFFFFFF), // Pure white background
  heroOverlay: Color(0x00000000), // No overlay in minimal design
  shadowBrandSubtitle: Color(0xFF666666), // Medium gray shadow for depth

  // Navigation tokens - pure black for maximum contrast
  navIcon: Color(0xFF000000), // Pure black for maximum visibility
  navIconPressed: Color(0xFF333333), // Dark gray when pressed
  navText: Color(0xFF000000), // Pure black for maximum readability
  headerBg: Color(0xFFFFFFFF), // Pure white header

  // Border tokens - strong black borders for minimal aesthetic
  borderDefault: Color(0xFF333333), // Dark gray for visibility
  borderFocus: Color(0xFF000000), // Pure black focus ring
  borderMuted: Color(0xFF666666), // Medium gray muted border

  // Surface tokens - pure minimalist surfaces
  surface: Color(0xFFFFFFFF), // Pure white surface
  surfaceAlt: Color(0xFFFAFAFA), // Very subtle gray alternative

  // Text tokens - maximum contrast black text for minimal design
  textPrimary: Color(0xFF000000), // Pure black for maximum readability
  textInverse: Color(0xFFFFFFFF), // White for dark backgrounds
  textSecondary: Color(0xFF333333), // Dark gray for secondary text
  textTertiary: Color(0xFF666666), // Medium gray for tertiary text
  shadow: Color(0x1A000000), // Medium shadow

  // Achievement System - Minimal dark section with high contrast
  achieveBackground: Color(0xFF0A0A0A), // Softer dark surface for achievements
  achieveGrid: Color(0xFF333333), // Dark gray grid lines
  achieveNeon: Color(0xFF000000), // Black accents (no color in minimal)
  badgeBackground: Color(0xFF1A1A1A), // Very dark gray badge background
  badgeRing: Color(0xFF666666), // Medium gray ring
  textEmphasis: Color(0xFFFFFFFF), // Pure white emphasis text
  textMuted: Color(0xFFCCCCCC), // Light gray muted text
  focusRing: Color(0xFF000000), // Pure black focus ring
  tierBronze: Color(0xFFCD7F32),
  tierSilver: Color(0xFFC0C0C0),
  tierGold: Color(0xFFFFD700),
  tierPlatinum: Color(0xFFE5E4E2),
  tierLegendary: Color(0xFFFF6B35),

  // Legacy tokens - ultra-minimal high contrast
  bg: Color(0xFFFFFFFF), // Pure white background
  elevatedSurface: Color(0xFFFFFFFF),
  primary: Color(0xFF000000),
  onPrimary: Color(0xFFFFFFFF),
  onPrimaryContainer: Color(0xFF000000),
  secondary: Color(0xFF333333),
  onSecondary: Color(0xFFFFFFFF),
  muted: Color(0xFF666666),
  onMuted: Color(0xFFFFFFFF),
  accent: Color(0xFF000000),
  onAccent: Color(0xFFFFFFFF),
  success: Color(0xFF2E7D32),
  warning: Color(0xFFEF6C00),
  error: Color(0xFFD32F2F),
  outline: Color(0xFF333333),
  divider: Color(0xFFE0E0E0),
  overlayDim: Color(0xCC000000),
  overlayGlow: Color(0x1A000000),
);

// Purple Neon theme: futuristic design with maximum readability and proper purple neon accents
const SemanticTokens _purpleNeonTokens = SemanticTokens(
  // Brand/Hero tokens - WCAG AAA compliant purple neon with perfect readability
  brandTitle: Color(0xFFDC8AFF), // Bright purple neon for title glow
  brandSubtitle: Color(0xFFFFFFFF), // Pure white for maximum contrast
  heroBackground: Color(0xFF000000), // Pure black background
  heroOverlay: Color(0x26A855F7), // 15% purple overlay for depth
  shadowBrandSubtitle: Color(0xFFE879F9), // Bright purple shadow effect

  // Navigation tokens - bright purple elements with high contrast
  navIcon: Color(0xFFFFFFFF), // Pure white for maximum visibility
  navIconPressed: Color(0xFFDC8AFF), // Bright purple when pressed
  navText: Color(0xFFFFFFFF), // Pure white for maximum readability
  headerBg: Color(0xFF000000), // Pure black header

  // Border tokens - visible purple neon borders
  borderDefault: Color(0xFFE879F9), // Bright purple for visibility
  borderFocus: Color(0xFFDC8AFF), // Brighter purple focus ring
  borderMuted: Color(0xFF7C3AED), // Dark purple muted border

  // Surface tokens - dark surfaces with purple accents
  surface: Color(0xFF0F0A1A), // Very dark purple-tinted surface
  surfaceAlt: Color(0xFF1A0F2E), // Slightly lighter purple alternative

  // Text tokens - high contrast white text for perfect readability
  textPrimary: Color(0xFFFFFFFF), // Pure white for maximum readability
  textInverse: Color(0xFF000000), // Black for bright backgrounds
  textSecondary: Color(0xFFF3E8FF), // Very light purple tint for secondary
  textTertiary: Color(0xFFE9D5FF), // Light purple for tertiary text
  shadow: Color(0x26A855F7), // Purple shadow

  // Achievement System - Purple Neon Cortex style with high contrast
  achieveBackground: Color(0xFF0A0A0A), // Softer dark surface for achievements
  achieveGrid: Color(0xFF581C87), // Purple grid lines
  achieveNeon: Color(0xFFDC8AFF), // Bright purple neon accents
  badgeBackground: Color(0xFF2D1B69), // Dark purple badge background
  badgeRing: Color(0xFFE879F9), // Bright purple ring
  textEmphasis: Color(0xFFFFFFFF), // Pure white emphasis text
  textMuted: Color(0xFFE9D5FF), // Light purple muted text
  focusRing: Color(0xFFDC8AFF), // Bright purple focus ring
  tierBronze: Color(0xFFCD7F32),
  tierSilver: Color(0xFFC0C0C0),
  tierGold: Color(0xFFFFD700),
  tierPlatinum: Color(0xFFE5E4E2),
  tierLegendary: Color(0xFFFF6B35),

  // Legacy tokens - high contrast purple theme
  bg: Color(0xFF000000), // Pure black background
  elevatedSurface: Color(0xFF1A0F2E),
  primary: Color(0xFFDC8AFF),
  onPrimary: Color(0xFF000000),
  onPrimaryContainer: Color(0xFFFFFFFF),
  secondary: Color(0xFFE879F9),
  onSecondary: Color(0xFF000000),
  muted: Color(0xFF7C3AED),
  onMuted: Color(0xFFFFFFFF),
  accent: Color(0xFFFF69B4),
  onAccent: Color(0xFF000000),
  success: Color(0xFF34D399),
  warning: Color(0xFFFBBF24),
  error: Color(0xFFFF6B6B),
  outline: Color(0xFFE879F9),
  divider: Color(0xFF581C87),
  overlayDim: Color(0xE6000000), // Darker overlay
  overlayGlow: Color(0x80DC8AFF),
);

// Typography with proper line heights and Dynamic Type support
class AccessibleTextTheme {
  static TextTheme build(AppTheme themeType) {
    final baseStyle = _getFontFamily(themeType);

    return TextTheme(
      displayLarge: baseStyle.copyWith(
        fontSize: 57.0,
        fontWeight: FontWeight.w400, // Avoid <300 weight
        height: 1.3, // Line height ≥ 1.3×
        letterSpacing: -0.25,
      ),
      displayMedium: baseStyle.copyWith(
        fontSize: 45.0,
        fontWeight: FontWeight.w400,
        height: 1.3,
        letterSpacing: 0.0,
      ),
      displaySmall: baseStyle.copyWith(
        fontSize: 36.0,
        fontWeight: FontWeight.w400,
        height: 1.3,
        letterSpacing: 0.0,
      ),
      headlineLarge: baseStyle.copyWith(
        fontSize: 32.0,
        fontWeight:
            FontWeight.w500, // Headings ≥ 1.2× contrast (handled by colors)
        height: 1.3,
        letterSpacing: 0.0,
      ),
      headlineMedium: baseStyle.copyWith(
        fontSize: 24.0,
        fontWeight: FontWeight.w500,
        height: 1.3,
        letterSpacing: 0.0,
      ),
      headlineSmall: baseStyle.copyWith(
        fontSize: 22.0,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0.0,
      ),
      titleLarge: baseStyle.copyWith(
        fontSize: 22.0,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.0,
      ),
      titleMedium: baseStyle.copyWith(
        fontSize: 18.0,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.15,
      ),
      titleSmall: baseStyle.copyWith(
        fontSize: 16.0,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.1,
      ),
      labelLarge: baseStyle.copyWith(
        fontSize: 16.0,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.1,
      ),
      labelMedium: baseStyle.copyWith(
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.5,
      ),
      labelSmall: baseStyle.copyWith(
        fontSize: 12.0,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.5,
      ),
      bodyLarge: baseStyle.copyWith(
        fontSize: 16.0,
        fontWeight: FontWeight.w400,
        height: 1.5, // Higher line height for body text
        letterSpacing: 0.15,
      ),
      bodyMedium: baseStyle.copyWith(
        fontSize: 14.0,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.25,
      ),
      bodySmall: baseStyle.copyWith(
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.4,
      ),
    );
  }

  static TextStyle _getFontFamily(AppTheme themeType) {
    return switch (themeType) {
      AppTheme.classic => GoogleFonts.inter(),
      AppTheme.purpleNeon => GoogleFonts.orbitron(),
      AppTheme.matrix => GoogleFonts.jetBrainsMono(),
      AppTheme.retro => GoogleFonts.orbitron(),
      AppTheme.cyberNeon => GoogleFonts.rajdhani(),
      AppTheme.darkMode => GoogleFonts.inter(),
      AppTheme.minimal => GoogleFonts.roboto(),
      AppTheme.oceanDepths => GoogleFonts.nunito(),
      AppTheme.sunsetGlow => GoogleFonts.poppins(),
      AppTheme.forestNight => GoogleFonts.sourceSerif4(),
    };
  }
}

// Main theme builder with accessibility-first design
ThemeData _buildTheme(AppTheme themeType, Brightness brightness) {
  var tokens = ThemeManager.instance._getSemanticTokens(themeType);

  final colorScheme = _buildColorScheme(tokens, brightness);
  final textTheme = AccessibleTextTheme.build(themeType)
      // Ensure all text defaults to token-driven colors (derived from onSurface)
      .apply(
    bodyColor: tokens.textPrimary,
    displayColor: tokens.textPrimary,
    decorationColor: tokens.textPrimary,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    textTheme: textTheme,

    // AppBar theme with proper navigation contrast (your requirements)
    appBarTheme: AppBarTheme(
      backgroundColor: tokens.headerBg,
      foregroundColor: tokens.navText,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: tokens.primary,
      titleTextStyle: textTheme.titleLarge?.copyWith(color: tokens.navText),
      iconTheme: IconThemeData(
        color: tokens.navIcon,
        size: 24, // Appropriate size to prevent overflow
      ),
      // Back button styling - constrained to prevent overflow
      leadingWidth: 64, // Constrained space to prevent overflow on mobile
    ),
    // Bottom Navigation / NavigationBar with token-driven contrast
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: tokens.headerBg,
      indicatorColor: tokens.primary.withValues(alpha: 0.15),
      surfaceTintColor: tokens.primary,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final base = IconThemeData(color: tokens.navIcon);
        if (states.contains(WidgetState.selected)) {
          return base.copyWith(color: tokens.navText);
        }
        return base;
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final style = textTheme.labelSmall
            ?.copyWith(color: tokens.navText, fontWeight: FontWeight.w600);
        return style!;
      }),
    ),

    // Button themes with minimum hit targets (your requirements: 44×44 pt iOS / 48×48 dp Android)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: tokens.primary,
        foregroundColor: tokens.onPrimary,
        minimumSize: const Size(48, 48), // Meets hit target requirement
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
              color: tokens.borderDefault, width: 2.0), // Visible border
        ),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ).copyWith(
        // Focus ring styling (your requirements: 2px ring + 2px offset)
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return tokens.borderFocus.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.pressed)) {
            return tokens.navIconPressed.withValues(alpha: 0.12);
          }
          return null;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return BorderSide(color: tokens.borderFocus, width: 2.0);
          }
          return BorderSide(color: tokens.borderDefault, width: 1.5);
        }),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: tokens.textPrimary,
        backgroundColor: Colors.transparent,
        minimumSize: const Size(48, 48), // Meets hit target requirement
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        side: BorderSide(
            color: tokens.borderDefault, width: 2.0), // ≥ 3:1 contrast borders
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ).copyWith(
        // Focus ring for outlined buttons
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return BorderSide(color: tokens.borderFocus, width: 2.0);
          }
          return BorderSide(color: tokens.borderDefault, width: 2.0);
        }),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: tokens.primary,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),

    // Input themes with accessible focus rings (your requirements)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tokens.surface,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 16), // Touch-friendly padding
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
            color: tokens.borderDefault, width: 2.0), // ≥ 3:1 contrast
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: tokens.borderDefault, width: 2.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
            color: tokens.borderFocus, width: 2.0), // ≥ 3:1 focus ring
        // 2px offset implemented via container padding in components
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: tokens.error, width: 2.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: tokens.error, width: 2.0),
      ),
      labelStyle: textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
      hintStyle: textTheme.bodyMedium?.copyWith(color: tokens.textTertiary),
      helperStyle: textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
      errorStyle: textTheme.bodySmall?.copyWith(color: tokens.error),
    ),

    // Card theme with visible borders (your requirements)
    cardTheme: CardThemeData(
      color: tokens.surface,
      surfaceTintColor: tokens.primary,
      elevation: 0, // Use borders instead of shadows for contrast
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: tokens.borderDefault, width: 1.5), // ≥ 3:1 contrast
      ),
      margin: const EdgeInsets.all(12), // Generous margins
    ),

    // List tile theme with focus support
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      minVerticalPadding: 16, // Touch-friendly padding
      textColor: tokens.textPrimary,
      iconColor: tokens.navIcon, // Use navigation icon color for consistency
      selectedColor: tokens.primary,
      selectedTileColor: tokens.primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
            color: tokens.borderDefault.withValues(alpha: 0.3), width: 1),
      ),
      // Focus styling handled by individual list tiles
    ),

    // Dialog theme
    dialogTheme: DialogThemeData(
      backgroundColor: tokens.elevatedSurface,
      surfaceTintColor: tokens.primary,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle:
          textTheme.headlineSmall?.copyWith(color: tokens.textPrimary),
      contentTextStyle:
          textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
    ),
    // SnackBar theme – strong legibility against app content
    snackBarTheme: SnackBarThemeData(
      backgroundColor: brightness == Brightness.dark
          ? const Color(0xFF111111)
          : const Color(0xFF222222),
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      actionTextColor: tokens.primary,
      behavior: SnackBarBehavior.floating,
      insetPadding: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),

    // Bottom sheet theme
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: tokens.elevatedSurface,
      surfaceTintColor: tokens.primary,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),

    // Divider theme
    dividerTheme: DividerThemeData(
      color: tokens.divider,
      thickness: 1,
      space: 1,
    ),

    // Tooltip theme
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: tokens.overlayDim,
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: textTheme.bodySmall?.copyWith(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    // Chip theme
    chipTheme: ChipThemeData(
      backgroundColor: tokens.muted,
      labelStyle: textTheme.labelMedium?.copyWith(color: tokens.onMuted),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    // Tab bar theme
    tabBarTheme: TabBarThemeData(
      labelColor: tokens.primary,
      unselectedLabelColor: tokens.textSecondary,
      indicatorColor: tokens.primary,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      unselectedLabelStyle: textTheme.labelLarge,
    ),

    // Progress indicator theme
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: tokens.primary,
      linearTrackColor: tokens.primary.withValues(alpha: 0.2),
      circularTrackColor: tokens.primary.withValues(alpha: 0.2),
    ),

    // Back button theme (your requirements: constrained to prevent overflow)
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: tokens.navIcon,
        minimumSize: const Size(44, 44), // Hit target requirement
        maximumSize: const Size(48, 48), // Constrain maximum size
        padding: const EdgeInsets.all(8), // Reduced padding to prevent overflow
      ).copyWith(
        // Focus ring for icon buttons
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return tokens.borderFocus.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.pressed)) {
            return tokens.navIconPressed.withValues(alpha: 0.12);
          }
          return null;
        }),
      ),
    ),

    // Extensions for semantic tokens access
    extensions: <ThemeExtension<dynamic>>[
      SemanticTokensExtension(tokens),
    ],
  );
}

ColorScheme _buildColorScheme(SemanticTokens tokens, Brightness brightness) {
  return brightness == Brightness.dark
      ? ColorScheme.dark(
          primary: tokens.primary,
          onPrimary: tokens.onPrimary,
          primaryContainer: tokens.elevatedSurface,
          onPrimaryContainer: tokens.textPrimary,
          secondary: tokens.secondary,
          onSecondary: tokens.onSecondary,
          secondaryContainer: tokens.muted,
          onSecondaryContainer: tokens.onMuted,
          tertiary: tokens.accent,
          onTertiary: tokens.onAccent,
          error: tokens.error,
          onError: tokens.onPrimary,
          errorContainer: tokens.error.withValues(alpha: 0.2),
          onErrorContainer: tokens.error,
          surface: tokens.bg,
          onSurface: tokens.textPrimary,
          surfaceContainerHighest: tokens.elevatedSurface,
          onSurfaceVariant: tokens.textSecondary,
          outline: tokens.outline,
          outlineVariant: tokens.divider,
          shadow: tokens.shadow,
          scrim: tokens.overlayDim,
          inversePrimary: tokens.accent,
          inverseSurface: tokens.textPrimary,
          onInverseSurface: tokens.bg,
          surfaceTint: tokens.primary,
        )
      : ColorScheme.light(
          primary: tokens.primary,
          onPrimary: tokens.onPrimary,
          primaryContainer: tokens.elevatedSurface,
          onPrimaryContainer: tokens.textPrimary,
          secondary: tokens.secondary,
          onSecondary: tokens.onSecondary,
          secondaryContainer: tokens.muted,
          onSecondaryContainer: tokens.onMuted,
          tertiary: tokens.accent,
          onTertiary: tokens.onAccent,
          error: tokens.error,
          onError: tokens.onPrimary,
          errorContainer: tokens.error.withValues(alpha: 0.2),
          onErrorContainer: tokens.error,
          surface: tokens.bg,
          onSurface: tokens.textPrimary,
          surfaceContainerHighest: tokens.elevatedSurface,
          onSurfaceVariant: tokens.textSecondary,
          outline: tokens.outline,
          outlineVariant: tokens.divider,
          shadow: tokens.shadow,
          scrim: tokens.overlayDim,
          inversePrimary: tokens.accent,
          inverseSurface: tokens.textPrimary,
          onInverseSurface: tokens.bg,
          surfaceTint: tokens.primary,
        );
}

// Theme extension for accessing semantic tokens
@immutable
class SemanticTokensExtension extends ThemeExtension<SemanticTokensExtension> {
  const SemanticTokensExtension(this.tokens);

  final SemanticTokens tokens;

  @override
  SemanticTokensExtension copyWith({SemanticTokens? tokens}) {
    return SemanticTokensExtension(tokens ?? this.tokens);
  }

  @override
  SemanticTokensExtension lerp(
      ThemeExtension<SemanticTokensExtension>? other, double t) {
    if (other is! SemanticTokensExtension) {
      return this;
    }
    return SemanticTokensExtension(
      SemanticTokens(
        // Brand/Hero tokens
        brandTitle: Color.lerp(tokens.brandTitle, other.tokens.brandTitle, t)!,
        brandSubtitle:
            Color.lerp(tokens.brandSubtitle, other.tokens.brandSubtitle, t)!,
        heroBackground:
            Color.lerp(tokens.heroBackground, other.tokens.heroBackground, t)!,
        heroOverlay:
            Color.lerp(tokens.heroOverlay, other.tokens.heroOverlay, t)!,
        shadowBrandSubtitle: Color.lerp(
            tokens.shadowBrandSubtitle, other.tokens.shadowBrandSubtitle, t)!,

        // Navigation tokens
        navIcon: Color.lerp(tokens.navIcon, other.tokens.navIcon, t)!,
        navIconPressed:
            Color.lerp(tokens.navIconPressed, other.tokens.navIconPressed, t)!,
        navText: Color.lerp(tokens.navText, other.tokens.navText, t)!,
        headerBg: Color.lerp(tokens.headerBg, other.tokens.headerBg, t)!,

        // Border tokens
        borderDefault:
            Color.lerp(tokens.borderDefault, other.tokens.borderDefault, t)!,
        borderFocus:
            Color.lerp(tokens.borderFocus, other.tokens.borderFocus, t)!,
        borderMuted:
            Color.lerp(tokens.borderMuted, other.tokens.borderMuted, t)!,

        // Surface tokens
        surface: Color.lerp(tokens.surface, other.tokens.surface, t)!,
        surfaceAlt: Color.lerp(tokens.surfaceAlt, other.tokens.surfaceAlt, t)!,

        // Text tokens
        textPrimary:
            Color.lerp(tokens.textPrimary, other.tokens.textPrimary, t)!,
        textInverse:
            Color.lerp(tokens.textInverse, other.tokens.textInverse, t)!,
        textSecondary:
            Color.lerp(tokens.textSecondary, other.tokens.textSecondary, t)!,
        textTertiary:
            Color.lerp(tokens.textTertiary, other.tokens.textTertiary, t)!,
        shadow: Color.lerp(tokens.shadow, other.tokens.shadow, t)!,

        // Achievement tokens
        achieveBackground: Color.lerp(
            tokens.achieveBackground, other.tokens.achieveBackground, t)!,
        achieveGrid:
            Color.lerp(tokens.achieveGrid, other.tokens.achieveGrid, t)!,
        achieveNeon:
            Color.lerp(tokens.achieveNeon, other.tokens.achieveNeon, t)!,
        badgeBackground: Color.lerp(
            tokens.badgeBackground, other.tokens.badgeBackground, t)!,
        badgeRing: Color.lerp(tokens.badgeRing, other.tokens.badgeRing, t)!,
        textEmphasis:
            Color.lerp(tokens.textEmphasis, other.tokens.textEmphasis, t)!,
        textMuted: Color.lerp(tokens.textMuted, other.tokens.textMuted, t)!,
        focusRing: Color.lerp(tokens.focusRing, other.tokens.focusRing, t)!,
        // Tier colors
        tierBronze: Color.lerp(tokens.tierBronze, other.tokens.tierBronze, t)!,
        tierSilver: Color.lerp(tokens.tierSilver, other.tokens.tierSilver, t)!,
        tierGold: Color.lerp(tokens.tierGold, other.tokens.tierGold, t)!,
        tierPlatinum:
            Color.lerp(tokens.tierPlatinum, other.tokens.tierPlatinum, t)!,
        tierLegendary:
            Color.lerp(tokens.tierLegendary, other.tokens.tierLegendary, t)!,

        // Legacy tokens
        bg: Color.lerp(tokens.bg, other.tokens.bg, t)!,
        elevatedSurface: Color.lerp(
            tokens.elevatedSurface, other.tokens.elevatedSurface, t)!,
        primary: Color.lerp(tokens.primary, other.tokens.primary, t)!,
        onPrimary: Color.lerp(tokens.onPrimary, other.tokens.onPrimary, t)!,
        onPrimaryContainer: Color.lerp(
            tokens.onPrimaryContainer, other.tokens.onPrimaryContainer, t)!,
        secondary: Color.lerp(tokens.secondary, other.tokens.secondary, t)!,
        onSecondary:
            Color.lerp(tokens.onSecondary, other.tokens.onSecondary, t)!,
        muted: Color.lerp(tokens.muted, other.tokens.muted, t)!,
        onMuted: Color.lerp(tokens.onMuted, other.tokens.onMuted, t)!,
        accent: Color.lerp(tokens.accent, other.tokens.accent, t)!,
        onAccent: Color.lerp(tokens.onAccent, other.tokens.onAccent, t)!,
        success: Color.lerp(tokens.success, other.tokens.success, t)!,
        warning: Color.lerp(tokens.warning, other.tokens.warning, t)!,
        error: Color.lerp(tokens.error, other.tokens.error, t)!,
        outline: Color.lerp(tokens.outline, other.tokens.outline, t)!,
        divider: Color.lerp(tokens.divider, other.tokens.divider, t)!,
        overlayDim: Color.lerp(tokens.overlayDim, other.tokens.overlayDim, t)!,
        overlayGlow:
            Color.lerp(tokens.overlayGlow, other.tokens.overlayGlow, t)!,
      ),
    );
  }
}

// Helper extension for easy access to semantic tokens
extension SemanticTokensContext on BuildContext {
  SemanticTokens get tokens {
    try {
      final theme = Theme.of(this);
      final extension = theme.extension<SemanticTokensExtension>();
      return extension?.tokens ?? _classicTokens;
    } catch (e) {
      // Fallback to classic tokens if Theme.of() fails during startup
      return _classicTokens;
    }
  }
}

// Ocean Depths theme: deep blue underwater experience with aquatic vibes
const SemanticTokens _oceanDepthsTokens = SemanticTokens(
  // Brand/Hero tokens - Deep ocean blues with aquatic glow
  brandTitle: Color(0xFF00E5FF), // Bright aqua for title glow
  brandSubtitle: Color(0xFFFFFFFF), // Pure white for contrast against deep blue
  heroBackground: Color(0xFF0D47A1), // Deep ocean blue
  heroOverlay: Color(0x1A00E5FF), // Aqua overlay for depth
  shadowBrandSubtitle: Color(0xFF4FC3F7), // Light blue shadow

  // Navigation tokens - Aquatic elements with high contrast
  navIcon: Color(0xFF00E5FF), // Bright aqua for maximum visibility
  navIconPressed: Color(0xFF0288D1), // Deeper blue when pressed
  navText: Color(0xFFFFFFFF), // Pure white for maximum readability
  headerBg: Color(0xFF1565C0), // Ocean blue header

  // Border tokens - Ocean-inspired borders
  borderDefault: Color(0xFF4FC3F7), // Light blue for visibility
  borderFocus: Color(0xFF00E5FF), // Bright aqua focus ring
  borderMuted: Color(0xFF42A5F5), // Medium blue muted border

  // Surface tokens - Deep water surfaces
  surface: Color(0xFF0A1929), // Very deep blue surface
  surfaceAlt: Color(0xFF1E3A8A), // Slightly lighter ocean blue

  // Text tokens - High contrast text for underwater reading
  textPrimary: Color(0xFFFFFFFF), // Pure white for maximum readability
  textInverse: Color(0xFF0D47A1), // Deep blue for bright backgrounds
  textSecondary: Color(0xFF81D4FA), // Light aqua for secondary text
  textTertiary: Color(0xFFE1F5FE), // Very light blue for tertiary text
  shadow: Color(0x1A00E5FF), // Aqua shadow

  // Achievement System - Ocean Depths style
  achieveBackground: Color(0xFF0A1929), // Deep ocean surface for achievements
  achieveGrid: Color(0xFF1976D2), // Ocean blue grid lines
  achieveNeon: Color(0xFF00E5FF), // Bright aqua neon accents
  badgeBackground: Color(0xFF1565C0), // Ocean blue badge background
  badgeRing: Color(0xFF4FC3F7), // Light blue ring
  textEmphasis: Color(0xFFFFFFFF), // Pure white emphasis text
  textMuted: Color(0xFF81D4FA), // Light aqua muted text
  focusRing: Color(0xFF00E5FF), // Bright aqua focus ring
  tierBronze: Color(0xFFCD7F32),
  tierSilver: Color(0xFFC0C0C0),
  tierGold: Color(0xFFFFD700),
  tierPlatinum: Color(0xFFE5E4E2),
  tierLegendary: Color(0xFF00E5FF),

  // Legacy tokens - Ocean depths theme
  bg: Color(0xFF0D47A1), // Deep ocean blue background
  elevatedSurface: Color(0xFF1565C0),
  primary: Color(0xFF00E5FF),
  onPrimary: Color(0xFF0D47A1),
  onPrimaryContainer: Color(0xFFFFFFFF),
  secondary: Color(0xFF4FC3F7),
  onSecondary: Color(0xFF0D47A1),
  muted: Color(0xFF1976D2),
  onMuted: Color(0xFFFFFFFF),
  accent: Color(0xFF00E5FF),
  onAccent: Color(0xFF0D47A1),
  success: Color(0xFF00BCD4),
  warning: Color(0xFFFFB74D),
  error: Color(0xFFFF5252),
  outline: Color(0xFF4FC3F7),
  divider: Color(0xFF1976D2),
  overlayDim: Color(0xE60D47A1),
  overlayGlow: Color(0x8000E5FF),
);

// Sunset Glow theme: warm oranges and pinks with golden hour vibes
const SemanticTokens _sunsetGlowTokens = SemanticTokens(
  // Brand/Hero tokens - Warm sunset colors
  brandTitle: Color(0xFFFF6F00), // Bright orange for title glow
  brandSubtitle: Color(0xFFFFFFFF), // Pure white for contrast
  heroBackground: Color(0xFFBF360C), // Deep sunset red
  heroOverlay: Color(0x1AFF8A65), // Warm orange overlay
  shadowBrandSubtitle: Color(0xFFFFAB91), // Light orange shadow

  // Navigation tokens - Sunset elements
  navIcon: Color(0xFFFF6F00), // Bright orange for visibility
  navIconPressed: Color(0xFFE65100), // Deeper orange when pressed
  navText: Color(0xFFFFFFFF), // Pure white for readability
  headerBg: Color(0xFFD84315), // Sunset orange header

  // Border tokens - Warm sunset borders
  borderDefault: Color(0xFFFFAB91), // Light orange for visibility
  borderFocus: Color(0xFFFF6F00), // Bright orange focus ring
  borderMuted: Color(0xFFFF8A65), // Medium orange muted border

  // Surface tokens - Warm sunset surfaces
  surface: Color(0xFF3E2723), // Dark brown surface
  surfaceAlt: Color(0xFF5D4037), // Lighter brown alternative

  // Text tokens - High contrast text for sunset reading
  textPrimary: Color(0xFFFFFFFF), // Pure white for maximum readability
  textInverse: Color(0xFFBF360C), // Deep red for bright backgrounds
  textSecondary: Color(0xFFFFCC02), // Golden yellow for secondary text
  textTertiary: Color(0xFFFFF3E0), // Very light orange for tertiary text
  shadow: Color(0x1AFF6F00), // Orange shadow

  // Achievement System - Sunset Glow style
  achieveBackground: Color(0xFF3E2723), // Dark brown surface for achievements
  achieveGrid: Color(0xFFD84315), // Sunset orange grid lines
  achieveNeon: Color(0xFFFF6F00), // Bright orange neon accents
  badgeBackground: Color(0xFFBF360C), // Deep red badge background
  badgeRing: Color(0xFFFFAB91), // Light orange ring
  textEmphasis: Color(0xFFFFFFFF), // Pure white emphasis text
  textMuted: Color(0xFFFFCC02), // Golden muted text
  focusRing: Color(0xFFFF6F00), // Bright orange focus ring
  tierBronze: Color(0xFFCD7F32),
  tierSilver: Color(0xFFC0C0C0),
  tierGold: Color(0xFFFFD700),
  tierPlatinum: Color(0xFFE5E4E2),
  tierLegendary: Color(0xFFFF6F00),

  // Legacy tokens - Sunset glow theme
  bg: Color(0xFFBF360C), // Deep sunset red background
  elevatedSurface: Color(0xFFD84315),
  primary: Color(0xFFFF6F00),
  onPrimary: Color(0xFFFFFFFF),
  onPrimaryContainer: Color(0xFFFFFFFF),
  secondary: Color(0xFFFFAB91),
  onSecondary: Color(0xFFBF360C),
  muted: Color(0xFFFF8A65),
  onMuted: Color(0xFFFFFFFF),
  accent: Color(0xFFFFCC02),
  onAccent: Color(0xFFBF360C),
  success: Color(0xFF4CAF50),
  warning: Color(0xFFFFEB3B),
  error: Color(0xFFF44336),
  outline: Color(0xFFFFAB91),
  divider: Color(0xFFD84315),
  overlayDim: Color(0xE6BF360C),
  overlayGlow: Color(0x80FF6F00),
);

// Forest Night theme: deep greens with nature-inspired dark atmosphere
const SemanticTokens _forestNightTokens = SemanticTokens(
  // Brand/Hero tokens - Deep forest greens
  brandTitle: Color(0xFF4CAF50), // Bright green for title glow
  brandSubtitle: Color(0xFFFFFFFF), // Pure white for contrast
  heroBackground: Color(0xFF1B5E20), // Deep forest green
  heroOverlay: Color(0x1A66BB6A), // Green overlay for depth
  shadowBrandSubtitle: Color(0xFF81C784), // Light green shadow

  // Navigation tokens - Forest elements
  navIcon: Color(0xFF4CAF50), // Bright green for visibility
  navIconPressed: Color(0xFF388E3C), // Deeper green when pressed
  navText: Color(0xFFFFFFFF), // Pure white for readability
  headerBg: Color(0xFF2E7D32), // Forest green header

  // Border tokens - Nature-inspired borders
  borderDefault: Color(0xFF81C784), // Light green for visibility
  borderFocus: Color(0xFF4CAF50), // Bright green focus ring
  borderMuted: Color(0xFF66BB6A), // Medium green muted border

  // Surface tokens - Forest floor surfaces
  surface: Color(0xFF0D1B0F), // Very dark green surface
  surfaceAlt: Color(0xFF1A2E1D), // Slightly lighter forest green

  // Text tokens - High contrast text for forest reading
  textPrimary: Color(0xFFFFFFFF), // Pure white for maximum readability
  textInverse: Color(0xFF1B5E20), // Deep green for bright backgrounds
  textSecondary: Color(0xFFA5D6A7), // Light green for secondary text
  textTertiary: Color(0xFFE8F5E8), // Very light green for tertiary text
  shadow: Color(0x1A4CAF50), // Green shadow

  // Achievement System - Forest Night style
  achieveBackground: Color(0xFF0D1B0F), // Dark forest surface for achievements
  achieveGrid: Color(0xFF2E7D32), // Forest green grid lines
  achieveNeon: Color(0xFF4CAF50), // Bright green neon accents
  badgeBackground: Color(0xFF1B5E20), // Deep green badge background
  badgeRing: Color(0xFF81C784), // Light green ring
  textEmphasis: Color(0xFFFFFFFF), // Pure white emphasis text
  textMuted: Color(0xFFA5D6A7), // Light green muted text
  focusRing: Color(0xFF4CAF50), // Bright green focus ring
  tierBronze: Color(0xFFCD7F32),
  tierSilver: Color(0xFFC0C0C0),
  tierGold: Color(0xFFFFD700),
  tierPlatinum: Color(0xFFE5E4E2),
  tierLegendary: Color(0xFF4CAF50),

  // Legacy tokens - Forest night theme
  bg: Color(0xFF1B5E20), // Deep forest green background
  elevatedSurface: Color(0xFF2E7D32),
  primary: Color(0xFF4CAF50),
  onPrimary: Color(0xFFFFFFFF),
  onPrimaryContainer: Color(0xFFFFFFFF),
  secondary: Color(0xFF81C784),
  onSecondary: Color(0xFF1B5E20),
  muted: Color(0xFF66BB6A),
  onMuted: Color(0xFFFFFFFF),
  accent: Color(0xFF8BC34A),
  onAccent: Color(0xFF1B5E20),
  success: Color(0xFF4CAF50),
  warning: Color(0xFFFF9800),
  error: Color(0xFFF44336),
  outline: Color(0xFF81C784),
  divider: Color(0xFF2E7D32),
  overlayDim: Color(0xE61B5E20),
  overlayGlow: Color(0x804CAF50),
);

// Backwards compatibility
ThemeData get lightTheme => ThemeManager.instance.lightTheme;
ThemeData get darkTheme => ThemeManager.instance.darkTheme;
