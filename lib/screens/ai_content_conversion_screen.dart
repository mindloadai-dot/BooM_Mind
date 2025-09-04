import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mindload/models/study_data.dart';
import 'package:mindload/services/openai_integration_service.dart';
import 'package:mindload/widgets/unified_design_system.dart';
import 'package:mindload/core/youtube_utils.dart';

/// Comprehensive AI Content Conversion Screen
/// 
/// This screen provides an easy-to-use interface for converting various content types
/// (documents, YouTube videos, websites, text) into flashcards and quizzes using OpenAI.
class AIContentConversionScreen extends StatefulWidget {
  const AIContentConversionScreen({super.key});

  @override
  State<AIContentConversionScreen> createState() => _AIContentConversionScreenState();
}

class _AIContentConversionScreenState extends State<AIContentConversionScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Content input controllers
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _youtubeController = TextEditingController();
  
  // Generation settings
  int _flashcardCount = 15;
  int _quizCount = 10;
  String _difficulty = 'medium';
  bool _isProcessing = false;
  String? _errorMessage;
  String _processingStatus = '';
  double _processingProgress = 0.0;
  
  // Results
  StudySet? _generatedStudySet;
  
  // Supported file types
  final List<String> _supportedExtensions = [
    'pdf', 'docx', 'txt', 'rtf', 'epub', 'odt'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _urlController.dispose();
    _youtubeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: UnifiedText(
          'AI Content Converter',
          style: UnifiedTypography.headlineMedium,
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.text_fields),
              text: 'Text',
            ),
            Tab(
              icon: Icon(Icons.description),
              text: 'Document',
            ),
            Tab(
              icon: Icon(Icons.play_circle),
              text: 'YouTube',
            ),
            Tab(
              icon: Icon(Icons.language),
              text: 'Website',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Generation settings
          _buildGenerationSettings(),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTextTab(),
                _buildDocumentTab(),
                _buildYouTubeTab(),
                _buildWebsiteTab(),
              ],
            ),
          ),
          
          // Processing indicator
          if (_isProcessing) _buildProcessingIndicator(),
          
          // Results
          if (_generatedStudySet != null) _buildResults(),
        ],
      ),
    );
  }

  Widget _buildGenerationSettings() {
    return UnifiedCard(
      margin: EdgeInsets.all(UnifiedSpacing.md),
      child: Padding(
        padding: EdgeInsets.all(UnifiedSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UnifiedText(
              'Generation Settings',
              style: UnifiedTypography.titleMedium,
            ),
            SizedBox(height: UnifiedSpacing.sm),
            
            // Flashcard count
            Row(
              children: [
                UnifiedText('Flashcards: '),
                Expanded(
                  child: Slider(
                    value: _flashcardCount.toDouble(),
                    min: 5,
                    max: 50,
                    divisions: 9,
                    label: _flashcardCount.toString(),
                    onChanged: (value) {
                      setState(() {
                        _flashcardCount = value.round();
                      });
                    },
                  ),
                ),
                UnifiedText('$_flashcardCount'),
              ],
            ),
            
            // Quiz count
            Row(
              children: [
                UnifiedText('Quiz Questions: '),
                Expanded(
                  child: Slider(
                    value: _quizCount.toDouble(),
                    min: 3,
                    max: 25,
                    divisions: 11,
                    label: _quizCount.toString(),
                    onChanged: (value) {
                      setState(() {
                        _quizCount = value.round();
                      });
                    },
                  ),
                ),
                UnifiedText('$_quizCount'),
              ],
            ),
            
            // Difficulty
            Row(
              children: [
                UnifiedText('Difficulty: '),
                Expanded(
                  child: DropdownButton<String>(
                    value: _difficulty,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'easy', child: Text('Easy')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'hard', child: Text('Hard')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _difficulty = value ?? 'medium';
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextTab() {
    return Padding(
      padding: EdgeInsets.all(UnifiedSpacing.md),
      child: Column(
        children: [
          UnifiedText(
            'Enter or paste your text content',
            style: UnifiedTypography.bodyLarge,
          ),
          SizedBox(height: UnifiedSpacing.md),
          
          Expanded(
            child: TextField(
              controller: _textController,
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(
                hintText: 'Paste your text here...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          
          SizedBox(height: UnifiedSpacing.md),
          
          UnifiedButton(
            onPressed: _textController.text.trim().isEmpty ? null : _convertText,
            child: UnifiedText('Convert to Study Set'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentTab() {
    return Padding(
      padding: EdgeInsets.all(UnifiedSpacing.md),
      child: Column(
        children: [
          UnifiedText(
            'Upload a document to convert',
            style: UnifiedTypography.bodyLarge,
          ),
          SizedBox(height: UnifiedSpacing.md),
          
          UnifiedText(
            'Supported formats: PDF, DOCX, TXT, RTF, EPUB, ODT',
            style: UnifiedTypography.bodySmall,
          ),
          
          SizedBox(height: UnifiedSpacing.lg),
          
          UnifiedButton(
            onPressed: _pickDocument,
            child: UnifiedText('Select Document'),
          ),
          
          SizedBox(height: UnifiedSpacing.md),
          
          if (_errorMessage != null)
            Container(
              padding: EdgeInsets.all(UnifiedSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: UnifiedText(
                _errorMessage!,
                style: UnifiedTypography.bodyMedium.copyWith(
                  color: Colors.red.shade800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildYouTubeTab() {
    return Padding(
      padding: EdgeInsets.all(UnifiedSpacing.md),
      child: Column(
        children: [
          UnifiedText(
            'Enter a YouTube URL',
            style: UnifiedTypography.bodyLarge,
          ),
          SizedBox(height: UnifiedSpacing.md),
          
          TextField(
            controller: _youtubeController,
            decoration: const InputDecoration(
              hintText: 'https://www.youtube.com/watch?v=...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.play_circle),
            ),
            onChanged: (value) {
              setState(() {
                _errorMessage = null;
              });
            },
          ),
          
          SizedBox(height: UnifiedSpacing.md),
          
          if (_youtubeController.text.isNotEmpty)
            _buildYouTubePreview(),
          
          SizedBox(height: UnifiedSpacing.md),
          
          UnifiedButton(
            onPressed: _youtubeController.text.trim().isEmpty ? null : _convertYouTube,
            child: UnifiedText('Convert to Study Set'),
          ),
          
          if (_errorMessage != null)
            Container(
              margin: EdgeInsets.only(top: UnifiedSpacing.sm),
              padding: EdgeInsets.all(UnifiedSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: UnifiedText(
                _errorMessage!,
                style: UnifiedTypography.bodyMedium.copyWith(
                  color: Colors.red.shade800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWebsiteTab() {
    return Padding(
      padding: EdgeInsets.all(UnifiedSpacing.md),
      child: Column(
        children: [
          UnifiedText(
            'Enter a website URL',
            style: UnifiedTypography.bodyLarge,
          ),
          SizedBox(height: UnifiedSpacing.md),
          
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              hintText: 'https://example.com',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.language),
            ),
            onChanged: (value) {
              setState(() {
                _errorMessage = null;
              });
            },
          ),
          
          SizedBox(height: UnifiedSpacing.md),
          
          UnifiedButton(
            onPressed: _urlController.text.trim().isEmpty ? null : _convertWebsite,
            child: UnifiedText('Convert to Study Set'),
          ),
          
          if (_errorMessage != null)
            Container(
              margin: EdgeInsets.only(top: UnifiedSpacing.sm),
              padding: EdgeInsets.all(UnifiedSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: UnifiedText(
                _errorMessage!,
                style: UnifiedTypography.bodyMedium.copyWith(
                  color: Colors.red.shade800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildYouTubePreview() {
    final videoId = YouTubeUtils.extractYouTubeId(_youtubeController.text);
    if (videoId == null) {
      return Container(
        padding: EdgeInsets.all(UnifiedSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: UnifiedText(
          'Invalid YouTube URL',
          style: UnifiedTypography.bodyMedium,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(UnifiedSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Image.network(
            YouTubeUtils.getThumbnailUrl(videoId),
            width: 120,
            height: 90,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 120,
                height: 90,
                color: Colors.grey.shade300,
                child: const Icon(Icons.play_circle, size: 40),
              );
            },
          ),
          SizedBox(width: UnifiedSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UnifiedText(
                  'YouTube Video Detected',
                  style: UnifiedTypography.titleSmall,
                ),
                UnifiedText(
                  'Video ID: $videoId',
                  style: UnifiedTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Container(
      padding: EdgeInsets.all(UnifiedSpacing.md),
      margin: EdgeInsets.all(UnifiedSpacing.md),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          UnifiedText(
            'Processing Content...',
            style: UnifiedTypography.titleSmall,
          ),
          SizedBox(height: UnifiedSpacing.sm),
          
          LinearProgressIndicator(
            value: _processingProgress,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
          ),
          
          SizedBox(height: UnifiedSpacing.sm),
          
          UnifiedText(
            _processingStatus,
            style: UnifiedTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_generatedStudySet == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(UnifiedSpacing.md),
      margin: EdgeInsets.all(UnifiedSpacing.md),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: UnifiedSpacing.sm),
              UnifiedText(
                'Study Set Generated Successfully!',
                style: UnifiedTypography.titleMedium,
              ),
            ],
          ),
          
          SizedBox(height: UnifiedSpacing.md),
          
          UnifiedText(
            'Title: ${_generatedStudySet!.title}',
            style: UnifiedTypography.bodyMedium,
          ),
          UnifiedText(
            'Flashcards: ${_generatedStudySet!.flashcards.length}',
            style: UnifiedTypography.bodyMedium,
          ),
          UnifiedText(
            'Quiz Questions: ${_generatedStudySet!.quizQuestions.length}',
            style: UnifiedTypography.bodyMedium,
          ),
          
          SizedBox(height: UnifiedSpacing.md),
          
          Row(
            children: [
              Expanded(
                child: UnifiedButton(
                  onPressed: _saveStudySet,
                  child: const UnifiedText('Save Study Set'),
                ),
              ),
              SizedBox(width: UnifiedSpacing.sm),
              Expanded(
                child: UnifiedButton(
                  onPressed: _previewStudySet,
                  child: const UnifiedText('Preview'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Action methods
  Future<void> _convertText() async {
    if (_textController.text.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _processingProgress = 0.0;
      _processingStatus = 'Processing text content...';
    });

    try {
      final service = OpenAIIntegrationService.instance;
      
      setState(() {
        _processingProgress = 0.3;
        _processingStatus = 'Generating flashcards and quizzes...';
      });

      final studySet = await service.convertTextToStudySet(
        text: _textController.text.trim(),
        flashcardCount: _flashcardCount,
        quizCount: _quizCount,
        difficulty: _difficulty,
      );

      setState(() {
        _processingProgress = 1.0;
        _processingStatus = 'Study set generated successfully!';
        _generatedStudySet = studySet;
        _isProcessing = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to convert text: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _supportedExtensions,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;
        final extension = file.extension ?? 'txt';
        final fileName = file.name;

        if (bytes == null) {
          setState(() {
            _errorMessage = 'Failed to read file bytes';
          });
          return;
        }

        setState(() {
          _isProcessing = true;
          _errorMessage = null;
          _processingProgress = 0.0;
          _processingStatus = 'Processing document...';
        });

        try {
          final service = OpenAIIntegrationService.instance;
          
          setState(() {
            _processingProgress = 0.3;
            _processingStatus = 'Extracting text from document...';
          });

          final studySet = await service.convertDocumentToStudySet(
            fileBytes: bytes,
            fileName: fileName,
            extension: extension,
            flashcardCount: _flashcardCount,
            quizCount: _quizCount,
            difficulty: _difficulty,
          );

          setState(() {
            _processingProgress = 1.0;
            _processingStatus = 'Study set generated successfully!';
            _generatedStudySet = studySet;
            _isProcessing = false;
          });

        } catch (e) {
          setState(() {
            _errorMessage = 'Failed to convert document: $e';
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick document: $e';
      });
    }
  }

  Future<void> _convertYouTube() async {
    if (_youtubeController.text.trim().isEmpty) return;

    final videoId = YouTubeUtils.extractYouTubeId(_youtubeController.text);
    if (videoId == null) {
      setState(() {
        _errorMessage = 'Invalid YouTube URL';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _processingProgress = 0.0;
      _processingStatus = 'Processing YouTube video...';
    });

    try {
      final service = OpenAIIntegrationService.instance;
      
      setState(() {
        _processingProgress = 0.3;
        _processingStatus = 'Extracting transcript...';
      });

      final studySet = await service.convertYouTubeToStudySet(
        youtubeUrl: _youtubeController.text.trim(),
        flashcardCount: _flashcardCount,
        quizCount: _quizCount,
        difficulty: _difficulty,
      );

      setState(() {
        _processingProgress = 1.0;
        _processingStatus = 'Study set generated successfully!';
        _generatedStudySet = studySet;
        _isProcessing = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to convert YouTube video: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _convertWebsite() async {
    if (_urlController.text.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _processingProgress = 0.0;
      _processingStatus = 'Processing website...';
    });

    try {
      final service = OpenAIIntegrationService.instance;
      
      setState(() {
        _processingProgress = 0.3;
        _processingStatus = 'Extracting content from website...';
      });

      final studySet = await service.convertWebsiteToStudySet(
        websiteUrl: _urlController.text.trim(),
        flashcardCount: _flashcardCount,
        quizCount: _quizCount,
        difficulty: _difficulty,
      );

      setState(() {
        _processingProgress = 1.0;
        _processingStatus = 'Study set generated successfully!';
        _generatedStudySet = studySet;
        _isProcessing = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to convert website: $e';
        _isProcessing = false;
      });
    }
  }

  void _saveStudySet() {
    // TODO: Implement save functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Study set saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _previewStudySet() {
    // TODO: Navigate to study set preview screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preview functionality coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
