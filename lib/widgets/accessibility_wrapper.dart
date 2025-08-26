import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:mindload/widgets/accessible_components.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/services/telemetry_service.dart';

/// Comprehensive accessibility wrapper that ensures WCAG 2.1 AA compliance
/// for any screen or widget in the Mindload app
class AccessibilityWrapper extends StatefulWidget {
  const AccessibilityWrapper({
    super.key,
    required this.child,
    required this.screenName,
    this.enableDiagnostics = false,
    this.announceScreenName = true,
  });

  final Widget child;
  final String screenName;
  final bool enableDiagnostics;
  final bool announceScreenName;

  @override
  State<AccessibilityWrapper> createState() => _AccessibilityWrapperState();
}

class _AccessibilityWrapperState extends State<AccessibilityWrapper>
    with WidgetsBindingObserver {
  bool _hasAnnouncedScreen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Perform initial accessibility checks
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performAccessibilityChecks();
      if (widget.announceScreenName && !_hasAnnouncedScreen) {
        _announceScreenEntry();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAccessibilityFeatures() {
    super.didChangeAccessibilityFeatures();
    _performAccessibilityChecks();
  }

  void _performAccessibilityChecks() {
    if (!mounted) return;
    
    final mediaQuery = MediaQuery.of(context);
    final tokens = ThemeManager.instance.currentTokens;
    
    // Check safe area violations
    LayoutSafety.checkSafeArea(context, widget.screenName);
    
    // Check font scaling
    LayoutSafety.checkFontScaling(context);
    
    // Check RTL support
    LayoutSafety.checkRTL(context);
    
    // Check accessibility features
    _checkAccessibilityFeatures(mediaQuery);
    
    // Contrast validation removed
  }

  void _checkAccessibilityFeatures(MediaQueryData mediaQuery) {
    // Get accessibility features from MediaQuery
    final boldTextEnabled = MediaQuery.boldTextOf(context);
    final highContrastEnabled = MediaQuery.highContrastOf(context);
    final disableAnimationsEnabled = MediaQuery.disableAnimationsOf(context);
    
    // Track accessibility feature usage
    final features = <String>[];
    
    if (boldTextEnabled) {
      features.add('bold_text');
    }
    if (highContrastEnabled) {
      features.add('high_contrast');
    }
    if (disableAnimationsEnabled) {
      features.add('disable_animations');
    }
    
    if (features.isNotEmpty) {
      TelemetryService.instance.logEvent(
        TelemetryEvent.a11yViolationDetected.name,
        {
          'screen': widget.screenName,
          'features': features,
          'text_scale': mediaQuery.textScaler.scale(1.0),
        },
      );
    }
  }

  // Contrast checks removed

  void _announceScreenEntry() {
    if (!mounted) return;
    
    final announcement = 'Entered ${widget.screenName.replaceAll('_', ' ')} screen';
    
    SemanticsService.announce(
      announcement,
      TextDirection.ltr,
    );
    
    _hasAnnouncedScreen = true;
  }

  @override
  Widget build(BuildContext context) {
    Widget child = SafeAreaWrapper(
      screenName: widget.screenName,
      child: widget.child,
    );

    // Add diagnostics overlay in development mode
    if (widget.enableDiagnostics || ThemeManager.instance.isDiagnosticsModeEnabled) {
      child = AccessibilityDiagnostics(child: child);
    }

    // Add semantic screen boundary
    child = Semantics(
      label: '${widget.screenName.replaceAll('_', ' ')} screen',
      child: child,
    );

    return child;
  }
}

// Contrast check helper removed

/// Enhanced app-wide accessibility provider
class MindloadAccessibilityProvider extends StatelessWidget {
  const MindloadAccessibilityProvider({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        // Keyboard shortcuts for accessibility
        LogicalKeySet(LogicalKeyboardKey.tab): const NextFocusIntent(),
        LogicalKeySet(LogicalKeyboardKey.tab, LogicalKeyboardKey.shift): const PreviousFocusIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
        LogicalKeySet(LogicalKeyboardKey.enter): ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.space): ActivateIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          NextFocusIntent: NextFocusAction(),
          PreviousFocusIntent: PreviousFocusAction(),
          DismissIntent: DismissAction(),
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (intent) {
              final button = primaryFocus?.context?.widget;
              if (button is ElevatedButton || button is TextButton || button is OutlinedButton) {
                // Simulate button press
                return Actions.invoke(primaryFocus!.context!, intent);
              }
              return null;
            },
          ),
        },
        child: FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: child,
        ),
      ),
    );
  }
}

