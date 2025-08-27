import 'dart:math';
import 'package:mindload/services/mindload_token_service.dart';

/// Comprehensive Token Estimation Service
/// Provides clear pre-processing information for all content types
class TokenEstimationService {
  static final TokenEstimationService _instance =
      TokenEstimationService._internal();
  static TokenEstimationService get instance => _instance;
  TokenEstimationService._internal();

  final MindloadTokenService _tokenService = MindloadTokenService();

  /// Estimate tokens for text content with detailed breakdown
  TokenEstimationResult estimateTextContent({
    required String text,
    required String depth,
    int? customFlashcardCount,
    int? customQuizCount,
  }) {
    final words = text.split(' ').length;
    final chars = text.length;
    final baseTokens = _tokenService.tokensForText(text);

    // Calculate output tokens based on custom counts or defaults
    final flashcardCount = customFlashcardCount ?? 50;
    final quizCount = customQuizCount ?? 30;

    // Estimate output tokens (1 token ≈ 30 quiz Q + 50 flashcards)
    final outputTokens = _estimateOutputTokens(flashcardCount, quizCount);

    // Depth multiplier
    final depthMultiplier = _getDepthMultiplier(depth);
    final totalTokens = (baseTokens * depthMultiplier).ceil();

    return TokenEstimationResult(
      inputType: 'text',
      inputDetails: {
        'words': words,
        'characters': chars,
        'depth': depth,
      },
      baseTokens: baseTokens,
      depthMultiplier: depthMultiplier,
      totalTokens: totalTokens,
      outputEstimate: {
        'flashcards': flashcardCount,
        'quizQuestions': quizCount,
        'outputTokens': outputTokens,
      },
      canProceed: true,
      warnings: _generateWarnings(words, chars, depth),
      costEstimate: _tokenService.getCostEstimate(totalTokens),
    );
  }

  /// Estimate tokens for YouTube content with detailed breakdown
  TokenEstimationResult estimateYouTubeContent({
    required String videoId,
    required int durationSeconds,
    required bool hasCaptions,
    required String depth,
    String? language,
  }) {
    final durationMinutes = durationSeconds / 60;
    final baseTokens = _tokenService.tokensForYouTube(
      durationMinutes: durationMinutes.ceil(),
      hasCaptions: hasCaptions,
      language: language,
    );

    // Depth multiplier
    final depthMultiplier = _getDepthMultiplier(depth);
    final totalTokens = (baseTokens * depthMultiplier).ceil();

    // Estimate output (1 token ≈ 30 quiz Q + 50 flashcards)
    final estimatedOutput = _estimateOutputFromDuration(durationMinutes);

    return TokenEstimationResult(
      inputType: 'youtube',
      inputDetails: {
        'videoId': videoId,
        'durationSeconds': durationSeconds,
        'durationMinutes': durationMinutes,
        'hasCaptions': hasCaptions,
        'language': language ?? 'en',
        'depth': depth,
      },
      baseTokens: baseTokens,
      depthMultiplier: depthMultiplier,
      totalTokens: totalTokens,
      outputEstimate: {
        'flashcards': estimatedOutput['flashcards']!,
        'quizQuestions': estimatedOutput['quizQuestions']!,
        'outputTokens': estimatedOutput['outputTokens']!,
      },
      canProceed: true,
      warnings: _generateYouTubeWarnings(durationMinutes, hasCaptions, depth),
      costEstimate: _tokenService.getCostEstimate(totalTokens),
    );
  }

  /// Estimate tokens for PDF content with detailed breakdown
  TokenEstimationResult estimatePdfContent({
    required int pageCount,
    required int estimatedWordsPerPage,
    required String depth,
    int? customFlashcardCount,
    int? customQuizCount,
  }) {
    final totalWords = pageCount * estimatedWordsPerPage;
    final baseTokens =
        _tokenService.tokensForPdf(pageCount, estimatedWordsPerPage);

    // Calculate output tokens based on custom counts or defaults
    final flashcardCount = customFlashcardCount ?? 50;
    final quizCount = customQuizCount ?? 30;
    final outputTokens = _estimateOutputTokens(flashcardCount, quizCount);

    // Depth multiplier
    final depthMultiplier = _getDepthMultiplier(depth);
    final totalTokens = (baseTokens * depthMultiplier).ceil();

    return TokenEstimationResult(
      inputType: 'pdf',
      inputDetails: {
        'pageCount': pageCount,
        'wordsPerPage': estimatedWordsPerPage,
        'totalWords': totalWords,
        'depth': depth,
      },
      baseTokens: baseTokens,
      depthMultiplier: depthMultiplier,
      totalTokens: totalTokens,
      outputEstimate: {
        'flashcards': flashcardCount,
        'quizQuestions': quizCount,
        'outputTokens': outputTokens,
      },
      canProceed: true,
      warnings: _generatePdfWarnings(pageCount, totalWords, depth),
      costEstimate: _tokenService.getCostEstimate(totalTokens),
    );
  }

