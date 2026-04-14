# GIT_RELEASE_STEPS.md

**Repository:** `https://github.com/cutaway-security/ICSWatchDog.git`
**Live Site:** `https://icswatchdog.com`

## Overview

All development occurs on the `claude-dev` branch. Releases strip development files and force-push to `main`. Main is a deployment target only -- no work is committed there directly. The website is deployed separately to the `gh-pages` branch via deploy-site.sh.

### Defensive layer: .gitattributes export-ignore

`.gitattributes` at the repo root marks these paths as `export-ignore`:

- `claude-dev/` (whole directory)
- `docs/` (whole directory)
- `CLAUDE.md`
- `tools/Test-GetSysmonCoverage.ps1`
- `tools/Test-CompareSystemInventory.ps1`
- `tools/Test-MergeSysmonModules.ps1`
- `tools/test-fixtures/`

This is a structural safety net behind the manual `git rm` step in Section 4 below: any future release path that uses `git archive` or relies on GitHub's auto-generated release tarballs will automatically exclude those paths even if the manual step is missed. The current force-push process is unaffected and continues to work as documented. When adding a new dev-only path under the repo root, add it to both `.gitattributes` (export-ignore) and to Section 4 below (manual `git rm`).

### Helper script

`claude-dev/release.sh` automates Steps 1-5 below (all local, reversible operations) and stops before any push to `main`. It prints the exact commands for Steps 6-9 to run manually. See Section "Using release.sh" below for the recommended flow. The manual steps are documented in full because they remain the authoritative procedure and the rollback path.

### Tag and Branch Naming

| Item | Format | Example | Purpose |
|------|--------|---------|---------|
| Dev snapshot tag | `dev-v#` | `dev-v3` | Marks the claude-dev state that produced a release |
| Release branch | `release-v#` | `release-v3` | Temporary branch for stripping dev files |
| Main release tag | `v#` | `v3` | Marks the public release on main; used for rollbacks |


List existing tags before creating a new one:

```bash
git tag
```

## Pre-Release Checklist

- [ ] All changes committed and pushed on `claude-dev`
- [ ] PLAN.md reflects current completion status
- [ ] RESUME.md is up to date
- [ ] README.md is accurate for the public release
- [ ] `NOTICE` file is current (attribution, third-party content, dual-license statement)
- [ ] No sensitive data, credentials, or internal references in code or docs
- [ ] No `[TBD]` or placeholder markers visible to end users
- [ ] All site links to configs and repo point to main branch
- [ ] All XML configs pass validation: `for f in sysmon-configs/*.xml sysmon-configs/community/*.xml sysmon-configs/reference/*.xml; do xmllint --noout "$f"; done`

## Using release.sh (Recommended)

The helper script runs Steps 1-5 automatically and stops before any destructive action:

```bash
./claude-dev/release.sh <version>     # e.g. ./claude-dev/release.sh 9
```

What it does:

1. Preflight: verifies you are on `claude-dev`, tree is clean, `dev-v#` / `v#` / `release-v#` do not already exist, local `claude-dev` is in sync with `origin/claude-dev`
2. **Website-only detection:** compares HEAD to the most recent `dev-v*` tag. If only files under `docs/` changed, it recommends running `./claude-dev/deploy-site.sh` instead of cutting a full release, and asks for confirmation before continuing
3. Prompts you to confirm the manual pre-release checklist items (PLAN/RESUME/README/NOTICE accuracy, no sensitive data, site links point to `main`)
4. Runs automated checks: xmllint on all configs, grep for `[TBD]` markers in shipping files
5. Creates and pushes `dev-v#` on `claude-dev`
6. Creates `release-v#`, runs the `git rm` file list, commits "Remove dev files for release v#"
7. Verifies the release branch: required files present, dev files absent, xmllint passes
8. **Stops.** Prints the exact Step 6/7/8/9 commands (force-push to main, tag `v#`, cleanup, deploy site) for you to run manually

If anything looks wrong at the stop point, the script prints abandon commands to delete the release branch and the `dev-v#` tag.

If you prefer to run the process manually, the full procedure follows.

## Release Steps

### 1. Verify starting state

Confirm you are on `claude-dev` with a clean working tree:

```bash
git status
```

Expected: `On branch claude-dev` with `nothing to commit, working tree clean`. If there are uncommitted changes, commit or stash them before proceeding.

### 2. Tag the release on claude-dev

```bash
git tag -a dev-v# -m "Release v#: <brief description>"
git push origin --tags
```

### 3. Create a release branch

```bash
git checkout -b release-v#
git status
```

Confirm: `On branch release-v#`.

### 4. Remove development files

