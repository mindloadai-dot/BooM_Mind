import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mindload/services/unified_storage_service.dart';
import 'package:mindload/models/storage_models.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/widgets/mindload_app_bar.dart';
import 'package:mindload/widgets/unified_design_system.dart';

class StorageManagementScreen extends StatefulWidget {
  const StorageManagementScreen({super.key});

  @override
  State<StorageManagementScreen> createState() =>
      _StorageManagementScreenState();
}

class _StorageManagementScreenState extends State<StorageManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: MindloadAppBarFactory.secondary(title: 'Storage Management'),
      body: Consumer<UnifiedStorageService>(
        builder: (context, storageService, child) {
          final totals = storageService.totals;
          final metadata = storageService.metadata;

          return FutureBuilder<Map<String, dynamic>>(
            future: storageService.getStorageStats(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final stats = snapshot.data!;

              return SingleChildScrollView(
                padding: UnifiedSpacing.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Storage Overview
                    _buildStorageOverview(stats),

                    SizedBox(height: UnifiedSpacing.lg),

                    // Storage Warning Banner
                    if (storageService.isStorageWarning)
                      _buildStorageWarningBanner(),

                    SizedBox(height: UnifiedSpacing.lg),

                    // Storage Actions
                    _buildStorageActions(storageService),

                    SizedBox(height: UnifiedSpacing.lg),

                    // Study Sets List
                    _buildStudySetsList(metadata, storageService),

                    SizedBox(height: UnifiedSpacing.lg),

                    // Storage Tips
                    _buildStorageTips(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Storage overview card
  Widget _buildStorageOverview(Map<String, dynamic> stats) {
    final totalBytes = stats['totalBytes'] as int;
    final totalSets = stats['totalSets'] as int;
    final totalItems = stats['totalItems'] as int;
    final budgetMB = stats['budgetMB'] as int;
    final usagePercentage = stats['usagePercentage'] as double;
    final freeSpaceGB = stats['freeSpaceGB'] as int;

    return UnifiedCard(
      padding: UnifiedSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UnifiedText(
            'Storage Overview',
            style: UnifiedTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: UnifiedSpacing.md),

          // Usage bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  UnifiedText(
                    'Local Storage',
                    style: UnifiedTypography.titleMedium,
                  ),
                  UnifiedText(
                    '${(usagePercentage * 100).toStringAsFixed(1)}%',
                    style: UnifiedTypography.titleMedium.copyWith(
                      color: _getUsageColor(usagePercentage),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: UnifiedSpacing.sm),
              LinearProgressIndicator(
                value: usagePercentage,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getUsageColor(usagePercentage),
                ),
                minHeight: 8,
              ),
              SizedBox(height: UnifiedSpacing.xs),
              UnifiedText(
                '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB / $budgetMB MB',
                style: UnifiedTypography.bodySmall.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),

          SizedBox(height: UnifiedSpacing.md),

          // Stats grid
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Study Sets',
                  totalSets.toString(),
                  Icons.folder,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Total Items',
                  totalItems.toString(),
                  Icons.article,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Free Space',
                  '$freeSpaceGB GB',
                  Icons.storage,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Stat item widget
  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        UnifiedIcon(icon, color: color, size: 32),
        SizedBox(height: UnifiedSpacing.sm),
        UnifiedText(
          value,
          style: UnifiedTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        UnifiedText(
          label,
          style: UnifiedTypography.bodySmall.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Storage warning banner
  Widget _buildStorageWarningBanner() {
    return UnifiedCard(
      padding: UnifiedSpacing.cardPadding,
      borderRadius: UnifiedBorderRadius.mdRadius,
      child: Row(
        children: [
          UnifiedIcon(Icons.warning_amber_rounded,
              color: context.tokens.warning),
          SizedBox(width: UnifiedSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UnifiedText(
                  'Storage Almost Full',
                  style: UnifiedTypography.titleMedium.copyWith(
                    color: context.tokens.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                UnifiedText(
                  'Consider archiving old sets or upgrading your plan for more storage.',
                  style: UnifiedTypography.bodyMedium.copyWith(
                    color: context.tokens.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Storage actions
  Widget _buildStorageActions(UnifiedStorageService storageService) {
    return UnifiedCard(
      padding: UnifiedSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UnifiedText(
            'Storage Actions',
            style: UnifiedTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: UnifiedSpacing.md),
          Row(
            children: [
              Expanded(
                child: UnifiedButton(
                  onPressed: () => _showArchiveDialog(storageService),
                  icon: Icons.archive,
                  child: UnifiedText('Archive to Cloud'),
                ),
              ),
              SizedBox(width: UnifiedSpacing.sm),
              Expanded(
                child: UnifiedButton(
                  onPressed: () => _showCleanupDialog(storageService),
                  icon: Icons.cleaning_services,
                  child: UnifiedText('Clean Up'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Study sets list
  Widget _buildStudySetsList(Map<String, StudySetMetadata> metadata,
      UnifiedStorageService storageService) {
    final sets = metadata.values.toList()
      ..sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));

    return UnifiedCard(
      padding: UnifiedSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              UnifiedText(
                'Study Sets (${sets.length})',
                style: UnifiedTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              UnifiedText(
                'Tap to pin/unpin',
                style: UnifiedTypography.bodySmall.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: UnifiedSpacing.md),
          if (sets.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    UnifiedIcon(
                      Icons.folder_open,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: UnifiedSpacing.md),
                    UnifiedText(
                      'No study sets found',
                      style: UnifiedTypography.titleMedium.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    UnifiedText(
                      'Create or import study sets to see them here',
                      style: UnifiedTypography.bodyMedium.copyWith(
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sets.length,
              itemBuilder: (context, index) {
                final set = sets[index];
                return _buildStudySetTile(set, storageService);
              },
            ),
        ],
      ),
    );
  }

  // Study set tile
  Widget _buildStudySetTile(
      StudySetMetadata set, UnifiedStorageService storageService) {
    final isPinned = set.isPinned;
    final isArchived = set.isArchived;

    return ListTile(
      leading: UnifiedIcon(
        isPinned ? Icons.push_pin : Icons.folder,
        color: isPinned ? Colors.red : Colors.grey[600],
      ),
      title: UnifiedText(
        set.title,
        style: TextStyle(
          fontWeight: isPinned ? FontWeight.bold : FontWeight.normal,
          decoration: isArchived ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UnifiedText(
            '${set.items} items • ${(set.bytes / 1024).toStringAsFixed(1)} KB',
            style: UnifiedTypography.bodySmall,
          ),
          UnifiedText(
            'Last opened: ${_formatDate(set.lastOpenedAt)}',
            style: UnifiedTypography.bodySmall.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isArchived)
            Chip(
              label: UnifiedText('Archived'),
              backgroundColor: Colors.grey[200],
              labelStyle: TextStyle(color: Colors.grey[700]),
            ),
          IconButton(
            onPressed: () => _togglePin(set.setId, storageService),
            icon: UnifiedIcon(
              isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: isPinned ? Colors.red : Colors.grey[600],
            ),
            tooltip: isPinned ? 'Unpin' : 'Pin',
          ),
        ],
      ),
      onTap: () => _showSetDetails(set, storageService),
    );
  }

  // Storage tips
  Widget _buildStorageTips() {
    return UnifiedCard(
      padding: UnifiedSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UnifiedText(
            'Storage Tips',
            style: UnifiedTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: UnifiedSpacing.md),
          _buildTipItem(
            Icons.push_pin,
            'Pin Important Sets',
            'Pinned sets are never automatically removed from local storage.',
          ),
          _buildTipItem(
            Icons.archive,
            'Archive Old Sets',
            'Archive sets you don\'t need locally. You can always re-download them.',
          ),
          _buildTipItem(
            Icons.cleaning_services,
            'Regular Cleanup',
            'Use the Clean Up feature to remove old temporary files and free space.',
          ),
          _buildTipItem(
            Icons.upgrade,
            'Upgrade Plan',
            'Consider upgrading to a higher tier for more storage capacity.',
          ),
        ],
      ),
    );
  }

  // Tip item widget
  Widget _buildTipItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UnifiedIcon(icon, color: Colors.blue[600], size: 24),
          SizedBox(width: UnifiedSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UnifiedText(
                  title,
                  style: UnifiedTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                UnifiedText(
                  description,
                  style: UnifiedTypography.bodyMedium.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getUsageColor(double percentage) {
    if (percentage >= 0.9) return Colors.red;
    if (percentage >= 0.8) return Colors.orange;
    if (percentage >= 0.6) return Colors.yellow[700]!;
    return Colors.green;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Action methods
  void _togglePin(String setId, UnifiedStorageService storageService) {
    storageService.togglePin(setId);
  }

  void _showSetDetails(
      StudySetMetadata set, UnifiedStorageService storageService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: UnifiedText(set.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UnifiedText('Items: ${set.items}'),
            UnifiedText('Size: ${(set.bytes / 1024).toStringAsFixed(1)} KB'),
            UnifiedText('Created: ${_formatDate(set.createdAt)}'),
            UnifiedText('Last opened: ${_formatDate(set.lastOpenedAt)}'),
            UnifiedText('Status: ${set.isPinned ? "Pinned" : "Unpinned"}'),
            if (set.isArchived) UnifiedText('Archived: Yes'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: UnifiedText('Close'),
          ),
        ],
      ),
    );
  }

  void _showArchiveDialog(UnifiedStorageService storageService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: UnifiedText('Archive to Cloud'),
        content: UnifiedText(
          'This will move selected study sets to cloud storage, freeing up local space. '
          'You can always re-download them later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: UnifiedText('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement archive functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: UnifiedText('Archive functionality coming soon')),
              );
            },
            child: UnifiedText('Archive'),
          ),
        ],
      ),
    );
  }

  void _showCleanupDialog(UnifiedStorageService storageService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: UnifiedText('Clean Up Storage'),
        content: UnifiedText(
          'This will remove temporary files and clean up old data to free up space. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: UnifiedText('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement cleanup functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: UnifiedText('Cleanup functionality coming soon')),
              );
            },
            child: UnifiedText('Clean Up'),
          ),
        ],
      ),
    );
  }
}
