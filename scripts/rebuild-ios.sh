#!/bin/bash

# MindLoad iOS Post-Test Rebuild Script
# This script rebuilds the iOS app after tests complete

echo "🧪 Tests completed successfully, rebuilding iOS app..."

# Clean Flutter build cache
echo "🧹 Cleaning Flutter build cache..."
flutter clean

# Get Flutter dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Clean and reinstall CocoaPods
echo "🍎 Cleaning and reinstalling CocoaPods..."
cd ios
rm -rf Pods
rm -rf Podfile.lock
pod install --repo-update
cd ..

# Build iOS app
echo "🏗️ Building iOS app..."
flutter build ios --release --no-codesign

echo "✅ Post-test iOS rebuild completed successfully!"
