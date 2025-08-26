import 'package:flutter/material.dart';
import 'package:mindload/models/pdf_export_models.dart';
import 'package:mindload/config/storage_config.dart';
import 'package:mindload/services/mindload_economy_service.dart';
import 'package:mindload/models/mindload_economy_models.dart';
import 'package:provider/provider.dart';

class PdfExportOptionsDialog extends StatefulWidget {
  final String setId;
  final String setTitle;
  final int totalItems;
  final Function(PdfExportOptions) onExport;
  
  const PdfExportOptionsDialog({
    super.key,
    required this.setId,
    required this.setTitle,
    required this.totalItems,
    required this.onExport,
  });

  @override
  State<PdfExportOptionsDialog> createState() => _PdfExportOptionsDialogState();
}

class _PdfExportOptionsDialogState extends State<PdfExportOptionsDialog> {
  bool _includeFlashcards = true;
  bool _includeQuiz = true;
  String _selectedStyle = 'standard';
  String _selectedPageSize = 'Letter';
  bool _includeMindloadBranding = true; // Branding control
  
  // Style options
  final List<Map<String, String>> _styleOptions = [
    {'value': 'compact', 'label': 'Compact', 'description': 'Dense layout, more content per page'},
    {'value': 'standard', 'label': 'Standard', 'description': 'Balanced spacing and readability'},
    {'value': 'spaced', 'label': 'Spaced', 'description': 'Generous spacing for easy reading'},
  ];
  
  // Page size options
  final List<Map<String, String>> _pageSizeOptions = [
    {'value': 'Letter', 'label': 'Letter (8.5" × 11")', 'description': 'US Standard'},
    {'value': 'A4', 'label': 'A4 (210 × 297 mm)', 'description': 'International Standard'},
  ];
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 400,
          maxWidth: 600,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            
            const SizedBox(height: 24),
            
            // Content options
            _buildContentOptions(),
            
            const SizedBox(height: 24),
            
            // Style options
            _buildStyleOptions(),
            
            const SizedBox(height: 24),
            
            // Page size options
            _buildPageSizeOptions(),
            
            const SizedBox(height: 24),
            
            // Branding options (for paid users)
            _buildBrandingOptions(),
            
            const SizedBox(height: 24),
            
            // Export preview
            _buildExportPreview(),
            
