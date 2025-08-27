import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/widgets/mindload_app_bar.dart';
import 'package:mindload/widgets/credits_state_banners.dart';
import 'package:mindload/widgets/pre_flight_cost_preview.dart';
import 'package:mindload/widgets/credits_feedback_snackbar.dart';
import 'package:mindload/widgets/credits_token_chip.dart';
import 'package:mindload/widgets/deadline_date_picker.dart';
import 'package:mindload/widgets/token_estimation_display.dart';
import 'package:mindload/widgets/enhanced_upload_panel.dart';
import 'package:mindload/services/mindload_economy_service.dart';
import 'package:mindload/services/token_estimation_service.dart';
import 'package:mindload/services/deadline_service.dart';
import 'package:mindload/models/mindload_economy_models.dart';
import 'package:mindload/models/study_data.dart';
import 'package:mindload/services/document_processor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mindload/core/youtube_utils.dart';
import 'package:mindload/services/youtube_service.dart';
import 'package:mindload/models/youtube_preview_models.dart';
import 'package:mindload/widgets/youtube_preview_card.dart';
import 'package:flutter/foundation.dart';

import 'package:mindload/services/enhanced_storage_service.dart';
import 'package:mindload/services/openai_service.dart';
import 'package:mindload/services/auth_service.dart';

