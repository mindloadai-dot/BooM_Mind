import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/services/telemetry_service.dart';
import 'package:mindload/l10n/app_localizations.dart';
import 'package:mindload/widgets/accessible_components.dart';

class AccessibleThemeSelector extends StatefulWidget {
  const AccessibleThemeSelector({super.key});

  @override
  State<AccessibleThemeSelector> createState() => _AccessibleThemeSelectorState();
}

class _AccessibleThemeSelectorState extends State<AccessibleThemeSelector> {
  AppTheme? _selectedTheme;
  
  @override
  void initState() {
    super.initState();
    _selectedTheme = ThemeManager.instance.currentTheme;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    
    return AccessibilityDiagnostics(
      child: SafeAreaWrapper(
        screenName: 'ThemeSelector',
        child: Dialog(
          backgroundColor: tokens.elevatedSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Spacing.md),
            side: BorderSide(
              color: tokens.outline,
              width: 1.0,
            ),
          ),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 400, 
              maxHeight: 700, // Increased for better content fit
            ),
            child: KeyboardAwareScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  _buildHeader(context, tokens, l10n),
                  
                  // Theme options list
                  Flexible(
                    child: _buildThemeList(context, tokens, l10n),
                  ),
                  
                  // Action buttons (just close button now)
                  _buildActionButtons(context, tokens, l10n),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SemanticTokens tokens, AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Spacing.md)),
        border: Border(
          bottom: BorderSide(
            color: tokens.divider,
            width: 1.0,
          ),
        ),
      ),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            Container(
              width: HitTargets.iOS,
              height: HitTargets.iOS,
              decoration: BoxDecoration(
                color: tokens.primary,
                borderRadius: BorderRadius.circular(Spacing.sm),
              ),
              child: Icon(
                Icons.palette,
                color: tokens.onPrimary,
                size: 24,
                semanticLabel: l10n?.themeSelector ?? 'Theme selector icon',
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (l10n?.appearance ?? 'APPEARANCE').toUpperCase(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                    semanticsLabel: l10n?.appearance ?? 'Appearance settings',
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    l10n?.chooseYourPreferredTheme ?? 'Choose your preferred theme for the best experience',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: tokens.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeList(BuildContext context, SemanticTokens tokens, AppLocalizations? l10n) {
    final themeOptions = _getThemeOptions();
    
    return Semantics(
      explicitChildNodes: true,
      child: ListView.separated(
        padding: const EdgeInsets.all(Spacing.md),
        shrinkWrap: true,
        itemCount: themeOptions.length,
        separatorBuilder: (context, index) => const SizedBox(height: Spacing.sm),
        itemBuilder: (context, index) {
          final themeOption = themeOptions[index];
          return _buildThemeOption(context, themeOption, tokens, l10n);
        },
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, SemanticTokens tokens, AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(Spacing.md)),
        border: Border(
          top: BorderSide(
            color: tokens.divider,
            width: 1.0,
          ),
        ),
      ),
      child: Semantics(
        explicitChildNodes: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AccessibleButton(
              onPressed: () => Navigator.of(context).pop(),
              variant: ButtonVariant.text,
              size: ButtonSize.medium,
              semanticLabel: l10n?.cancel ?? 'Cancel theme selection',
              tooltip: 'Close theme selector without saving changes',
              child: Text((l10n?.cancel ?? 'CANCEL').toUpperCase()),
            ),
            const SizedBox(width: Spacing.md),
            AccessibleButton(
              onPressed: () => Navigator.of(context).pop(),
              variant: ButtonVariant.primary,
              size: ButtonSize.medium,
              semanticLabel: 'Done with theme selection',
              tooltip: 'Close theme selector',
              child: const Text('DONE'),
            ),
          ],
        ),
      ),
    );
  }
  
  List<ThemeOption> _getThemeOptions() {
    return [
      ThemeOption(
        theme: AppTheme.classic,
        title: 'Classic',
        description: 'Neutral surfaces with high contrast text for maximum readability',
        accessibilityDescription: 'Classic theme with neutral surfaces. Ideal for users who need maximum text clarity.',
        features: ['High contrast text', 'Neutral colors', 'Maximum readability'],
        contrastRatio: '',
        wcagCompliance: '',
      ),
      ThemeOption(
        theme: AppTheme.purpleNeon,
        title: 'Purple Neon',
        description: 'Futuristic purple theme with neon accents and dark backgrounds',
        accessibilityDescription: 'Purple neon theme with high contrast on dark surfaces. Perfect for users who prefer futuristic aesthetics with excellent readability.',
        features: ['Dark purple backgrounds', 'Neon purple accents', 'High contrast text'],
        contrastRatio: '',
        wcagCompliance: '',
      ),
      ThemeOption(
        theme: AppTheme.matrix,
        title: 'Matrix',
        description: 'Dark terminal theme with light text and matrix green accents',
        accessibilityDescription: 'High contrast dark theme. Reduces eye strain in low-light conditions with terminal-inspired design.',
        features: ['Dark background', 'Green accents', 'Low-light friendly'],
        contrastRatio: '',
        wcagCompliance: '',
      ),
      ThemeOption(
        theme: AppTheme.retro,
        title: 'Retro',
        description: 'Sepia surfaces with near-black text and warm tones',
        accessibilityDescription: 'Warm retro theme. Reduces blue light with sepia tones while maintaining excellent readability.',
        features: ['Warm sepia tones', 'Reduced blue light', 'Vintage aesthetic'],
        contrastRatio: '',
        wcagCompliance: '',
      ),
      ThemeOption(
        theme: AppTheme.cyberNeon,
        title: 'Cyber Neon',
        description: 'Futuristic design with accessibility-first approach',
        accessibilityDescription: 'Cyberpunk theme. Neon effects are decorative only, with all text on solid high-contrast surfaces.',
        features: ['Futuristic design', 'Decorative neons', 'Solid text surfaces'],
        contrastRatio: '',
        wcagCompliance: '',
      ),
      ThemeOption(
        theme: AppTheme.darkMode,
        title: 'Dark Mode',
        description: 'Near-black background with light text, no harsh whites',
        accessibilityDescription: 'Eye-friendly dark theme. Uses soft whites instead of pure white to reduce glare and eye fatigue.',
        features: ['Near-black background', 'Soft whites', 'Eye strain reduction'],
        contrastRatio: '',
        wcagCompliance: '',
      ),
      ThemeOption(
        theme: AppTheme.minimal,
        title: 'Minimal',
        description: 'Clean design with generous spacing and high contrast',
        accessibilityDescription: 'Minimal design with generous margins, enhanced touch targets, and clean typography for optimal accessibility.',
        features: ['Maximum contrast', 'Large touch targets', 'Clean typography'],
        contrastRatio: '',
        wcagCompliance: '',
      ),
    ];
  }
  
  Widget _buildThemeOption(BuildContext context, ThemeOption option, SemanticTokens tokens, AppLocalizations? l10n) {
    final isSelected = _selectedTheme == option.theme;
    final isCurrentTheme = ThemeManager.instance.currentTheme == option.theme;
    
    // Build comprehensive semantic label
    final semanticLabel = _buildSemanticLabel(option, isSelected, isCurrentTheme, l10n);
    
    return AccessibleCard(
      onTap: () async {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedTheme = option.theme;
        });
        
        // Apply theme immediately
        await _applyThemeImmediately(option.theme);
      },
      selected: isSelected,
      padding: const EdgeInsets.all(Spacing.md),
      margin: EdgeInsets.zero,
      elevation: isSelected ? 4.0 : 1.0,
      semanticLabel: semanticLabel,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Theme preview icon
          _buildThemePreview(context, option, tokens, isSelected, isCurrentTheme),
          
          const SizedBox(width: Spacing.md),
          
          // Theme details
          Expanded(
            child: _buildThemeDetails(context, option, tokens, isSelected, isCurrentTheme, l10n),
          ),
          
          const SizedBox(width: Spacing.sm),
          
          // Selection and status indicators
          _buildStatusIndicators(context, option, tokens, isSelected, isCurrentTheme, l10n),
        ],
      ),
    );
  }

  String _buildSemanticLabel(ThemeOption option, bool isSelected, bool isCurrentTheme, AppLocalizations? l10n) {
    final buffer = StringBuffer();
    
    // Theme name and status
    buffer.write('${option.title} theme');
    if (isCurrentTheme) {
      buffer.write(', currently active');
    }
    if (isSelected) {
      buffer.write(', selected for preview');
    }
    
    // Accessibility information
    buffer.write('. ${option.accessibilityDescription}');
    
    // Feature highlights
    if (option.features.isNotEmpty) {
      buffer.write(' Features: ${option.features.join(", ")}.');
    }
    
    // Skip WCAG compliance info if empty
    if (option.wcagCompliance.isNotEmpty && option.contrastRatio.isNotEmpty) {
      buffer.write(' WCAG ${option.wcagCompliance} compliant with ${option.contrastRatio} contrast ratio.');
    }
    
    return buffer.toString();
  }

  Widget _buildThemePreview(BuildContext context, ThemeOption option, SemanticTokens tokens, bool isSelected, bool isCurrentTheme) {
    final semanticTokens = ThemeManager.instance.getSemanticTokens(option.theme);
    
    return Container(
      width: HitTargets.touch,
      height: HitTargets.touch,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Spacing.sm),
        border: Border.all(
          color: isSelected ? tokens.primary : tokens.outline,
          width: isSelected ? 2.0 : 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Spacing.sm - 1),
        child: Stack(
          children: [
            // Background color preview
            Container(
              width: double.infinity,
              height: double.infinity,
              color: semanticTokens.bg,
            ),
            // Surface color preview (top half)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: HitTargets.touch / 2,
              child: Container(
                color: semanticTokens.surface,
              ),
            ),
            // Primary color accent
            Positioned(
              bottom: Spacing.xs,
              right: Spacing.xs,
              child: Container(
                width: Spacing.sm,
                height: Spacing.sm,
                decoration: BoxDecoration(
                  color: semanticTokens.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Theme icon overlay
            Center(
              child: Icon(
                ThemeManager.instance.getThemeIcon(option.theme),
                color: semanticTokens.textPrimary,
                size: 20,
                semanticLabel: '${option.title} theme preview',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeDetails(BuildContext context, ThemeOption option, SemanticTokens tokens, bool isSelected, bool isCurrentTheme, AppLocalizations? l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Theme title and current badge
        Row(
          children: [
            Expanded(
              child: Text(
                option.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isSelected ? tokens.primary : tokens.textPrimary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (isCurrentTheme)
              AccessibleChip(
                label: const Text('CURRENT'),
                selected: true,
                enabled: true,
                semanticLabel: 'Currently active theme',
              ),
          ],
        ),
        
        const SizedBox(height: Spacing.xs),
        
        // Theme description
        Text(
          option.description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: tokens.textSecondary,
            height: 1.4,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: Spacing.xs),
        
        // Features badges (only show if WCAG info exists)
        if (option.wcagCompliance.isNotEmpty && option.contrastRatio.isNotEmpty)
          Wrap(
            spacing: Spacing.xs,
            runSpacing: Spacing.xs,
            children: [
              // WCAG compliance badge
              AccessibleChip(
                label: Text('WCAG ${option.wcagCompliance}'),
                enabled: true,
                semanticLabel: 'WCAG ${option.wcagCompliance} compliant',
              ),
              // Contrast ratio badge
              AccessibleChip(
                label: Text(option.contrastRatio),
                enabled: true,
                semanticLabel: '${option.contrastRatio} contrast ratio',
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildStatusIndicators(BuildContext context, ThemeOption option, SemanticTokens tokens, bool isSelected, bool isCurrentTheme, AppLocalizations? l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Selection indicator
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? tokens.primary : tokens.surface,
            border: Border.all(
              color: isSelected ? tokens.primary : tokens.outline,
              width: 2.0,
            ),
          ),
          child: isSelected
              ? Icon(
                  Icons.check_rounded,
                  color: tokens.onPrimary,
                  size: 18,
                  semanticLabel: 'Selected',
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
  
  Future<void> _applyThemeImmediately(AppTheme theme) async {
    try {
      final previousTheme = ThemeManager.instance.currentTheme;
      await ThemeManager.instance.setTheme(theme);
      
      // Log successful theme change
      TelemetryService.instance.logEvent(
        TelemetryEvent.themeApplied.name,
        {
          'theme_id': theme.id,
          'previous_theme_id': previousTheme.id,
          'action': 'immediate_apply',
          'from_selector': true,
        },
      );
    } catch (e) {
      // Log theme application error but don't show error to user
      // since the old theme will remain active
      TelemetryService.instance.logEvent(
        TelemetryEvent.themeApplicationFailed.name,
        {
          'theme_id': theme.id,
          'error': e.toString(),
        },
      );
    }
  }
  
  void _applyTheme() async {
    if (_selectedTheme == null) return;
    
    try {
      final previousTheme = ThemeManager.instance.currentTheme;
      await ThemeManager.instance.setTheme(_selectedTheme!);
      
      if (mounted) {
        final tokens = context.tokens;
        final themeName = ThemeManager.instance.getThemeDisplayName(_selectedTheme!);
        
        // Show accessible success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Semantics(
              liveRegion: true,
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: tokens.onPrimary,
                    size: 24,
                    semanticLabel: 'Success',
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Theme Applied Successfully',
                          style: TextStyle(
                            color: tokens.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Now using $themeName theme',
                          style: TextStyle(
                            color: tokens.onPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: tokens.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Spacing.sm),
            ),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'DISMISS',
              textColor: tokens.onPrimary,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
        
        // Log successful theme change
        TelemetryService.instance.logEvent(
          TelemetryEvent.themeApplied.name,
          {
            'theme_id': _selectedTheme!.id,
            'previous_theme_id': previousTheme.id,
            'action': 'applied',
            'from_selector': true,
          },
        );
        
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        final tokens = context.tokens;
        
        // Show accessible error feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Semantics(
              liveRegion: true,
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: tokens.onPrimary,
                    size: 24,
                    semanticLabel: 'Error',
                  ),
                  const SizedBox(width: Spacing.sm),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Theme Application Failed',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Please try again or restart the app',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: tokens.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Spacing.sm),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
        
        // Log theme application error
        TelemetryService.instance.logEvent(
          TelemetryEvent.themeApplicationFailed.name,
          {
            'theme_id': _selectedTheme!.id,
            'error': e.toString(),
          },
        );
      }
    }
  }
}

class ThemeOption {
  final AppTheme theme;
  final String title;
  final String description;
  final String accessibilityDescription;
  final List<String> features;
  final String contrastRatio;
  final String wcagCompliance;
  
  const ThemeOption({
    required this.theme,
    required this.title,
    required this.description,
    required this.accessibilityDescription,
    required this.features,
    required this.contrastRatio,
    required this.wcagCompliance,
  });
}