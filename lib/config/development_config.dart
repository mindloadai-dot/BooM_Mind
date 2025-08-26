// Development Configuration for MindLoad
// This file contains development API keys and should NOT be committed to version control
// Copy this file and rename to development_config_local.dart with your actual keys

class DevelopmentConfig {
  // Development API Keys - Replace with your actual keys
  static const String openaiApiKey = 'YOUR_OPENAI_API_KEY_HERE';
  static const String youtubeApiKey = 'YOUR_YOUTUBE_API_KEY_HERE';
  static const String? openaiOrganizationId = null;
  
  // Development Environment
  static const String environment = 'development';
  
  // Validation
  static bool get isConfigured => 
      openaiApiKey != 'YOUR_OPENAI_API_KEY_HERE' && 
      youtubeApiKey != 'YOUR_YOUTUBE_API_KEY_HERE';
}
