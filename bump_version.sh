#!/bin/bash
set -e

# Get the current version
git fetch --tags
CURRENT_VERSION=$(git describe --tags `git rev-list --tags --max-count=1` 2>/dev/null || echo "0.0.0")

# Default bump type
DEFAULT_BUMP=${DEFAULT_BUMP:-minor}

# Get the current version
CURRENT_VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "0.0.0")

# Remove the 'v' prefix if it exists
CURRENT_VERSION=${CURRENT_VERSION#v}

# Split the version into parts
IFS='.' read -r -a VERSION_PARTS <<< "$CURRENT_VERSION"
MAJOR="${VERSION_PARTS[0]}"
MINOR="${VERSION_PARTS[1]}"
PATCH="${VERSION_PARTS[2]}"

# Bump the version
case $DEFAULT_BUMP in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
  *)
    echo "Unknown bump type: $DEFAULT_BUMP"
    exit 1
    ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"

# Update version in setup.py
sed -i "s/version=\".*\"/version=\"$NEW_VERSION\"/" setup.py

# Configure git to use the GITHUB_TOKEN
git config --global user.name "github-actions"
git config --global user.email "github-actions@github.com"

# Set the remote URL with the GITHUB_TOKEN
git remote set-url origin "https://${GITHUB_TOKEN}@github.com/tawanda-kembo/code-collator.git"

# Check if the tag already exists
if git rev-parse "v$NEW_VERSION" >/dev/null 2>&1; then
    echo "Tag v$NEW_VERSION already exists. Skipping tag creation."
else
    # Create a new tag
    git tag "v$NEW_VERSION"

    # Push the tag using the GITHUB_TOKEN
    git push origin "v$NEW_VERSION"
fi

# Set the output variable for the new version
echo "::set-output name=NEW_VERSION::v$NEW_VERSION"