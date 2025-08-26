#!/bin/bash

# MindLoad Secure API Key Setup Script
# This script helps you set up environment variables for secure API key management

echo "🔐 MindLoad Secure API Key Setup"
echo "================================="

# Check if .env file exists
if [ -f ".env" ]; then
    echo "⚠️  .env file already exists. Backing up to .env.backup"
    cp .env .env.backup
fi

# Create .env file from template
if [ -f "env.example" ]; then
    cp env.example .env
    echo "✅ Created .env file from template"
else
    echo "❌ env.example file not found. Creating basic .env file..."
    
    cat > .env << EOF
# MindLoad Environment Configuration
# Fill in your actual API keys below

# OpenAI Configuration
OPENAI_API_KEY=your_openai_api_key_here
OPENAI_ORGANIZATION_ID=your_organization_id_here

# YouTube API Configuration
YOUTUBE_API_KEY=your_youtube_api_key_here

# Environment
ENVIRONMENT=development
EOF
    
    echo "✅ Created basic .env file"
fi

echo ""
echo "📝 Next Steps:"
echo "1. Edit the .env file with your actual API keys"
echo "2. For development, you can use the hardcoded fallbacks"
echo "3. For production, set ENVIRONMENT=production"
echo "4. Run the app with: flutter run --dart-define-from-file=.env"
echo ""
echo "🔧 Firebase Functions Setup:"
echo "1. Set YouTube API key: firebase functions:secrets:set YOUTUBE_API_KEY"
echo "2. Set OpenAI API key: firebase functions:secrets:set OPENAI_API_KEY"
echo ""
echo "📚 See SECURE_API_SETUP.md for detailed instructions"
