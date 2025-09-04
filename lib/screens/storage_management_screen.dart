import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mindload/services/unified_storage_service.dart';
import 'package:mindload/models/storage_models.dart';
import 'package:mindload/theme.dart';

import 'package:mindload/widgets/mindload_app_bar.dart';

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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Storage Overview
                    _buildStorageOverview(stats),

                    const SizedBox(height: 24),

                    // Storage Warning Banner
                    if (storageService.isStorageWarning)
                      _buildStorageWarningBanner(),

                    const SizedBox(height: 24),

                    // Storage Actions
                    _buildStorageActions(storageService),

                    const SizedBox(height: 24),

                    // Study Sets List
                    _buildStudySetsList(metadata, storageService),

                    const SizedBox(height: 24),

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

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Storage Overview',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Usage bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Local Storage',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${(usagePercentage * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: _getUsageColor(usagePercentage),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: usagePercentage,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getUsageColor(usagePercentage),
                  ),
                  minHeight: 8,
                ),
                const SizedBox(height: 4),
                Text(
                  '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB / $budgetMB MB',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),

            const SizedBox(height: 16),

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
      ),
    );
  }

  // Stat item widget
  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Storage warning banner
  Widget _buildStorageWarningBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tokens.warning.withValues(alpha: 0.1),
        border:
            Border.all(color: context.tokens.warning.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: context.tokens.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Storage Almost Full',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: context.tokens.warning,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Consider archiving old sets or upgrading your plan for more storage.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Storage Actions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showArchiveDialog(storageService),
                    icon: const Icon(Icons.archive),
                    label: const Text('Archive to Cloud'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.tokens.primary,
                      foregroundColor: context.tokens.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showCleanupDialog(storageService),
                    icon: const Icon(Icons.cleaning_services),
                    label: const Text('Clean Up'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.tokens.success,
                      foregroundColor: context.tokens.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Study sets list
  Widget _buildStudySetsList(Map<String, StudySetMetadata> metadata,
      UnifiedStorageService storageService) {
    final sets = metadata.values.toList()
      ..sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Study Sets (${sets.length})',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Tap to pin/unpin',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (sets.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No study sets found',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                      ),
                      Text(
                        'Create or import study sets to see them here',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
      ),
    );
  }

  // Study set tile
  Widget _buildStudySetTile(
      StudySetMetadata set, UnifiedStorageService storageService) {
    final isPinned = set.isPinned;
    final isArchived = set.isArchived;

    return ListTile(
      leading: Icon(
        isPinned ? Icons.push_pin : Icons.folder,
        color: isPinned ? Colors.red : Colors.grey[600],
      ),
      title: Text(
        set.title,
        style: TextStyle(
          fontWeight: isPinned ? FontWeight.bold : FontWeight.normal,
          decoration: isArchived ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${set.items} items • ${(set.bytes / 1024).toStringAsFixed(1)} KB',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            'Last opened: ${_formatDate(set.lastOpenedAt)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
              label: const Text('Archived'),
              backgroundColor: Colors.grey[200],
              labelStyle: TextStyle(color: Colors.grey[700]),
            ),
          IconButton(
            onPressed: () => _togglePin(set.setId, storageService),
            icon: Icon(
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
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Storage Tips',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
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
          Icon(icon, color: Colors.blue[600], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
        title: Text(set.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Items: ${set.items}'),
            Text('Size: ${(set.bytes / 1024).toStringAsFixed(1)} KB'),
            Text('Created: ${_formatDate(set.createdAt)}'),
            Text('Last opened: ${_formatDate(set.lastOpenedAt)}'),
            Text('Status: ${set.isPinned ? "Pinned" : "Unpinned"}'),
            if (set.isArchived) Text('Archived: Yes'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showArchiveDialog(UnifiedStorageService storageService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive to Cloud'),
        content: const Text(
          'This will move selected study sets to cloud storage, freeing up local space. '
          'You can always re-download them later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement archive functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Archive functionality coming soon')),
              );
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  void _showCleanupDialog(UnifiedStorageService storageService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clean Up Storage'),
        content: const Text(
          'This will remove temporary files and clean up old data to free up space. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement cleanup functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Cleanup functionality coming soon')),
              );
            },
            child: const Text('Clean Up'),
          ),
        ],
      ),
    );
  }
}
