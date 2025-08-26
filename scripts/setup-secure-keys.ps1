# MindLoad Secure API Key Setup Script
# This script helps you set up environment variables for secure API key management

Write-Host "MindLoad Secure API Key Setup" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Check if .env file exists
if (Test-Path ".env") {
    Write-Host ".env file already exists. Backing up to .env.backup" -ForegroundColor Yellow
    Copy-Item ".env" ".env.backup"
}

# Create .env file from template
if (Test-Path "env.example") {
    Copy-Item "env.example" ".env"
    Write-Host "Created .env file from template" -ForegroundColor Green
} else {
    Write-Host "env.example file not found. Creating basic .env file..." -ForegroundColor Red
    
    $envContent = @"
# MindLoad Environment Configuration
# Fill in your actual API keys below

# OpenAI Configuration
OPENAI_API_KEY=your_openai_api_key_here
OPENAI_ORGANIZATION_ID=your_organization_id_here

# YouTube API Configuration
YOUTUBE_API_KEY=your_youtube_api_key_here

# Environment
ENVIRONMENT=development
"@
    
    $envContent | Out-File -FilePath ".env" -Encoding UTF8
    Write-Host "Created basic .env file" -ForegroundColor Green
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Edit the .env file with your actual API keys" -ForegroundColor White
Write-Host "2. For development, you can use the hardcoded fallbacks" -ForegroundColor White
Write-Host "3. For production, set ENVIRONMENT=production" -ForegroundColor White
Write-Host "4. Run the app with: flutter run --dart-define-from-file=.env" -ForegroundColor White
Write-Host ""
Write-Host "Firebase Functions Setup:" -ForegroundColor Yellow
Write-Host "1. Set YouTube API key: firebase functions:secrets:set YOUTUBE_API_KEY" -ForegroundColor White
Write-Host "2. Set OpenAI API key: firebase functions:secrets:set OPENAI_API_KEY" -ForegroundColor White
Write-Host ""
Write-Host "See SECURE_API_SETUP.md for detailed instructions" -ForegroundColor Cyan
