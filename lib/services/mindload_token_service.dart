import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// MindLoad Token Service
/// Single source of truth for token calculations and management
class MindloadTokenService {
  static final MindloadTokenService _instance = MindloadTokenService._internal();
  factory MindloadTokenService() => _instance;
  MindloadTokenService._internal();

  /// Token calculation constants
  static const int _wordsPerToken = 1000;
  static const int _audioMinutesPerToken = 2;
  static const double _youtubeWordsPerMinute = 150; // Approximate words per minute

  /// Calculate tokens required for a source
  /// 1 MindLoad Token => up to 30 quiz Q + 50 flashcards
  /// Per-token input allowance: ≤1,000 words; if no captions, +≤2 minutes audio per token
  int tokensForSource({
    required int words,
    int minutes = 0,
    required bool hasCaptions,
  }) {
    final wordCost = (words / _wordsPerToken).ceil();
    final audioCost = hasCaptions ? 0 : (minutes / _audioMinutesPerToken).ceil();
    return max(1, wordCost + audioCost);
  }

  /// UI estimator for YouTube minutes (keep consistent with server)
  int tokensByMinutes(int minutes, bool hasCaptions) {
    final approxWords = (minutes * _youtubeWordsPerMinute).ceil();
    final wordCost = (approxWords / _wordsPerToken).ceil();
    final audioCost = hasCaptions ? 0 : (minutes / _audioMinutesPerToken).ceil();
    return max(1, wordCost + audioCost);
  }

  /// Calculate tokens for text input
  int tokensForText(String text) {
    final words = text.split(' ').length;
    return tokensForSource(words: words, hasCaptions: true);
  }

  /// Calculate tokens for PDF input
  int tokensForPdf(int pageCount, int estimatedWordsPerPage) {
    final totalWords = pageCount * estimatedWordsPerPage;
    return tokensForSource(words: totalWords, hasCaptions: true);
  }

  /// Calculate tokens for YouTube video
  int tokensForYouTube({
    required int durationMinutes,
    required bool hasCaptions,
    String? language,
  }) {
    return tokensByMinutes(durationMinutes, hasCaptions);
  }

  /// Generate source hash for deduplication
  String generateSourceHash({
    required String sourceId,
    required String depth,
    String language = 'en',
  }) {
    final data = '$sourceId:$depth:$language';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Validate token estimate
  bool isValidTokenEstimate(int tokens) {
    return tokens > 0 && tokens <= 1000; // Reasonable upper limit
  }

  /// Get cost estimate in USD (approximate)
  double getCostEstimate(int tokens) {
    // Rough estimate: $0.01 per token
    return tokens * 0.01;
  }

  /// Check if user can afford operation
  bool canAfford(int requiredTokens, int availableTokens) {
    return availableTokens >= requiredTokens;
  }

  /// Get remaining tokens after operation
  int getRemainingTokens(int availableTokens, int usedTokens) {
    return max(0, availableTokens - usedTokens);
  }

  /// Format token count for display
  String formatTokens(int tokens) {
    if (tokens >= 1000) {
      return '${(tokens / 1000).toStringAsFixed(1)}k';
    }
    return tokens.toString();
  }

  /// Get token usage breakdown
  Map<String, dynamic> getTokenBreakdown({
    required int words,
    int minutes = 0,
    required bool hasCaptions,
  }) {
    final wordCost = (words / _wordsPerToken).ceil();
    final audioCost = hasCaptions ? 0 : (minutes / _audioMinutesPerToken).ceil();
    final totalCost = max(1, wordCost + audioCost);

    return {
      'wordCost': wordCost,
      'audioCost': audioCost,
      'totalCost': totalCost,
      'wordsPerToken': _wordsPerToken,
      'audioMinutesPerToken': _audioMinutesPerToken,
      'hasCaptions': hasCaptions,
    };
  }
}
