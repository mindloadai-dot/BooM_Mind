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
import 'package:mindload/widgets/semantic_color_picker.dart';
import 'package:mindload/widgets/url_study_set_dialog.dart';
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

import 'package:mindload/services/unified_storage_service.dart';
import 'package:mindload/services/enhanced_ai_service.dart';
import 'package:mindload/services/auth_service.dart';
import 'package:mindload/services/achievement_tracker_service.dart';
import 'package:mindload/services/mindload_notification_service.dart';
import 'package:mindload/services/advanced_flashcard_generator.dart';
import 'package:mindload/models/advanced_study_models.dart';

/// Redesigned Create Screen - Modern, intuitive study set creation
///
/// Features:
/// - Step-by-step wizard interface
/// - Modern card-based design inspired by pub.dev
/// - Improved content input methods with visual feedback
/// - Intuitive generation controls with preview
/// - Enhanced visual hierarchy and spacing
/// - Better mobile responsiveness
/// - Progressive disclosure of advanced options
class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen>
    with TickerProviderStateMixin {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _instructionController = TextEditingController();
  final TextEditingController _youtubeController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  // Animation controllers for smooth transitions
  late AnimationController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Current step in the creation process
  int _currentStep = 0;
  final int _totalSteps = 4;

  bool _isGenerating = false;
  DateTime? _selectedDeadline;
  bool _isDeadlineEnabled = false;

  // Generation type and count controls
  bool _generateFlashcards = true;
  bool _generateQuizzes = true;
  int _flashcardCount = 10;
  int _quizCount = 5;

  // Content input type with improved UX
  String _contentInputType = 'text'; // 'text', 'youtube', 'document'

  // YouTube integration state
  YouTubePreview? _currentYouTubePreview;
  bool _isLoadingYouTubePreview = false;
  String? _errorMessage;

  // Document upload state
  PlatformFile? _uploadedDocument;
  bool _isProcessingDocument = false;
  String? _extractedDocumentText;

  // Study set color selection
  String? _selectedThemeColor;

  // Title auto-population state
  bool _isTitleAutoPopulated = false;

  // Advanced options visibility
  bool _showAdvancedOptions = false;

  // Progress tracking for AI processing
  double _processingProgress = 0.0;
  String _processingStatus = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // Start the fade animation to make content visible
    _fadeController.forward();

    // Listen for manual title changes to reset auto-populated flag
    _titleController.addListener(() {
      if (_isTitleAutoPopulated && _titleController.text.trim().isNotEmpty) {
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

    // Auto-populate title when moving to Step 4 if title is empty
    _pageController.addListener(() {
      if (_currentStep == 3 &&
          _titleController.text.trim().isEmpty &&
          _hasContent()) {
        _autoPopulateTitleFromContent();
      }
    });
  }

  void _initializeAnimations() {
    _pageController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    _titleController.dispose();
    _instructionController.dispose();
    _youtubeController.dispose();
    _urlController.dispose();
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final size = MediaQuery.of(context).size;

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

          // Step indicator
          _buildStepIndicator(tokens),

          // Main content - takes up remaining screen space
          Expanded(
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: size.height * 0.6,
                        minWidth: double.infinity,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Step content based on current step
                          _buildCurrentStepContent(tokens),

                          const SizedBox(height: 32),

                          // Navigation buttons
                          _buildNavigationButtons(tokens),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build step indicator
  Widget _buildStepIndicator(SemanticTokens tokens) {
    final stepNames = ['Source', 'Content', 'Options', 'Review'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(
          bottom: BorderSide(
            color: tokens.borderDefault.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Row(
              children: [
                // Step circle
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? tokens.primary
                        : isActive
                            ? tokens.primary.withOpacity(0.2)
                            : tokens.borderDefault.withOpacity(0.3),
                    border: isActive
                        ? Border.all(color: tokens.primary, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(
                            Icons.check,
                            size: 18,
                            color: tokens.onPrimary,
                          )
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive
                                  ? tokens.primary
                                  : tokens.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),

                // Step name
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stepNames[index],
                    style: TextStyle(
                      color: isActive
                          ? tokens.primary
                          : isCompleted
                              ? tokens.textPrimary
                              : tokens.textSecondary,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Connector line
                if (index < _totalSteps - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? tokens.primary
                            : tokens.borderDefault.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// Build current step content
  Widget _buildCurrentStepContent(SemanticTokens tokens) {
    switch (_currentStep) {
      case 0:
        return _buildStep1Content(tokens);
      case 1:
        return _buildStep2Content(tokens);
      case 2:
        return _buildStep3Content(tokens);
      case 3:
        return _buildStep4Content(tokens);
      default:
        return _buildStep1Content(tokens);
    }
  }

  /// Step 1: Content Source Selection
  Widget _buildStep1Content(SemanticTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildStepHeader(
          tokens,
          'Content Source',
          'Choose how you want to add your study material',
          Icons.input,
        ),

        const SizedBox(height: 24),

        // Content input type selector
        _buildModernCard(
          tokens,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardHeader(tokens, 'Select Content Source', Icons.input),
              const SizedBox(height: 16),
              _buildContentTypeSelector(tokens),
            ],
          ),
        ),
      ],
    );
  }

  /// Step 2: Content Input
  Widget _buildStep2Content(SemanticTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildStepHeader(
          tokens,
          'Add Your Content',
          'Provide the material you want to study',
          Icons.edit_note,
        ),

        const SizedBox(height: 24),

        // Dynamic content input based on type
        _buildModernCard(
          tokens,
          child: _buildDynamicContentInput(context, tokens),
        ),

        const SizedBox(height: 24),

        // Study set color selection
        _buildModernCard(
          tokens,
          child: SemanticColorPicker(
            selectedColor: _selectedThemeColor,
            onColorChanged: (color) {
              setState(() {
                _selectedThemeColor = color;
              });
            },
            tokens: tokens,
          ),
        ),
      ],
    );
  }

  /// Step 3: Generation Options
  Widget _buildStep3Content(SemanticTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildStepHeader(
          tokens,
          'Study Materials',
          'Choose what to generate from your content',
          Icons.school,
        ),

        const SizedBox(height: 24),

        // Generation options card
        _buildModernCard(
          tokens,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardHeader(tokens, 'Generate Study Materials', Icons.tune),
              const SizedBox(height: 20),
              _buildGenerationTypeSelector(tokens),
              const SizedBox(height: 24),
              _buildCountControls(tokens),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Advanced options card
        _buildModernCard(
          tokens,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildCardHeader(tokens, 'Advanced Options', Icons.settings),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showAdvancedOptions = !_showAdvancedOptions;
                      });
                    },
                    icon: Icon(
                      _showAdvancedOptions
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
              if (_showAdvancedOptions) ...[
                const SizedBox(height: 16),
                _buildAdvancedOptions(tokens),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Step 4: Review and Generate
  Widget _buildStep4Content(SemanticTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildStepHeader(
          tokens,
          'Review & Generate',
          'Review your settings and create your study set',
          Icons.preview,
        ),

        const SizedBox(height: 24),

        // Title input card (moved to last step)
        _buildModernCard(
          tokens,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardHeader(tokens, 'Study Set Title', Icons.title),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                style: TextStyle(
                  fontSize: 16,
                  color: tokens.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter a descriptive title...',
                  hintStyle: TextStyle(
                    color: tokens.textTertiary,
                    fontSize: 16,
                  ),
                  filled: true,
                  fillColor: tokens.surfaceAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              if (_isTitleAutoPopulated) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: tokens.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Auto-generated title from content',
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'The title has been auto-generated from your content. Feel free to customize it!',
                style: TextStyle(
                  color: tokens.textSecondary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Summary card
        _buildModernCard(
          tokens,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardHeader(tokens, 'Study Set Summary', Icons.summarize),
              const SizedBox(height: 20),
              _buildSummaryContent(tokens),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Cost preview
        if (_hasContent()) _buildPreFlightSection(context, tokens),
      ],
    );
  }

  /// Build step header
  Widget _buildStepHeader(
      SemanticTokens tokens, String title, String subtitle, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tokens.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: tokens.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: tokens.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 16,
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build modern card container
  Widget _buildModernCard(SemanticTokens tokens, {required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tokens.borderDefault.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }

  /// Build card header
  Widget _buildCardHeader(SemanticTokens tokens, String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: tokens.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: tokens.textPrimary,
          ),
        ),
      ],
    );
  }

  /// Build content type selector
  Widget _buildContentTypeSelector(SemanticTokens tokens) {
    final options = [
      {
        'id': 'text',
        'icon': Icons.edit_note,
        'title': 'Text',
        'subtitle': 'Paste or type content'
      },
      {
        'id': 'url',
        'icon': Icons.link,
        'title': 'URL',
        'subtitle': 'Generate from web content'
      },
      {
        'id': 'youtube',
        'icon': Icons.play_circle_outline,
        'title': 'YouTube',
        'subtitle': 'Process video content'
      },
      {
        'id': 'document',
        'icon': Icons.upload_file,
        'title': 'Document',
        'subtitle': 'Upload PDF, DOCX, etc.'
      },
    ];

    return Column(
      children: options.map((option) {
        final isSelected = _contentInputType == option['id'];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              setState(() {
                _contentInputType = option['id'] as String;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? tokens.primary.withOpacity(0.1)
                    : tokens.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? tokens.primary
                      : tokens.borderDefault.withOpacity(0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? tokens.primary
                          : tokens.textSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      option['icon'] as IconData,
                      color:
                          isSelected ? tokens.onPrimary : tokens.textSecondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option['title'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: tokens.textPrimary,
                          ),
                        ),
                        Text(
                          option['subtitle'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: tokens.primary,
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Build generation type selector
  Widget _buildGenerationTypeSelector(SemanticTokens tokens) {
    return Row(
      children: [
        Expanded(
          child: _buildGenerationTypeCard(
            tokens,
            'Flashcards',
            'Memory cards for active recall',
            Icons.style,
            _generateFlashcards,
            (value) {
              setState(() {
                _generateFlashcards = value ?? false;
                if (!_generateFlashcards && !_generateQuizzes) {
                  _generateQuizzes = true;
                }
              });
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildGenerationTypeCard(
            tokens,
            'Quiz Questions',
            'Test your understanding',
            Icons.quiz,
            _generateQuizzes,
            (value) {
              setState(() {
                _generateQuizzes = value ?? false;
                if (!_generateFlashcards && !_generateQuizzes) {
                  _generateFlashcards = true;
                }
              });
            },
          ),
        ),
      ],
    );
  }

  /// Build generation type card
  Widget _buildGenerationTypeCard(
    SemanticTokens tokens,
    String title,
    String subtitle,
    IconData icon,
    bool isSelected,
    ValueChanged<bool?> onChanged,
  ) {
    return InkWell(
      onTap: () => onChanged(!isSelected),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected ? tokens.primary.withOpacity(0.1) : tokens.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? tokens.primary
                : tokens.borderDefault.withOpacity(0.3),
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
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? tokens.primary : tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: tokens.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build count controls
  Widget _buildCountControls(SemanticTokens tokens) {
    return Column(
      children: [
        if (_generateFlashcards) ...[
          _buildCountControl(
            tokens,
            'Flashcards',
            _flashcardCount,
            (value) => setState(() => _flashcardCount = value),
            min: 1,
            max: 50,
            icon: Icons.style,
          ),
          const SizedBox(height: 16),
        ],
        if (_generateQuizzes) ...[
          _buildCountControl(
            tokens,
            'Quiz Questions',
            _quizCount,
            (value) => setState(() => _quizCount = value),
            min: 1,
            max: 20,
            icon: Icons.quiz,
          ),
        ],
      ],
    );
  }

  /// Build count control
  Widget _buildCountControl(
    SemanticTokens tokens,
    String label,
    int value,
    ValueChanged<int> onChanged, {
    required int min,
    required int max,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tokens.borderDefault.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: tokens.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Number of $label',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: tokens.textPrimary,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: value > min ? () => onChanged(value - 1) : null,
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: value > min ? tokens.primary : tokens.textTertiary,
                    ),
                    iconSize: 20,
                  ),
                  IconButton(
                    onPressed: value < max ? () => onChanged(value + 1) : null,
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: value < max ? tokens.primary : tokens.textTertiary,
                    ),
                    iconSize: 20,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build advanced options
  Widget _buildAdvancedOptions(SemanticTokens tokens) {
    return Column(
      children: [
        // Custom instructions
        TextField(
          controller: _instructionController,
          maxLines: 3,
          style: TextStyle(
            fontSize: 14,
            color: tokens.textPrimary,
          ),
          decoration: InputDecoration(
            labelText: 'Custom Instructions (Optional)',
            hintText: 'Add specific instructions for AI generation...',
            hintStyle: TextStyle(
              color: tokens.textTertiary,
              fontSize: 14,
            ),
            filled: true,
            fillColor: tokens.surfaceAlt,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Deadline picker
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
      ],
    );
  }

  /// Build summary content
  Widget _buildSummaryContent(SemanticTokens tokens) {
    return Column(
      children: [
        _buildSummaryItem(
            tokens,
            'Title',
            _titleController.text.isNotEmpty
                ? _titleController.text
                : 'Not set',
            Icons.title,
            isAutoGenerated: _isTitleAutoPopulated),
        _buildSummaryItem(
            tokens, 'Content Source', _getContentSourceLabel(), Icons.input),
        _buildSummaryItem(
            tokens, 'Study Materials', _getStudyMaterialsLabel(), Icons.school),
        if (_instructionController.text.isNotEmpty)
          _buildSummaryItem(tokens, 'Custom Instructions', 'Added', Icons.edit),
        if (_isDeadlineEnabled && _selectedDeadline != null)
          _buildSummaryItem(tokens, 'Deadline',
              _formatDeadline(_selectedDeadline!), Icons.schedule),
      ],
    );
  }

  /// Build summary item
  Widget _buildSummaryItem(
    SemanticTokens tokens,
    String label,
    String value,
    IconData icon, {
    bool isAutoGenerated = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: tokens.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: tokens.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isAutoGenerated) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.auto_awesome,
                        size: 12,
                        color: tokens.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Auto-generated',
                        style: TextStyle(
                          fontSize: 10,
                          color: tokens.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build navigation buttons
  Widget _buildNavigationButtons(SemanticTokens tokens) {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _previousStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: tokens.borderDefault),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_back, size: 20),
                  const SizedBox(width: 8),
                  Text('Previous'),
                ],
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _canProceedToNext() ? _nextStep : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.primary,
              foregroundColor: tokens.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_getNextButtonText()),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Check if can proceed to next step
  bool _canProceedToNext() {
    switch (_currentStep) {
      case 0:
        return _contentInputType.isNotEmpty; // Just need to select content type
      case 1:
        return _hasContent();
      case 2:
        return _generateFlashcards || _generateQuizzes;
      case 3:
        return _titleController.text
            .trim()
            .isNotEmpty; // Title required in final step
      default:
        return false;
    }
  }

  /// Get next button text
  String _getNextButtonText() {
    switch (_currentStep) {
      case 0:
      case 1:
      case 2:
        return 'Next';
      case 3:
        return _isGenerating ? 'Generating...' : 'Create Study Set';
      default:
        return 'Next';
    }
  }

  /// Navigate to next step
  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });

      // Auto-populate title when moving to Step 4
      if (_currentStep == 3) {
        _autoPopulateTitleFromContent();
      }

      _fadeController.reset();
      _fadeController.forward();
    } else {
      _handleGenerate();
    }
  }

  /// Navigate to previous step
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _fadeController.reset();
      _fadeController.forward();
    }
  }

  /// Get content source label
  String _getContentSourceLabel() {
    switch (_contentInputType) {
      case 'text':
        return 'Text Input';
      case 'url':
        return 'URL Input';
      case 'youtube':
        return 'YouTube Video';
      case 'document':
        return 'Document Upload';
      default:
        return 'Unknown';
    }
  }

  /// Get study materials label
  String _getStudyMaterialsLabel() {
    final materials = <String>[];
    if (_generateFlashcards) {
      materials.add('$_flashcardCount Flashcards');
    }
    if (_generateQuizzes) {
      materials.add('$_quizCount Quiz Questions');
    }
    return materials.join(', ');
  }

  /// Format deadline
  String _formatDeadline(DateTime deadline) {
    return '${deadline.day}/${deadline.month}/${deadline.year}';
  }

  /// Check if there's any content to process
  bool _hasContent() {
    return _contentController.text.isNotEmpty ||
        _uploadedDocument != null ||
        _currentYouTubePreview != null;
  }

  /// Build dynamic content input based on selected type
  Widget _buildDynamicContentInput(
      BuildContext context, SemanticTokens tokens) {
    switch (_contentInputType) {
      case 'text':
        return _buildTextInput(context, tokens);
      case 'url':
        return _buildURLInput(context, tokens);
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
            _handleBuyCredits();
          },
        );
      },
    );
  }

  /// Build URL input section
  Widget _buildURLInput(BuildContext context, SemanticTokens tokens) {
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
                  Icons.link,
                  size: 20,
                  color: tokens.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'URL Content Generation',
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
              'Paste a URL to automatically extract web content and generate study materials. The content will be processed offline once generated.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tokens.textSecondary,
                    height: 1.4,
                  ),
            ),
          ),

          // URL input field
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _urlController,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: tokens.textPrimary,
                  ),
              decoration: InputDecoration(
                hintText: 'https://example.com/article',
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

          // Generate button
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _urlController.text.trim().isNotEmpty
                  ? _showUrlStudySetDialog
                  : null,
              icon: Icon(Icons.auto_awesome, color: tokens.onPrimary),
              label: Text(
                'Generate Study Set from URL',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: tokens.onPrimary,
                    ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          // Info card
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
                    Icon(Icons.info_outline, color: tokens.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'How it works',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Extracts clean content from web pages\n• Generates 40-60 study items (MCQs, flashcards, short answers)\n• Works completely offline once generated\n• Processing takes 2-5 minutes',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens.textSecondary,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
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
              'Paste a YouTube URL to automatically extract video content and generate study materials',
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
              child: LinearProgressIndicator(
                value: _processingProgress,
              ),
            ),
          ] else if (_currentYouTubePreview != null) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: YouTubePreviewCard(
                preview: _currentYouTubePreview!,
                onIngest: null, // Disable manual ingest since it's automatic
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
              'Upload PDF, DOCX, TXT, or other supported documents to automatically extract content',
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
              child: LinearProgressIndicator(
                value: _processingProgress,
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
            const SizedBox(height: 4),
            Text(
              'Content will be automatically extracted',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tokens.textTertiary,
                    fontStyle: FontStyle.italic,
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
                    _contentController.clear();
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
          // Show processing status if document is being processed
          if (_isProcessingDocument) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: tokens.borderDefault.withValues(alpha: 0.3)),
              ),
              child: LinearProgressIndicator(
                value: _processingProgress,
              ),
            ),
          ],
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

        // Automatically process the document after upload
        await _processDocument();
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
      _processingProgress = 0.0;
      _processingStatus = 'Initializing document processing...';
    });

    try {
      final fileBytes = _uploadedDocument!.bytes!;
      final extension = _uploadedDocument!.extension ?? '';
      final fileName = _uploadedDocument!.name;

      // Update progress for document analysis
      setState(() {
        _processingProgress = 0.2;
        _processingStatus = 'Analyzing document structure...';
      });

      // Extract text from document
      setState(() {
        _processingProgress = 0.4;
        _processingStatus = 'Extracting text content...';
      });

      final extractedText = await DocumentProcessor.extractTextFromFile(
        fileBytes,
        extension,
        fileName,
      );

      setState(() {
        _processingProgress = 0.8;
        _processingStatus = 'Finalizing extraction...';
      });

      setState(() {
        _extractedDocumentText = extractedText;
        _isProcessingDocument = false;
        _processingProgress = 1.0;
        _processingStatus = 'Document processed successfully!';
      });

      // Update content controller for generation
      _contentController.text = extractedText;

      // Auto-populate title from document name if title is empty or not customized
      _suggestTitleFromDocument(_uploadedDocument!.name);

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Document processed successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to process document: $e';
        _isProcessingDocument = false;
        _processingProgress = 0.0;
        _processingStatus = '';
      });

      // Show error feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Failed to process document: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
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
      _processingProgress = 0.0;
      _processingStatus = 'Initializing YouTube preview...';
    });

    try {
      // Add debug logging
      if (kDebugMode) {
        print('🎬 Fetching YouTube preview for video: $videoId');
        print('🔍 Video ID length: ${videoId.length}');
        print(
            '🔍 Video ID pattern: ${RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(videoId)}');
      }

      // Update progress for video analysis
      setState(() {
        _processingProgress = 0.3;
        _processingStatus = 'Analyzing video metadata...';
      });

      // Update progress for content extraction
      setState(() {
        _processingProgress = 0.6;
        _processingStatus = 'Extracting video content...';
      });

      final preview = await YouTubeService().getPreview(videoId);

      // Update progress for final processing
      setState(() {
        _processingProgress = 0.9;
        _processingStatus = 'Finalizing preview...';
      });

      if (mounted) {
        setState(() {
          _currentYouTubePreview = preview;
          _isLoadingYouTubePreview = false;
          _processingProgress = 1.0;
          _processingStatus = 'Preview loaded successfully!';
        });

        // Auto-populate title if it's empty or user hasn't customized it
        _suggestTitleFromYouTube(preview);

        // Automatically process the YouTube content if it can proceed
        if (preview.canProceed) {
          _handleYouTubeIngest();
        }

        if (kDebugMode) {
          print('✅ YouTube preview loaded successfully: ${preview.title}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingYouTubePreview = false;
          _processingProgress = 0.0;
          _processingStatus = '';
        });

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

  /// Auto-populate title from content when moving to final step
  void _autoPopulateTitleFromContent() {
    if (_titleController.text.trim().isNotEmpty) {
      return; // Don't override if user already set title
    }

    String suggestedTitle = '';

    if (_contentInputType == 'text' &&
        _contentController.text.trim().isNotEmpty) {
      suggestedTitle = _generateTextTitle(_contentController.text.trim());
    } else if (_currentYouTubePreview != null) {
      suggestedTitle = _generateYouTubeTitle(_currentYouTubePreview!);
    } else if (_uploadedDocument != null) {
      suggestedTitle = _generateDocumentTitle(_uploadedDocument!.name);
    }

    if (suggestedTitle.isNotEmpty) {
      _titleController.text = suggestedTitle;
      _isTitleAutoPopulated = true;

      if (kDebugMode) {
        print('📝 Auto-populated title in Step 4: $suggestedTitle');
      }
    }
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
                              width: 120,
                              child: LinearProgressIndicator(
                                value: _processingProgress,
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

  /// Show URL study set generation dialog
  void _showUrlStudySetDialog() {
    showDialog(
      context: context,
      builder: (context) => UrlStudySetDialog(
        onStudySetGenerated: (studySetId, title) {
          // Handle successful study set generation
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Study set "$title" generated successfully!'),
              backgroundColor: context.tokens.success,
            ),
          );

          // Navigate back to home or study set selection
          Navigator.of(context).pop(); // Close dialog
          Navigator.of(context).pop(); // Close create screen
        },
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
        'This is sample pasted content for demonstration. In a real implementation, this would paste from the system clipboard.\n\nThis content is long enough to demonstrate the character counter and potential paste cap issues when content exceeds the tier limits.\n\nFor example, all tiers now have a 500,000 character limit for pasted content.';
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
        economy.userEconomy?.getPasteCharLimit(economy.budgetState) ?? 500000;

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
      _processingProgress = 0.0;
      _processingStatus = 'Initializing AI generation...';
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

      // Generate content using Advanced AI system
      final totalCardCount = (_generateFlashcards ? _flashcardCount : 0) +
          (_generateQuizzes ? _quizCount : 0);

      if (kDebugMode) {
        print('🧠 Starting advanced AI generation...');
        print('📊 Total cards requested: $totalCardCount');
        print('📝 Custom instructions: ${_instructionController.text}');
      }

      // Update progress for AI analysis
      setState(() {
        _processingProgress = 0.2;
        _processingStatus = 'Analyzing content structure...';
      });

      // Update progress for AI generation
      setState(() {
        _processingProgress = 0.4;
        _processingStatus = 'Generating study materials...';
      });

      // Generate advanced flashcard set
      final advancedSet = await _generateAdvancedStudySet(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        cardCount: totalCardCount,
        customInstructions: _instructionController.text.trim(),
      );

      // Update progress for content processing
      setState(() {
        _processingProgress = 0.7;
        _processingStatus = 'Processing generated content...';
      });

      // Convert to legacy format for compatibility
      final flashcards = advancedSet.cards
          .where((card) => _generateFlashcards)
          .map((card) => card.toLegacyFlashcard())
          .toList();

      final quizQuestions = advancedSet.quiz?.questions
              .where((q) => _generateQuizzes)
              .map((q) => _convertAdvancedToQuizQuestion(q))
              .toList() ??
          <QuizQuestion>[];

      if (kDebugMode) {
        print('✅ Advanced generation complete');
        print('🃏 Generated ${flashcards.length} flashcards');
        print('❓ Generated ${quizQuestions.length} quiz questions');
        print('📊 Bloom\'s mix: ${advancedSet.bloomMix}');
        print('🎯 Difficulty: ${advancedSet.difficulty}');
      }

      // Update progress for final processing
      setState(() {
        _processingProgress = 0.9;
        _processingStatus = 'Finalizing study set...';
      });

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
                type: QuestionType.multipleChoice,
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
        themeColor: _selectedThemeColor,
      );

      // Save the study set to storage
      final saveSuccess = await _saveStudySet(studySet);

      if (saveSuccess) {
        // Track achievement progress for study set creation
        await AchievementTrackerService.instance.trackStudySetCreated(
          cardCount: flashcards.length + quizQuestions.length,
          setType: 'ai_generated',
          isPublic: false,
        );

        // Track individual card creation achievements
        if (flashcards.isNotEmpty) {
          await AchievementTrackerService.instance.trackCardsCreated(
            flashcards.length,
            cardType: 'flashcard',
          );
        }

        if (quizQuestions.isNotEmpty) {
          await AchievementTrackerService.instance.trackCardsCreated(
            quizQuestions.length,
            cardType: 'quiz_question',
          );
        }

        if (kDebugMode) {
          print('✅ Study set created and saved successfully!');
          print('📚 ID: ${studySet.id}');
          print('📚 Title: ${studySet.title}');
          print('📚 Flashcards: ${studySet.flashcards.length}');
          print('📚 Quiz Questions: ${studySet.quizQuestions.length}');
          print('📚 Quizzes: ${studySet.quizzes.length}');
        }

        // Schedule deadline notifications if deadline is enabled and set
        if (_isDeadlineEnabled && _selectedDeadline != null) {
          await DeadlineService.instance
              .scheduleDeadlineNotifications(studySet);
        }

        // Fire first-run notification if this is the first study set
        await MindLoadNotificationService
            .fireFirstStudySetNotificationIfNeeded();

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

        // Consume credits for generation
        final generationRequest = GenerationRequest(
          sourceContent: _contentController.text,
          sourceCharCount: _contentController.text.length,
          isRecreate: false,
          lastAttemptFailed: false,
        );

        final creditsConsumed =
            await economy.useCreditsForGeneration(generationRequest);

        if (!creditsConsumed) {
          // Handle credit consumption failure
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to consume credits. Please try again.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          return;
        }

        // Show credits feedback
        CreditsFeedbackSnackbar.showSuccess(
          context: context,
          creditsUsed: 1,
          creditsRemaining: economy.creditsRemaining,
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

      setState(() {
        _processingProgress = 0.0;
        _processingStatus = '';
      });

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
          _processingProgress = 1.0;
          _processingStatus = 'Generation complete!';
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

  /// Generate advanced study set using EnhancedAIService
  Future<AdvancedStudySet> _generateAdvancedStudySet({
    required String title,
    required String content,
    required int cardCount,
    String? customInstructions,
  }) async {
    try {
      if (kDebugMode) {
        print('🧠 Generating study set using EnhancedAIService...');
        print('📊 Card count: $cardCount');
        print('📝 Custom instructions: ${customInstructions ?? 'None'}');
      }

      // Determine difficulty based on content complexity and user preference
      final difficulty = _calculateContentDifficulty(content);

      // Use EnhancedAIService for mobile-optimized AI generation
      final enhancedResult =
          await EnhancedAIService.instance.generateStudyMaterials(
        content: content,
        flashcardCount: _generateFlashcards ? _flashcardCount : 0,
        quizCount: _generateQuizzes ? _quizCount : 0,
        difficulty: _mapDifficultyToString(difficulty),
        questionTypes: customInstructions != null ? 'comprehensive' : null,
        cognitiveLevel: _determineAudience(content),
        realWorldContext: customInstructions != null ? 'high' : null,
        challengeLevel: _mapDifficultyToString(difficulty),
        learningStyle: 'adaptive',
        promptEnhancement: customInstructions,
      );

      if (!enhancedResult.isSuccess) {
        throw Exception(
            'EnhancedAIService failed: ${enhancedResult.errorMessage}');
      }

      if (kDebugMode) {
        print(
            '✅ Mobile AI generation successful using ${enhancedResult.method.name}');
        if (enhancedResult.isFallback) {
          print('📱 Using mobile fallback: ${enhancedResult.method.name}');
        }
        print('🎴 Generated ${enhancedResult.flashcards.length} flashcards');
        print(
            '❓ Generated ${enhancedResult.quizQuestions.length} quiz questions');
        print(
            '⏱️ Mobile processing time: ${enhancedResult.processingTimeMs}ms');
        if (enhancedResult.errorMessage != null) {
          print('📱 Mobile info: ${enhancedResult.errorMessage}');
        }
      }

      // Convert EnhancedAIService results to AdvancedFlashcard format
      final advancedCards = enhancedResult.flashcards
          .map((f) => AdvancedFlashcard.fromLegacyFlashcard(f))
          .toList();

      // Create quiz from EnhancedAIService quiz questions
      AdvancedQuiz? advancedQuiz;
      if (enhancedResult.quizQuestions.isNotEmpty) {
        // Convert quiz questions to flashcard format for AdvancedQuiz
        final quizAsCards = enhancedResult.quizQuestions
            .map((q) => AdvancedFlashcard(
                  id: 'q_${DateTime.now().millisecondsSinceEpoch}_${q.hashCode}',
                  type: 'mcq',
                  bloom: 'Understand',
                  difficulty: q.difficulty.toString().split('.').last,
                  question: q.question,
                  choices: q.options,
                  correctIndex: q.options.indexOf(q.correctAnswer),
                  answerExplanation: q.correctAnswer,
                  hint: 'Think about the key concepts',
                  anchors: ['quiz', 'ai-generated'],
                  sourceSpan: 'AI Generated Content',
                ))
            .toList();

        advancedQuiz = AdvancedQuiz(
          id: 'quiz_${DateTime.now().millisecondsSinceEpoch}',
          title: 'AI Quiz for $title',
          questions: quizAsCards,
          numQuestions: quizAsCards.length,
          typeMix: {'mcq': 100.0},
          timeLimitSeconds: quizAsCards.length * 30,
          passThreshold: 0.7,
          createdDate: DateTime.now(),
          results: [],
          bloomMix: {'understand': 60.0, 'apply': 40.0},
          difficulty: 3, // Medium difficulty
        );
      }

      // Create advanced study set with enhanced metadata
      final advancedSet = AdvancedStudySet(
        id: 'study_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        content: content,
        sourceSummary:
            'Generated using EnhancedAIService (${enhancedResult.method.name})',
        tags: [
          'ai_generated',
          'enhanced_ai',
          enhancedResult.method.name,
          if (enhancedResult.isFallback) 'fallback',
        ],
        difficulty: difficulty,
        bloomMix: _calculateBloomMix(enhancedResult.flashcards),
        cards: advancedCards,
        createdDate: DateTime.now(),
        lastStudied: DateTime.now(),
      );

      if (kDebugMode) {
        print('✅ Advanced study set generated successfully');
        print('📊 Cards: ${advancedSet.cards.length}');
        print('🎯 Difficulty: ${advancedSet.difficulty}');
        print('📈 Bloom distribution: ${advancedSet.bloomMix}');
        print('🏷️ Tags: ${advancedSet.tags}');
      }

      return advancedSet;
    } catch (e) {
      if (kDebugMode) {
        print('❌ EnhancedAIService generation failed: $e');
        print('📋 Falling back to template generation...');
      }

      // Fallback to template-based generation
      return await _fallbackToTemplateGeneration(title, content, cardCount);
    }
  }

  /// Calculate content difficulty based on complexity indicators
  int _calculateContentDifficulty(String content) {
    int difficulty = 3; // Start with intermediate

    // Increase difficulty based on content indicators
    if (content.contains(RegExp(r'\b(analyze|evaluate|synthesize|critique)\b',
        caseSensitive: false))) {
      difficulty += 2;
    }
    if (content.contains(RegExp(
        r'\b(however|nevertheless|furthermore|consequently)\b',
        caseSensitive: false))) {
      difficulty += 1;
    }
    if (content.length > 5000) {
      difficulty += 1;
    }
    if (content.split(RegExp(r'[.!?]')).length > 50) {
      difficulty += 1;
    }

    // Decrease difficulty for simpler content
    if (content.contains(RegExp(r'\b(simple|basic|introduction|beginner)\b',
        caseSensitive: false))) {
      difficulty -= 1;
    }

    return difficulty.clamp(1, 7);
  }

  /// Determine audience based on content analysis
  String _determineAudience(String content) {
    final contentLower = content.toLowerCase();

    if (contentLower
        .contains(RegExp(r'\b(phd|doctoral|research|dissertation)\b'))) {
      return 'PhD';
    }
    if (contentLower
        .contains(RegExp(r'\b(advanced|graduate|master|complex)\b'))) {
      return 'advanced';
    }
    if (contentLower
        .contains(RegExp(r'\b(intermediate|college|university)\b'))) {
      return 'intermediate';
    }
    if (contentLower
        .contains(RegExp(r'\b(basic|introduction|beginner|elementary)\b'))) {
      return 'beginner';
    }

    // Default based on content length and complexity
    if (content.length > 10000) return 'advanced';
    if (content.length > 3000) return 'intermediate';
    return 'beginner';
  }

  /// Extract focus anchors from custom instructions
  List<String> _extractFocusAnchors(String instructions) {
    if (instructions.isEmpty) return [];

    final anchors = <String>[];
    final words = instructions.split(RegExp(r'\W+'));

    for (final word in words) {
      if (word.length > 3 && !_isStopWord(word.toLowerCase())) {
        anchors.add(word);
        if (anchors.length >= 5) break; // Limit to 5 anchors
      }
    }

    return anchors;
  }

  /// Check if word is a stop word
  bool _isStopWord(String word) {
    const stopWords = {
      'the',
      'a',
      'an',
      'and',
      'or',
      'but',
      'in',
      'on',
      'at',
      'to',
      'for',
      'of',
      'with',
      'by',
      'is',
      'are',
      'was',
      'were',
      'about',
      'focus',
      'make',
      'questions',
      'quiz',
      'study',
      'from',
      'this',
      'that'
    };
    return stopWords.contains(word.toLowerCase());
  }

  /// Map difficulty level to string for EnhancedAIService
  String _mapDifficultyToString(int difficulty) {
    switch (difficulty) {
      case 1:
      case 2:
        return 'easy';
      case 3:
      case 4:
        return 'medium';
      case 5:
      case 6:
      case 7:
        return 'hard';
      default:
        return 'medium';
    }
  }

  /// Calculate Bloom's taxonomy mix from flashcards
  Map<String, double> _calculateBloomMix(List<Flashcard> flashcards) {
    final bloomCounts = <String, int>{};

    for (final card in flashcards) {
      final difficulty = card.difficulty;
      if (difficulty == DifficultyLevel.beginner) {
        bloomCounts['Understand'] = (bloomCounts['Understand'] ?? 0) + 1;
      } else if (difficulty == DifficultyLevel.intermediate) {
        bloomCounts['Apply'] = (bloomCounts['Apply'] ?? 0) + 1;
      } else if (difficulty == DifficultyLevel.advanced) {
        bloomCounts['Analyze'] = (bloomCounts['Analyze'] ?? 0) + 1;
      }
    }

    final total = flashcards.length;
    if (total == 0) return {'Apply': 0.6, 'Understand': 0.4};

    return {
      'Understand': (bloomCounts['Understand'] ?? 0) / total,
      'Apply': (bloomCounts['Apply'] ?? 0) / total,
      'Analyze': (bloomCounts['Analyze'] ?? 0) / total,
      'Evaluate': 0.0,
      'Create': 0.0,
    };
  }

  /// Fallback to template-based generation using AdvancedFlashcardGenerator
  Future<AdvancedStudySet> _fallbackToTemplateGeneration(
      String title, String content, int cardCount) async {
    try {
      if (kDebugMode) {
        print('🔄 Using template-based generation as fallback...');
      }

      // Determine difficulty based on content complexity
      final difficulty = _calculateContentDifficulty(content);
      final audience = _determineAudience(content);
      final focusAnchors = _extractFocusAnchors('');

      // Generate using AdvancedFlashcardGenerator as fallback
      final generationSchema = await AdvancedFlashcardGenerator.instance
          .generateAdvancedFlashcardSet(
        content: content,
        setTitle: title,
        cardCount: cardCount,
        audience: audience,
        priorKnowledge: 'medium',
        difficulty: difficulty,
        focusAnchors: focusAnchors,
        scenarioPercentage: 0.4,
        maxRecallPercentage: 0.1,
      );

      // Convert to AdvancedStudySet
      final advancedSet = AdvancedStudySet.fromGenerationSchema(
        'study_${DateTime.now().millisecondsSinceEpoch}',
        title,
        content,
        generationSchema,
      );

      if (kDebugMode) {
        print('✅ Template-based generation successful');
      }

      return advancedSet;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Template generation also failed: $e');
      }

      // Return empty study set as last resort
      return AdvancedStudySet(
        id: 'study_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        content: content,
        sourceSummary: 'Generation failed - empty set created',
        tags: ['generation_failed'],
        difficulty: 3,
        bloomMix: {},
        cards: [],
        createdDate: DateTime.now(),
        lastStudied: DateTime.now(),
      );
    }
  }

  /// Fallback to legacy generation if advanced generation fails
  Future<AdvancedStudySet> _fallbackToLegacyGeneration(
      String title, String content, int cardCount) async {
    try {
      // Use EnhancedAIService for robust generation
      final enhancedResult =
          await EnhancedAIService.instance.generateStudyMaterials(
        content: content,
        flashcardCount: cardCount,
        quizCount: 0,
        difficulty: 'medium',
      );

      if (!enhancedResult.isSuccess) {
        throw Exception(
            'Failed to generate content: ${enhancedResult.errorMessage}');
      }

      final flashcards = enhancedResult.flashcards;

      // Convert legacy flashcards to advanced format
      final advancedCards = flashcards
          .map((f) => AdvancedFlashcard.fromLegacyFlashcard(f))
          .toList();

      // Create basic advanced study set
      return AdvancedStudySet(
        id: 'study_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        content: content,
        sourceSummary: 'Generated using legacy fallback system',
        tags: ['legacy_generation', 'fallback'],
        difficulty: 3,
        bloomMix: {'Apply': 0.6, 'Understand': 0.4},
        cards: advancedCards,
        createdDate: DateTime.now(),
        lastStudied: DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Legacy fallback also failed: $e');
      }

      // Return empty study set as last resort
      return AdvancedStudySet(
        id: 'study_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        content: content,
        sourceSummary: 'Generation failed - empty set created',
        tags: ['generation_failed'],
        difficulty: 3,
        bloomMix: {},
        cards: [],
        createdDate: DateTime.now(),
        lastStudied: DateTime.now(),
      );
    }
  }

  /// Convert AdvancedFlashcard to QuizQuestion for compatibility
  QuizQuestion _convertAdvancedToQuizQuestion(AdvancedFlashcard card) {
    if (card.type == 'mcq' && card.choices.isNotEmpty) {
      return QuizQuestion(
        id: card.id,
        question: card.question,
        options: card.choices,
        correctAnswer: card.choices[card.correctIndex],
        type: QuestionType.multipleChoice,
        difficulty: card.cardDifficulty == CardDifficulty.easy
            ? DifficultyLevel.beginner
            : card.cardDifficulty == CardDifficulty.hard
                ? DifficultyLevel.advanced
                : DifficultyLevel.intermediate,
      );
    } else if (card.type == 'truefalse') {
      return QuizQuestion(
        id: card.id,
        question: card.question,
        options: ['True', 'False'],
        correctAnswer:
            card.choices.isNotEmpty ? card.choices[card.correctIndex] : 'True',
        type: QuestionType.trueFalse,
        difficulty: card.cardDifficulty == CardDifficulty.easy
            ? DifficultyLevel.beginner
            : card.cardDifficulty == CardDifficulty.hard
                ? DifficultyLevel.advanced
                : DifficultyLevel.intermediate,
      );
    } else {
      // Convert QA type to multiple choice
      return QuizQuestion(
        id: card.id,
        question: card.question,
        options: [
          card.answerExplanation,
          'Incorrect option 1',
          'Incorrect option 2',
          'Incorrect option 3'
        ],
        correctAnswer: card.answerExplanation,
        type: QuestionType.multipleChoice,
        difficulty: card.cardDifficulty == CardDifficulty.easy
            ? DifficultyLevel.beginner
            : card.cardDifficulty == CardDifficulty.hard
                ? DifficultyLevel.advanced
                : DifficultyLevel.intermediate,
      );
    }
  }

  /// Map string difficulty to CardDifficulty
  CardDifficulty _mapStringToCardDifficulty(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return CardDifficulty.easy;
      case 'hard':
        return CardDifficulty.hard;
      default:
        return CardDifficulty.medium;
    }
  }

  /// Map difficulty to integer scale
  int _mapDifficultyToInt(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return 1;
      case DifficultyLevel.intermediate:
        return 3;
      case DifficultyLevel.advanced:
        return 5;
      case DifficultyLevel.expert:
        return 7;
    }
  }

  /// Save study set to storage
  Future<bool> _saveStudySet(StudySet studySet) async {
    try {
      // Save to local storage using StorageService
      final success =
          await UnifiedStorageService.instance.addStudySet(studySet);

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
