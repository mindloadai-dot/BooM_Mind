import 'package:flutter/material.dart';
import 'package:mindload/models/pdf_export_models.dart';
import 'package:mindload/services/pdf_export_service.dart';

class PdfExportProgressDialog extends StatefulWidget {
  final String setId;
  final PdfExportOptions options;
  final Function(PdfExportResult)? onComplete;
  final VoidCallback? onCancel;

  const PdfExportProgressDialog({
    super.key,
    required this.setId,
    required this.options,
    this.onComplete,
    this.onCancel,
  });

  @override
  State<PdfExportProgressDialog> createState() =>
      _PdfExportProgressDialogState();
}

class _PdfExportProgressDialogState extends State<PdfExportProgressDialog> {
  PdfExportProgress? _progress;
  PdfExportResult? _result;
  bool _isExporting = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startExport();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isExporting) {
          _showCancelConfirmDialog();
          return false;
        }
        return true;
      },
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 400,
            maxWidth: 500,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              _buildHeader(),

              const SizedBox(height: 24),

              // Progress content
              if (_isExporting && _progress != null)
                _buildProgressContent()
              else if (_result != null)
                _buildResultContent()
              else if (_errorMessage != null)
                _buildErrorContent()
              else
                _buildLoadingContent(),

              const SizedBox(height: 24),

              // Action buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // Header section
  Widget _buildHeader() {
    IconData icon;
    String title;
    Color color;

    if (_result != null) {
      if (_result!.success) {
        icon = Icons.check_circle;
        title = 'Export Complete';
        color = Colors.green;
      } else {
        icon = Icons.error;
        title = 'Export Failed';
        color = Colors.red;
      }
    } else if (_errorMessage != null) {
      icon = Icons.error;
      title = 'Export Error';
      color = Colors.red;
    } else {
      icon = Icons.picture_as_pdf;
      title = 'Exporting to PDF';
      color = Colors.blue;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              Text(
                'Study Set: ${widget.options.setId}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Progress content
  Widget _buildProgressContent() {
    final progress = _progress!;
    final percentage = progress.percentage;

    return Column(
      children: [
        // Progress bar
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.blue[600],
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
              minHeight: 8,
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Progress details
        _buildProgressDetail(
          'Current Operation',
          progress.currentOperation,
          Icons.settings,
        ),

        _buildProgressDetail(
          'Pages Generated',
          '${progress.currentPage} / ${progress.totalPages}',
          Icons.pages,
        ),

        _buildProgressDetail(
          'Items Processed',
          '${progress.currentItem} / ${progress.totalItems}',
          Icons.article,
        ),

        // Estimated time remaining
        if (percentage > 0 && percentage < 100)
          _buildProgressDetail(
            'Estimated Time',
            _estimateTimeRemaining(percentage),
            Icons.timer,
          ),
      ],
    );
  }

  // Progress detail row
  Widget _buildProgressDetail(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  // Result content
  Widget _buildResultContent() {
    final result = _result!;

    if (result.success) {
      return Column(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'PDF exported successfully!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Result details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              children: [
                _buildResultDetail('File Size',
                    '${(result.bytes! / (1024 * 1024)).toStringAsFixed(2)} MB'),
                _buildResultDetail('Pages', result.pages.toString()),
                _buildResultDetail(
                    'Duration', _formatDuration(result.duration)),
                if (result.checksum != null)
                  _buildResultDetail(
                      'Checksum', '${result.checksum!.substring(0, 8)}...'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'File saved to: ${result.filePath}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Icon(
            Icons.error,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Export failed',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Column(
              children: [
                if (result.errorCode != null)
                  _buildResultDetail('Error Code', result.errorCode!),
                if (result.errorMessage != null)
                  _buildResultDetail('Error Message', result.errorMessage!),
                _buildResultDetail(
                    'Duration', _formatDuration(result.duration)),
              ],
            ),
          ),
        ],
      );
    }
  }

  // Result detail row
  Widget _buildResultDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  // Error content
  Widget _buildErrorContent() {
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 64,
        ),
        const SizedBox(height: 16),
        Text(
          'An error occurred',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          _errorMessage!,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.red[600],
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Loading content
  Widget _buildLoadingContent() {
    return Column(
      children: [
        LinearProgressIndicator(
          value: 0.5,
        ),
        const SizedBox(height: 16),
        Text(
          'Preparing export...',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  // Action buttons
  Widget _buildActionButtons() {
    if (_isExporting) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: _cancelExport,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Cancel Export'),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (widget.onComplete != null && _result != null) {
                widget.onComplete!(_result!);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Close'),
          ),
        ],
      );
    }
  }

  // Export methods
  void _startExport() async {
    try {
      final result = await PdfExportService.instance.exportToPdf(
        uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
        setId: widget.options.setId,
        appVersion: '1.0.0+25',
        itemCounts: {'flashcards': 10, 'quizzes': 5},
        options: widget.options,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _progress = progress;
            });
          }
        },
        onCancelled: () {
          if (mounted) {
            setState(() {
              _isExporting = false;
              _errorMessage = 'Export cancelled';
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _result = result;
          _isExporting = false;
          _progress = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isExporting = false;
        });
      }
    }
  }

  void _cancelExport() {
    PdfExportService.instance.cancelExport();
    setState(() {
      _isExporting = false;
      _errorMessage = 'Export cancelled by user';
    });
  }

  void _showCancelConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Export?'),
        content: const Text(
          'Are you sure you want to cancel this export? '
          'Any progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Export'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelExport();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Export'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _estimateTimeRemaining(double percentage) {
    if (percentage <= 0) return 'Calculating...';

    // Simple estimation based on progress
    final elapsed = DateTime.now().difference(_progress!.startedAt);
    final estimatedTotal = elapsed.inMilliseconds / (percentage / 100);
    final remaining = estimatedTotal - elapsed.inMilliseconds;

    if (remaining < 600000) {
      return '${(remaining / 1000).round()} seconds';
    } else {
      return '${(remaining / 600000).round()} minutes';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}
