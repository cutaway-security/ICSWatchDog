# GIT_RELEASE_STEPS.md

**Repository:** `https://github.com/cutaway-security/ICSWatchDog.git`
**Live Site:** `https://icswatchdog.com`

## Overview

All development occurs on the `claude-dev` branch. Releases strip development files and force-push to `main`. Main is a deployment target only -- no work is committed there directly. The website is deployed separately to the `gh-pages` branch via deploy-site.sh.

### Defensive layer: .gitattributes export-ignore

`.gitattributes` at the repo root marks `claude-dev/`, `docs/`, and `CLAUDE.md` as `export-ignore`. This is a structural safety net behind the manual `git rm` step in Section 4 below: any future release path that uses `git archive` or relies on GitHub's auto-generated release tarballs will automatically exclude those paths even if the manual step is missed. The current force-push process is unaffected and continues to work as documented. When adding a new dev-only path under the repo root, add it to both `.gitattributes` (export-ignore) and to Section 4 below (manual `git rm`).

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
- [ ] No sensitive data, credentials, or internal references in code or docs
- [ ] No `[TBD]` or placeholder markers visible to end users
- [ ] All site links to configs and repo point to main branch
- [ ] All XML configs pass validation: `for f in sysmon-configs/*.xml sysmon-configs/community/*.xml sysmon-configs/reference/*.xml; do xmllint --noout "$f"; done`

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

- [ ] All user-facing files are present: sysmon-configs/ (with community/ and reference/), README.md, License, images/, CNAME
- [ ] No development files remain (`ls claude-dev/` should fail, `ls docs/` should fail, `ls CLAUDE.md` should fail)
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
| `claude-dev/deploy-site.sh` | Website deployment script |
| `claude-dev/html-css-jekyll.md` | Code standard reference |
| `claude-dev/SYSMON_CODING_STANDARD.md` | Sysmon XML coding standard |
| `claude-dev/TOOL_CODING_STANDARD.md` | PowerShell/Python tool coding standard |
| `claude-dev/REMOTE_TESTING.md` | Proxmox remote test environment setup |
| `claude-dev/remote-testing.example.conf` | Local-config template (real config gitignored) |
| `claude-dev/test-fixtures/` | Dev-only test fixtures for tool harnesses |
| `docs/` | Jekyll website source (deployed separately to gh-pages) |

The entire `claude-dev/` directory is also marked `export-ignore` in `.gitattributes` as a defensive safety net (see Overview).
