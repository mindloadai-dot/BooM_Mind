import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mindload/services/enhanced_storage_service.dart';
import 'package:mindload/screens/storage_management_screen.dart';
import 'package:mindload/theme.dart';

class StorageWarningBanner extends StatelessWidget {
  final VoidCallback? onManageStorage;
  final bool showManageButton;

  const StorageWarningBanner({
    super.key,
    this.onManageStorage,
    this.showManageButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedStorageService>(
      builder: (context, storageService, child) {
        if (!storageService.isStorageWarning) {
          return const SizedBox.shrink();
        }

        return FutureBuilder<Map<String, dynamic>>(
          future: storageService.getStorageStats(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }

            final stats = snapshot.data!;
            final usagePercentage = stats['usagePercentage'] as double;
            final totalBytes = stats['totalBytes'] as int;
            final budgetMB = stats['budgetMB'] as int;

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getBannerColor(context, usagePercentage),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getBorderColor(context, usagePercentage),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getWarningIcon(usagePercentage),
                        color: _getIconColor(context, usagePercentage),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getWarningTitle(usagePercentage),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color:
                                        _getTextColor(context, usagePercentage),
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getWarningMessage(
                                  usagePercentage, totalBytes, budgetMB),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color:
                                        _getTextColor(context, usagePercentage),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (showManageButton) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: onManageStorage ??
                              () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const StorageManagementScreen(),
                                  ),
                                );
                              },
                          style: TextButton.styleFrom(
                            foregroundColor:
                                _getButtonColor(context, usagePercentage),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: const Text('Manage Storage'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper methods for dynamic styling based on usage percentage
  Color _getBannerColor(BuildContext context, double usagePercentage) {
    if (usagePercentage >= 0.95) {
      return context.tokens.error.withValues(alpha: 0.1);
    }
    if (usagePercentage >= 0.9) {
      return context.tokens.error.withValues(alpha: 0.1);
    }
    if (usagePercentage >= 0.8) {
      return context.tokens.warning.withValues(alpha: 0.1);
    }
    return context.tokens.warning.withValues(alpha: 0.1);
  }

  Color _getBorderColor(BuildContext context, double usagePercentage) {
    if (usagePercentage >= 0.95) {
      return context.tokens.error.withValues(alpha: 0.3);
    }
    if (usagePercentage >= 0.9) {
      return context.tokens.error.withValues(alpha: 0.3);
    }
    if (usagePercentage >= 0.8) {
      return context.tokens.warning.withValues(alpha: 0.3);
    }
    return context.tokens.warning.withValues(alpha: 0.3);
  }

  Color _getIconColor(BuildContext context, double usagePercentage) {
    if (usagePercentage >= 0.95) {
      return context.tokens.error;
    }
    if (usagePercentage >= 0.9) {
      return context.tokens.error;
    }
    if (usagePercentage >= 0.8) {
      return context.tokens.warning;
    }
    return context.tokens.warning;
  }

  Color _getTextColor(BuildContext context, double usagePercentage) {
    if (usagePercentage >= 0.95) {
      return context.tokens.error;
    }
    if (usagePercentage >= 0.9) {
      return context.tokens.error;
    }
    if (usagePercentage >= 0.8) {
      return context.tokens.warning;
    }
    return context.tokens.warning;
  }

  Color _getButtonColor(BuildContext context, double usagePercentage) {
    if (usagePercentage >= 0.95) {
      return context.tokens.error;
    }
    if (usagePercentage >= 0.9) {
      return context.tokens.error;
    }
    if (usagePercentage >= 0.8) {
      return context.tokens.warning;
    }
    return context.tokens.warning;
  }

  IconData _getWarningIcon(double usagePercentage) {
    if (usagePercentage >= 0.95) {
      return Icons.error;
    }
    if (usagePercentage >= 0.9) {
      return Icons.error_outline;
    }
    if (usagePercentage >= 0.8) {
      return Icons.warning_amber_rounded;
    }
    return Icons.info_outline;
  }

  String _getWarningTitle(double usagePercentage) {
    if (usagePercentage >= 0.95) {
      return 'Critical Storage Warning';
    }
    if (usagePercentage >= 0.9) {
      return 'Storage Critical';
    }
    if (usagePercentage >= 0.8) {
      return 'Storage Almost Full';
    }
    return 'Storage Notice';
  }

  String _getWarningMessage(
      double usagePercentage, int totalBytes, int budgetMB) {
    final usedMB = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
    final percentage = (usagePercentage * 100).toStringAsFixed(1);

    if (usagePercentage >= 0.95) {
      return 'Your device storage is critically low. Some features may be limited. '
          'Used: $usedMB MB ($percentage% of $budgetMB MB budget)';
    } else if (usagePercentage >= 0.9) {
      return 'Your device storage is very low. Consider freeing up space soon. '
          'Used: $usedMB MB ($percentage% of $budgetMB MB budget)';
    } else if (usagePercentage >= 0.8) {
      return 'Your device storage is getting full. Consider archiving old sets. '
          'Used: $usedMB MB ($percentage% of $budgetMB MB budget)';
    }

    return 'Storage usage is moderate. Used: $usedMB MB ($percentage% of $budgetMB MB budget)';
  }
}

// Compact version for use in smaller spaces
class CompactStorageWarningBanner extends StatelessWidget {
  final VoidCallback? onManageStorage;

  const CompactStorageWarningBanner({
    super.key,
    this.onManageStorage,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedStorageService>(
      builder: (context, storageService, child) {
        if (!storageService.isStorageWarning) {
          return const SizedBox.shrink();
        }

        return FutureBuilder<Map<String, dynamic>>(
          future: storageService.getStorageStats(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }

            final stats = snapshot.data!;
            final usagePercentage = stats['usagePercentage'] as double;

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _getBannerColor(context, usagePercentage),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getBorderColor(context, usagePercentage),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getWarningIcon(usagePercentage),
                    color: _getIconColor(context, usagePercentage),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getCompactMessage(usagePercentage),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _getTextColor(context, usagePercentage),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: onManageStorage ??
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const StorageManagementScreen(),
                            ),
                          );
                        },
                    style: TextButton.styleFrom(
                      foregroundColor:
                          _getButtonColor(context, usagePercentage),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 0),
                    ),
                    child: const Text('Manage'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper methods (same as main banner but for compact styling)
  Color _getBannerColor(BuildContext context, double usagePercentage) {
    if (usagePercentage >= 0.95) {
      return context.tokens.error.withValues(alpha: 0.1);
    }
    if (usagePercentage >= 0.9) {
      return context.tokens.error.withValues(alpha: 0.1);
    }
    if (usagePercentage >= 0.8) {
      return context.tokens.warning.withValues(alpha: 0.1);
    }
    return context.tokens.warning.withValues(alpha: 0.1);
  }

  Color _getBorderColor(BuildContext context, double usagePercentage) {
    if (usagePercentage >= 0.95) {
      return context.tokens.error.withValues(alpha: 0.3);
    }
    if (usagePercentage >= 0.9) {
      return context.tokens.error.withValues(alpha: 0.3);
    }
    if (usagePercentage >= 0.8) {
      return context.tokens.warning.withValues(alpha: 0.3);
    }
    return context.tokens.warning.withValues(alpha: 0.3);
  }

  Color _getIconColor(BuildContext context, double usagePercentage) {
    if (usagePercentage >= 0.95) {
      return context.tokens.error;
    }
    if (usagePercentage >= 0.9) {
      return context.tokens.error;
    }
    if (usagePercentage >= 0.8) {
      return context.tokens.warning;
    }
    return context.tokens.warning;
  }

  Color _getTextColor(BuildContext context, double usagePercentage) {
    if (usagePercentage >= 0.95) {
      return context.tokens.error;
    }
    if (usagePercentage >= 0.9) {
      return context.tokens.error;
    }
    if (usagePercentage >= 0.8) {
      return context.tokens.warning;
    }
    return context.tokens.warning;
  }

  Color _getButtonColor(BuildContext context, double usagePercentage) {
    if (usagePercentage >= 0.95) {
      return context.tokens.error;
    }
    return context.tokens.warning;
  }

  IconData _getWarningIcon(double usagePercentage) {
    if (usagePercentage >= 0.95) {
      return Icons.error;
    }
    if (usagePercentage >= 0.9) {
      return Icons.error_outline;
    }
    if (usagePercentage >= 0.8) {
      return Icons.warning_amber_rounded;
    }
    return Icons.info_outline;
  }

  String _getCompactMessage(double usagePercentage) {
    if (usagePercentage >= 0.95) {
      return 'Critical storage warning';
    }
    if (usagePercentage >= 0.9) {
      return 'Storage critical';
    }
    if (usagePercentage >= 0.8) {
      return 'Storage almost full';
    }
    return 'Storage notice';
  }
}
