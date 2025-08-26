#!/bin/bash

# Manual App Store Connect Upload Script
# Use this as a backup if Codemagic upload fails

set -e

echo "🚀 Manual App Store Connect Upload Script"
echo "=========================================="

# Configuration
IPA_PATH=""
BUNDLE_ID="com.MindLoad.ios"
KEY_ID="565ZN92ZGD"
ISSUER_ID="ece20104-b50b-43b0-a586-94384a0b1151"

# Check if IPA path is provided
if [ -z "$1" ]; then
    echo "❌ Usage: $0 <path_to_ipa_file>"
    echo "Example: $0 build/ios/ipa/Mindload.ipa"
    exit 1
fi

IPA_PATH="$1"

# Verify IPA file exists
if [ ! -f "$IPA_PATH" ]; then
    echo "❌ IPA file not found: $IPA_PATH"
    exit 1
fi

echo "📦 IPA file: $IPA_PATH"
echo "🆔 Bundle ID: $BUNDLE_ID"
echo "🔑 Key ID: $KEY_ID"

# Check IPA size
IPA_SIZE=$(du -h "$IPA_PATH" | cut -f1)
echo "📊 IPA size: $IPA_SIZE"

# Method 1: Try using altool (traditional method)
echo ""
echo "🔄 Attempting upload with altool..."
echo "=================================="

if command -v altool &> /dev/null; then
    altool --upload-app \
        --file "$IPA_PATH" \
        --type ios \
        --apiKey "$KEY_ID" \
        --apiIssuer "$ISSUER_ID" \
        --verbose
else
    echo "⚠️  altool not found, trying xcrun altool..."
    xcrun altool --upload-app \
        --file "$IPA_PATH" \
        --type ios \
        --apiKey "$KEY_ID" \
        --apiIssuer "$ISSUER_ID" \
        --verbose
fi

echo ""
echo "✅ Upload completed successfully!"
echo "📱 Check App Store Connect for processing status"
echo "🔗 https://appstoreconnect.apple.com/apps"