```bash
git rm -r claude-dev/
git rm -r docs/
git rm CLAUDE.md
git rm tools/Test-GetSysmonCoverage.ps1
git rm tools/Test-CompareSystemInventory.ps1
git rm tools/Test-MergeSysmonModules.ps1
git rm -r tools/test-fixtures/
git status
```

**NOTE:** `git rm -r docs/` only removes tracked files. If you have run Jekyll
locally (`bundle install`, `jekyll build`), untracked files will remain on disk
(vendor/bundle/, _site/, .bundle/). These are in .gitignore and will NOT be in
the commit. If the docs/ directory still appears after `git rm`, clean up with:

```bash
rm -rf docs/vendor docs/_site docs/.bundle
```

Confirm: only development file deletions are staged. No unexpected changes.

```bash
git commit -m "Remove development files for release v#"
```

### 5. Verify the release branch

- [ ] All user-facing files are present: sysmon-configs/ (with community/ and reference/), README.md, License, NOTICE, images/, CNAME, .github/ISSUE_TEMPLATE/
- [ ] No development files remain (`ls claude-dev/` should fail, `ls docs/` should fail, `ls CLAUDE.md` should fail, `ls tools/test-fixtures/` should fail, `ls tools/Test-GetSysmonCoverage.ps1` should fail)
- [ ] Validate XML configs: `for f in sysmon-configs/*.xml sysmon-configs/community/*.xml sysmon-configs/reference/*.xml; do xmllint --noout "$f"; done`

### 6. Force-push to main

Main is a deployment target only. Force-push replaces it entirely with the clean release branch.

Confirm you are on the release branch before proceeding:

```bash
git status
```

Expected: `On branch release-v#` with `nothing to commit, working tree clean`.

```bash
git checkout main
git reset --hard release-v#
git push origin main --force
```

### 7. Tag the release on main

```bash
git tag -a v# -m "Release v#"
git push origin --tags
```

### 8. Clean up

```bash
git checkout claude-dev
git branch -d release-v#
```

### 9. Deploy website to gh-pages

```bash
./claude-dev/deploy-site.sh
```

## Post-Release

- Update PLAN.md on claude-dev with next phase goals
- Update RESUME.md with release summary

## Website-Only Deployment

To deploy website changes without a full release (e.g., documentation updates, page fixes, styling changes):

1. Commit and push changes on `claude-dev`
2. Run the deploy script:

```bash
./claude-dev/deploy-site.sh
```

This updates the `gh-pages` branch without affecting `main`. No tagging or release branch needed.

## Rollback

If a release needs to be reverted, reset main to the previous release tag:

```bash
git checkout main
git reset --hard v<PREVIOUS#>
git push origin main --force
```

## Files Removed During Release

The following files exist only on the `claude-dev` branch and are stripped before pushing to `main`:

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Claude Code project configuration |
| `claude-dev/PLAN.md` | Development plan and task tracking |
| `claude-dev/RESUME.md` | Session history and context |
| `claude-dev/ARCHITECTURE.md` | Technical architecture reference |
| `claude-dev/GIT_RELEASE_STEPS.md` | This file |
| `claude-dev/GITHUB_ISSUE_STANDARD.md` | Issue template and label conventions |
| `claude-dev/deploy-site.sh` | Website deployment script |
| `claude-dev/release.sh` | Release helper script |
| `claude-dev/html-css-jekyll.md` | Code standard reference |
| `claude-dev/SYSMON_CODING_STANDARD.md` | Sysmon XML coding standard |
| `claude-dev/TOOL_CODING_STANDARD.md` | PowerShell/Python tool coding standard |
| `claude-dev/REMOTE_TESTING.md` | Proxmox remote test environment setup |
| `claude-dev/TESTING_STANDARD.md` | Config and script testing procedures |
| `claude-dev/test-fixtures/` | Dev-only test fixtures for tool harnesses |
| `tools/Test-GetSysmonCoverage.ps1` | Coverage tool test harness (needs dev fixtures) |
| `tools/Test-CompareSystemInventory.ps1` | Compare tool test harness (needs dev fixtures) |
| `tools/Test-MergeSysmonModules.ps1` | Merge tool test harness (needs dev fixtures) |
| `tools/test-fixtures/` | Merge tool test fixtures |
| `docs/` | Jekyll website source (deployed separately to gh-pages) |

**Note**: `tools/Test-SysmonConfig.ps1` IS shipped. It tests against the live system and does not depend on fixtures. All other `Test-*.ps1` scripts are dev-only.

The entire `claude-dev/` directory is also marked `export-ignore` in `.gitattributes` as a defensive safety net (see Overview).
