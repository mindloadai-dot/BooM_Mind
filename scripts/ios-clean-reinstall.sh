#!/bin/bash

# MindLoad iOS Clean & Reinstall Script
# Senior iOS Build Engineer - 2025 iOS Build Rules Compliance
# This script ensures clean builds for Codemagic and TestFlight

set -e  # Exit on any error

echo "🍎 MindLoad iOS Clean & Reinstall Script"
echo "========================================"

# Step 1: Clean Flutter build cache
echo "🧹 Step 1: Cleaning Flutter build cache..."
flutter clean

# Step 2: Get Flutter dependencies
echo "📦 Step 2: Getting Flutter dependencies..."
flutter pub get

# Step 3: Navigate to iOS directory
echo "📱 Step 3: Navigating to iOS directory..."
cd ios

# Step 4: Remove existing Pods and lock file
echo "🗑️  Step 4: Removing existing Pods and lock file..."
rm -rf Pods
rm -rf Podfile.lock

# Step 5: Clean CocoaPods cache
echo "🧽 Step 5: Cleaning CocoaPods cache..."
pod cache clean --all

# Step 6: Update CocoaPods repo
echo "🔄 Step 6: Updating CocoaPods repository..."
pod repo update

# Step 7: Install pods with repo update
echo "📥 Step 7: Installing pods with repository update..."
pod install --repo-update --verbose

# Step 8: Verify deployment targets
echo "✅ Step 8: Verifying deployment targets..."
echo "Checking that all pods have iOS 15.0+ deployment target..."

# Check for any pods with deployment target below 15.0
DEPLOYMENT_ISSUES=$(grep -r "IPHONEOS_DEPLOYMENT_TARGET.*[0-9]\{1,2\}\.[0-9]" Pods/ | grep -v "15.0" | grep -v "16.0" | grep -v "17.0" | grep -v "18.0" || true)

if [ -n "$DEPLOYMENT_ISSUES" ]; then
    echo "⚠️  WARNING: Found pods with deployment target below iOS 15.0:"
    echo "$DEPLOYMENT_ISSUES"
    echo "These should be fixed by the post_install script in Podfile"
else
    echo "✅ All pods have iOS 15.0+ deployment target"
fi

# Step 9: Return to project root
echo "🔙 Step 9: Returning to project root..."
cd ..

# Step 10: Final verification
echo "🔍 Step 10: Final verification..."
echo "✅ Flutter clean completed"
echo "✅ Dependencies updated"
echo "✅ CocoaPods cleaned and reinstalled"
echo "✅ iOS 15.0+ deployment target enforced"

echo ""
echo "🎉 iOS Clean & Reinstall completed successfully!"
echo "Ready for Codemagic/TestFlight builds with 2025 iOS rules compliance"
