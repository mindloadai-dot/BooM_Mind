import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Long Press Service
/// Handles 800ms confirmation requirement for operations
class LongPressService {
  static final LongPressService _instance = LongPressService._internal();
  factory LongPressService() => _instance;
  LongPressService._internal();

  static const int _requiredHoldTime = 800; // 800ms as specified
  static const int _progressUpdateInterval = 50; // Update progress every 50ms

  Timer? _holdTimer;
  Timer? _progressTimer;
  bool _isHolding = false;
  double _progress = 0.0;

  /// Start long press detection
  void startLongPress({
    required VoidCallback onComplete,
    required VoidCallback onProgress,
    required VoidCallback onCancel,
  }) {
    _isHolding = true;
    _progress = 0.0;
    
    // Start progress timer
    _progressTimer = Timer.periodic(
      Duration(milliseconds: _progressUpdateInterval),
      (timer) {
        _progress += _progressUpdateInterval / _requiredHoldTime;
        if (_progress >= 1.0) {
          _progress = 1.0;
          timer.cancel();
        }
        onProgress();
      },
    );

    // Start hold timer
    _holdTimer = Timer(
      Duration(milliseconds: _requiredHoldTime),
      () {
        if (_isHolding) {
          _completeLongPress(onComplete);
        }
      },
    );

    // Provide haptic feedback
    HapticFeedback.lightImpact();
  }

  /// Cancel long press
  void cancelLongPress() {
    _isHolding = false;
    _progress = 0.0;
    
    _holdTimer?.cancel();
    _progressTimer?.cancel();
    
    _holdTimer = null;
    _progressTimer = null;
  }

  /// Complete long press
  void _completeLongPress(VoidCallback onComplete) {
    _isHolding = false;
    _progress = 1.0;
    
    _holdTimer?.cancel();
    _progressTimer?.cancel();
    
    _holdTimer = null;
    _progressTimer = null;

    // Provide success haptic feedback
    HapticFeedback.heavyImpact();
    
    // Execute callback
    onComplete();
  }

  /// Get current progress (0.0 to 1.0)
  double get progress => _progress;

  /// Check if currently holding
  bool get isHolding => _isHolding;

  /// Get remaining time in milliseconds
  int get remainingTime {
    if (!_isHolding) return 0;
    return (_requiredHoldTime * (1.0 - _progress)).round();
  }

  /// Get progress percentage
  int get progressPercentage => (_progress * 100).round();

  /// Check if long press is complete
  bool get isComplete => _progress >= 1.0;

  /// Reset service state
  void reset() {
    cancelLongPress();
    _progress = 0.0;
  }

  /// Dispose of timers
  void dispose() {
    cancelLongPress();
  }
}

/// Long Press Button Widget
/// Custom button that requires long press to activate
class LongPressButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool disabled;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const LongPressButton({
    super.key,
    required this.text,
    this.onPressed,
    this.disabled = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
  });

  @override
  State<LongPressButton> createState() => _LongPressButtonState();
}

class _LongPressButtonState extends State<LongPressButton>
    with TickerProviderStateMixin {
  final LongPressService _longPressService = LongPressService();
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _longPressService.dispose();
    super.dispose();
  }

  void _startLongPress() {
    if (widget.disabled || widget.onPressed == null) return;

    _longPressService.startLongPress(
      onComplete: () {
        _progressController.forward();
        widget.onPressed?.call();
      },
      onProgress: () {
        _progressController.value = _longPressService.progress;
      },
      onCancel: () {
        _progressController.reverse();
      },
    );
  }

  void _cancelLongPress() {
    _longPressService.cancelLongPress();
    _progressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = widget.disabled || widget.onPressed == null;

    return GestureDetector(
      onTapDown: (_) => _startLongPress(),
      onTapUp: (_) => _cancelLongPress(),
      onTapCancel: () => _cancelLongPress(),
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: isDisabled
                  ? theme.disabledColor
                  : (widget.backgroundColor ?? theme.primaryColor),
              borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                // Progress indicator
                if (_longPressService.isHolding)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _progressAnimation.value,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.foregroundColor ?? theme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                
                // Button content
                Center(
                  child: Padding(
                    padding: widget.padding ?? const EdgeInsets.all(16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          widget.icon!,
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.text,
                          style: TextStyle(
                            color: isDisabled
                                ? theme.disabledColor
                                : (widget.foregroundColor ?? theme.colorScheme.onPrimary),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Long Press Confirmation Dialog
/// Shows token estimate and requires long press confirmation
class LongPressConfirmationDialog extends StatefulWidget {
  final String title;
  final String message;
  final int tokensRequired;
  final List<String> warnings;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool canAfford;

  const LongPressConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.tokensRequired,
    required this.warnings,
    required this.onConfirm,
    required this.onCancel,
    required this.canAfford,
  });

  @override
  State<LongPressConfirmationDialog> createState() =>
      _LongPressConfirmationDialogState();
}

class _LongPressConfirmationDialogState
    extends State<LongPressConfirmationDialog> {
  final LongPressService _longPressService = LongPressService();

  @override
  void dispose() {
    _longPressService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message),
          const SizedBox(height: 16),
          Text(
            'This will use ${widget.tokensRequired} MindLoad Tokens.',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (widget.warnings.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Warnings:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            ...widget.warnings.map((warning) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Text('• $warning'),
            )),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Cancel'),
        ),
        LongPressButton(
          text: 'Hold to confirm',
          onPressed: widget.canAfford ? widget.onConfirm : null,
          disabled: !widget.canAfford,
          backgroundColor: widget.canAfford ? null : Colors.grey,
        ),
      ],
    );
  }
}
