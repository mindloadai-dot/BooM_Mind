// YouTube Configuration for Mindload
// This file contains the YouTube API configuration for video processing

import 'environment_config.dart';

class YouTubeConfig {
  // API Configuration - Now using secure environment variables
  static String get apiKey => EnvironmentConfig.youtubeApiKey;
  static const String apiEndpoint =
      'https://www.googleapis.com/youtube/v3/videos';

  // Configuration for YouTube processing
  static const int tokensPerMLToken = 750;
  static const int outTokensDefault = 500;
  static const int freeMaxDurationSeconds = 1800; // 30 min
  static const int proMaxDurationSeconds = 7200; // 120 min
  static const List<String> transcriptLangFallbacks = ['en', 'en-US'];
  static const int cacheTtlMinutes = 15;
  static const int maxCacheEntries = 1000;

  // Rate limiting
  static const int maxRequestsPerMinute = 100;
  static const int maxRequestsPerHour = 10000;

  // Error handling
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Validation
  static bool get isConfigured => EnvironmentConfig.isConfigured;

  // Security validation
  static void validateConfiguration() {
    EnvironmentConfig.validateConfiguration();
  }
}
