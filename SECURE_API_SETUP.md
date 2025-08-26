# Secure API Key Setup Guide

This guide explains how to securely configure API keys for the MindLoad application.

## Overview

The application now uses a secure environment-based configuration system that:
- Loads API keys from environment variables
- Provides fallbacks for development
- Validates configuration on startup
- Prevents API keys from being committed to version control

## Setup Instructions

### 1. Environment Variables

Create a `.env` file in your project root (copy from `env.example`):

```bash
# Copy the example file
cp env.example .env
```

Edit `.env` with your actual API keys:

```env
# OpenAI Configuration
OPENAI_API_KEY=sk-proj-your-actual-openai-key-here
OPENAI_ORGANIZATION_ID=your-org-id-here

# YouTube API Configuration
YOUTUBE_API_KEY=your-actual-youtube-api-key-here

# Environment
ENVIRONMENT=development
```

### 2. Flutter Environment Variables

For Flutter builds, you need to pass environment variables during compilation:

#### Development
```bash
flutter run --dart-define=OPENAI_API_KEY=your-key-here --dart-define=YOUTUBE_API_KEY=your-key-here
```

#### Production Build
```bash
flutter build apk --dart-define=OPENAI_API_KEY=your-key-here --dart-define=YOUTUBE_API_KEY=your-key-here
```

### 3. IDE Configuration

#### VS Code
Add to your `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "MindLoad Debug",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart",
      "args": [
        "--dart-define=OPENAI_API_KEY=your-key-here",
        "--dart-define=YOUTUBE_API_KEY=your-key-here"
      ]
    }
  ]
}
```

#### Android Studio
In Run Configuration, add VM options:
```
--dart-define=OPENAI_API_KEY=your-key-here --dart-define=YOUTUBE_API_KEY=your-key-here
```

## Security Features

### 1. Environment Validation
The app validates configuration on startup:
```dart
EnvironmentConfig.validateConfiguration();
```

### 2. Development Fallbacks
In development mode, the app can use hardcoded fallbacks (remove in production).

### 3. Production Safety
In production, the app will throw exceptions if API keys are not properly configured.

## Firebase Functions

Firebase Functions use Secret Manager for secure API key storage:

```bash
# Set OpenAI API key
firebase functions:secrets:set OPENAI_API_KEY

# Set YouTube API key  
firebase functions:secrets:set YOUTUBE_API_KEY
```

## File Structure

```
lib/config/
├── environment_config.dart    # Main environment configuration
├── openai_config.dart        # OpenAI-specific configuration
├── youtube_config.dart       # YouTube-specific configuration
└── firebase_secrets_template.dart  # Firebase secrets template

env.example                   # Environment variables template
.env                         # Your actual environment file (gitignored)
```

## Best Practices

1. **Never commit `.env` files** - They're in `.gitignore`
2. **Use different keys for dev/prod** - Separate environments
3. **Rotate keys regularly** - Security best practice
4. **Monitor usage** - Track API key usage
5. **Use least privilege** - Minimal required permissions

## Troubleshooting

### "API key not configured" Error
- Check your `.env` file exists and has the correct keys
- Verify environment variables are passed to Flutter
- Ensure `ENVIRONMENT` is set correctly

### Development Fallbacks Not Working
- Check `ENVIRONMENT=development` in your `.env`
- Verify the fallback keys are still valid
- Check console for configuration errors

### Production Build Issues
- Ensure all required environment variables are set
- Remove development fallbacks for production
- Test configuration validation

## Migration from Hardcoded Keys

If you're migrating from hardcoded keys:

1. Update your configuration files to use the new system
2. Set up environment variables
3. Test in development first
4. Deploy to production with proper environment setup
5. Remove hardcoded fallbacks once confirmed working

## Support

For issues with API key configuration:
1. Check the console logs for specific error messages
2. Verify your environment variables are set correctly
3. Test with the development fallbacks first
4. Check Firebase Functions logs for server-side issues
