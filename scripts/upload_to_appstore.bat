@echo off
REM Manual App Store Connect Upload Script for Windows
REM Use this as a backup if Codemagic upload fails

echo 🚀 Manual App Store Connect Upload Script
echo ==========================================

REM Configuration
set IPA_PATH=%1
set BUNDLE_ID=com.MindLoad.ios
set KEY_ID=565ZN92ZGD
set ISSUER_ID=ece20104-b50b-43b0-a586-94384a0b1151

REM Check if IPA path is provided
if "%IPA_PATH%"=="" (
    echo ❌ Usage: %0 ^<path_to_ipa_file^>
    echo Example: %0 build\ios\ipa\Mindload.ipa
    exit /b 1
)

REM Verify IPA file exists
if not exist "%IPA_PATH%" (
    echo ❌ IPA file not found: %IPA_PATH%
    exit /b 1
)

echo 📦 IPA file: %IPA_PATH%
echo 🆔 Bundle ID: %BUNDLE_ID%
echo 🔑 Key ID: %KEY_ID%

echo.
echo 🔄 For Windows, use Transporter app or Xcode on macOS
echo 📱 Download Transporter from Mac App Store
echo 🔗 https://apps.apple.com/us/app/transporter/id1450874784
echo.
echo 📋 Instructions:
echo 1. Open Transporter app
echo 2. Drag and drop your IPA file
echo 3. Enter your Apple ID credentials
echo 4. Click "Deliver"
echo.
echo ✅ Manual upload completed!
echo 📱 Check App Store Connect for processing status
echo 🔗 https://appstoreconnect.apple.com/apps

pause
