#!/bin/bash

# MindLoad Firebase Deployment Script
echo "🚀 Starting MindLoad Firebase deployment..."

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Please install: npm install -g firebase-tools"
    exit 1
fi

# Check if user is logged in
if ! firebase projects:list &> /dev/null; then
    echo "❌ Not logged into Firebase. Please run: firebase login"
    exit 1
fi

echo "📦 Installing Functions dependencies..."
cd functions
if [ ! -d "node_modules" ]; then
    npm install
fi
npm run build
cd ..

echo "🛡️ Validating Firestore rules..."
firebase firestore:rules:validate --project default

echo "🚀 Deploying to Firebase..."
firebase deploy --project default

echo "✅ Deployment complete! Check Firebase console for details."