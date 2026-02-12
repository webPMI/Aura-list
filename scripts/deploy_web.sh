#!/bin/bash
# Deploy AuraList Web to Firebase Hosting

set -e  # Exit on error

echo "========================================"
echo "   Deploying AuraList to Firebase"
echo "========================================"
echo ""

# Check if Firebase CLI is available
if ! command -v firebase &> /dev/null; then
    echo "ERROR: Firebase CLI not found"
    echo "Install with: npm install -g firebase-tools"
    exit 1
fi

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "ERROR: Flutter not found in PATH"
    exit 1
fi

echo "[1/4] Getting dependencies..."
flutter pub get

echo "[2/4] Generating code..."
dart run build_runner build --delete-conflicting-outputs

echo "[3/4] Building web release..."
flutter build web --release --base-href="/" --pwa-strategy=offline-first

echo "[4/4] Deploying to Firebase Hosting..."
firebase deploy --only hosting

echo ""
echo "========================================"
echo "   Deployment Successful!"
echo "========================================"
echo ""
echo "Your app is live at: https://aura-list.web.app"
echo ""
