// OpenAI Configuration for MindLoad
// This file contains the OpenAI API configuration

import 'environment_config.dart';

class OpenAIConfig {
  // API Configuration - Now using secure environment variables
  static String get apiKey => EnvironmentConfig.openaiApiKey;
  static String? get organizationId => EnvironmentConfig.openaiOrganizationId;
  static const String apiEndpoint =
      'https://api.openai.com/v1/chat/completions';
  static const String model = 'gpt-4o-mini';

  // Rate limiting configuration
  static const int maxRequestsPerMinute = 20;
  static const int maxTokensPerRequest = 4000;
  static const int maxTokensPerResponse = 2000;

  // Timeout configuration
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);

  // Validation
  static bool get isConfigured => EnvironmentConfig.isConfigured;

  // Security validation
  static void validateConfiguration() {
    EnvironmentConfig.validateConfiguration();
  }
}
