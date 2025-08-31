import 'package:flutter/material.dart';
import 'package:mindload/theme.dart';

/// Semantic color options for study sets that align with the app's theme system
class StudySetColor {
  final String name;
  final String semanticToken;
  final Color color;
  final String description;

  const StudySetColor({
    required this.name,
    required this.semanticToken,
    required this.color,
    required this.description,
  });
}

/// A color picker widget that uses semantic theme colors
class SemanticColorPicker extends StatefulWidget {
  final String? selectedColor;
  final Function(String?) onColorChanged;
  final SemanticTokens tokens;

  const SemanticColorPicker({
    super.key,
    this.selectedColor,
    required this.onColorChanged,
    required this.tokens,
  });

  @override
  State<SemanticColorPicker> createState() => _SemanticColorPickerState();
}

class _SemanticColorPickerState extends State<SemanticColorPicker> {
  late String? _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.selectedColor;
  }

  @override
  void didUpdateWidget(SemanticColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedColor != widget.selectedColor) {
      _selectedColor = widget.selectedColor;
    }
  }

  /// Get available semantic colors based on the current theme
  List<StudySetColor> get _availableColors {
    return [
      StudySetColor(
        name: 'Primary',
        semanticToken: 'primary',
        color: widget.tokens.primary,
        description: 'Main theme color',
      ),
      StudySetColor(
        name: 'Secondary',
        semanticToken: 'secondary',
        color: widget.tokens.secondary,
        description: 'Supporting color',
      ),
      StudySetColor(
        name: 'Accent',
        semanticToken: 'accent',
        color: widget.tokens.accent,
        description: 'Highlight color',
      ),
      StudySetColor(
        name: 'Success',
        semanticToken: 'success',
        color: widget.tokens.success,
        description: 'Positive actions',
      ),
      StudySetColor(
        name: 'Warning',
        semanticToken: 'warning',
        color: widget.tokens.warning,
        description: 'Caution elements',
      ),
      StudySetColor(
        name: 'Brand',
        semanticToken: 'brandTitle',
        color: widget.tokens.brandTitle,
        description: 'Brand identity',
      ),
      StudySetColor(
        name: 'Surface',
        semanticToken: 'surface',
        color: widget.tokens.surface,
        description: 'Background surface',
      ),
      StudySetColor(
        name: 'Muted',
        semanticToken: 'muted',
        color: widget.tokens.muted,
        description: 'Subtle elements',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.palette_rounded,
              color: widget.tokens.textPrimary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Study Set Color',
              style: TextStyle(
                color: widget.tokens.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (_selectedColor != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedColor = null;
                  });
                  widget.onColorChanged(null);
                },
                child: Text(
                  'Clear',
                  style: TextStyle(
                    color: widget.tokens.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Color grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: _availableColors.length,
          itemBuilder: (context, index) {
            final colorOption = _availableColors[index];
            final isSelected = _selectedColor == colorOption.semanticToken;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = isSelected ? null : colorOption.semanticToken;
                });
                widget.onColorChanged(_selectedColor);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: colorOption.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? widget.tokens.borderFocus
                        : widget.tokens.borderDefault.withValues(alpha: 0.3),
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colorOption.color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Stack(
                  children: [
                    // Color preview
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(11),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorOption.color,
                            colorOption.color.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),

                    // Selection indicator
                    if (isSelected)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: widget.tokens.textInverse,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.tokens.borderFocus,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.check,
                            size: 10,
                            color: widget.tokens.textPrimary,
                          ),
                        ),
                      ),

                    // Color name
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Text(
                        colorOption.name,
                        style: TextStyle(
                          color: _getContrastColor(colorOption.color),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Description
        if (_selectedColor != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.tokens.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.tokens.borderMuted,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _getSelectedColor(),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getSelectedColorDescription(),
                    style: TextStyle(
                      color: widget.tokens.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Color _getSelectedColor() {
    if (_selectedColor == null) return widget.tokens.primary;
    final colorOption = _availableColors.firstWhere(
      (c) => c.semanticToken == _selectedColor,
      orElse: () => _availableColors.first,
    );
    return colorOption.color;
  }

  String _getSelectedColorDescription() {
    if (_selectedColor == null) return 'No color selected';
    final colorOption = _availableColors.firstWhere(
      (c) => c.semanticToken == _selectedColor,
      orElse: () => _availableColors.first,
    );
    return colorOption.description;
  }

  Color _getContrastColor(Color backgroundColor) {
    // Calculate luminance to determine if we need light or dark text
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
