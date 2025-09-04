import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../services/url_study_set_service.dart';

/// Dialog for entering a URL to generate a study set
class UrlStudySetDialog extends StatefulWidget {
  final Function(String studySetId, String title) onStudySetGenerated;

  const UrlStudySetDialog({
    super.key,
    required this.onStudySetGenerated,
  });

  @override
  State<UrlStudySetDialog> createState() => _UrlStudySetDialogState();
}

class _UrlStudySetDialogState extends State<UrlStudySetDialog>
    with TickerProviderStateMixin {
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isPreviewing = false;
  Map<String, dynamic>? _previewData;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _urlController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Dialog(
          backgroundColor: tokens.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.link,
                        color: tokens.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Generate from URL',
                          style: textTheme.headlineSmall?.copyWith(
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: tokens.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  Text(
                    'Paste a URL to automatically generate study materials from the content.',
                    style: textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  
                  // URL Input
                  TextFormField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: 'URL',
                      hintText: 'https://example.com/article',
                      prefixIcon: Icon(Icons.link, color: tokens.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabled: !_isLoading,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a URL';
                      }
                      try {
                        final uri = Uri.parse(value);
                        if (!uri.hasScheme || !uri.hasAuthority) {
                          return 'Please enter a valid URL';
                        }
                      } catch (e) {
                        return 'Please enter a valid URL';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      if (_previewData != null) {
                        setState(() {
                          _previewData = null;
                          _errorMessage = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Title Input (optional)
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Custom Title (optional)',
                      hintText: 'Leave empty to use article title',
                      prefixIcon: Icon(Icons.title, color: tokens.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabled: !_isLoading,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Preview Section
                  if (_previewData != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: tokens.surfaceAlt.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: tokens.outline),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.preview, color: tokens.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Preview',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Domain: ${_previewData!['domain']}',
                            style: textTheme.bodyMedium,
                          ),
                          Text(
                            'Estimated items: ${_previewData!['estimatedItems']}',
                            style: textTheme.bodyMedium,
                          ),
                          Text(
                            'Processing time: ${_previewData!['estimatedProcessingTime']}',
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Error Message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: tokens.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: tokens.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: textTheme.bodyMedium?.copyWith(color: tokens.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Action Buttons
                  Row(
                    children: [
                      if (_previewData == null) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _previewUrl,
                            icon: _isPreviewing
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: tokens.primary,
                                    ),
                                  )
                                : Icon(Icons.preview, color: tokens.primary),
                            label: Text(
                              _isPreviewing ? 'Previewing...' : 'Preview',
                              style: textTheme.labelLarge?.copyWith(color: tokens.primary),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _generateStudySet,
                          icon: _isLoading
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: tokens.onPrimary,
                                  ),
                                )
                              : Icon(Icons.auto_awesome, color: tokens.onPrimary),
                          label: Text(
                            _isLoading ? 'Generating...' : 'Generate Study Set',
                            style: textTheme.labelLarge?.copyWith(color: tokens.onPrimary),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tokens.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _previewUrl() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isPreviewing = true;
      _errorMessage = null;
    });
    
    try {
      final previewData = await UrlStudySetService.instance.previewUrlContent(
        _urlController.text.trim(),
      );
      
      setState(() {
        _previewData = previewData;
        _isPreviewing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isPreviewing = false;
      });
    }
  }

  Future<void> _generateStudySet() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final result = await UrlStudySetService.instance.generateStudySetFromUrl(
        url: _urlController.text.trim(),
        title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
      );
      
      if (mounted) {
        Navigator.of(context).pop();
        widget.onStudySetGenerated(
          result['studySetId'],
          result['title'],
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
}
