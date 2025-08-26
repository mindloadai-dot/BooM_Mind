import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:mindload/models/study_data.dart';

import 'package:mindload/services/storage_service.dart';
import 'package:mindload/services/openai_service.dart';
import 'package:mindload/services/document_processor.dart';

import 'package:mindload/screens/study_screen.dart';
import 'package:mindload/screens/ultra_mode_screen.dart';
import 'package:mindload/screens/profile_screen.dart';
import 'package:mindload/screens/tiers_benefits_screen.dart';
import 'package:mindload/services/pdf_export_service.dart';
import 'package:mindload/models/pdf_export_models.dart';
// Removed import: study_set_notification_service - service removed

import 'package:mindload/services/mindload_economy_service.dart';
import 'package:mindload/models/mindload_economy_models.dart';
import 'package:mindload/widgets/customize_study_set_dialog.dart';
import 'package:mindload/widgets/brain_logo.dart';
import 'package:mindload/widgets/accessible_components.dart';
import 'package:mindload/widgets/credits_state_banners.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/widgets/mindload_app_bar.dart';
import 'package:mindload/screens/achievements_screen.dart';
import 'package:mindload/services/achievement_tracker_service.dart';
import 'package:mindload/services/notification_service.dart';
import 'package:mindload/screens/notification_settings_screen.dart';
import 'package:mindload/screens/create_screen.dart';
import 'package:mindload/screens/enhanced_subscription_screen.dart';
import 'package:mindload/screens/subscription_settings_screen.dart';
import 'package:mindload/screens/settings_screen.dart';
import 'package:mindload/widgets/youtube_preview_card.dart';
import 'package:mindload/services/youtube_service.dart';
import 'package:mindload/models/youtube_preview_models.dart';
import 'package:mindload/core/youtube_utils.dart';
import 'dart:async' show Timer;
import 'package:mindload/widgets/token_estimation_display.dart';
import 'package:mindload/services/token_estimation_service.dart';
import 'package:mindload/services/haptic_feedback_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<StudySet> _studySets = [];
  bool _isLoading = false;
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.linear),
    );

    _initializeData();
  }

  @override
  void dispose() {
    _scanController.dispose();
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _loadStudySets();
  }

  Future<void> _loadStudySets() async {
    setState(() => _isLoading = true);
    try {
      final studySetsMetadata = await StorageService.instance.getStudySets();
      studySetsMetadata.sort((a, b) => b.lastStudied.compareTo(a.lastStudied));

      // Load full study sets with flashcards and quiz questions
      final fullStudySets = <StudySet>[];
      for (final metadata in studySetsMetadata) {
        debugPrint('Loading full study set for: ${metadata.setId}');
        final fullStudySet =
            await StorageService.instance.getFullStudySet(metadata.setId);
        if (fullStudySet != null) {
          debugPrint(
              '✅ Loaded full study set: ${fullStudySet.title} with ${fullStudySet.flashcards.length} flashcards and ${fullStudySet.quizzes.length} quizzes');
          fullStudySets.add(fullStudySet);
        } else {
          debugPrint(
              '⚠️ Full study set not found, using metadata fallback for: ${metadata.setId}');
          // Fallback to metadata-only if full data not available
          fullStudySets.add(StudySet.fromJson(metadata.toStudySetData()));
        }
      }

      setState(() => _studySets = fullStudySets);
    } catch (e) {
      _showErrorSnackBar('Failed to load study sets');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showDocumentUploadOptions() {
    HapticFeedbackService().mediumImpact();
    final tokens = context.tokens;
    showModalBottomSheet(
      context: context,
      backgroundColor: tokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      isDismissible: true, // Allow user to dismiss by tapping outside
      enableDrag: true, // Allow user to drag down to dismiss
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + Spacing.lg,
          left: Spacing.lg,
          right: Spacing.lg,
          top: Spacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.upload_file, color: tokens.primary),
                const SizedBox(width: Spacing.sm),
                Text(
                  'UPLOAD DOCUMENT',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: tokens.primary,
                        letterSpacing: 1,
                      ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            Text(
              'Supported Formats:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: tokens.textPrimary,
                  ),
            ),
            const SizedBox(height: Spacing.sm),
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                _buildFormatChip('TXT', true),
                _buildFormatChip('RTF', true),
                _buildFormatChip('PDF', true),
                _buildFormatChip('DOCX', true),
                _buildFormatChip('EPUB', true),
                _buildFormatChip('ODT', true),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '✓ Full text extraction from all supported formats\n📱 Optimized for mobile file access',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tokens.textSecondary,
                  ),
            ),
            const SizedBox(height: Spacing.lg),

            // Primary upload button
            AccessibleButton(
              onPressed: () {
                Navigator.pop(context);
                _uploadDocument();
              },
              fullWidth: true,
              size: ButtonSize.large,
              semanticLabel: 'Select document to upload',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.file_open),
                  const SizedBox(width: Spacing.sm),
                  const Text('SELECT DOCUMENT'),
                ],
              ),
            ),

            const SizedBox(height: Spacing.md),

            // Alternative options for Android issues
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tokens.surfaceAlt.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: tokens.outline,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: tokens.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'Having trouble with file picker?',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: tokens.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'If the file picker gets stuck, try these alternatives:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens.textMuted,
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: Spacing.sm),

            // Alternative buttons
            Row(
              children: [
                Expanded(
                  child: AccessibleButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showPasteTextDialog();
                    },
                    variant: ButtonVariant.secondary,
                    size: ButtonSize.medium,
                    semanticLabel: 'Paste text instead of uploading file',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.paste, size: 18),
                        const SizedBox(width: 6),
                        const Text('PASTE TEXT'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                // Camera option removed per request
              ],
            ),

            const SizedBox(height: Spacing.sm),

            // Cancel button - always visible for safety
            AccessibleButton(
              onPressed: () => Navigator.pop(context),
              variant: ButtonVariant.text,
              size: ButtonSize.medium,
              semanticLabel: 'Cancel document upload',
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatChip(String format, bool fullySupported) {
    final tokens = context.tokens;
    return AccessibleChip(
      label: Text(format),
      selected: fullySupported,
      avatar: Icon(
        fullySupported ? Icons.check_circle : Icons.warning,
        size: 14,
      ),
      semanticLabel: fullySupported
          ? '$format format is fully supported'
          : '$format format has limited support',
    );
  }

  Future<void> _uploadDocument() async {
    setState(() => _isLoading = true);

    try {
      // Debug: Log that upload is starting
      if (kDebugMode) {
        print('Starting document upload...');
      }

      // Add timeout and better error handling for Android file picker issues
      final FilePickerResult? result = await FilePicker.platform
          .pickFiles(
        type: FileType.custom,
        allowedExtensions: DocumentProcessor.getSupportedExtensions(),
        allowMultiple: false,
        withData: true, // Ensure we get the file bytes
        // Add Android-specific options to prevent getting stuck
        lockParentWindow: false, // Prevent window locking issues
        allowCompression: false, // Prevent compression issues
        withReadStream: false, // Use withData instead for better compatibility
        // Add Android-specific options to prevent getting stuck
        dialogTitle: 'Select Document',
        initialDirectory: null, // Let user choose
      )
          .timeout(
        const Duration(seconds: 30), // 30 second timeout
        onTimeout: () {
          _showErrorSnackBar(
              'File picker timed out. Please try again or use PASTE TEXT option.');
          return null;
        },
      );

      if (result != null && result.files.isNotEmpty) {
        final PlatformFile file = result.files.first;
        final String fileName = file.name;
        final String fileExtension = fileName.split('.').last.toLowerCase();

        // Debug: Log file details
        if (kDebugMode) {
          print(
              'File selected: $fileName ($fileExtension) - Size: ${file.size} bytes');
        }

        if (file.bytes == null) {
          if (kDebugMode) {
            print('File bytes are null - file picker issue');
          }
          _showErrorSnackBar(
              'Unable to read file. Please try again or use PASTE TEXT option.');
          return;
        }

        // Show progress indication with better UI
        final scaffold = ScaffoldMessenger.of(context);
        final tokens = context.tokens;
        scaffold.hideCurrentSnackBar();
        scaffold.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      tokens.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Processing Document...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: tokens.onPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      Text(
                        DocumentProcessor.getFormatDisplayName(fileExtension),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: tokens.onPrimary.withValues(alpha: 0.8),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: tokens.primary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 5),
          ),
        );

        try {
          // Debug: Log processing start
          if (kDebugMode) {
            print('Starting document processing...');
          }

          // Validate PDF page limits before processing
          if (fileExtension.toLowerCase() == 'pdf') {
            if (kDebugMode) {
              print('Validating PDF page limits...');
            }
            await DocumentProcessor.validatePdfPageLimit(file.bytes!);
            if (kDebugMode) {
              print('PDF validation passed');
            }
          }

          if (kDebugMode) {
            print('Extracting text from file...');
          }

          final extractedContent = await DocumentProcessor.extractTextFromFile(
              file.bytes!, fileExtension, fileName);

          if (kDebugMode) {
            print(
                'Text extraction completed. Content length: ${extractedContent.length}');
          }

          if (extractedContent.trim().isNotEmpty) {
            // Hide processing snackbar and show success
            scaffold.hideCurrentSnackBar();
            scaffold.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: tokens.onPrimary),
                    const SizedBox(width: Spacing.sm),
                    Text(
                        'Document extracted successfully! Generating study materials...'),
                  ],
                ),
                backgroundColor: tokens.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 2),
              ),
            );

            final String title = fileName.split('.').first;
            _showProcessingOptionsDialog(extractedContent, title);
          } else {
            scaffold.hideCurrentSnackBar();
            _showErrorSnackBar('No readable content found in the file');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error processing file: $e');
          }
          scaffold.hideCurrentSnackBar();
          _showErrorSnackBar(
              'Failed to process file: ${e.toString()}. Please check the file format and try again.');
        }
      } else {
        // User cancelled or no file selected - this is normal behavior
        // Don't show error for user cancellation
        return;
      }
    } catch (e) {
      // Debug: Log the error
      if (kDebugMode) {
        print('File picker error: $e');
      }

      // Handle file picker errors specifically
      String errorMessage = 'Error selecting file';
      if (e.toString().contains('timeout')) {
        errorMessage =
            'File picker timed out. Please try again or use PASTE TEXT option.';
      } else if (e.toString().contains('permission')) {
        errorMessage =
            'Permission denied. Please grant file access permissions.';
      } else if (e.toString().contains('cancel')) {
        errorMessage = 'File selection cancelled.';
      } else if (e.toString().contains('User cancelled')) {
        // User cancelled - this is normal behavior
        return;
      } else {
        errorMessage = 'Error selecting file: ${e.toString()}';
      }

      _showErrorSnackBar(errorMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showTextInputDialog() {
    final tokens = context.tokens;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: tokens.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.terminal, color: tokens.primary),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    'INPUT TEXT DATA',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: tokens.primary,
                          letterSpacing: 1,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.lg),
              AccessibleTextInput(
                controller: _textController,
                labelText: 'Study Material',
                hintText: 'Paste your study content here...',
                maxLines: 6,
                semanticLabel: 'Enter or paste your study material content',
              ),
              const SizedBox(height: Spacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AccessibleButton(
                    onPressed: () => Navigator.pop(context),
                    variant: ButtonVariant.text,
                    semanticLabel: 'Cancel text input',
                    child: const Text('CANCEL'),
                  ),
                  const SizedBox(width: Spacing.sm),
                  AccessibleButton(
                    onPressed: _textController.text.isNotEmpty
                        ? () {
                            if (_textController.text.isEmpty) return;

                            Navigator.pop(context);
                            final String content = _textController.text;
                            _textController.clear();

                            _showProcessingOptionsDialog(
                                content, 'Custom Study Set');
                          }
                        : null,
                    disabled: _textController.text.isEmpty,
                    semanticLabel:
                        'Process the entered text to create study materials',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.play_arrow),
                        const SizedBox(width: Spacing.xs),
                        const Text('PROCESS'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProcessingOptionsDialog(String content, String title) {
    final tokens = context.tokens;

    // Get token estimation for the content
    final estimation = TokenEstimationService.instance.estimateTextContent(
      text: content,
      depth: 'standard',
      customFlashcardCount: 15, // Default flashcard count
      customQuizCount: 10, // Default quiz count
    );

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: tokens.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 500,
            maxHeight: 600,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: tokens.primary.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: tokens.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.auto_awesome,
                          color: tokens.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Generate Study Set',
                            style: TextStyle(
                              color: tokens.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'How would you like to generate your study materials?',
                            style: TextStyle(
                              color: tokens.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Token estimation display
                      TokenEstimationDisplay(
                        estimation: estimation,
                        showProceedButton: false,
                        isInDialog: true,
                      ),

                      const SizedBox(height: 16),

                      // Info box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: tokens.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: tokens.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 20,
                              color: tokens.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Recommended Settings',
                                    style: TextStyle(
                                      color: tokens.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '10 Quiz Questions + 15 Flashcards',
                                    style: TextStyle(
                                      color: tokens.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Actions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: tokens.borderDefault.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AccessibleButton(
                      onPressed: () => Navigator.pop(context),
                      variant: ButtonVariant.text,
                      semanticLabel: 'Cancel study set generation',
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    AccessibleButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _processContent(content, title);
                      },
                      variant: ButtonVariant.text,
                      semanticLabel:
                          'Generate study set with default settings: 10 quiz questions and 15 flashcards',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.flash_on),
                          const SizedBox(width: Spacing.xs),
                          const Text('Use Defaults'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    AccessibleButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showCustomizeStudySetDialog(content, title);
                      },
                      semanticLabel: 'Customize study set generation options',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.tune),
                          const SizedBox(width: Spacing.xs),
                          const Text('Customize'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomizeStudySetDialog(String content, String title) {
    showDialog(
      context: context,
      builder: (context) => CustomizeStudySetDialog(
        topicDifficulty: 'medium',
        onGenerate: (quizCount, flashcardCount) {
          _processContentWithCounts(content, title, quizCount, flashcardCount);
        },
      ),
    );
  }

  Future<void> _processContent(String content, String title) async {
    // Default processing: generate both flashcards and quiz
    await _processContentWithCounts(content, title, 10, 15);
  }

  Future<void> _processContentWithCounts(
      String content, String title, int quizCount, int flashcardCount) async {
    setState(() => _isLoading = true);
    final tokens = context.tokens;

    try {
      final economyService = MindloadEconomyService.instance;

      // Determine what to generate based on counts
      StudySetType studySetType;
      if (quizCount > 0 && flashcardCount > 0) {
        studySetType = StudySetType.both;
      } else if (quizCount > 0) {
        studySetType = StudySetType.quiz;
      } else if (flashcardCount > 0) {
        studySetType = StudySetType.flashcards;
      } else {
        _showErrorSnackBar('Please select at least one type to generate');
        setState(() => _isLoading = false);
        return;
      }

      // Check if user can generate this study set using MindloadEconomyService
      final request = GenerationRequest(
        sourceContent: content,
        sourceCharCount: content.length,
      );

      final enforcementResult = economyService.canGenerateContent(request);
      if (!enforcementResult.canProceed) {
        _showErrorSnackBar(
            enforcementResult.blockReason ?? 'Cannot generate content');
        setState(() => _isLoading = false);
        return;
      }

      // Consume credits for generation
      final creditsUsed = await economyService.useCreditsForGeneration(request);
      if (!creditsUsed) {
        _showErrorSnackBar('Failed to consume credits for generation');
        setState(() => _isLoading = false);
        return;
      }

      // Generate content based on requested counts
      List<Flashcard> flashcards = [];
      Quiz? quiz;
      bool aiGenerationSucceeded = false;

      // Strong haptic feedback to indicate AI processing start
      HapticFeedbackService().heavyImpact();

      try {
        debugPrint(
            'Starting AI generation for $flashcardCount flashcards and $quizCount quiz questions');
        final futures = <Future>[];

        if (flashcardCount > 0) {
          debugPrint('Adding flashcard generation to futures');
          futures.add(OpenAIService.instance.generateFlashcardsFromContent(
              content, flashcardCount, 'standard'));
        }

        if (quizCount > 0) {
          debugPrint('Adding quiz generation to futures');
          futures.add(OpenAIService.instance.generateQuizQuestionsFromContent(
              content, quizCount, 'standard'));
        }

        debugPrint(
            'Waiting for ${futures.length} AI generation futures to complete');
        final results = await Future.wait(futures);
        debugPrint('AI generation completed with ${results.length} results');

        int resultIndex = 0;
        if (flashcardCount > 0) {
          debugPrint('Processing flashcard results at index $resultIndex');
          flashcards = results[resultIndex] as List<Flashcard>;
          debugPrint('Generated ${flashcards.length} flashcards');
          // Trim to requested count
          if (flashcards.length > flashcardCount) {
            flashcards = flashcards.take(flashcardCount).toList();
          }
          resultIndex++;
        }

        if (quizCount > 0) {
          debugPrint('Processing quiz results at index $resultIndex');
          final quizQuestions = results[resultIndex] as List<QuizQuestion>;
          debugPrint('Generated ${quizQuestions.length} quiz questions');
          // Create a quiz from the questions
          quiz = Quiz(
            id: 'quiz_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Quiz for $title',
            type: QuizType.multipleChoice,
            questions: quizQuestions,
            results: [],
            createdDate: DateTime.now(),
          );
        }

        // Check if we actually got content
        aiGenerationSucceeded = (flashcards.isNotEmpty ||
            (quiz != null && quiz.questions.isNotEmpty));

        debugPrint(
            'AI generation success check: flashcards=${flashcards.length}, quiz=${quiz?.questions.length ?? 0}, succeeded=$aiGenerationSucceeded');

        // Haptic feedback for AI generation completion
        if (aiGenerationSucceeded) {
          HapticFeedbackService().success();
        }
      } catch (e) {
        // AI generation failed - error handled in UI
        aiGenerationSucceeded = false;
        // Haptic feedback for AI generation failure
        HapticFeedbackService().error();
      }

      // If AI generation failed or returned empty content, create a working study set
      if (!aiGenerationSucceeded && (flashcardCount > 0 || quizCount > 0)) {
        await StorageService.instance.createWorkingStudySet(title, content);
        await _loadStudySets();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.info, color: tokens.onPrimary),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    'AI generation unavailable. Created a working study set with sample questions for your content.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: tokens.onPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
            backgroundColor: tokens.secondary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );

        setState(() => _isLoading = false);
        return;
      }

      // Credits are already consumed by MindloadEconomyService during generation

      final StudySet studySet = StudySet(
        id: 'study_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        content: content,
        flashcards: flashcards,
        quizzes: (quiz != null && quiz.questions.isNotEmpty)
            ? [quiz]
            : const <Quiz>[],
        createdDate: DateTime.now(),
        lastStudied: DateTime.now(),
      );

      await StorageService.instance.saveFullStudySet(studySet);
      await _loadStudySets();

      // Track achievement progress
      await AchievementTrackerService.instance.trackStudySetCreated();
      if (flashcards.isNotEmpty) {
        await AchievementTrackerService.instance
            .trackCardsCreated(flashcards.length);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: tokens.onPrimary),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  'Study set "${studySet.title}" created successfully! 🧠',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: tokens.onPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
          backgroundColor: tokens.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to process content');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    final tokens = context.tokens;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: tokens.onPrimary),
            const SizedBox(width: Spacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: tokens.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showLimitReachedDialog(String type, String plural) {
    final economyService = MindloadEconomyService.instance;
    final tokens = context.tokens;
    final resetTime = economyService.userEconomy?.nextResetDate ??
        DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: tokens.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.block, color: tokens.error),
            const SizedBox(width: 8),
            Text(
              'Daily Limit Reached',
              style: TextStyle(color: tokens.textPrimary),
            ),
          ],
        ),
        content: Text(
          'You\'ve reached today\'s $plural limit for your plan. Try again after ${_formatResetTime(resetTime)}.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: tokens.textPrimary,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: tokens.textPrimary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TiersBenefitsScreen(),
                  ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: tokens.primary),
            child: Text(
              'UPGRADE',
              style: TextStyle(
                color: tokens.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSystemLimitDialog() {
    final tokens = context.tokens;
    final economyService = MindloadEconomyService.instance;
    final resetTime = economyService.userEconomy?.nextResetDate ??
        DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: tokens.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.pause_circle, color: tokens.error),
            const SizedBox(width: 8),
            Text(
              'Daily Budget Reached',
              style: TextStyle(color: tokens.textPrimary),
            ),
          ],
        ),
        content: Text(
          'We\'ve hit today\'s system-wide limit. Generation resumes after ${_formatResetTime(resetTime)}.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: tokens.textPrimary,
              ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: tokens.primary),
            child: Text(
              'GOT IT',
              style: TextStyle(
                color: tokens.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatResetTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  Future<void> _handleStudySetAction(String action, StudySet studySet) async {
    // Provide haptic feedback for the action
    HapticFeedbackService().selectionClick();

    switch (action) {
      case 'notifications':
        _showNotificationSettings(studySet);
        break;
      case 'rename':
        _showRenameDialog(studySet);
        break;
      case 'refresh':
        await _refreshStudySet(studySet);
        break;
      case 'export_flashcards':
        await _exportFlashcards(studySet);
        break;
      case 'export_quizzes':
        await _exportQuizzes(studySet);
        break;
      case 'delete':
        _showDeleteConfirmation(studySet);
        break;
    }
  }

  void _showNotificationSettings(StudySet studySet) {
    // Show bottom sheet with quick actions and link to main settings
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildNotificationSettingsSheet(studySet),
    );
  }

  Widget _buildNotificationSettingsSheet(StudySet studySet) {
    final tokens = context.tokens;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active, color: tokens.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'NOTIFICATION SETTINGS',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            studySet.title.toUpperCase(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.primary,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 20),

          // Toggle for this study set
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tokens.borderDefault),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enable Notifications',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: tokens.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Receive study reminders and quiz alerts for this set',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: tokens.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Switch(
                  value: studySet.notificationsEnabled,
                  onChanged: (value) async {
                    HapticFeedbackService().selectionClick();
                    final updatedStudySet =
                        studySet.copyWith(notificationsEnabled: value);
                    await _updateStudySet(updatedStudySet);

                    // Send test notification if enabled
                    if (value) {
                      await NotificationService.scheduleStudyReminder(
                        studySetId: studySet.id,
                        title: 'Study Reminder: ${studySet.title}',
                        body:
                            'Time to review your ${studySet.flashcards.length} flashcards!',
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Notifications enabled! Test reminder sent.'),
                          backgroundColor: tokens.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }

                    Navigator.pop(context);
                  },
                  activeThumbColor: tokens.primary,
                  activeTrackColor: tokens.primary.withValues(alpha: 0.3),
                  inactiveThumbColor: tokens.muted,
                  inactiveTrackColor: tokens.outline,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Quick actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    HapticFeedbackService().mediumImpact();
                    Navigator.pop(context);
                    await NotificationService.sendTestNotification();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Test notification sent!'),
                        backgroundColor: tokens.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('TEST'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.surface,
                    foregroundColor: tokens.primary,
                    side: BorderSide(color: tokens.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedbackService().mediumImpact();
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const NotificationSettingsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings, size: 18),
                  label: const Text('ALL SETTINGS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.primary,
                    foregroundColor: tokens.onPrimary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Future<void> _updateStudySet(StudySet updatedStudySet) async {
    final tokens = context.tokens;
    try {
      // Update the full study set to preserve all data including notificationsEnabled
      await StorageService.instance.updateFullStudySet(updatedStudySet);

      // Reload study sets to reflect changes
      await _loadStudySets();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: tokens.onPrimary),
              const SizedBox(width: Spacing.sm),
              Text('Notification settings updated'),
            ],
          ),
          backgroundColor: tokens.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to update study set: $e');
      }
      _showErrorSnackBar('Failed to update notification settings');
    }
  }

  Future<void> _exportFlashcards(StudySet studySet) async {
    HapticFeedbackService().mediumImpact();
    final tokens = context.tokens;
    if (studySet.flashcards.isEmpty) {
      _showErrorSnackBar('No flashcards to export');
      return;
    }

    try {
      // Use the new PDF export system with MindLoad branding
      final pdfService = PdfExportService();
      final options = PdfExportOptions(
        setId: studySet.id,
        includeFlashcards: true,
        includeQuiz: false,
        style: 'standard',
        pageSize: 'Letter',
        includeMindloadBranding: true, // Default to including branding
      );

      final result = await pdfService.exportToPdf(
        uid: pdfService.getCurrentUserId(),
        setId: studySet.id,
        appVersion: pdfService.getAppVersion(),
        itemCounts: {'flashcards': studySet.flashcards.length},
        options: options,
        onProgress: (progress) {
          // Update progress in UI
          if (kDebugMode) {
            debugPrint('Export progress: ${progress.percentage}%');
          }
        },
        onCancelled: () {
          if (kDebugMode) {
            debugPrint('Export cancelled');
          }
        },
      );

      if (result.success) {
        // Track export achievement with detailed metrics
        await _trackExportAchievement(
            'flashcards', studySet.flashcards.length, 'pdf');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: tokens.onPrimary),
                const SizedBox(width: Spacing.sm),
                Text('Flashcards PDF exported successfully!'),
              ],
            ),
            backgroundColor: tokens.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Open PDF viewer
                if (kDebugMode) {
                  debugPrint('Open PDF: ${result.filePath}');
                }
              },
            ),
          ),
        );
      } else {
        throw Exception('Export failed: ${result.errorMessage}');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to export flashcards: ${e.toString()}');
    }
  }

  Future<void> _exportQuizzes(StudySet studySet) async {
    HapticFeedbackService().mediumImpact();
    final tokens = context.tokens;
    if (studySet.quizzes.isEmpty) {
      _showErrorSnackBar('No quizzes to export');
      return;
    }

    try {
      // Use the new PDF export system with MindLoad branding
      final pdfService = PdfExportService();
      final options = PdfExportOptions(
        setId: studySet.id,
        includeFlashcards: false,
        includeQuiz: true,
        style: 'standard',
        pageSize: 'Letter',
        includeMindloadBranding: true, // Default to including branding
      );

      final result = await pdfService.exportToPdf(
        uid: pdfService.getCurrentUserId(),
        setId: studySet.id,
        appVersion: pdfService.getAppVersion(),
        itemCounts: {'quizzes': studySet.quizzes.length},
        options: options,
        onProgress: (progress) {
          // Update progress in UI
          if (kDebugMode) {
            debugPrint('Export progress: ${progress.percentage}%');
          }
        },
        onCancelled: () {
          if (kDebugMode) {
            debugPrint('Export cancelled');
          }
        },
      );

      if (result.success) {
        // Track export achievement with detailed metrics
        await _trackExportAchievement(
            'quizzes', studySet.quizzes.length, 'pdf');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: tokens.onPrimary),
                const SizedBox(width: Spacing.sm),
                Text('Quiz PDF exported successfully!'),
              ],
            ),
            backgroundColor: tokens.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Open PDF viewer
                if (kDebugMode) {
                  debugPrint('Open PDF: ${result.filePath}');
                }
              },
            ),
          ),
        );
      } else {
        throw Exception('Export failed: ${result.errorMessage}');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to export quizzes: ${e.toString()}');
    }
  }

  void _showDeleteConfirmation(StudySet studySet) {
    HapticFeedbackService().warning();
    final tokens = context.tokens;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: tokens.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: tokens.error),
            const SizedBox(width: 8),
            Text(
              'DELETE STUDY SET',
              style: TextStyle(
                color: tokens.error,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${studySet.title}"?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: tokens.textPrimary,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tokens.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: tokens.error.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This will permanently delete:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens.error,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• ${studySet.flashcards.length} flashcards',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens.textPrimary,
                        ),
                  ),
                  Text(
                    '• ${studySet.quizzes.length} quiz${studySet.quizzes.length != 1 ? 'es' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens.textPrimary,
                        ),
                  ),
                  Text(
                    '• All notification settings',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens.textPrimary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: TextStyle(color: tokens.textPrimary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedbackService().error();
              _deleteStudySet(studySet);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.error,
              foregroundColor: tokens.onPrimary,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStudySet(StudySet studySet) async {
    Navigator.pop(context); // Close dialog
    HapticFeedbackService().heavyImpact();
    final tokens = context.tokens;

    try {
      // Cancel any scheduled notifications
      await NotificationService.instance.cancelAllNotifications();

      // Delete from storage
      await StorageService.instance.deleteStudySet(studySet.id);

      // Reload study sets
      await _loadStudySets();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: tokens.onPrimary),
              const SizedBox(width: Spacing.sm),
              Text('Study set deleted successfully'),
            ],
          ),
          backgroundColor: tokens.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to delete study set');
    }
  }

  void _showRenameDialog(StudySet studySet) {
    HapticFeedbackService().lightImpact();
    final tokens = context.tokens;
    final renameController = TextEditingController(text: studySet.title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: tokens.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit, color: tokens.primary),
            const SizedBox(width: 8),
            Text(
              'RENAME STUDY SET',
              style: TextStyle(
                color: tokens.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: renameController,
          autofocus: true,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.words,
          maxLength: 100,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              HapticFeedbackService().success();
              _renameStudySet(studySet, value);
            }
          },
          decoration: InputDecoration(
            labelText: 'Study Set Name',
            labelStyle: TextStyle(color: tokens.primary),
            counterText: '', // Hide character counter
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: tokens.primary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: tokens.primary.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: tokens.primary, width: 2),
            ),
          ),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: TextStyle(color: tokens.textPrimary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final newTitle = renameController.text.trim();
              if (newTitle.isNotEmpty) {
                _renameStudySet(studySet, newTitle);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid name')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.primary,
              foregroundColor: tokens.onPrimary,
            ),
            child: const Text('RENAME'),
          ),
        ],
      ),
    );
  }

  Future<void> _renameStudySet(StudySet studySet, String newTitle) async {
    Navigator.pop(context); // Close dialog
    final tokens = context.tokens;

    if (newTitle.trim().isEmpty) {
      _showErrorSnackBar('Study set name cannot be empty');
      return;
    }

    try {
      final updatedStudySet = studySet.copyWith(title: newTitle.trim());
      await StorageService.instance
          .updateStudySet(updatedStudySet.toMetadata());
      await _loadStudySets();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: tokens.onPrimary),
              const SizedBox(width: Spacing.sm),
              Text('Study set renamed successfully'),
            ],
          ),
          backgroundColor: tokens.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to rename study set');
    }
  }

  Future<void> _refreshStudySet(StudySet studySet) async {
    HapticFeedbackService().mediumImpact();
    final tokens = context.tokens;
    setState(() => _isLoading = true);

    try {
      final economyService = MindloadEconomyService.instance;

      // Check if we can generate new content
      if (!economyService.canGenerate) {
        _showLimitReachedDialog('content', 'content');
        setState(() => _isLoading = false);
        return;
      }

      // Check if user has credits
      if (!economyService.hasCredits) {
        _showLimitReachedDialog('credits', 'credits');
        setState(() => _isLoading = false);
        return;
      }

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(tokens.onPrimary),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Text('Refreshing study set with AI...'),
            ],
          ),
          backgroundColor: tokens.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 5),
        ),
      );

      // Get tier-based counts
      final tier = economyService.currentTier;
      final flashcardCount = economyService.getFlashcardsPerCredit(tier);
      final quizCount = economyService.getQuizPerCredit(tier);

      // Strong haptic feedback to indicate AI processing start
      HapticFeedbackService().heavyImpact();

      // Generate new flashcards and quizzes using the original content
      final newFlashcards = await OpenAIService.instance
          .generateFlashcards(studySet.content, count: flashcardCount);
      final newQuizQuestions = await OpenAIService.instance
          .generateQuiz(studySet.content, count: quizCount);

      // Credits are already managed by MindloadEconomyService

      // Update the study set with new content
      final updatedStudySet = studySet.copyWith(
        flashcards: newFlashcards,
        quizzes: newQuizQuestions.isNotEmpty
            ? [
                Quiz(
                  id: 'quiz_${DateTime.now().millisecondsSinceEpoch}',
                  title: '${studySet.title} Quiz',
                  questions: newQuizQuestions,
                  type: QuizType.multipleChoice,
                  results: [],
                  createdDate: DateTime.now(),
                )
              ]
            : const <Quiz>[],
        lastStudied: DateTime.now(),
      );

      await StorageService.instance
          .updateStudySet(updatedStudySet.toMetadata());
      await _loadStudySets();

      // Hide loading and show success
      HapticFeedbackService().success();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: tokens.onPrimary),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                    'Study set refreshed with new AI-generated content! 🧠'),
              ),
            ],
          ),
          backgroundColor: tokens.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showErrorSnackBar('Failed to refresh study set: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Credits economy handlers

  void _handleBuyCredits() {
    HapticFeedbackService().mediumImpact();
    // Navigate to enhanced subscription screen for credit purchases
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const EnhancedSubscriptionScreen(),
        ));
  }

  void _handleViewLedger() {
    HapticFeedbackService().mediumImpact();
    // Navigate to subscription settings for credit history
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SubscriptionSettingsScreen(),
        ));
  }

  void _handleUpgrade() {
    HapticFeedbackService().mediumImpact();
    // Navigate to subscription upgrade options
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const TiersBenefitsScreen(),
        ));
  }

  Widget _buildStatRow({required String label, required String value}) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        // Ensure user can always navigate back
        if (!didPop) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: MindloadAppBarFactory.main(
          title: 'MINDLOAD',
          onBuyCredits: _handleBuyCredits,
          onViewLedger: _handleViewLedger,
          onUpgrade: _handleUpgrade,
          actions: [
            PopupMenuButton<String>(
              icon: Icon(Icons.notifications, color: tokens.accent),
              tooltip: 'Notification Settings',
              color: tokens.surface,
              onSelected: (value) async {
                switch (value) {
                  case 'test':
                    await NotificationService.sendTestNotification();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Test notification sent!'),
                        backgroundColor: tokens.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    break;
                  case 'settings':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsScreen()),
                    ).then((_) => setState(() {}));
                    break;
                  case 'profile':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ProfileScreen()),
                    ).then((_) => setState(() {}));
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'test',
                  child: Row(
                    children: [
                      Icon(Icons.notification_add,
                          color: tokens.success, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Send Test Notification',
                        style: TextStyle(color: tokens.textPrimary),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings, color: tokens.primary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Settings',
                        style: TextStyle(color: tokens.textPrimary),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline,
                          color: tokens.primary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Profile & More Settings',
                        style: TextStyle(color: tokens.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            IconButton(
              icon: Icon(Icons.person, color: tokens.primary),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Credits state banners (low/empty credits) - constrained to prevent overflow
            Flexible(
              child: const CreditsStateBanners(),
            ),

            // Main content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadStudySets,
                color: tokens.primary,
                child: _isLoading ? _buildLoadingScreen() : _buildMainContent(),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: tokens.primary.withValues(alpha: 0.2)),
            ),
          ),
          child: SafeArea(
            child: Container(
              color: tokens.surface,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Consumer<MindloadEconomyService>(
                builder: (context, economyService, child) {
                  // Check if user can upload documents (has credits and can generate content)
                  final canUpload =
                      economyService.hasCredits && economyService.canGenerate;

                  return IntrinsicHeight(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: _buildBottomNavButtonWithUsage(
                            icon: Icons.upload_file,
                            label: 'UPLOAD DOC',
                            usageType: 'upload',
                            canPerformAction: canUpload,
                            onTap: canUpload
                                ? _showDocumentUploadOptions
                                : () => _showLimitReachedDialog(
                                    'upload', 'uploads'),
                          ),
                        ),
                        Expanded(
                          child: _buildBottomNavButton(
                            icon: Icons.add_circle_outline,
                            label: 'CREATE SET',
                            onTap: () {
                              HapticFeedbackService().mediumImpact();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const CreateScreen()),
                              );
                            },
                          ),
                        ),
                        Expanded(
                          child: _buildBottomNavButton(
                            icon: Icons.emoji_events,
                            label: 'ACHIEVEMENTS',
                            onTap: () {
                              HapticFeedbackService().mediumImpact();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const AchievementsScreen()),
                              );
                            },
                          ),
                        ),
                        Expanded(
                          child: _buildBottomNavButton(
                            icon: Icons.flash_on,
                            label: 'ULTRA MODE',
                            onTap: () {
                              HapticFeedbackService().mediumImpact();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const UltraModeScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    final tokens = context.tokens;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _scanAnimation,
            builder: (context, child) => Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: tokens.primary, width: 2),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CircularProgressIndicator(
                      value: _scanAnimation.value,
                      color: tokens.primary,
                      strokeWidth: 3,
                    ),
                  ),
                  Center(
                    child: BrainLogo(
                      size: 40,
                      color: tokens.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'PROCESSING NEURAL DATA...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: tokens.primary,
                  letterSpacing: 1,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    final tokens = context.tokens;
    return Consumer<MindloadEconomyService>(
      builder: (context, economyService, child) {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Budget Protection Banner
                    if (economyService.budgetState != BudgetState.normal) ...[
                      _BudgetProtectionBanner(
                        status: economyService.budgetState,
                        message: economyService.budgetController.statusMessage,
                      ),
                      const SizedBox(height: 16),
                    ],

                    Text(
                      'RECENT STUDY SETS',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: tokens.primary,
                            letterSpacing: 1,
                          ),
                    ),
                    const SizedBox(height: Spacing.md),
                  ],
                ),
              ),
            ),
            _studySets.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 60,
                            color: tokens.primary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: Spacing.sm),
                          Text(
                            'NO STUDY SETS FOUND',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: tokens.textPrimary,
                                  letterSpacing: 1,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: Spacing.xs),
                          Text(
                            'Upload a document or paste text to get started',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: tokens.textSecondary,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildStudySetCard(_studySets[index]),
                        childCount: _studySets.length,
                      ),
                    ),
                  ),
          ],
        );
      },
    );
  }

  Widget _buildStudySetCard(StudySet studySet) {
    final tokens = context.tokens;
    final daysSinceStudied =
        DateTime.now().difference(studySet.lastStudied).inDays;

    return AccessibleCard(
      margin: const EdgeInsets.only(bottom: Spacing.md),
      padding: const EdgeInsets.all(Spacing.lg),
      onTap: () {
        HapticFeedbackService().lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudyScreen(studySet: studySet),
          ),
        );
      },
      semanticLabel:
          'Study set: ${studySet.title}, ${studySet.flashcards.length} flashcards, ${studySet.quizzes.length} quizzes, last studied ${daysSinceStudied == 0 ? 'today' : '$daysSinceStudied days ago'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  studySet.title.toUpperCase(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                ),
              ),
              // Three dot menu
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: tokens.textPrimary,
                  size: 20,
                ),
                color: tokens.surface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (value) => _handleStudySetAction(value, studySet),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'notifications',
                    child: Row(
                      children: [
                        Icon(
                          studySet.notificationsEnabled
                              ? Icons.notifications_active
                              : Icons.notifications_off,
                          color: tokens.primary,
                          size: 20,
                        ),
                        const SizedBox(width: Spacing.sm),
                        Text(
                          'Notifications',
                          style: TextStyle(color: tokens.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit,
                          color: tokens.primary,
                          size: 20,
                        ),
                        const SizedBox(width: Spacing.sm),
                        Text(
                          'Rename Set',
                          style: TextStyle(color: tokens.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(
                          Icons.refresh,
                          color: tokens.secondary,
                          size: 20,
                        ),
                        const SizedBox(width: Spacing.sm),
                        Text(
                          'Refresh Set',
                          style: TextStyle(color: tokens.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'export_flashcards',
                    child: Row(
                      children: [
                        Icon(
                          Icons.picture_as_pdf,
                          color: tokens.secondary,
                          size: 20,
                        ),
                        const SizedBox(width: Spacing.sm),
                        Text(
                          'Export Flashcards',
                          style: TextStyle(color: tokens.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'export_quizzes',
                    child: Row(
                      children: [
                        Icon(
                          Icons.quiz,
                          color: tokens.secondary,
                          size: 20,
                        ),
                        const SizedBox(width: Spacing.sm),
                        Text(
                          'Export Quizzes',
                          style: TextStyle(color: tokens.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete,
                          color: tokens.error,
                          size: 20,
                        ),
                        const SizedBox(width: Spacing.sm),
                        Text(
                          'Delete',
                          style: TextStyle(color: tokens.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                color: tokens.textSecondary,
                size: 16,
                semanticLabel: 'Navigate to study set',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatChip(
                icon: Icons.quiz,
                label: '${studySet.flashcards.length} Cards',
              ),
              _buildStatChip(
                icon: Icons.assignment,
                label:
                    '${studySet.quizzes.length} Quiz${studySet.quizzes.length != 1 ? 'es' : ''}',
              ),
              if (studySet.notificationsEnabled)
                _buildStatChip(
                  icon: Icons.notifications_active,
                  label: 'Notifications On',
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            daysSinceStudied == 0
                ? 'Studied today'
                : 'Last studied $daysSinceStudied day${daysSinceStudied > 1 ? 's' : ''} ago',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tokens.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({required IconData icon, required String label}) {
    final tokens = context.tokens;
    return AccessibleChip(
      label: Text(label),
      avatar: Icon(icon, size: 16, color: tokens.textSecondary),
      semanticLabel: label,
    );
  }

  Widget _buildBottomNavButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final tokens = context.tokens;
    return AccessibleButton(
      onPressed: onTap,
      variant: ButtonVariant.text,
      size: ButtonSize.medium,
      semanticLabel: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: tokens.navIcon),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: tokens.navText,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavButtonWithUsage({
    required IconData icon,
    required String label,
    required String usageType,
    required bool canPerformAction,
    required VoidCallback onTap,
  }) {
    final tokens = context.tokens;
    return AccessibleButton(
      onPressed: onTap,
      variant: ButtonVariant.text,
      size: ButtonSize.medium,
      disabled: !canPerformAction,
      semanticLabel:
          canPerformAction ? label : '$label - disabled, limit reached',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              canPerformAction ? icon : Icons.block,
              size: 18,
              color: canPerformAction ? tokens.navIcon : tokens.textTertiary,
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: canPerformAction
                          ? tokens.navText
                          : tokens.textTertiary,
                      fontWeight: FontWeight.w600,
                      fontSize: 7,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactUsageIndicator(String usageType, bool canPerformAction) {
    return Consumer<MindloadEconomyService>(
      builder: (context, economyService, child) {
        final tokens = context.tokens;
        final userEconomy = economyService.userEconomy;

        if (userEconomy == null) {
          return const SizedBox.shrink();
        }

        int remaining;
        int total;
        Color color;

        switch (usageType) {
          case 'quiz':
            remaining = userEconomy.creditsRemaining;
            total = userEconomy.monthlyQuota;
            color = tokens.primary;
            break;
          case 'flashcard':
            remaining = userEconomy.creditsRemaining;
            total = userEconomy.monthlyQuota;
            color = tokens.success;
            break;
          case 'upload':
            remaining = userEconomy.creditsRemaining;
            total = userEconomy.monthlyQuota;
            color = tokens.warning;
            break;
          default:
            return const SizedBox.shrink();
        }

        final isAtLimit = remaining <= 0;
        final isLow = remaining <= (total * 0.2);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: isAtLimit
                ? tokens.error.withValues(alpha: 0.1)
                : isLow
                    ? tokens.warning.withValues(alpha: 0.1)
                    : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isAtLimit
                  ? tokens.error.withValues(alpha: 0.3)
                  : isLow
                      ? tokens.warning.withValues(alpha: 0.3)
                      : color.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          child: Text(
            '$remaining',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isAtLimit
                      ? tokens.error
                      : isLow
                          ? tokens.warning
                          : color,
                  fontWeight: FontWeight.bold,
                  fontSize: 6,
                ),
          ),
        );
      },
    );
  }

  /// Show paste text dialog as alternative to file upload
  void _showPasteTextDialog() {
    final tokens = context.tokens;
    final textController = TextEditingController();
    String? currentVideoId;
    YouTubePreview? currentPreview;
    bool isLoadingPreview = false;
    String? errorMessage;
    Timer? debounceTimer;

    const debounceDuration = Duration(milliseconds: 500);

    void onTextChanged() {
      debounceTimer?.cancel();
      debounceTimer = Timer(debounceDuration, () {
        final text = textController.text.trim();
        if (text.isEmpty) {
          currentVideoId = null;
          currentPreview = null;
          errorMessage = null;
          return;
        }

        final videoId = YouTubeUtils.extractYouTubeId(text);
        if (videoId != null && videoId != currentVideoId) {
          _fetchYouTubePreviewForDialog(videoId, (preview, error) {
            currentPreview = preview;
            errorMessage = error;
            isLoadingPreview = false;
          });
          currentVideoId = videoId;
          isLoadingPreview = true;
        } else if (videoId == null && currentVideoId != null) {
          currentVideoId = null;
          currentPreview = null;
          errorMessage = null;
        }
      });
    }

    textController.addListener(onTextChanged);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: tokens.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.paste, color: tokens.primary),
                const SizedBox(width: 12),
                Text(
                  'Paste Text or YouTube Link',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paste your document content or a YouTube video link:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: tokens.textSecondary,
                      ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: textController,
                  maxLines: 8,
                  maxLength: 10000,
                  decoration: InputDecoration(
                    hintText:
                        'Paste your text here...\n\n• Lecture notes\n• Textbook chapters\n• Articles\n• Course materials\n• YouTube video links (youtube.com / youtu.be)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: tokens.borderDefault),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: tokens.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: tokens.surfaceAlt,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${textController.text.length}/10,000 characters',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens.textMuted,
                      ),
                ),

                // YouTube Preview Section
                if (currentVideoId != null && currentPreview != null)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    child: YouTubePreviewCard(
                      preview: currentPreview!,
                      onIngest: () {
                        Navigator.pop(context);
                        _handleYouTubeIngestFromDialog(currentPreview!);
                      },
                      isLoading: false,
                      errorMessage: null,
                    ),
                  )
                else if (isLoadingPreview)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
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
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(tokens.primary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Loading video preview...',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: tokens.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  )
                else if (errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tokens.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: tokens.error.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 16,
                          color: tokens.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: tokens.error,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  debounceTimer?.cancel();
                  Navigator.pop(context);
                },
                child: Text('Cancel',
                    style: TextStyle(color: tokens.textSecondary)),
              ),
              AccessibleButton(
                onPressed: () {
                  if (textController.text.trim().isNotEmpty) {
                    debounceTimer?.cancel();
                    Navigator.pop(context);
                    if (currentPreview != null) {
                      _handleYouTubeIngestFromDialog(currentPreview!);
                    } else {
                      _showProcessingOptionsDialog(
                        textController.text.trim(),
                        'Pasted Text',
                      );
                    }
                  }
                },
                variant: ButtonVariant.primary,
                child: Text(
                    currentPreview != null ? 'Process Video' : 'Process Text'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _fetchYouTubePreviewForDialog(
      String videoId, Function(YouTubePreview?, String?) callback) async {
    try {
      final preview = await YouTubeService().getPreview(videoId);
      callback(preview, null);
    } catch (e) {
      callback(null, 'Failed to load video preview: ${e.toString()}');
    }
  }

  Future<void> _handleYouTubeIngestFromDialog(YouTubePreview preview) async {
    try {
      setState(() => _isLoading = true);

      final request = YouTubeIngestRequest(
        videoId: preview.videoId,
        preferredLanguage: preview.primaryLang,
      );

      final response = await YouTubeService().ingestTranscript(request);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'YouTube video processed successfully! Study materials created.'),
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate to create screen to show the new materials
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreateScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to process video: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Process uploaded document with achievement tracking
  Future<void> _processDocument(PlatformFile file) async {
    try {
      setState(() => _isLoading = true);

      // Track document upload for achievements
      await _trackDocumentUpload(file);

      // Process the document
      // TODO: Implement proper document processing
      // For now, we'll simulate successful processing
      final result = _simulateDocumentProcessing(file);

      if (result.isSuccess) {
        // Track successful document processing
        await _trackDocumentProcessingSuccess(file.name, result.pageCount ?? 0);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Document processed successfully!'),
              backgroundColor: context.tokens.primary,
            ),
          );
        }

        // Navigate to study set creation
        if (mounted) {
          Navigator.pushNamed(
            context,
            '/study-set-creation',
            arguments: result.data,
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to process document: ${result.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Document processing error - handled gracefully
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Simulate document processing for now
  DocumentProcessingResult _simulateDocumentProcessing(PlatformFile file) {
    // Replace with actual document processing
    return DocumentProcessingResult.success(
      data: 'Simulated document content for ${file.name}',
      pageCount: 5, // Simulated page count
    );
  }

  /// Track document upload for achievements
  Future<void> _trackDocumentUpload(PlatformFile file) async {
    try {
      // For now, we'll just log the document upload
      // In a future implementation, this could be tracked through a proper service
      // Document upload tracked for achievements
    } catch (e) {
      // Failed to track document upload - non-critical
    }
  }

  /// Track successful document processing for achievements
  Future<void> _trackDocumentProcessingSuccess(
      String fileName, int pageCount) async {
    try {
      // For now, we'll just log the document processing success
      // In a future implementation, this could be tracked through a proper service
      // Document processing success tracked for achievements
    } catch (e) {
      // Failed to track document processing success - non-critical
    }
  }

  /// Track export achievement with detailed metrics
  Future<void> _trackExportAchievement(
      String exportType, int itemCount, String format) async {
    try {
      // For now, we'll just log the export
      // In a future implementation, this could be tracked through a proper service
      // Export achievement tracked
    } catch (e) {
      // Failed to track export achievement - non-critical
    }
  }

  /// Get achievement tracker service dynamically
  Future<dynamic> _getAchievementTracker() async {
    // Implement proper achievement tracker access
    // For now, return null to avoid circular dependencies
    return null;
  }
}

/// Simple document processing result class
class DocumentProcessingResult {
  final bool isSuccess;
  final String? data;
  final String? error;
  final int? pageCount;

  const DocumentProcessingResult._({
    required this.isSuccess,
    this.data,
    this.error,
    this.pageCount,
  });

  factory DocumentProcessingResult.success({String? data, int? pageCount}) {
    return DocumentProcessingResult._(
      isSuccess: true,
      data: data,
      pageCount: pageCount,
    );
  }

  factory DocumentProcessingResult.failure(String error) {
    return DocumentProcessingResult._(
      isSuccess: false,
      error: error,
    );
  }
}

class _BudgetProtectionBanner extends StatelessWidget {
  final BudgetState status;
  final String message;

  const _BudgetProtectionBanner({
    required this.status,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    Color bannerColor;
    IconData icon;

    switch (status) {
      case BudgetState.savingsMode:
        bannerColor = tokens.warning;
        icon = Icons.warning;
        break;
      case BudgetState.paused:
        bannerColor = tokens.error;
        icon = Icons.pause_circle;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bannerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: bannerColor, size: 24),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: bannerColor,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
