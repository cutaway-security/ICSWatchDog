#!/usr/bin/env bash
#
# claude-dev/release.sh
#
# Automates Steps 1-5 of GIT_RELEASE_STEPS.md and stops before any
# destructive action. Force-pushing to main and tagging the release on
# main are printed as copy-paste commands for you to run manually.
#
# Usage: ./claude-dev/release.sh <version>
#        e.g. ./claude-dev/release.sh 9
#
# Run from the repo root.

set -euo pipefail

# ----- args -----
if [ $# -ne 1 ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 9"
    exit 1
fi

VERSION="$1"
DEV_TAG="dev-v${VERSION}"
REL_TAG="v${VERSION}"
REL_BRANCH="release-v${VERSION}"

# ----- output helpers -----
if [ -t 1 ]; then
    RED=$'\033[0;31m'
    YELLOW=$'\033[0;33m'
    GREEN=$'\033[0;32m'
    BOLD=$'\033[1m'
    RESET=$'\033[0m'
else
    RED=""; YELLOW=""; GREEN=""; BOLD=""; RESET=""
fi

say()  { echo "${BOLD}$*${RESET}"; }
ok()   { echo "  ${GREEN}OK${RESET}: $*"; }
warn() { echo "  ${YELLOW}WARN${RESET}: $*"; }
die()  { echo "${RED}ERROR${RESET}: $*" >&2; exit 1; }

confirm() {
    # $1 = prompt. Returns 0 on y/Y, 1 otherwise.
    local reply
    read -r -p "$1 [y/N] " reply
    [ "$reply" = "y" ] || [ "$reply" = "Y" ]
}

# ----- preflight -----
say "=== Preflight checks ==="

[ -d ".git" ] || die "Must be run from the repo root (no .git directory here)"

CUR_BRANCH=$(git rev-parse --abbrev-ref HEAD)
[ "$CUR_BRANCH" = "claude-dev" ] || die "Must be on claude-dev branch (currently on $CUR_BRANCH)"
ok "On claude-dev branch"

if [ -n "$(git status --porcelain)" ]; then
    die "Working tree is not clean. Commit or stash changes first."
fi
ok "Working tree is clean"

if git rev-parse "$DEV_TAG" >/dev/null 2>&1; then
    die "Tag $DEV_TAG already exists. Pick a different version or delete the tag."
fi
ok "Tag $DEV_TAG does not yet exist"

if git rev-parse "$REL_TAG" >/dev/null 2>&1; then
    die "Tag $REL_TAG already exists. Pick a different version."
fi
ok "Tag $REL_TAG does not yet exist"

if git show-ref --quiet "refs/heads/$REL_BRANCH"; then
    die "Branch $REL_BRANCH already exists. Delete it or pick a different version."
fi
ok "Branch $REL_BRANCH does not yet exist"

if git fetch origin claude-dev >/dev/null 2>&1; then
    LOCAL=$(git rev-parse claude-dev)
    REMOTE=$(git rev-parse origin/claude-dev 2>/dev/null || echo "")
    if [ -n "$REMOTE" ] && [ "$LOCAL" != "$REMOTE" ]; then
        die "Local claude-dev differs from origin/claude-dev. Push or pull first."
    fi
    ok "claude-dev is in sync with origin"
else
    warn "Could not fetch origin/claude-dev (offline?). Continuing."
fi

# ----- website-only detection -----
PREV_DEV_TAG=$(git tag --list 'dev-v*' --sort=-v:refname | head -n1)
if [ -n "$PREV_DEV_TAG" ]; then
    echo ""
    say "=== Change scope since $PREV_DEV_TAG ==="
    CHANGED_FILES=$(git diff --name-only "$PREV_DEV_TAG..HEAD")
    if [ -z "$CHANGED_FILES" ]; then
        die "No changes since $PREV_DEV_TAG. Nothing to release."
    fi

    CHANGE_COUNT=$(echo "$CHANGED_FILES" | wc -l)
    NON_DOCS_CHANGED=$(echo "$CHANGED_FILES" | grep -v '^docs/' || true)

    if [ -z "$NON_DOCS_CHANGED" ]; then
        echo ""
        say "  ${YELLOW}Only docs/ files changed since $PREV_DEV_TAG ($CHANGE_COUNT file(s)).${RESET}"
        echo ""
        echo "  A full release may not be needed. Website-only changes can be"
        echo "  shipped by running just the deploy script:"
        echo ""
        echo "      ./claude-dev/deploy-site.sh"
        echo ""
        echo "  That updates gh-pages with the new website and does not touch"
        echo "  main, does not cut a new release of configs or tools, and does"
        echo "  not create new tags."
        echo ""
        if ! confirm "Proceed with full release v${VERSION} anyway?"; then
            echo ""
            echo "Aborted. Run ./claude-dev/deploy-site.sh to ship the website changes."
            exit 0
        fi
    else
        NON_DOCS_COUNT=$(echo "$NON_DOCS_CHANGED" | wc -l)
        ok "$CHANGE_COUNT files changed ($NON_DOCS_COUNT outside docs/)"
    fi
fi

# ----- manual checklist -----
echo ""
say "=== Manual pre-release checklist ==="
echo "Confirm each of the following is true before proceeding:"
echo "  - PLAN.md reflects current completion status"
echo "  - RESUME.md is up to date with this release's work"
echo "  - README.md is accurate for the public release"
echo "  - NOTICE file is current (attribution, third-party content)"
echo "  - No sensitive data, credentials, or internal references in shipping files"
echo "  - All site links to configs and repo point to main branch"
echo ""
if ! confirm "All of the above confirmed?"; then
    die "Aborted. Update the items above, then re-run."
fi

# ----- automated checks -----
echo ""
say "=== Automated checks ==="

FAILED=0
for f in sysmon-configs/*.xml sysmon-configs/community/*.xml sysmon-configs/reference/*.xml; do
    if ! xmllint --noout "$f" 2>/dev/null; then
        echo "  FAIL: $f"
        FAILED=$((FAILED+1))
    fi
done
[ $FAILED -eq 0 ] || die "$FAILED XML files failed validation"
ok "All curated/community/reference XML configs pass xmllint"

TBD_HITS=$(grep -rn '\[TBD\]' README.md sysmon-configs/ tools/ 2>/dev/null || true)
if [ -n "$TBD_HITS" ]; then
    echo "$TBD_HITS"
    warn "Found [TBD] markers in shipping files (see above)"
    if ! confirm "Proceed anyway?"; then
        die "Aborted. Resolve [TBD] markers, then re-run."
    fi
else
    ok "No [TBD] markers in shipping files"
fi

# ----- Step 2: tag claude-dev -----
echo ""
say "=== Step 2: Tag claude-dev as $DEV_TAG ==="
read -r -p "Brief description for the tag message: " TAG_MSG
[ -n "$TAG_MSG" ] || die "Tag message cannot be empty"

git tag -a "$DEV_TAG" -m "Release v${VERSION}: ${TAG_MSG}"
ok "Created tag $DEV_TAG locally"

git push origin "$DEV_TAG"
ok "Pushed $DEV_TAG to origin"

# ----- Step 3: release branch -----
echo ""
say "=== Step 3: Create $REL_BRANCH ==="
git checkout -b "$REL_BRANCH"
ok "Checked out $REL_BRANCH"

# ----- Step 4: remove dev files -----
echo ""
say "=== Step 4: Remove development files ==="
git rm -rq claude-dev/
git rm -rq docs/
git rm -q CLAUDE.md
git rm -q tools/Test-GetSysmonCoverage.ps1
git rm -q tools/Test-CompareSystemInventory.ps1
git rm -q tools/Test-MergeSysmonModules.ps1
git rm -rq tools/test-fixtures/

# Clean up any untracked Jekyll build artifacts left behind
rm -rf docs/vendor docs/_site docs/.bundle 2>/dev/null || true
# Remove now-empty docs/ directory if it's still on disk
[ -d docs ] && rmdir docs 2>/dev/null || true

ok "Dev files removed"

git commit -q -m "Remove dev files for release v${VERSION}"
ok "Release commit created"

# ----- Step 5: verify -----
echo ""
say "=== Step 5: Verify release branch ==="

MISSING=0
for required_file in README.md License NOTICE CNAME; do
    if [ ! -f "$required_file" ]; then
        echo "  MISSING FILE: $required_file"
        MISSING=$((MISSING+1))
    fi
done
for required_dir in sysmon-configs images .github/ISSUE_TEMPLATE; do
    if [ ! -d "$required_dir" ]; then
        echo "  MISSING DIR: $required_dir"
        MISSING=$((MISSING+1))
    fi
done
[ $MISSING -eq 0 ] || die "$MISSING required items missing from release branch"
ok "All required user-facing files present"

ABSENT_VIOLATIONS=0
for forbidden in claude-dev docs CLAUDE.md tools/test-fixtures \
                 tools/Test-GetSysmonCoverage.ps1 \
                 tools/Test-CompareSystemInventory.ps1 \
                 tools/Test-MergeSysmonModules.ps1; do
    if [ -e "$forbidden" ]; then
        echo "  STILL PRESENT: $forbidden"
        ABSENT_VIOLATIONS=$((ABSENT_VIOLATIONS+1))
    fi
done
[ $ABSENT_VIOLATIONS -eq 0 ] || die "$ABSENT_VIOLATIONS dev items still present on release branch"
ok "All dev items absent"

FAILED=0
for f in sysmon-configs/*.xml sysmon-configs/community/*.xml sysmon-configs/reference/*.xml; do
    if ! xmllint --noout "$f" 2>/dev/null; then
        echo "  FAIL: $f"
        FAILED=$((FAILED+1))
    fi
done
[ $FAILED -eq 0 ] || die "$FAILED XML files failed validation on release branch"
ok "XML validation passes on release branch"

# ----- manual commands -----
echo ""
say "=============================================================="
say "  Release branch $REL_BRANCH is ready."
say "=============================================================="
echo ""
echo "Review before shipping:"
echo ""
echo "    git log --stat $REL_BRANCH | head -40"
echo "    git diff main..$REL_BRANCH --stat"
echo "    git ls-tree -r $REL_BRANCH --name-only | grep -E '^(claude-dev|docs|CLAUDE)' || echo OK"
echo ""
echo "When you are satisfied, ship the release by running these commands"
echo "MANUALLY. Force-push to main is never automated."
echo ""
echo "    # Step 6: Force-push to main"
echo "    git checkout main"
echo "    git reset --hard $REL_BRANCH"
echo "    git push origin main --force"
echo ""
echo "    # Step 7: Tag the release on main"
echo "    git tag -a $REL_TAG -m \"Release v${VERSION}\""
echo "    git push origin $REL_TAG"
echo ""
echo "    # Step 8: Clean up"
echo "    git checkout claude-dev"
echo "    git branch -d $REL_BRANCH"
echo ""
echo "    # Step 9: Deploy website to gh-pages"
echo "    ./claude-dev/deploy-site.sh"
echo ""
echo "If something looks wrong, abandon the release with:"
echo ""
echo "    git checkout claude-dev"
echo "    git branch -D $REL_BRANCH"
echo "    git tag -d $DEV_TAG"
echo "    git push origin :refs/tags/$DEV_TAG"
echo ""
