import 'package:flutter/material.dart';
import 'package:mindload/models/pdf_export_models.dart';

import 'package:mindload/widgets/pdf_export_options_dialog.dart';
import 'package:mindload/widgets/pdf_export_progress_dialog.dart';
import 'package:flutter/foundation.dart';

class MindloadPdfExportButton extends StatelessWidget {
  final String setId;
  final String setTitle;
  final int flashcardCount;
  final int quizCount;
  final String uid;
  final String appVersion;
  final VoidCallback? onExportComplete;
  final VoidCallback? onExportError;
  
  const MindloadPdfExportButton({
    super.key,
    required this.setId,
    required this.setTitle,
    required this.flashcardCount,
    required this.quizCount,
    required this.uid,
    required this.appVersion,
    this.onExportComplete,
    this.onExportError,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _showExportOptions(context),
      icon: const Icon(Icons.picture_as_pdf),
      label: const Text('Export to PDF'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => PdfExportOptionsDialog(
        setId: setId,
        setTitle: setTitle,
        totalItems: flashcardCount + quizCount,
        onExport: (options) => _startExport(context, options),
      ),
    );
  }

  void _startExport(BuildContext context, PdfExportOptions options) {
    Navigator.pop(context); // Close options dialog
    
    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PdfExportProgressDialog(
        setId: setId,
        options: options,
        onComplete: (result) {
          if (result.success) {
            _showSuccessMessage(context, result);
            onExportComplete?.call();
          } else {
            _showErrorMessage(context, result);
            onExportError?.call();
          }
        },
      ),
    );
  }

  void _showSuccessMessage(BuildContext context, PdfExportResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PDF exported successfully!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${result.pages} pages • ${(result.bytes! / (1024 * 1024)).toStringAsFixed(2)} MB',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // Open PDF viewer or file manager
            if (kDebugMode) {
              debugPrint('Open PDF: ${result.filePath}');
            }
          },
        ),
      ),
    );
  }

  void _showErrorMessage(BuildContext context, PdfExportResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Export failed: ${result.errorMessage ?? 'Unknown error'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

// Compact version for use in smaller spaces
class CompactMindloadPdfExportButton extends StatelessWidget {
  final String setId;
  final String setTitle;
  final int flashcardCount;
  final int quizCount;
  final String uid;
  final String appVersion;
  final VoidCallback? onExportComplete;
  final VoidCallback? onExportError;
  
  const CompactMindloadPdfExportButton({
    super.key,
    required this.setId,
    required this.setTitle,
    required this.flashcardCount,
    required this.quizCount,
    required this.uid,
    required this.appVersion,
    this.onExportComplete,
    this.onExportError,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _showExportOptions(context),
      icon: const Icon(Icons.picture_as_pdf),
      tooltip: 'Export to PDF',
      style: IconButton.styleFrom(
        backgroundColor: Colors.blue[50],
        foregroundColor: Colors.blue[600],
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => PdfExportOptionsDialog(
        setId: setId,
        setTitle: setTitle,
        totalItems: flashcardCount + quizCount,
        onExport: (options) => _startExport(context, options),
      ),
    );
  }

  void _startExport(BuildContext context, PdfExportOptions options) {
    Navigator.pop(context); // Close options dialog
    
    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PdfExportProgressDialog(
        setId: setId,
        options: options,
        onComplete: (result) {
          if (result.success) {
            _showSuccessMessage(context, result);
            onExportComplete?.call();
          } else {
            _showErrorMessage(context, result);
            onExportError?.call();
          }
        },
      ),
    );
  }

  void _showSuccessMessage(BuildContext context, PdfExportResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF exported: ${result.pages} pages'),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(BuildContext context, PdfExportResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export failed: ${result.errorMessage ?? 'Unknown error'}'),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// Export menu item for use in popup menus
class MindloadPdfExportMenuItem extends StatelessWidget {
  final String setId;
  final String setTitle;
  final int flashcardCount;
  final int quizCount;
  final String uid;
  final String appVersion;
  final VoidCallback? onExportComplete;
  final VoidCallback? onExportError;
  
  const MindloadPdfExportMenuItem({
    super.key,
    required this.setId,
    required this.setTitle,
    required this.flashcardCount,
    required this.quizCount,
    required this.uid,
    required this.appVersion,
    this.onExportComplete,
    this.onExportError,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuItem<String>(
      value: 'export_pdf',
      child: Row(
        children: [
          Icon(Icons.picture_as_pdf, color: Colors.blue[600]),
          const SizedBox(width: 12),
          const Text('Export to PDF'),
        ],
      ),
      onTap: () => _showExportOptions(context),
    );
  }

  void _showExportOptions(BuildContext context) {
    // Small delay to allow popup menu to close
    Future.delayed(const Duration(milliseconds: 100), () {
      showDialog(
        context: context,
        builder: (context) => PdfExportOptionsDialog(
          setId: setId,
          setTitle: setTitle,
          totalItems: flashcardCount + quizCount,
          onExport: (options) => _startExport(context, options),
        ),
      );
    });
  }

  void _startExport(BuildContext context, PdfExportOptions options) {
    Navigator.pop(context); // Close options dialog
    
    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PdfExportProgressDialog(
        setId: setId,
        options: options,
        onComplete: (result) {
          if (result.success) {
            _showSuccessMessage(context, result);
            onExportComplete?.call();
          } else {
            _showErrorMessage(context, result);
            onExportError?.call();
          }
        },
      ),
    );
  }

  void _showSuccessMessage(BuildContext context, PdfExportResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF exported: ${result.pages} pages'),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(BuildContext context, PdfExportResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export failed: ${result.errorMessage ?? 'Unknown error'}'),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
