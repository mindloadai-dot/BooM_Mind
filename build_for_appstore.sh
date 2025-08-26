#!/bin/bash

# Mindload App Store Build Script
# This script prepares your app for App Store submission

echo "🚀 Mindload App Store Build Script"
echo "=================================="

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: This script must be run from the Flutter project root directory"
    exit 1
fi

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}📋 Pre-build checklist:${NC}"
echo "1. Have you updated the bundle identifier from com.example.cogniflow?"
echo "2. Have you replaced the Firebase configuration files with your project's files?"
echo "3. Have you configured your Apple Developer Team ID?"
echo "4. Have you set up your app in App Store Connect?"
echo ""
read -p "Press Enter to continue if all above items are completed, or Ctrl+C to exit..."

echo -e "${YELLOW}🧹 Cleaning project...${NC}"
flutter clean
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Flutter clean failed${NC}"
    exit 1
fi

echo -e "${YELLOW}📦 Getting dependencies...${NC}"
flutter pub get
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Flutter pub get failed${NC}"
    exit 1
fi

echo -e "${YELLOW}🔍 Running analysis...${NC}"
flutter analyze
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}⚠️  Analysis found issues, but continuing...${NC}"
fi

echo -e "${YELLOW}🏗️  Building for iOS (App Store)...${NC}"
flutter build ios --release --no-codesign
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ iOS build failed${NC}"
    exit 1
fi

echo -e "${YELLOW}📱 Building for Android (Play Store)...${NC}"
flutter build appbundle --release
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Android build failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build completed successfully!${NC}"
echo ""
echo -e "${YELLOW}📋 Next steps:${NC}"
echo "iOS:"
echo "  1. Open ios/Runner.xcworkspace in Xcode"
echo "  2. Select 'Runner' target and 'Any iOS Device' as destination"
echo "  3. Go to Product > Archive"
echo "  4. After archive completes, click 'Distribute App'"
echo "  5. Choose 'App Store Connect' and follow the prompts"
echo ""
echo "Android:"
echo "  1. Upload build/app/outputs/bundle/release/app-release.aab to Google Play Console"
echo "  2. Follow the Play Console guidelines for submission"
echo ""
echo -e "${GREEN}🎉 Your Mindload app is ready for store submission!${NC}"

# Check if Firebase is properly configured
echo ""
echo -e "${YELLOW}🔥 Firebase Configuration Check:${NC}"
if grep -q "lca5kr3efmasxydmsi1rvyjoizifj4" lib/firebase_options.dart; then
    echo -e "${RED}⚠️  WARNING: You're still using the placeholder Firebase configuration${NC}"
    echo "   Make sure to replace firebase_options.dart with your production configuration"
    echo "   before submitting to the App Store."
else
    echo -e "${GREEN}✅ Firebase configuration appears to be customized${NC}"
fi

echo ""
echo -e "${YELLOW}📱 Bundle Identifier Check:${NC}"
if grep -q "com.example.cogniflow" ios/Runner/Info.plist; then
    echo -e "${RED}⚠️  WARNING: You're still using the example bundle identifier${NC}"
    echo "   Make sure to update com.example.cogniflow to your registered bundle ID"
    echo "   in both iOS and Android configurations."
else
    echo -e "${GREEN}✅ Bundle identifier appears to be customized${NC}"
fi