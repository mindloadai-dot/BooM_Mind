#!/bin/bash

# Firebase Deployment Script with Error Checking
echo "🚀 Starting Firebase deployment for MindLoad..."

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI is not installed. Please install it first:"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Check if logged in to Firebase
if ! firebase projects:list &> /dev/null; then
    echo "❌ Not logged in to Firebase. Please run:"
    echo "firebase login"
    exit 1
fi

# Ensure functions dependencies are installed
echo "📦 Installing functions dependencies..."
cd functions
npm install
if [ $? -ne 0 ]; then
    echo "❌ Failed to install functions dependencies"
    exit 1
fi
cd ..

# Clean and build functions
echo "🔨 Building functions..."
cd functions
npm run clean
npm run build
if [ $? -ne 0 ]; then
    echo "❌ Failed to build functions"
    exit 1
fi
cd ..

# Deploy Firestore rules first
echo "📜 Deploying Firestore rules..."
firebase deploy --only firestore
if [ $? -ne 0 ]; then
    echo "❌ Failed to deploy Firestore rules"
    exit 1
fi

# Deploy Storage rules
echo "💾 Deploying Storage rules..."
firebase deploy --only storage
if [ $? -ne 0 ]; then
    echo "❌ Failed to deploy Storage rules"
    exit 1
fi

# Deploy Functions
echo "⚡ Deploying Functions..."
firebase deploy --only functions
if [ $? -ne 0 ]; then
    echo "❌ Failed to deploy Functions"
    exit 1
fi

# Deploy Hosting (optional)
echo "🌐 Deploying Hosting..."
firebase deploy --only hosting
if [ $? -ne 0 ]; then
    echo "⚠️  Hosting deployment failed (this is optional for mobile app)"
fi

echo "✅ Firebase deployment completed successfully!"
echo "🎉 MindLoad backend is now live!"