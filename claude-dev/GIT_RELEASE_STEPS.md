# GIT_RELEASE_STEPS.md

**Repository:** `https://github.com/cutaway-security/ICSWatchDog.git`
**Live Site:** `https://icswatchdog.com`

## Overview

All development occurs on the `claude-dev` branch. Releases strip development files and force-push to `main`. Main is a deployment target only -- no work is committed there directly. The website is deployed separately to the `gh-pages` branch via deploy-site.sh.

### Tag and Branch Naming

| Item | Format | Example | Purpose |
|------|--------|---------|---------|
| Dev snapshot tag | `release-v#` | `release-v3` | Marks the claude-dev state that produced a release |
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
git tag -a release-v# -m "Release v#: <brief description>"
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
git rm -r .claude/
git rm CLAUDE.md
git status
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
| `docs/` | Jekyll website source (deployed separately to gh-pages) |
| `.claude/` | Claude Code session data |
