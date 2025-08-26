/// Secure environment configuration for MindLoad
/// This class handles loading API keys and configuration from environment variables
class EnvironmentConfig {
  static const String _openaiApiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const String _openaiOrgId =
      String.fromEnvironment('OPENAI_ORGANIZATION_ID');
  static const String _youtubeApiKey =
      String.fromEnvironment('YOUTUBE_API_KEY');
  static const String _environment =
      String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');

  // OpenAI Configuration
  static String get openaiApiKey {
    // First try environment variable
    if (_openaiApiKey.isNotEmpty) {
      return _openaiApiKey;
    }

    // Fallback to development config for development
    if (_environment == 'development') {
      try {
        // Try to load from development config if available
        // This will be replaced with actual keys in development_config_local.dart
        return 'YOUR_OPENAI_API_KEY_HERE';
      } catch (e) {
        return 'YOUR_OPENAI_API_KEY_HERE';
      }
    }

    throw Exception(
        'OpenAI API key not configured. Set OPENAI_API_KEY environment variable.');
  }

  static String? get openaiOrganizationId {
    return _openaiOrgId.isNotEmpty ? _openaiOrgId : null;
  }

  // YouTube Configuration
  static String get youtubeApiKey {
    // First try environment variable
    if (_youtubeApiKey.isNotEmpty) {
      return _youtubeApiKey;
    }

    // Fallback to development config for development
    if (_environment == 'development') {
      try {
        // Try to load from development config if available
        // This will be replaced with actual keys in development_config_local.dart
        return 'YOUR_YOUTUBE_API_KEY_HERE';
      } catch (e) {
        return 'YOUR_YOUTUBE_API_KEY_HERE';
      }
    }

    throw Exception(
        'YouTube API key not configured. Set YOUTUBE_API_KEY environment variable.');
  }

  // Environment
  static String get environment => _environment;
  static bool get isDevelopment => _environment == 'development';
  static bool get isProduction => _environment == 'production';

  // Validation
  static bool get isConfigured {
    try {
      return openaiApiKey.isNotEmpty && youtubeApiKey.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Security check
  static void validateConfiguration() {
    if (!isConfigured) {
      throw Exception(
          'API configuration is incomplete. Please check your environment variables.');
    }

    if (isProduction && _environment == 'development') {
      throw Exception(
          'Production environment should not use development fallbacks.');
    }
  }
}
