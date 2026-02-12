#!/bin/bash
# Version bumping script for AuraList
# Increments the build number in pubspec.yaml

set -e

echo "========================================"
echo "   AuraList Version Bump"
echo "========================================"
echo ""

# Check if pubspec.yaml exists
if [ ! -f "pubspec.yaml" ]; then
    echo "ERROR: pubspec.yaml not found"
    echo "Run this script from the project root"
    exit 1
fi

# Read current version
CURRENT_VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //')
echo "Current version: $CURRENT_VERSION"

# Split version and build number
IFS='+' read -ra PARTS <<< "$CURRENT_VERSION"
VERSION=${PARTS[0]}
BUILD=${PARTS[1]}

# Increment build number
NEW_BUILD=$((BUILD + 1))
NEW_VERSION="${VERSION}+${NEW_BUILD}"

echo "New version: $NEW_VERSION"
echo ""

# Ask for confirmation
read -p "Update pubspec.yaml to $NEW_VERSION? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Update pubspec.yaml
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/version: .*/version: $NEW_VERSION/" pubspec.yaml
else
    # Linux
    sed -i "s/version: .*/version: $NEW_VERSION/" pubspec.yaml
fi

echo ""
echo "========================================"
echo "   Version updated successfully!"
echo "========================================"
echo ""
echo "Old: $CURRENT_VERSION"
echo "New: $NEW_VERSION"
echo ""
echo "Don't forget to commit this change:"
echo "  git add pubspec.yaml"
echo "  git commit -m \"chore: bump version to $NEW_VERSION\""
echo ""
