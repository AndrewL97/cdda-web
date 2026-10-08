#!/bin/bash
set -e

RELEASE_TAG="${1:-latest}"
CDDA_REPO="CleverRaven/cataclysm-dda"
SOURCE_DIR="cdda-source"

echo "Fetching CDDA release: $RELEASE_TAG"

# Clean up previous source
if [ -d "$SOURCE_DIR" ]; then
  echo "Removing previous source directory..."
  rm -rf "$SOURCE_DIR"
fi

# Create source directory
mkdir -p "$SOURCE_DIR"
cd "$SOURCE_DIR"

if [ "$RELEASE_TAG" = "latest" ]; then
  echo "Fetching latest CDDA release..."

  RELEASE_TAG=$(curl -fsSL \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/${CDDA_REPO}/releases?per_page=1" |
    jq -r '.[0].tag_name')

  if [ -z "$RELEASE_TAG" ] || [ "$RELEASE_TAG" = "null" ]; then
    echo "Error: Could not determine latest CDDA release tag"
    exit 1
  fi

  echo "Latest CDDA release tag: $RELEASE_TAG"
fi

# Download the release tarball using the release tag
echo "Downloading $RELEASE_TAG from GitHub..."
wget -O "cataclysm-dda-${RELEASE_TAG}.tar.gz" "https://github.com/${CDDA_REPO}/archive/refs/tags/${RELEASE_TAG}.tar.gz"

# Extract the tarball
echo "Extracting tarball..."
tar -xzf "cataclysm-dda-${RELEASE_TAG}.tar.gz"

# Find the extracted directory (handle different naming conventions)
EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "Cataclysm-DDA-*" | head -n1)
if [ -z "$EXTRACTED_DIR" ]; then
  # Try alternative naming pattern
  EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "cataclysm-dda-*" | head -n1)
fi

if [ -z "$EXTRACTED_DIR" ]; then
  echo "Error: Could not find extracted directory"
  ls -la
  exit 1
fi

echo "Found extracted directory: $EXTRACTED_DIR"
mv "$EXTRACTED_DIR"/* .
rm -rf "$EXTRACTED_DIR"
rm "cataclysm-dda-${RELEASE_TAG}.tar.gz"

echo "Source fetched successfully to: $SOURCE_DIR"
echo "Release tag: $RELEASE_TAG"