  /// Estimate tokens for document content (DOCX, EPUB, etc.)
  TokenEstimationResult estimateDocumentContent({
    required String fileType,
    required int fileSizeBytes,
    required int estimatedWords,
    required String depth,
    int? customFlashcardCount,
    int? customQuizCount,
  }) {
    final baseTokens = _tokenService.tokensForSource(
      words: estimatedWords,
      hasCaptions: true,
    );

    // Calculate output tokens
    final flashcardCount = customFlashcardCount ?? 50;
    final quizCount = customQuizCount ?? 30;
    final outputTokens = _estimateOutputTokens(flashcardCount, quizCount);

    // Depth multiplier
    final depthMultiplier = _getDepthMultiplier(depth);
    final totalTokens = (baseTokens * depthMultiplier).ceil();

    return TokenEstimationResult(
      inputType: 'document',
      inputDetails: {
        'fileType': fileType,
        'fileSizeBytes': fileSizeBytes,
        'estimatedWords': estimatedWords,
        'depth': depth,
      },
      baseTokens: baseTokens,
      depthMultiplier: depthMultiplier,
      totalTokens: totalTokens,
      outputEstimate: {
        'flashcards': flashcardCount,
        'quizQuestions': quizCount,
        'outputTokens': outputTokens,
      },
      canProceed: true,
      warnings: _generateDocumentWarnings(fileSizeBytes, estimatedWords, depth),
      costEstimate: _tokenService.getCostEstimate(totalTokens),
    );
  }

  /// Estimate tokens for regenerating content
  TokenEstimationResult estimateRegeneration({
    required int currentFlashcardCount,
    required int currentQuizCount,
    required int newFlashcardCount,
    required int newQuizCount,
    required String depth,
  }) {
    final currentOutput =
        _estimateOutputTokens(currentFlashcardCount, currentQuizCount);
    final newOutput = _estimateOutputTokens(newFlashcardCount, newQuizCount);

    // Regeneration typically costs 0.5 tokens per output item
    final regenerationTokens =
        ((newFlashcardCount + newQuizCount) * 0.5).ceil();

    // Depth multiplier
    final depthMultiplier = _getDepthMultiplier(depth);
    final totalTokens = (regenerationTokens * depthMultiplier).ceil();

    return TokenEstimationResult(
      inputType: 'regeneration',
      inputDetails: {
        'currentFlashcards': currentFlashcardCount,
        'currentQuizQuestions': currentQuizCount,
        'newFlashcards': newFlashcardCount,
        'newQuizQuestions': newQuizCount,
        'depth': depth,
      },
      baseTokens: regenerationTokens,
      depthMultiplier: depthMultiplier,
      totalTokens: totalTokens,
      outputEstimate: {
        'flashcards': newFlashcardCount,
        'quizQuestions': newQuizCount,
        'outputTokens': newOutput,
      },
      canProceed: true,
      warnings: _generateRegenerationWarnings(newFlashcardCount, newQuizCount),
      costEstimate: _tokenService.getCostEstimate(totalTokens),
    );
  }

  /// Get depth multiplier for different analysis depths
  double _getDepthMultiplier(String depth) {
    switch (depth.toLowerCase()) {
      case 'quick':
        return 0.7; // 30% reduction for quick analysis
      case 'standard':
        return 1.0; // Standard analysis
      case 'deep':
        return 1.5; // 50% increase for deep analysis
      default:
        return 1.0;
    }
  }

  /// Estimate output tokens based on flashcard and quiz counts
  int _estimateOutputTokens(int flashcardCount, int quizCount) {
    // 1 token ≈ 50 flashcards OR 30 quiz questions
    final flashcardTokens = (flashcardCount / 50.0).ceil();
    final quizTokens = (quizCount / 30.0).ceil();
    return max(flashcardTokens, quizTokens);
  }

  /// Estimate output from video duration
  Map<String, int> _estimateOutputFromDuration(double durationMinutes) {
    // Estimate based on content length
    final estimatedWords =
        (durationMinutes * 150).ceil(); // 150 words per minute
    final estimatedTokens = (estimatedWords / 1000).ceil();

    return {
      'flashcards': min(estimatedTokens * 50, 200), // Cap at 200 flashcards
      'quizQuestions': min(estimatedTokens * 30, 120), // Cap at 120 questions
      'outputTokens': estimatedTokens,
    };
  }

  /// Generate warnings for text content
  List<String> _generateWarnings(int words, int chars, String depth) {
    final warnings = <String>[];

    if (words > 10000) {
      warnings.add(
          'Large text input (${_formatNumber(words)} words) - consider splitting into smaller sections');
    }

    if (chars > 500000) {
      warnings.add(
          'Very long content (${_formatNumber(chars)} characters) - processing may take longer');
    }

    if (depth == 'deep' && words > 5000) {
      warnings.add('Deep analysis on large content will use more tokens');
    }

    return warnings;
  }