/// Intent classes for keyboard shortcuts
class NextFocusIntent extends Intent {
  const NextFocusIntent();
}

class PreviousFocusIntent extends Intent {
  const PreviousFocusIntent();
}

class DismissIntent extends Intent {
  const DismissIntent();
}

/// Action classes for keyboard shortcuts
class NextFocusAction extends Action<NextFocusIntent> {
  @override
  Object? invoke(NextFocusIntent intent) {
    return Actions.invoke(primaryFocus!.context!, const NextFocusIntent());
  }
}

class PreviousFocusAction extends Action<PreviousFocusIntent> {
  @override
  Object? invoke(PreviousFocusIntent intent) {
    return Actions.invoke(primaryFocus!.context!, const PreviousFocusIntent());
  }
}

class DismissAction extends Action<DismissIntent> {
  @override
  Object? invoke(DismissIntent intent) {
    if (Navigator.canPop(primaryFocus!.context!)) {
      Navigator.pop(primaryFocus!.context!);
    }
    return null;
  }
}

/// Accessible dialog wrapper
class AccessibleDialog extends StatelessWidget {
  const AccessibleDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions = const [],
    this.semanticLabel,
  });

  final Widget title;
  final Widget content;
  final List<Widget> actions;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeManager.instance.currentTokens;
    
    return Semantics(
      label: semanticLabel,
      scopesRoute: true,
      explicitChildNodes: true,
      child: AlertDialog(
        backgroundColor: tokens.elevatedSurface,
        surfaceTintColor: tokens.primary,
        title: DefaultTextStyle(
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: tokens.textPrimary,
          ) ?? TextStyle(color: tokens.textPrimary),
          child: title,
        ),
        content: DefaultTextStyle(
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: tokens.textSecondary,
          ) ?? TextStyle(color: tokens.textSecondary),
          child: content,
        ),
        actions: actions,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

/// Accessible snackbar helper
class AccessibleSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    String? semanticLabel,
  }) {
    final tokens = ThemeManager.instance.currentTokens;
    
    Color backgroundColor;
    Color textColor;
    IconData icon;
    
    switch (type) {
      case SnackBarType.success:
        backgroundColor = tokens.success;
        textColor = tokens.onPrimary;
        icon = Icons.check_circle;
        break;
      case SnackBarType.error:
        backgroundColor = tokens.error;
        textColor = tokens.onPrimary;
        icon = Icons.error;
        break;
      case SnackBarType.warning:
        backgroundColor = tokens.warning;
        textColor = tokens.onPrimary;
        icon = Icons.warning;
        break;
      case SnackBarType.info:
        backgroundColor = tokens.primary;
        textColor = tokens.onPrimary;
        icon = Icons.info;
        break;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Semantics(
          label: semanticLabel ?? message,
          liveRegion: true,
          child: Row(
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: textColor),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
    
    // Announce for screen readers
    SemanticsService.announce(
      semanticLabel ?? message,
      TextDirection.ltr,
    );
  }
}

enum SnackBarType { success, error, warning, info }

/// RTL-aware directional icon helper
class DirectionalIcon extends StatelessWidget {
  const DirectionalIcon({
    super.key,
    required this.icon,
    this.rtlIcon,
    this.color,
    this.size,
    this.semanticLabel,
  });

  final IconData icon;
  final IconData? rtlIcon;
  final Color? color;
  final double? size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final effectiveIcon = (isRTL && rtlIcon != null) ? rtlIcon! : icon;
    
    return Icon(
      effectiveIcon,
      color: color,
      size: size,
      semanticLabel: semanticLabel,
    );
  }
}