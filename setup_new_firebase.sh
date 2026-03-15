#!/bin/bash

# Firebase New Project Setup Script
# Run this after creating your new Firebase project

echo "🔥 Setting up new Firebase project for MindNest..."

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Installing..."
    npm install -g firebase-tools
fi

# Check if FlutterFire CLI is installed
if ! command -v flutterfire &> /dev/null; then
    echo "❌ FlutterFire CLI not found. Installing..."
    dart pub global activate flutterfire_cli
fi

# Login to Firebase (if not already logged in)
echo "🔐 Logging into Firebase..."
firebase login

# List available projects
echo "📋 Available Firebase projects:"
firebase projects:list

# Prompt for project ID
read -p "Enter your new Firebase project ID: " PROJECT_ID

# Set the project
echo "🎯 Setting Firebase project to $PROJECT_ID..."
firebase use $PROJECT_ID

# Configure FlutterFire
echo "⚙️ Configuring FlutterFire..."
flutterfire configure --project=$PROJECT_ID

# Deploy Firestore rules
echo "🛡️ Deploying Firestore security rules..."
firebase deploy --only firestore:rules

# Deploy Firestore indexes
echo "📊 Deploying Firestore indexes..."
cp firestore.indexes.new.json firestore.indexes.json
firebase deploy --only firestore:indexes

# Clean up Flutter
echo "🧹 Cleaning Flutter project..."
flutter clean
flutter pub get

echo "✅ Firebase setup complete!"
echo "📝 Next steps:"
echo "   1. Enable Authentication methods in Firebase Console"
echo "   2. Test your app with the new Firebase project"
echo "   3. Set up billing alerts in Firebase Console"
echo "   4. Consider setting up separate dev/prod environments"