import 'package:flutter/material.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/theme/contrast.dart';

class ContrastGoggles extends StatelessWidget {
  final Widget child;
  const ContrastGoggles({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!ThemeManager.instance.isDiagnosticsModeEnabled) return child;
    final tokens = context.tokens;
    final bg = tokens.bg;
    final fg = tokens.textPrimary;
    final ratio = contrastRatio(fg, bg);
    return Stack(
      children: [
        child,
        Positioned(
          left: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.white, fontSize: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 14, height: 14, color: bg),
                  const SizedBox(width: 6),
                  Container(width: 14, height: 14, color: fg),
                  const SizedBox(width: 8),
                  Text('CR ${ratio.toStringAsFixed(2)}'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}


