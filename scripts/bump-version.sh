#!/bin/bash
set -e

# Usage: ./scripts/bump-version.sh 1.1.0 [build_number]

VERSION="$1"
BUILD="${2:-1}"

if [ -z "$VERSION" ]; then
  echo "Usage: $0 <version> [build_number]"
  echo "Example: $0 1.1.0 2"
  exit 1
fi

PROJECT="Clawdachi.xcodeproj/project.pbxproj"

# Check if project file exists
if [ ! -f "$PROJECT" ]; then
  echo "Error: $PROJECT not found. Run this script from the project root."
  exit 1
fi

# Update MARKETING_VERSION
sed -i '' "s/MARKETING_VERSION = [^;]*;/MARKETING_VERSION = $VERSION;/g" "$PROJECT"

# Update CURRENT_PROJECT_VERSION
sed -i '' "s/CURRENT_PROJECT_VERSION = [^;]*;/CURRENT_PROJECT_VERSION = $BUILD;/g" "$PROJECT"

echo "Updated version to $VERSION (build $BUILD)"
echo ""
echo "Next steps:"
echo "  1. Commit: git commit -am 'Release v$VERSION'"
echo "  2. Tag: git tag v$VERSION"
echo "  3. Push: git push && git push --tags"
