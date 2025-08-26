@echo off
setlocal enabledelayedexpansion

REM OpenAI API Key Setup Script for Mindload (Windows)
REM This script sets up the OpenAI API key in Firebase Secret Manager

echo 🤖 OpenAI API Key Setup for Mindload
echo ==================================

REM Check if gcloud is installed
where gcloud >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Google Cloud CLI (gcloud) is not installed
    echo Please install it from: https://cloud.google.com/sdk/docs/install
    pause
    exit /b 1
)

REM Check if user is authenticated
gcloud auth list --filter=status:ACTIVE --format="value(account)" | findstr /r "." >nul
if %errorlevel% neq 0 (
    echo ⚠️  Not authenticated with Google Cloud
    echo Please run: gcloud auth login
    pause
    exit /b 1
)

REM Get project ID
for /f "tokens=*" %%i in ('gcloud config get-value project 2^>nul') do set PROJECT_ID=%%i
if "%PROJECT_ID%"=="" (
    echo ❌ No project ID configured
    echo Please run: gcloud config set project YOUR_PROJECT_ID
    pause
    exit /b 1
)

echo ✅ Using project: %PROJECT_ID%

REM OpenAI API Key
set OPENAI_API_KEY=YOUR_OPENAI_API_KEY_HERE

echo 🔑 Setting up OpenAI API Key...

REM Create the secret
echo Creating OpenAI API Key secret...
echo %OPENAI_API_KEY% | gcloud secrets create OPENAI_API_KEY --data-file=- --replication-policy="automatic" --project="%PROJECT_ID%"

if %errorlevel% equ 0 (
    echo ✅ OpenAI API Key secret created successfully
) else (
    echo ⚠️  Secret might already exist, checking...
    
    REM Check if secret exists
    gcloud secrets describe OPENAI_API_KEY --project="%PROJECT_ID%" >nul 2>&1
    if %errorlevel% equ 0 (
        echo ✅ OpenAI API Key secret already exists
        
        REM Update the existing secret
        echo Updating existing secret...
        echo %OPENAI_API_KEY% | gcloud secrets versions add OPENAI_API_KEY --data-file=- --project="%PROJECT_ID%"
        
        if %errorlevel% equ 0 (
            echo ✅ OpenAI API Key secret updated successfully
        ) else (
            echo ❌ Failed to update secret
            pause
            exit /b 1
        )
    ) else (
        echo ❌ Failed to create secret
        pause
        exit /b 1
    )
)

REM Grant access to Cloud Functions service account
echo 🔐 Granting access to Cloud Functions...

REM Get the Cloud Functions service account
set SERVICE_ACCOUNT=%PROJECT_ID%@appspot.gserviceaccount.com

echo Granting access to: %SERVICE_ACCOUNT%

gcloud secrets add-iam-policy-binding OPENAI_API_KEY --member="serviceAccount:%SERVICE_ACCOUNT%" --role="roles/secretmanager.secretAccessor" --project="%PROJECT_ID%"

if %errorlevel% equ 0 (
    echo ✅ Access granted to Cloud Functions
) else (
    echo ⚠️  Failed to grant access (might already have access)
)

echo.
echo 🎉 OpenAI API Key setup completed!
echo.
echo 📋 Next steps:
echo 1. Deploy your Cloud Functions: firebase deploy --only functions
echo 2. Test the AI features in your app
echo 3. Monitor usage in OpenAI dashboard
echo.
echo 🔍 Verification:
echo You can verify the secret was created by running:
echo gcloud secrets list --project=%PROJECT_ID%
echo.
echo ⚠️  Security Note:
echo The API key is now stored securely in Firebase Secret Manager
echo and accessed only by your Cloud Functions, not by client code.
echo.
echo ✅ Setup complete! Your Mindload app can now use AI features.
echo.
pause
