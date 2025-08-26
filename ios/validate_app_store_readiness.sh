#!/bin/bash

# Mindload iOS App Store Readiness Validation Script

echo "🔍 VALIDATING MINDLOAD APP STORE READINESS..."
echo "=============================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

VALIDATION_ERRORS=0

echo -e "\n📱 ${YELLOW}Checking App Configuration...${NC}"

# Check Bundle ID
if grep -q "com.MindLoad.ios" ios/Runner.xcodeproj/project.pbxproj; then
    echo -e "✅ ${GREEN}Bundle ID correctly set to 'com.MindLoad.ios'${NC}"
else
    echo -e "❌ ${RED}Bundle ID not properly configured${NC}"
    ((VALIDATION_ERRORS++))
fi

# Check iOS Deployment Target
if grep -q "IPHONEOS_DEPLOYMENT_TARGET = 15.0" ios/Runner.xcodeproj/project.pbxproj; then
    echo -e "✅ ${GREEN}iOS Deployment Target set to 15.0+${NC}"
else
    echo -e "❌ ${RED}iOS Deployment Target should be 15.0 or higher${NC}"
    ((VALIDATION_ERRORS++))
fi

# Check App Name in Info.plist
if grep -q "<string>Mindload</string>" ios/Runner/Info.plist; then
    echo -e "✅ ${GREEN}App name correctly set to 'Mindload'${NC}"
else
    echo -e "❌ ${RED}App name not properly configured${NC}"
    ((VALIDATION_ERRORS++))
fi

echo -e "\n🔒 ${YELLOW}Checking Privacy & Permissions...${NC}"

# Check Face ID permission
if grep -q "NSFaceIDUsageDescription" ios/Runner/Info.plist; then
    echo -e "✅ ${GREEN}Face ID permission description present${NC}"
else
    echo -e "❌ ${RED}Face ID permission description missing${NC}"
    ((VALIDATION_ERRORS++))
fi

# Check Notification permissions
if grep -q "NSUserNotificationUsageDescription" ios/Runner/Info.plist; then
    echo -e "✅ ${GREEN}Notification permission descriptions present${NC}"
else
    echo -e "❌ ${RED}Notification permission descriptions missing${NC}"
    ((VALIDATION_ERRORS++))
fi

# Check Privacy Manifest
if [ -f "ios/Runner/PrivacyInfo.xcprivacy" ]; then
    echo -e "✅ ${GREEN}Privacy Manifest file exists${NC}"
    
    # Check if tracking is disabled
    if grep -q "<false/>" ios/Runner/PrivacyInfo.xcprivacy; then
        echo -e "✅ ${GREEN}User tracking properly disabled${NC}"
    else
        echo -e "❌ ${RED}User tracking configuration issue${NC}"
        ((VALIDATION_ERRORS++))
    fi
else
    echo -e "❌ ${RED}Privacy Manifest file missing${NC}"
    ((VALIDATION_ERRORS++))
fi

echo -e "\n🔐 ${YELLOW}Checking Security Settings...${NC}"

# Check App Transport Security
if grep -q "NSAppTransportSecurity" ios/Runner/Info.plist; then
    echo -e "✅ ${GREEN}App Transport Security configured${NC}"
    
    # Check for secure TLS version
    if grep -q "TLSv1.2" ios/Runner/Info.plist; then
        echo -e "✅ ${GREEN}TLS 1.2+ enforced for secure connections${NC}"
    else
        echo -e "⚠️ ${YELLOW}Consider updating to TLS 1.2+ for enhanced security${NC}"
    fi
else
    echo -e "❌ ${RED}App Transport Security not configured${NC}"
    ((VALIDATION_ERRORS++))
fi

# Check export compliance
if grep -q "ITSAppUsesNonExemptEncryption" ios/Runner/Info.plist; then
    echo -e "✅ ${GREEN}Export compliance declaration present${NC}"
else
    echo -e "❌ ${RED}Export compliance declaration missing${NC}"
    ((VALIDATION_ERRORS++))
fi

echo -e "\n📦 ${YELLOW}Checking App Store Category...${NC}"

# Check app category
if grep -q "public.app-category.education" ios/Runner/Info.plist; then
    echo -e "✅ ${GREEN}App categorized as Education${NC}"
else
    echo -e "⚠️ ${YELLOW}App category not explicitly set (will default)${NC}"
fi

echo -e "\n🏗️ ${YELLOW}Checking Build Configuration...${NC}"

# Check if Flutter dependencies are up to date
if [ -f "pubspec.yaml" ]; then
    echo -e "✅ ${GREEN}pubspec.yaml exists${NC}"
    
    # Check app name in pubspec.yaml
    if grep -q "name: mindload" pubspec.yaml; then
        echo -e "✅ ${GREEN}Package name correctly set to 'mindload'${NC}"
    else
        echo -e "❌ ${RED}Package name should be 'mindload'${NC}"
        ((VALIDATION_ERRORS++))
    fi
else
    echo -e "❌ ${RED}pubspec.yaml not found${NC}"
    ((VALIDATION_ERRORS++))
fi

# Check for Firebase configuration
if [ -f "lib/firebase_options.dart" ]; then
    echo -e "✅ ${GREEN}Firebase configuration exists${NC}"
else
    echo -e "⚠️ ${YELLOW}Firebase configuration not found (required for production)${NC}"
fi

echo -e "\n📊 ${YELLOW}Final Validation Results...${NC}"
echo "=============================================="

if [ $VALIDATION_ERRORS -eq 0 ]; then
    echo -e "🎉 ${GREEN}CONGRATULATIONS! Your app is ready for App Store submission!${NC}"
    echo -e "📋 ${GREEN}Next steps:${NC}"
    echo -e "   1. Run 'flutter build ios --release'"
    echo -e "   2. Open 'ios/Runner.xcworkspace' in Xcode"
    echo -e "   3. Select your development team and sign the app"
    echo -e "   4. Archive and upload to App Store Connect"
    echo -e "   5. Complete app metadata and submit for review"
    echo -e "\n📖 See ios/DEPLOYMENT_GUIDE.md for detailed instructions"
else
    echo -e "⚠️ ${RED}Found $VALIDATION_ERRORS validation errors that need to be fixed${NC}"
    echo -e "📋 ${YELLOW}Please address the issues above before submitting to App Store${NC}"
fi

echo -e "\n🔗 ${YELLOW}Useful Resources:${NC}"
echo -e "   • App Store Connect: https://appstoreconnect.apple.com"
echo -e "   • iOS Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/ios"
echo -e "   • App Store Review Guidelines: https://developer.apple.com/app-store/review/guidelines/"

exit $VALIDATION_ERRORS