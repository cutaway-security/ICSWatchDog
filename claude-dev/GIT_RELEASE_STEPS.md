# GIT_RELEASE_STEPS.md

## Release Process

All development occurs on the `claude-dev` branch. When a version is ready for public release, follow these steps.

### Tagging Convention

- claude-dev tag: `release-v<VERSION>` (marks the development snapshot)
- Release branch: `release-v<VERSION>` (used for stripping dev files before merge)
- main tag: `v<VERSION>` (marks the public release)

### Pre-Release Checklist

- [ ] All planned features for this release are complete and tested
- [ ] PLAN.md reflects current completion status
- [ ] RESUME.md is up to date
- [ ] README.md is accurate for the public release
- [ ] No sensitive data, credentials, or internal references in code or docs
- [ ] All site links to configs and repo point to main branch
- [ ] All changes committed on claude-dev

### Release Steps

1. **Check current branch and switch to claude-dev if needed**

   ```bash
   git status
   git checkout claude-dev  # if not already on claude-dev
   ```

2. **Check existing tags to determine next version**

   ```bash
   git tag
   ```

3. **Tag the release on claude-dev**

   ```bash
   git tag -a release-v<VERSION> -m "Release v<VERSION>: <brief description>"
   ```

4. **Create a release branch**

   ```bash
   git checkout -b release-v<VERSION>
   ```

5. **Remove development-only files and directories**

   ```bash
   rm -rf claude-dev/
   rm -rf docs/
   rm -rf .claude/
   rm -f CLAUDE.md
   ```

6. **Verify the release branch**

   - Confirm user-facing files are present: sysmon-configs/ (with community/ and reference/), README.md, License, images/, CNAME
   - Confirm no development files remain (claude-dev/, docs/, .claude/, CLAUDE.md)
   - Validate XML configs: `for f in sysmon-configs/*.xml sysmon-configs/community/*.xml sysmon-configs/reference/*.xml; do xmllint --noout "$f"; done`

7. **Merge to main**

   ```bash
   git checkout main
   git merge release-v<VERSION>
   git tag -a v<VERSION> -m "Release v<VERSION>"
   git push origin main --tags
   ```

8. **Clean up release branch**

   ```bash
   git branch -d release-v<VERSION>
   git checkout claude-dev
   ```

9. **Deploy website to gh-pages**

   ```bash
   ./claude-dev/deploy-site.sh
   ```

### Post-Release

- Update PLAN.md on claude-dev with next phase goals
- Update RESUME.md with release summary