  /// Generate warnings for YouTube content
  List<String> _generateYouTubeWarnings(
      double durationMinutes, bool hasCaptions, String depth) {
    final warnings = <String>[];

    if (durationMinutes > 60) {
      warnings.add(
          'Long video (${durationMinutes.toStringAsFixed(1)} min) - consider shorter segments for better results');
    }

    if (!hasCaptions) {
      warnings.add(
          'No captions available - audio processing will use additional tokens');
    }

    if (depth == 'deep' && durationMinutes > 30) {
      warnings.add(
          'Deep analysis on long video will use significantly more tokens');
    }

    return warnings;
  }

  /// Generate warnings for PDF content
  List<String> _generatePdfWarnings(
      int pageCount, int totalWords, String depth) {
    final warnings = <String>[];

    if (pageCount > 50) {
      warnings.add(
          'Large PDF (${_formatNumber(pageCount)} pages) - consider processing in sections');
    }

    if (totalWords > 500000) {
      warnings.add(
          'Very long content (${_formatNumber(totalWords)} words) - processing may take longer');
    }

    if (depth == 'deep' && pageCount > 20) {
      warnings.add('Deep analysis on large PDF will use more tokens');
    }

    return warnings;
  }

  /// Generate warnings for document content
  List<String> _generateDocumentWarnings(
      int fileSizeBytes, int estimatedWords, String depth) {
    final warnings = <String>[];
    final fileSizeMB = fileSizeBytes / (1024 * 1024);

    if (fileSizeMB > 10) {
      warnings.add(
          'Large file (${fileSizeMB.toStringAsFixed(1)} MB) - processing may take longer');
    }

    if (estimatedWords > 500000) {
      warnings.add(
          'Very long content (${_formatNumber(estimatedWords)} words) - consider splitting');
    }

    if (depth == 'deep' && estimatedWords > 500000) {
      warnings.add('Deep analysis on large document will use more tokens');
    }

    return warnings;
  }

  /// Generate warnings for regeneration
  List<String> _generateRegenerationWarnings(
      int flashcardCount, int quizCount) {
    final warnings = <String>[];

    if (flashcardCount > 100 || quizCount > 60) {
      warnings.add(
          'Large regeneration request - consider smaller batches for better results');
    }

    return warnings;
  }

  /// Format large numbers for display
  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}

/// Result of token estimation with detailed breakdown
class TokenEstimationResult {
  final String inputType;
  final Map<String, dynamic> inputDetails;
  final int baseTokens;
  final double depthMultiplier;
  final int totalTokens;
  final Map<String, int> outputEstimate;
  final bool canProceed;
  final List<String> warnings;
  final double costEstimate;

  const TokenEstimationResult({
    required this.inputType,
    required this.inputDetails,
    required this.baseTokens,
    required this.depthMultiplier,
    required this.totalTokens,
    required this.outputEstimate,
    required this.canProceed,
    required this.warnings,
    required this.costEstimate,
  });

  /// Get human-readable summary
  String get summary {
    final inputDesc = _getInputDescription();
    final outputDesc = _getOutputDescription();
    final costDesc = _getCostDescription();

    return '$inputDesc → $outputDesc ($costDesc)';
  }

  /// Get detailed breakdown for UI
  Map<String, dynamic> get breakdown {
    return {
      'inputType': inputType,
      'inputDetails': inputDetails,
      'baseTokens': baseTokens,
      'depthMultiplier': depthMultiplier,
      'totalTokens': totalTokens,
      'outputEstimate': outputEstimate,
      'warnings': warnings,
      'costEstimate': costEstimate,
      'summary': summary,
    };
  }

  /// Get input description
  String _getInputDescription() {
    switch (inputType) {
      case 'text':
        final words = inputDetails['words'] as int;
        return '${_formatNumber(words)} words';
      case 'youtube':
        final minutes = inputDetails['durationMinutes'] as double;
        return '${minutes.toStringAsFixed(1)} min video';
      case 'pdf':
        final pages = inputDetails['pageCount'] as int;
        return '${_formatNumber(pages)} page PDF';
      case 'document':
        final words = inputDetails['estimatedWords'] as int;
        final type = inputDetails['fileType'] as String;
        return '${_formatNumber(words)} words ($type)';
      case 'regeneration':
        return 'Regenerate content';
      default:
        return 'Unknown input type';
    }
  }

  /// Get output description
  String _getOutputDescription() {
    final flashcards = outputEstimate['flashcards'] as int;
    final quizQuestions = outputEstimate['quizQuestions'] as int;

    if (flashcards > 0 && quizQuestions > 0) {
      return '$flashcards flashcards + $quizQuestions quiz questions';
    } else if (flashcards > 0) {
      return '$flashcards flashcards';
    } else if (quizQuestions > 0) {
      return '$quizQuestions quiz questions';
    } else {
      return 'No output specified';
    }
  }

  /// Get cost description
  String _getCostDescription() {
    if (totalTokens == 1) {
      return '1 MindLoad Token';
    } else {
      return '$totalTokens MindLoad Tokens';
    }
  }

  /// Format large numbers for display
  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}