            const SizedBox(height: 24),
            
            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }
  
  // Header section
  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.picture_as_pdf,
          color: Colors.blue[600],
          size: 32,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Export to PDF',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.setTitle,
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
  
  // Content options section
  Widget _buildContentOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Content to Include',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildContentOption(
                'Flashcards',
                'Include all flashcards in the set',
                Icons.flip_to_back,
                _includeFlashcards,
                (value) => setState(() => _includeFlashcards = value),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildContentOption(
                'Quiz Questions',
                'Include all quiz questions and answers',
                Icons.quiz,
                _includeQuiz,
                (value) => setState(() => _includeQuiz = value),
              ),
            ),
          ],
        ),
        
        if (!_includeFlashcards && !_includeQuiz)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please select at least one content type to export.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  // Content option checkbox
  Widget _buildContentOption(
    String title,
    String description,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: value ? Colors.blue[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? Colors.blue[200]! : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: value ? Colors.blue[600] : Colors.grey[600], size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: value ? Colors.blue[800] : Colors.grey[800],
                  ),
                ),
              ),
              Checkbox(
                value: value,
                onChanged: (newValue) => onChanged(newValue ?? false),
                activeColor: Colors.blue[600],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: value ? Colors.blue[600] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  // Style options section
  Widget _buildStyleOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Layout Style',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        ...(_styleOptions.map((style) => _buildStyleOption(style))),
      ],
    );
  }
  
  // Style option radio button
  Widget _buildStyleOption(Map<String, String> style) {
    final isSelected = _selectedStyle == style['value'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: RadioListTile<String>(
        value: style['value']!,
        groupValue: _selectedStyle,
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedStyle = value);
          }
        },
        title: Text(
          style['label']!,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.blue[800] : Colors.grey[800],
          ),
        ),
        subtitle: Text(
          style['description']!,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isSelected ? Colors.blue[600] : Colors.grey[600],
          ),
        ),
        activeColor: Colors.blue[600],
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  // Page size options section
  Widget _buildPageSizeOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Page Size',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        ...(_pageSizeOptions.map((size) => _buildPageSizeOption(size))),
      ],
    );
  }
  
  // Page size option radio button
  Widget _buildPageSizeOption(Map<String, String> size) {
    final isSelected = _selectedPageSize == size['value'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: RadioListTile<String>(
        value: size['value']!,
        groupValue: _selectedPageSize,
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedPageSize = value);
          }
        },
        title: Text(
          size['label']!,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.blue[800] : Colors.grey[800],
          ),
        ),
        subtitle: Text(
          size['description']!,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isSelected ? Colors.blue[600] : Colors.grey[600],
          ),
        ),
        activeColor: Colors.blue[600],
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  // Branding options section (for paid users)
  Widget _buildBrandingOptions() {
    return Consumer<MindloadEconomyService>(
      builder: (context, economyService, child) {
        final economy = economyService.userEconomy;
        final isPaidUser = economy != null && economy.tier != MindloadTier.free;
        
        if (!isPaidUser) {
          // Free users always get branding
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MindLoad Branding',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Free users always include MindLoad branding on exports.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        
        // Paid users can control branding
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MindLoad Branding',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'As a paid user, you can choose whether to include MindLoad branding on your exports.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            
            // Branding control options
            Row(
              children: [
                Radio<bool>(
                  value: true,
                  groupValue: _includeMindloadBranding,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _includeMindloadBranding = value);
                    }
                  },
                  activeColor: Colors.blue[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Include MindLoad Branding',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Adds MindLoad logo, tagline, and footer to your PDFs',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Radio<bool>(
                  value: false,
                  groupValue: _includeMindloadBranding,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _includeMindloadBranding = value);
                    }
                  },
                  activeColor: Colors.blue[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Remove MindLoad Branding',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Clean, unbranded PDFs for professional use',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
  
  // Export preview section
  Widget _buildExportPreview() {
    final estimatedPages = _estimatePages();
    final estimatedSize = _estimateFileSize(estimatedPages);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Export Preview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildPreviewItem(
                  'Estimated Pages',
                  estimatedPages.toString(),
                  Icons.pages,
                  estimatedPages > StorageConfig.maxExportPages ? Colors.orange : Colors.green,
                ),
              ),
              Expanded(
                child: _buildPreviewItem(
                  'Estimated Size',
                  '${estimatedSize.toStringAsFixed(1)} MB',
                  Icons.storage,
                  estimatedSize > StorageConfig.maxExportSizeMB ? Colors.orange : Colors.green,
                ),
              ),
            ],
          ),
          
          if (estimatedPages > StorageConfig.maxExportPages || estimatedSize > StorageConfig.maxExportSizeMB)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This export may exceed limits and will be truncated if necessary.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  // Preview item widget
  Widget _buildPreviewItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
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
  
  // Action buttons
  Widget _buildActionButtons() {
    final canExport = _includeFlashcards || _includeQuiz;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: canExport ? _startExport : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Export to PDF'),
        ),
      ],
    );
  }
  
  // Export method
  void _startExport() {
    final options = PdfExportOptions(
      setId: widget.setId,
      includeFlashcards: _includeFlashcards,
      includeQuiz: _includeQuiz,
      style: _selectedStyle,
      pageSize: _selectedPageSize,
      includeMindloadBranding: _includeMindloadBranding,
    );
    
    Navigator.of(context).pop();
    widget.onExport(options);
  }
  
  // Helper methods for estimates
  int _estimatePages() {
    int totalItems = 0;
    if (_includeFlashcards) totalItems += widget.totalItems;
    if (_includeQuiz) totalItems += widget.totalItems;
    
    // Rough estimate: 10-15 items per page depending on style
    double itemsPerPage;
    switch (_selectedStyle) {
      case 'compact':
        itemsPerPage = 15;
        break;
      case 'standard':
        itemsPerPage = 12;
        break;
      case 'spaced':
        itemsPerPage = 10;
        break;
      default:
        itemsPerPage = 12;
    }
    
    return (totalItems / itemsPerPage).ceil();
  }
  
  double _estimateFileSize(int pages) {
    // Rough estimate: 0.1-0.15 MB per page depending on style
    double mbPerPage;
    switch (_selectedStyle) {
      case 'compact':
        mbPerPage = 0.1;
        break;
      case 'standard':
        mbPerPage = 0.12;
        break;
      case 'spaced':
        mbPerPage = 0.15;
        break;
      default:
        mbPerPage = 0.12;
    }
    
    return pages * mbPerPage;
  }
}
