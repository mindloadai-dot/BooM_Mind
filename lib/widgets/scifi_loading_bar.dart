import 'package:flutter/material.dart';
import 'package:mindload/theme.dart';

class ScifiLoadingBar extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final String? statusText;
  final String? percentageText;
  final Color? primaryColor;
  final Color? secondaryColor;
  final double height;
  final Duration animationDuration;

  const ScifiLoadingBar({
    super.key,
    required this.progress,
    this.statusText,
    this.percentageText,
    this.primaryColor,
    this.secondaryColor,
    this.height = 8.0,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<ScifiLoadingBar> createState() => _ScifiLoadingBarState();
}

class _ScifiLoadingBarState extends State<ScifiLoadingBar>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scanController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for the loading bar
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Scan animation for the moving light effect
    _scanController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
    _scanController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primaryColor = widget.primaryColor ?? tokens.primary;
    final secondaryColor = widget.secondaryColor ?? tokens.primary.withValues(alpha: 0.3);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main loading bar container
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.height / 2),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.1),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background track
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.height / 2),
                  color: secondaryColor.withValues(alpha: 0.1),
                ),
              ),
              
              // Progress fill
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return FractionallySizedBox(
                    widthFactor: widget.progress,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(widget.height / 2),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            primaryColor.withValues(alpha: _pulseAnimation.value),
                            primaryColor.withValues(alpha: _pulseAnimation.value * 0.8),
                            primaryColor.withValues(alpha: _pulseAnimation.value * 0.6),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.4),
                            blurRadius: 4,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              // Scanning light effect
              AnimatedBuilder(
                animation: _scanAnimation,
                builder: (context, child) {
                  return Positioned(
                    left: _scanAnimation.value * MediaQuery.of(context).size.width,
                    child: Container(
                      width: 20,
                      height: widget.height,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(widget.height / 2),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.transparent,
                            primaryColor.withValues(alpha: 0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              // Glowing dots at the ends
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.6),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
              
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.6),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Status text and percentage
        if (widget.statusText != null || widget.percentageText != null) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status text
              if (widget.statusText != null)
                Expanded(
                  child: Text(
                    widget.statusText!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: tokens.textSecondary,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              
              // Percentage text
              if (widget.percentageText != null)
                Text(
                  widget.percentageText!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                    letterSpacing: 1,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

// Convenience widget for AI processing with automatic percentage calculation
class AIProcessingLoadingBar extends StatefulWidget {
  final String statusText;
  final double progress; // 0.0 to 1.0
  final Color? primaryColor;
  final Color? secondaryColor;
  final double height;

  const AIProcessingLoadingBar({
    super.key,
    required this.statusText,
    required this.progress,
    this.primaryColor,
    this.secondaryColor,
    this.height = 8.0,
  });

  @override
  State<AIProcessingLoadingBar> createState() => _AIProcessingLoadingBarState();
}

class _AIProcessingLoadingBarState extends State<AIProcessingLoadingBar> {
  @override
  Widget build(BuildContext context) {
    final percentage = (widget.progress * 100).toInt();
    
    return ScifiLoadingBar(
      progress: widget.progress,
      statusText: widget.statusText,
      percentageText: '$percentage%',
      primaryColor: widget.primaryColor,
      secondaryColor: widget.secondaryColor,
      height: widget.height,
    );
  }
}
