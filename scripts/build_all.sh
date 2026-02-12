#!/bin/bash
# Build script for AuraList - Linux/Mac
# Builds for Android, Web, and optionally iOS

set -e  # Exit on error

echo "========================================"
echo "   Building AuraList - All Platforms"
echo "========================================"
echo ""

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "ERROR: Flutter not found in PATH"
    exit 1
fi

echo "[1/6] Cleaning previous builds..."
flutter clean

echo "[2/6] Getting dependencies..."
flutter pub get

echo "[3/6] Generating code (Hive adapters)..."
dart run build_runner build --delete-conflicting-outputs

echo "[4/6] Building Android..."
echo "  → APKs (split by ABI)"
flutter build apk --release --split-per-abi
echo "  → App Bundle (for Play Store)"
flutter build appbundle --release
echo "Android builds completed!"
echo "  APKs: build/app/outputs/flutter-apk/"
echo "  AAB: build/app/outputs/bundle/release/"

echo "[5/6] Building Web (PWA)..."
flutter build web --release --base-href="/" --pwa-strategy=offline-first
echo "Web build completed!"
echo "  Location: build/web/"

# Check if running on Mac for iOS build
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "[6/6] Building iOS..."
    flutter build ipa --release
    echo "iOS build completed!"
    echo "  Location: build/ios/ipa/"
else
    echo "[6/6] Skipping iOS (not on macOS)"
fi

echo ""
echo "========================================"
echo "   Build Process Completed!"
echo "========================================"
echo ""
echo "Build outputs:"
echo "  - Android APKs: build/app/outputs/flutter-apk/"
echo "  - Android AAB: build/app/outputs/bundle/release/"
echo "  - Web: build/web/"
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "  - iOS: build/ios/ipa/"
fi
echo ""
