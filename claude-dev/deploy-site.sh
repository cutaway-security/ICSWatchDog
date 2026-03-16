#!/bin/bash
# deploy-site.sh - Deploy the site/ directory contents to the gh-pages branch
#
# Usage: Run from the repository root while on the claude-dev branch.
#   ./claude-dev/deploy-site.sh
#
# This script:
# 1. Verifies you are on the claude-dev branch
# 2. Verifies the site/ directory exists
# 3. Copies site/ contents to a temporary location
# 4. Switches to gh-pages (orphan branch if it does not exist)
# 5. Replaces gh-pages content with site/ contents
# 6. Commits and pushes to gh-pages
# 7. Switches back to claude-dev

set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"
SITE_DIR="${REPO_ROOT}/site"
TEMP_DIR="$(mktemp -d)"

# Verify we are on claude-dev
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [ "${CURRENT_BRANCH}" != "claude-dev" ]; then
    echo "ERROR: Must be on claude-dev branch. Currently on: ${CURRENT_BRANCH}"
    exit 1
fi

# Verify site/ exists and has content
if [ ! -d "${SITE_DIR}" ]; then
    echo "ERROR: site/ directory not found at ${SITE_DIR}"
    exit 1
fi

if [ -z "$(ls -A "${SITE_DIR}")" ]; then
    echo "ERROR: site/ directory is empty"
    exit 1
fi

echo "Copying site/ contents to temporary directory..."
cp -r "${SITE_DIR}/." "${TEMP_DIR}/"

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "ERROR: You have uncommitted changes on claude-dev. Commit or stash them first."
    rm -rf "${TEMP_DIR}"
    exit 1
fi

echo "Switching to gh-pages branch..."
if git show-ref --verify --quiet refs/heads/gh-pages; then
    git checkout gh-pages
else
    echo "Creating new orphan gh-pages branch..."
    git checkout --orphan gh-pages
    git rm -rf . 2>/dev/null || true
fi

# Remove existing content (except .git)
echo "Clearing existing gh-pages content..."
find . -maxdepth 1 -not -name '.git' -not -name '.' -exec rm -rf {} +

# Copy site contents
echo "Deploying site contents..."
cp -r "${TEMP_DIR}/." .

# Stage and commit
git add -A
if git diff --cached --quiet; then
    echo "No changes to deploy."
else
    DEPLOY_DATE="$(date +%Y-%m-%d_%H%M%S)"
    git commit -m "Deploy site ${DEPLOY_DATE}"
    echo "Pushing to gh-pages..."
    git push origin gh-pages
    echo "Site deployed successfully."
fi

# Clean up and switch back
rm -rf "${TEMP_DIR}"
echo "Switching back to claude-dev..."
git checkout claude-dev

echo "Done. Verify the site at https://icswatchdog.com"