/// Create Screen - Demonstrates the complete credits economy integration
///
/// Features:
/// - TokenChip in app bar (always visible)
/// - Credits state banners for low/empty credits
/// - Pre-flight cost preview before generation
/// - Post-action feedback with snackbars
/// - Integrated upgrade and buy credits flows
/// - Custom instruction field for AI generation
/// - Generation type selection (quiz/flashcard/both)
/// - Custom count inputs for questions and cards
/// - YouTube link processing with preview
/// - Document upload (PDF, DOCX, TXT, etc.)
/// - Comprehensive content input options
class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _instructionController = TextEditingController();
  final TextEditingController _youtubeController = TextEditingController();

  bool _isGenerating = false;
  DateTime? _selectedDeadline;
  bool _isDeadlineEnabled = false;

  // Generation type and count controls
  bool _generateFlashcards = true;
  bool _generateQuizzes = true;
  int _flashcardCount = 10;
  int _quizCount = 5;

  // Content input type
  String _contentInputType = 'text'; // 'text', 'youtube', 'document'

  // YouTube integration state
  YouTubePreview? _currentYouTubePreview;
  bool _isLoadingYouTubePreview = false;
  String? _errorMessage;

  // Document upload state
  PlatformFile? _uploadedDocument;
  bool _isProcessingDocument = false;
  String? _extractedDocumentText;

  // Title auto-population state
  bool _isTitleAutoPopulated = false;

  @override
  void initState() {
    super.initState();

    // Listen for manual title changes to reset auto-populated flag
    _titleController.addListener(() {
      if (_isTitleAutoPopulated && _titleController.text.trim().isNotEmpty) {
        // User has manually modified the title, so it's no longer auto-populated
        _isTitleAutoPopulated = false;
        if (kDebugMode) {
          print('📝 User manually modified title, auto-population disabled');
        }
      }
    });

    // Listen for content changes to suggest titles from text
    _contentController.addListener(() {
      if (_contentInputType == 'text' &&
          _contentController.text.trim().isNotEmpty) {
        _suggestTitleFromText(_contentController.text.trim());
      }
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    _titleController.dispose();
    _instructionController.dispose();
    _youtubeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Scaffold(
      appBar: MindloadAppBarFactory.standard(
        title: 'Create Study Set',
        onBuyCredits: _handleBuyCredits,
        onViewLedger: _handleViewLedger,
        onUpgrade: _handleUpgrade,
      ),
      body: Column(
        children: [
          // Credits state banners (low/empty credits)
          const CreditsStateBanners(),

          // Main content - takes up remaining screen space
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 0,
                  minWidth: double.infinity,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title input section
                    _buildTitleInput(context, tokens),

                    const SizedBox(height: 24),

                    // Content input type selector
                    _buildContentInputTypeSelector(context, tokens),

                    const SizedBox(height: 24),

                    // Content input section (dynamic based on type)
                    _buildDynamicContentInput(context, tokens),

                    const SizedBox(height: 24),

                    // Custom instruction section
                    _buildCustomInstructionSection(context, tokens),

                    const SizedBox(height: 24),

                    // Generation options section
                    _buildGenerationOptionsSection(context, tokens),

                    const SizedBox(height: 24),

                    // Deadline picker section
                    DeadlineDatePicker(
                      initialDate: _selectedDeadline,
                      initialToggleState: _isDeadlineEnabled,
                      onDateChanged: (date) {
                        setState(() {
                          _selectedDeadline = date;
                        });
                      },
                      onToggleChanged: (enabled) {
                        setState(() {
                          _isDeadlineEnabled = enabled;
                          if (!enabled) {
                            _selectedDeadline = null;
                          }
                        });
                      },
                      label: 'Study Deadline',
                    ),

                    const SizedBox(height: 24),

                    // Pre-flight cost preview (if content exists)
                    if (_hasContent()) _buildPreFlightSection(context, tokens),

                    const SizedBox(height: 24),

                    // Generation controls
                    _buildGenerationControls(context, tokens),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Check if there's any content to process
  bool _hasContent() {
    return _contentController.text.isNotEmpty ||
        _uploadedDocument != null ||
        _currentYouTubePreview != null;
  }

  /// Build content input type selector
  Widget _buildContentInputTypeSelector(
      BuildContext context, SemanticTokens tokens) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tokens.borderDefault,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.input,
                  size: 20,
                  color: tokens.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Content Input Method',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),

          // Input type options
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildInputTypeOption(
                    context,
                    tokens,
                    'text',
                    Icons.edit_note,
                    'Text',
                    'Paste or type your content',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInputTypeOption(
                    context,
                    tokens,
                    'youtube',
                    Icons.play_circle_outline,
                    'YouTube',
                    'Process video content',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInputTypeOption(
                    context,
                    tokens,
                    'document',
                    Icons.upload_file,
                    'Document',
                    'Upload PDF, DOCX, etc.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual input type option
  Widget _buildInputTypeOption(
    BuildContext context,
    SemanticTokens tokens,
    String type,
    IconData icon,
    String label,
    String description,
  ) {
    final isSelected = _contentInputType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _contentInputType = type;
          // Clear other content when switching types
          if (type != 'text') _contentController.clear();
          if (type != 'youtube') {
            _youtubeController.clear();
            _currentYouTubePreview = null;
          }
          if (type != 'document') {
            _uploadedDocument = null;
            _extractedDocumentText = null;
          }

          // Clear title when switching content types to allow fresh suggestions
          _titleController.clear();

          // Reset title auto-population flag when switching content types
          // This allows new suggestions when switching between different content sources
          _isTitleAutoPopulated = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? tokens.primary.withValues(alpha: 0.1)
              : tokens.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? tokens.primary : tokens.borderDefault,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? tokens.primary : tokens.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isSelected ? tokens.primary : tokens.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected ? tokens.primary : tokens.textSecondary,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Build dynamic content input based on selected type
  Widget _buildDynamicContentInput(
      BuildContext context, SemanticTokens tokens) {
    switch (_contentInputType) {
      case 'text':
        return _buildTextInput(context, tokens);
      case 'youtube':
        return _buildYouTubeInput(context, tokens);
      case 'document':
        return _buildDocumentUpload(context, tokens);
      default:
        return _buildTextInput(context, tokens);
    }
  }

  /// Build text input section
  Widget _buildTextInput(BuildContext context, SemanticTokens tokens) {
    return Consumer<MindloadEconomyService>(
      builder: (context, economy, child) {
        return EnhancedUploadPanel(
          onTextSubmit: (text, depth) {
            _contentController.text = text;
            setState(() {});
          },
          onYouTubeSubmit: (videoId, depth) {
            // Handle YouTube submission
            _handleYouTubeSubmission(videoId, depth);
          },
          availableTokens: economy.userEconomy?.creditsRemaining ?? 0,
          onInsufficientTokens: () {
            // Handle insufficient tokens
            _handleInsufficientTokens();
          },
        );
      },
    );
  }

  /// Build YouTube input section
  Widget _buildYouTubeInput(BuildContext context, SemanticTokens tokens) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tokens.borderDefault,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.play_circle_outline,
                  size: 20,
                  color: tokens.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'YouTube Video Processing',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),

          // Description
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Paste a YouTube URL to extract video content and generate study materials',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tokens.textSecondary,
                    height: 1.4,
                  ),
            ),
          ),

          // YouTube URL input
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _youtubeController,
              onChanged: _onYouTubeUrlChanged,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: tokens.textPrimary,
                  ),
              decoration: InputDecoration(
                hintText: 'https://www.youtube.com/watch?v=...',
                hintStyle: TextStyle(
                  color: tokens.textTertiary,
                ),
                prefixIcon: Icon(
                  Icons.link,
                  color: tokens.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: tokens.borderDefault,
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: tokens.borderDefault,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: tokens.borderFocus,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),

          // YouTube preview
          if (_isLoadingYouTubePreview) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: tokens.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tokens.borderDefault),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(tokens.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Loading video preview...',
                    style: TextStyle(
                      color: tokens.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_currentYouTubePreview != null) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: YouTubePreviewCard(
                preview: _currentYouTubePreview!,
                onIngest: () => _handleYouTubeIngest(),
                isLoading: false,
                errorMessage: null,
              ),
            ),
          ],

          // Error message
          if (_errorMessage != null) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tokens.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tokens.error.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.error_outline, color: tokens.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: tokens.error),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _retryYouTubePreview(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tokens.primary,
                            foregroundColor: tokens.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Retry'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build document upload section
  Widget _buildDocumentUpload(BuildContext context, SemanticTokens tokens) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tokens.borderDefault,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.upload_file,
                  size: 20,
                  color: tokens.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Document Upload',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),

          // Description
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Upload PDF, DOCX, TXT, or other supported documents to extract content',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tokens.textSecondary,
                    height: 1.4,
                  ),
            ),
          ),

          // Upload area
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _uploadedDocument != null
                ? _buildUploadedDocumentPreview(context, tokens)
                : _buildUploadArea(context, tokens),
          ),

          // Processing status
          if (_isProcessingDocument) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tokens.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tokens.borderDefault),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(tokens.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Processing document...',
                    style: TextStyle(
                      color: tokens.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Extracted text preview
          if (_extractedDocumentText != null) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tokens.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tokens.borderDefault),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: tokens.success,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Document Processed Successfully',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: tokens.success,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Extracted ${_extractedDocumentText!.length} characters',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tokens.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: tokens.borderDefault.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _extractedDocumentText!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: tokens.textPrimary,
                          ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build upload area
  Widget _buildUploadArea(BuildContext context, SemanticTokens tokens) {
    return GestureDetector(
      onTap: _pickDocument,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: tokens.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: tokens.borderDefault,
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 32,
              color: tokens.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to upload document',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: tokens.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'PDF, DOCX, TXT, RTF, EPUB supported',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tokens.textTertiary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build uploaded document preview
  Widget _buildUploadedDocumentPreview(
      BuildContext context, SemanticTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getFileIcon(_uploadedDocument!.extension ?? ''),
                color: tokens.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _uploadedDocument!.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${(_uploadedDocument!.size / 1024).toStringAsFixed(1)} KB',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: tokens.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _uploadedDocument = null;
                    _extractedDocumentText = null;
                  });
                },
                icon: Icon(
                  Icons.close,
                  color: tokens.textSecondary,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessingDocument ? null : _processDocument,
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.primary,
                foregroundColor: tokens.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _isProcessingDocument ? 'Processing...' : 'Process Document',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get appropriate icon for file type
  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'docx':
      case 'doc':
        return Icons.description;
      case 'txt':
        return Icons.text_snippet;
      case 'rtf':
        return Icons.text_fields;
      case 'epub':
        return Icons.book;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// Pick document from file system
  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: DocumentProcessor.getSupportedExtensions(),
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _uploadedDocument = result.files.first;
          _extractedDocumentText = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick document: $e';
      });
    }
  }

  /// Process uploaded document
  Future<void> _processDocument() async {
    if (_uploadedDocument == null) return;

    setState(() {
      _isProcessingDocument = true;
      _errorMessage = null;
    });

    try {
      final fileBytes = _uploadedDocument!.bytes!;
      final extension = _uploadedDocument!.extension ?? '';
      final fileName = _uploadedDocument!.name;

      // Extract text from document
      final extractedText = await DocumentProcessor.extractTextFromFile(
        fileBytes,
        extension,
        fileName,
      );

      setState(() {
        _extractedDocumentText = extractedText;
        _isProcessingDocument = false;
      });

      // Update content controller for generation
      _contentController.text = extractedText;

      // Auto-populate title from document name if title is empty or not customized
      _suggestTitleFromDocument(_uploadedDocument!.name);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to process document: $e';
        _isProcessingDocument = false;
      });
    }
  }

  /// Handle YouTube URL changes
  void _onYouTubeUrlChanged(String url) {
    if (url.trim().isEmpty) {
      setState(() {
        _currentYouTubePreview = null;
        _errorMessage = null;
      });
      return;
    }

    final videoId = YouTubeUtils.extractYouTubeId(url);
    if (videoId != null) {
      _fetchYouTubePreview(videoId);
    } else {
      setState(() {
        _errorMessage = 'Invalid YouTube URL';
        _currentYouTubePreview = null;
      });
    }
  }

  /// Fetch YouTube preview
  Future<void> _fetchYouTubePreview(String videoId) async {
    setState(() {
      _isLoadingYouTubePreview = true;
      _errorMessage = null;
    });

    try {
      // Add debug logging
      if (kDebugMode) {
        print('🎬 Fetching YouTube preview for video: $videoId');
        print('🔍 Video ID length: ${videoId.length}');
        print(
            '🔍 Video ID pattern: ${RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(videoId)}');
      }

      final preview = await YouTubeService().getPreview(videoId);

      if (mounted) {
        setState(() {
          _currentYouTubePreview = preview;
          _isLoadingYouTubePreview = false;
        });

        // Auto-populate title if it's empty or user hasn't customized it
        _suggestTitleFromYouTube(preview);

        if (kDebugMode) {
          print('✅ YouTube preview loaded successfully: ${preview.title}');
        }
      }
    } catch (e) {
      if (mounted) {
        // Enhanced error handling with specific error types
        String errorMessage;
        String debugInfo = '';

        if (e.toString().contains('unauthenticated')) {
          errorMessage = 'Authentication required. Please sign in again.';
          debugInfo = 'User not authenticated';
        } else if (e.toString().contains('permission-denied')) {
          errorMessage =
              'Access denied. Please check your account permissions.';
          debugInfo = 'Permission denied';
        } else if (e.toString().contains('resource-exhausted')) {
          errorMessage = 'Rate limit exceeded. Please try again later.';
          debugInfo = 'Rate limit exceeded';
        } else if (e.toString().contains('unavailable')) {
          errorMessage =
              'YouTube service temporarily unavailable. Using fallback preview.';
          debugInfo = 'Service unavailable';
        } else if (e.toString().contains('YouTubeIngestError.unknown')) {
          errorMessage =
              'YouTube service temporarily unavailable. Using fallback preview.';
          debugInfo = 'YouTube service error - using fallback';
        } else if (e.toString().contains('YouTubeIngestError.serverError')) {
          errorMessage =
              'YouTube service temporarily unavailable. Using fallback preview.';
          debugInfo = 'YouTube server error - using fallback';
        } else if (e.toString().contains('YouTubeIngestError.networkError')) {
          errorMessage =
              'Network error. Please check your internet connection.';
          debugInfo = 'Network error';
        } else if (e.toString().contains('transcript')) {
          errorMessage =
              'Video transcript not available. Please try a different video.';
          debugInfo = 'No transcript available';
        } else if (e.toString().contains('private')) {
          errorMessage = 'This video is private and cannot be processed.';
          debugInfo = 'Private video';
        } else if (e.toString().contains('age-restricted')) {
          errorMessage = 'Age-restricted videos cannot be processed.';
          debugInfo = 'Age-restricted video';
        } else {
          errorMessage = 'Failed to load video preview: ${e.toString()}';
          debugInfo = 'Unknown error: ${e.toString()}';
        }

        setState(() {
          _errorMessage = errorMessage;
          _isLoadingYouTubePreview = false;
        });

        if (kDebugMode) {
          print('❌ YouTube preview failed: $e');
          print('🔍 Error type: ${e.runtimeType}');
          print('📝 Error details: ${e.toString()}');
          print('🔍 Debug info: $debugInfo');
          print('🔍 Video ID: $videoId');
        }
      }
    }
  }

  /// Handle YouTube ingest
  void _handleYouTubeIngest() {
    if (_currentYouTubePreview != null) {
      // Extract video information for content
      final content = 'YouTube Video: ${_currentYouTubePreview!.title}\n\n'
          'Channel: ${_currentYouTubePreview!.channel}\n\n'
          'Duration: ${_currentYouTubePreview!.durationSeconds ~/ 60} minutes';

      _contentController.text = content;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('YouTube video content extracted successfully!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Suggest title from YouTube video
  void _suggestTitleFromYouTube(YouTubePreview preview) {
    // Only suggest if title is empty or hasn't been customized by user
    if (_titleController.text.trim().isEmpty || _isTitleAutoPopulated) {
      final suggestedTitle = _generateYouTubeTitle(preview);
      _titleController.text = suggestedTitle;
      _isTitleAutoPopulated = true;

      if (kDebugMode) {
        print('📝 Auto-populated title from YouTube: $suggestedTitle');
      }
    }
  }

  /// Suggest title from document
  void _suggestTitleFromDocument(String fileName) {
    // Only suggest if title is empty or hasn't been customized by user
    if (_titleController.text.trim().isEmpty || _isTitleAutoPopulated) {
      final suggestedTitle = _generateDocumentTitle(fileName);
      _titleController.text = suggestedTitle;
      _isTitleAutoPopulated = true;

      if (kDebugMode) {
        print('📝 Auto-populated title from document: $suggestedTitle');
      }
    }
  }

  /// Generate title from YouTube video
  String _generateYouTubeTitle(YouTubePreview preview) {
    // Clean up the video title and make it suitable for a study set
    String title = preview.title;

    // Remove common YouTube suffixes
    title = title.replaceAll(
        RegExp(r'\s*[-|]\s*YouTube$', caseSensitive: false), '');
    title = title.replaceAll(
        RegExp(r'\s*[-|]\s*Official.*$', caseSensitive: false), '');
    title = title.replaceAll(
        RegExp(r'\s*[-|]\s*Official$', caseSensitive: false), '');

    // Add "Study Set:" prefix to make it clear this is for studying
    return 'Study Set: $title';
  }

  /// Generate title from document
  String _generateDocumentTitle(String fileName) {
    // Remove file extension
    String title = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');

    // Clean up common document naming patterns
    title = title.replaceAll(
        RegExp(r'^[0-9]+[-_]\s*'), ''); // Remove leading numbers
    title = title.replaceAll(RegExp(r'[-_]', multiLine: false),
        ' '); // Replace underscores/dashes with spaces
    title = title.replaceAll(RegExp(r'\s+'), ' '); // Normalize multiple spaces
    title = title.trim();

    // Capitalize first letter of each word
    title = title.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');

    // Add "Study Set:" prefix
    return 'Study Set: $title';
  }

  /// Suggest title from text content
  void _suggestTitleFromText(String text) {
    // Only suggest if title is empty or hasn't been customized by user
    if (_titleController.text.trim().isEmpty || _isTitleAutoPopulated) {
      final suggestedTitle = _generateTextTitle(text);
      _titleController.text = suggestedTitle;
      _isTitleAutoPopulated = true;

      if (kDebugMode) {
        print('📝 Auto-populated title from text: $suggestedTitle');
      }
    }
  }

  /// Generate title from text content
  String _generateTextTitle(String text) {
    // Take first line or first sentence as title
    String title = text.split('\n').first.trim();

    // If first line is too long, take first sentence
    if (title.length > 60) {
      title = text.split(RegExp(r'[.!?]')).first.trim();
      if (title.length > 60) {
        title = title.substring(0, 60).trim();
      }
    }

    // Clean up the title
    title = title.replaceAll(RegExp(r'\s+'), ' '); // Normalize spaces
    title = title.trim();

    // Remove common prefixes that don't make good titles
    title = title.replaceAll(
        RegExp(r'^(Chapter|Section|Part|Unit)\s+\d+[:\s-]*',
            caseSensitive: false),
        '');
    title = title.replaceAll(RegExp(r'^\d+[.\s-]*', caseSensitive: false),
        ''); // Remove leading numbers

    // Capitalize first letter
    if (title.isNotEmpty) {
      title = title[0].toUpperCase() + title.substring(1);
    }

    // Add "Study Set:" prefix
    return 'Study Set: $title';
  }

  Widget _buildTitleInput(BuildContext context, SemanticTokens tokens) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tokens.borderDefault,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.title,
                  size: 20,
                  color: tokens.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Study Set Title',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),

          // Text input
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleController,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: tokens.textPrimary,
                      ),
                  decoration: InputDecoration(
                    hintText: 'Enter a name for your study set...',
                    hintStyle: TextStyle(
                      color: tokens.textTertiary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: tokens.borderDefault,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: tokens.borderDefault,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: tokens.borderFocus,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                // Auto-population indicator and hint
                if (_titleController.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _isTitleAutoPopulated ? Icons.auto_awesome : Icons.edit,
                        size: 16,
                        color: _isTitleAutoPopulated
                            ? tokens.success
                            : tokens.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isTitleAutoPopulated
                            ? 'Title auto-suggested from content - feel free to rename!'
                            : 'You can customize this title anytime',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _isTitleAutoPopulated
                                  ? tokens.success
                                  : tokens.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomInstructionSection(
      BuildContext context, SemanticTokens tokens) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tokens.borderDefault,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 20,
                  color: tokens.accent,
                ),
                const SizedBox(width: 8),
                Text(
                  'Custom Instructions (Optional)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),

          // Description
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Tell AI what specific topics or types of questions you want. For example: "Focus on solar system planets" or "Make questions about chemical reactions"',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tokens.textSecondary,
                    height: 1.4,
                  ),
            ),
          ),

          // Text input
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _instructionController,
              maxLines: 3,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: tokens.textPrimary,
                  ),
              decoration: InputDecoration(
                hintText:
                    'e.g., "Give me a quiz about the solar system" or "Focus on key concepts from chapter 5"',
                hintStyle: TextStyle(
                  color: tokens.textTertiary,
                  height: 1.4,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: tokens.borderDefault,
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: tokens.borderDefault,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: tokens.borderFocus,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerationOptionsSection(
      BuildContext context, SemanticTokens tokens) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tokens.borderDefault,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.tune,
                  size: 20,
                  color: tokens.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Generation Options',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),

          // Generation type toggles
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // Flashcards toggle
                Row(
                  children: [
                    Checkbox(
                      value: _generateFlashcards,
                      onChanged: (value) {
                        setState(() {
                          _generateFlashcards = value ?? false;
                          // Ensure at least one type is selected
                          if (!_generateFlashcards && !_generateQuizzes) {
                            _generateQuizzes = true;
                          }
                        });
                      },
                      activeColor: tokens.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Generate Flashcards',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: tokens.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),

                // Quiz toggle
                Row(
                  children: [
                    Checkbox(
                      value: _generateQuizzes,
                      onChanged: (value) {
                        setState(() {
                          _generateQuizzes = value ?? false;
                          // Ensure at least one type is selected
                          if (!_generateFlashcards && !_generateQuizzes) {
                            _generateFlashcards = true;
                          }
                        });
                      },
                      activeColor: tokens.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Generate Quiz Questions',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: tokens.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Count inputs
          if (_generateFlashcards || _generateQuizzes) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  // Flashcard count
                  if (_generateFlashcards) ...[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Number of Flashcards',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: tokens.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _flashcardCount > 1
                                    ? () => setState(() => _flashcardCount--)
                                    : null,
                                icon: Icon(
                                  Icons.remove_circle_outline,
                                  color: _flashcardCount > 1
                                      ? tokens.primary
                                      : tokens.textTertiary,
                                ),
                                iconSize: 20,
                              ),
                              Expanded(
                                child: Text(
                                  '$_flashcardCount',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: tokens.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                              IconButton(
                                onPressed: _flashcardCount < 50
                                    ? () => setState(() => _flashcardCount++)
                                    : null,
                                icon: Icon(
                                  Icons.add_circle_outline,
                                  color: _flashcardCount < 50
                                      ? tokens.primary
                                      : tokens.textTertiary,
                                ),
                                iconSize: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_generateQuizzes) const SizedBox(width: 16),
                  ],

                  // Quiz count
                  if (_generateQuizzes) ...[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Number of Quiz Questions',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: tokens.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _quizCount > 1
                                    ? () => setState(() => _quizCount--)
                                    : null,
                                icon: Icon(
                                  Icons.remove_circle_outline,
                                  color: _quizCount > 1
                                      ? tokens.primary
                                      : tokens.textTertiary,
                                ),
                                iconSize: 20,
                              ),
                              Expanded(
                                child: Text(
                                  '$_quizCount',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: tokens.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                              IconButton(
                                onPressed: _quizCount < 30
                                    ? () => setState(() => _quizCount++)
                                    : null,
                                icon: Icon(
                                  Icons.add_circle_outline,
                                  color: _quizCount < 30
                                      ? tokens.primary
                                      : tokens.textTertiary,
                                ),
                                iconSize: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Info text
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tokens.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: tokens.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: tokens.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Custom instructions help AI focus on specific topics. Higher counts may use more credits.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: tokens.primary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreFlightSection(BuildContext context, SemanticTokens tokens) {
    return Consumer<MindloadEconomyService>(
      builder: (context, economy, child) {
        // Get token estimation for the current content
        final estimation = TokenEstimationService.instance.estimateTextContent(
          text: _contentController.text,
          depth: 'standard', // Default depth for create screen
          customFlashcardCount: _generateFlashcards ? _flashcardCount : null,
          customQuizCount: _generateQuizzes ? _quizCount : null,
        );

        return Column(
          children: [
            // Token estimation display
            TokenEstimationDisplay(
              estimation: estimation,
              showProceedButton: false,
            ),

            const SizedBox(height: 16),

            // Original pre-flight cost preview
            PreFlightCostPreview(
              sourceCharCount: _contentController.text.length,
              onTrimContent: _handleTrimContent,
              onAutoSplit: _handleAutoSplit,
              onBuyCredits: _handleBuyCredits,
              onUpgrade: _handleUpgrade,
              onGenerate: _isGenerating ? null : _handleGenerate,
            ),
          ],
        );
      },
    );
  }

  Widget _buildGenerationControls(BuildContext context, SemanticTokens tokens) {
    return Consumer<MindloadEconomyService>(
      builder: (context, economy, child) {
        // Use user's custom selections instead of tier defaults
        final userFlashcards = _generateFlashcards ? _flashcardCount : 0;
        final userQuiz = _generateQuizzes ? _quizCount : 0;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: tokens.borderDefault,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Output preview
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 20,
                    color: tokens.accent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'What you\'ll get',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Output counts based on user selection
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: tokens.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: tokens.borderDefault.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (_generateFlashcards)
                      _buildOutputCount(
                        context,
                        Icons.quiz,
                        '$userFlashcards',
                        'Flashcards',
                        tokens,
                      ),
                    if (_generateFlashcards && _generateQuizzes)
                      Container(
                        width: 1,
                        height: 40,
                        color: tokens.divider,
                      ),
                    if (_generateQuizzes)
                      _buildOutputCount(
                        context,
                        Icons.help_outline,
                        '$userQuiz',
                        'Quiz Questions',
                        tokens,
                      ),
                  ],
                ),
              ),

              // Custom instruction preview
              if (_instructionController.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tokens.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: tokens.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb,
                        size: 16,
                        color: tokens.accent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Custom Instructions:',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: tokens.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _instructionController.text,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: tokens.textPrimary,
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Tier-based message
              const SizedBox(height: 12),

              if (economy.budgetState == BudgetState.savingsMode)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tokens.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.eco,
                        size: 16,
                        color: tokens.warning,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Efficient mode active: optimized output to serve everyone better.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: tokens.warning,
                                  ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  'Your ${economy.currentTier.displayName} tier allows custom generation counts. Higher counts may use more credits.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),

              // Generate button
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isGenerating ? null : _handleGenerate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.primary,
                    foregroundColor: tokens.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isGenerating
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    tokens.onPrimary),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Generating...',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Generate Study Set',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
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
    );
  }

  Widget _buildOutputCount(
    BuildContext context,
    IconData icon,
    String count,
    String label,
    SemanticTokens tokens,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: tokens.primary,
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: tokens.textSecondary,
              ),
        ),
      ],
    );
  }

  // Action handlers

  void _handleBuyCredits() {
    // Show buy credits modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BuyCreditsSheet(),
    );
  }

  void _handleViewLedger() {
    // Navigate to credits ledger/history
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Credits ledger - Implementation needed'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleUpgrade() {
    // Navigate to subscription upgrade
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Subscription upgrade - Implementation needed'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleUploadPDF() {
    // Handle PDF upload
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF upload - Implementation needed'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handlePasteFromClipboard() {
    // Handle clipboard paste
    _contentController.text =
        'This is sample pasted content for demonstration. In a real implementation, this would paste from the system clipboard.\n\nThis content is long enough to demonstrate the character counter and potential paste cap issues when content exceeds the tier limits.\n\nFor example, the Neuron (free) tier has a 1,000 character limit, while Synapse has 5,000 and Cortex has 10,000 characters.';
    // Clear instruction field when new content is pasted
    _instructionController.clear();
    setState(() {});
  }

  void _handleClearContent() {
    _contentController.clear();
    _instructionController.clear();
    setState(() {});
  }

  void _handleTrimContent() {
    final economy = context.read<MindloadEconomyService>();
    final limit =
        economy.userEconomy?.getPasteCharLimit(economy.budgetState) ?? 100000;

    if (_contentController.text.length > limit) {
      _contentController.text = _contentController.text.substring(0, limit);
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Content trimmed to ${_formatNumber(limit)} characters'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleAutoSplit() {
    final economy = context.read<MindloadEconomyService>();
    final creditsNeeded =
        economy.calculateAutoSplitCredits(_contentController.text.length);

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Auto-Split Content'),
        content: Text(
          'This will split your content into multiple generations, using $creditsNeeded credits total. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performAutoSplitGeneration(creditsNeeded);
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  void _performAutoSplitGeneration(int creditsNeeded) {
    // Simulate auto-split generation
    setState(() {
      _isGenerating = true;
    });

    // AI-powered generation process
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });

        final economy = context.read<MindloadEconomyService>();

        // Show success feedback
        CreditsFeedbackSnackbar.showSuccess(
          context: context,
          creditsUsed: creditsNeeded,
          creditsRemaining: economy.creditsRemaining - creditsNeeded,
          onAddBrainpower: _handleBuyCredits,
          onViewLedger: _handleViewLedger,
        );
      }
    });
  }

  Future<void> _handleGenerate() async {
    // Debug: Check authentication status
    final authService = AuthService.instance;
    if (kDebugMode) {
      print('🔐 Authentication status: ${authService.isAuthenticated}');
      print('🔐 Current user: ${authService.currentUser?.email ?? 'None'}');
    }

    // Validate required fields
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title for your study set'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add some content to generate from'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Validate generation options
    if (!_generateFlashcards && !_generateQuizzes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please select at least one generation type (flashcards or quiz questions)'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final economy = context.read<MindloadEconomyService>();

    final request = GenerationRequest(
      sourceContent: _contentController.text,
      sourceCharCount: _contentController.text.length,
    );

    final enforcement = economy.canGenerateContent(request);

    if (!enforcement.canProceed) {
      // Show enforcement failure
      if (enforcement.showBuyCredits) {
        _handleBuyCredits();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enforcement.blockReason ?? 'Cannot generate'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Proceed with generation
    setState(() {
      _isGenerating = true;
    });

    // Real AI-powered generation process
    try {
      if (kDebugMode) {
        print('🚀 Starting AI-powered study set generation...');
        print('📚 Title: ${_titleController.text.trim()}');
        print('📝 Content length: ${_contentController.text.length}');
        print(
            '🃏 Generate flashcards: $_generateFlashcards ($_flashcardCount)');
        print('❓ Generate quizzes: $_generateQuizzes ($_quizCount)');
      }

      // Generate content using AI
      List<Flashcard> flashcards = <Flashcard>[];
      List<QuizQuestion> quizQuestions = <QuizQuestion>[];

      if (_generateFlashcards) {
        if (kDebugMode) {
          print('🃏 Starting flashcard generation...');
        }
        flashcards = await _generateAIFlashcards(
            _contentController.text, _flashcardCount);
        if (kDebugMode) {
          print('🃏 Generated ${flashcards.length} flashcards');
        }
      }

      if (_generateQuizzes) {
        if (kDebugMode) {
          print('❓ Starting quiz generation...');
        }
        quizQuestions =
            await _generateAIQuizQuestions(_contentController.text, _quizCount);
        if (kDebugMode) {
          print('❓ Generated ${quizQuestions.length} quiz questions');
        }
      }

      // Create the study set with AI-generated content
      final studySetId = 'study_${DateTime.now().millisecondsSinceEpoch}';
      final title = _titleController.text.trim();
      final content = _contentController.text.trim();

      if (kDebugMode) {
        print('📚 Creating study set:');
        print('📚 ID: $studySetId');
        print('📚 Title: $title');
        print('📚 Content length: ${content.length}');
        print('📚 Flashcards: ${flashcards.length}');
        print('📚 Quiz questions: ${quizQuestions.length}');
      }

      // Create quizzes from quiz questions
      final quizzes = quizQuestions.isNotEmpty
          ? [
              Quiz(
                id: 'quiz_${DateTime.now().millisecondsSinceEpoch}',
                title: 'Quiz for $title',
                questions: quizQuestions,
                type: QuizType.multipleChoice,
                results: [],
                createdDate: DateTime.now(),
              )
            ]
          : <Quiz>[];

      final studySet = StudySet(
        id: studySetId,
        title: title,
        content: content,
        flashcards: flashcards,
        quizQuestions: quizQuestions,
        quizzes: quizzes,
        createdDate: DateTime.now(),
        lastStudied: DateTime.now(),
        deadlineDate: _isDeadlineEnabled ? _selectedDeadline : null,
        notificationsEnabled: true,
        tags: [],
        isArchived: false,
      );

      // Save the study set to storage
      final saveSuccess = await _saveStudySet(studySet);

      if (saveSuccess) {
        // Schedule deadline notifications if deadline is enabled and set
        if (_isDeadlineEnabled && _selectedDeadline != null) {
          await DeadlineService.instance
              .scheduleDeadlineNotifications(studySet);
        }

        // Show success message with generation details
        final generationDetails = <String>[];
        if (_generateFlashcards && flashcards.isNotEmpty) {
          generationDetails.add('${flashcards.length} flashcards');
        }
        if (_generateQuizzes && quizQuestions.isNotEmpty) {
          generationDetails.add('${quizQuestions.length} quiz questions');
        }

        final instructionText = _instructionController.text.isNotEmpty
            ? ' with custom instructions: "${_instructionController.text}"'
            : '';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Study set "${studySet.title}" created successfully with ${generationDetails.join(' and ')}$instructionText! 🎉',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        // Show credits feedback
        CreditsFeedbackSnackbar.showSuccess(
          context: context,
          creditsUsed: 1,
          creditsRemaining: economy.creditsRemaining - 1,
          onAddBrainpower: _handleBuyCredits,
          onViewLedger: _handleViewLedger,
        );

        // Clear form after successful generation
        _titleController.clear();
        _contentController.clear();
        _instructionController.clear();
        setState(() {
          _selectedDeadline = null;
          _currentYouTubePreview = null;
          _errorMessage = null;
          // Reset to default values
          _flashcardCount = 10;
          _quizCount = 5;
        });

        if (kDebugMode) {
          print('✅ Study set created and saved successfully!');
          print('📚 ID: ${studySet.id}');
          print('📚 Title: ${studySet.title}');
          print('📚 Flashcards: ${studySet.flashcards.length}');
          print('📚 Quiz Questions: ${studySet.quizQuestions.length}');
          print('📚 Quizzes: ${studySet.quizzes.length}');
        }
      } else {
        // Handle save failure
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save study set. Please try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating study set: $e');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating study set: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      final thousands = (number / 1000).toStringAsFixed(1);
      return '${thousands}k';
    }
    return number.toString();
  }

  // YouTube integration methods
  void _handleYouTubeSubmission(String videoId, String depth) {
    // Handle YouTube video submission
    setState(() {
      _contentController.text = 'YouTube Video: $videoId (Depth: $depth)';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('YouTube video $videoId submitted for processing'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleInsufficientTokens() {
    // Handle insufficient tokens scenario
    _handleBuyCredits();
  }

  void _retryYouTubePreview() {
    final videoId = YouTubeUtils.extractYouTubeId(_youtubeController.text);
    if (videoId != null) {
      _fetchYouTubePreview(videoId);
    } else {
      setState(() {
        _errorMessage = 'Invalid YouTube URL for retry';
      });
    }
  }

  /// Generate flashcards using AI
  Future<List<Flashcard>> _generateAIFlashcards(
      String content, int count) async {
    try {
      if (kDebugMode) {
        print('🤖 Generating $count AI flashcards...');
      }

      final flashcards =
          await OpenAIService.instance.generateFlashcardsFromContent(
        content,
        count,
        'medium', // Default difficulty
      );

      if (kDebugMode) {
        print('✅ Generated ${flashcards.length} AI flashcards');
      }

      return flashcards;
    } catch (e) {
      if (kDebugMode) {
        print('❌ AI flashcard generation failed: $e');
      }
      // Return empty list on failure
      return <Flashcard>[];
    }
  }

  /// Generate quiz questions using AI
  Future<List<QuizQuestion>> _generateAIQuizQuestions(
      String content, int count) async {
    try {
      if (kDebugMode) {
        print('🤖 Generating $count AI quiz questions...');
      }

      final quizQuestions =
          await OpenAIService.instance.generateQuizQuestionsFromContent(
        content,
        count,
        'medium', // Default difficulty
      );

      if (kDebugMode) {
        print('✅ Generated ${quizQuestions.length} AI quiz questions');
      }

      return quizQuestions;
    } catch (e) {
      if (kDebugMode) {
        print('❌ AI quiz generation failed: $e');
      }
      // Return empty list on failure
      return <QuizQuestion>[];
    }
  }

  /// Save study set to storage
  Future<bool> _saveStudySet(StudySet studySet) async {
    try {
      // Save to local storage using StorageService
      final success =
          await EnhancedStorageService.instance.addStudySet(studySet);

      if (kDebugMode) {
        print('💾 Study set saved: ${success ? 'SUCCESS' : 'FAILED'}');
        print('📚 Study set ID: ${studySet.id}');
        print('📚 Title: ${studySet.title}');
        print('📚 Content length: ${studySet.content.length}');
        print('📚 Flashcards: ${studySet.flashcards.length}');
        print('📚 Quizzes: ${studySet.quizzes.length}');
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to save study set: $e');
      }
      return false;
    }
  }
}
