# GIT_RELEASE_STEPS.md

## Release Process

All development occurs on the `claude-dev` branch. When a version is ready for public release, follow these steps.

### Pre-Release Checklist

- [ ] All planned features for this release are complete and tested
- [ ] PLAN.md reflects current completion status
- [ ] RESUME.md is up to date
- [ ] README.md is accurate for the public release
- [ ] No sensitive data, credentials, or internal references in code or docs
- [ ] All site links to configs and repo point to main branch

### Release Steps

1. **Tag the release on claude-dev**

   ```bash
   git checkout claude-dev
   git tag -a v<VERSION> -m "Release v<VERSION>: <brief description>"
   ```

2. **Create a release branch**

   ```bash
   git checkout -b release/v<VERSION>
   ```

3. **Remove development-only files and directories**

   ```bash
   rm -rf claude-dev/
   rm -rf docs/
   rm -f CLAUDE.md
   rm -f index.html  # if still present
   ```

4. **Verify the release branch**

   - Confirm all user-facing files are present and correct (configs, README, License, images)
   - Confirm no development files remain (claude-dev/, docs/, CLAUDE.md)
   - Validate XML configs are well-formed
   - Review README.md for accuracy

5. **Merge to main**

   ```bash
   git checkout main
   git merge release/v<VERSION>
   git tag -a v<VERSION>-release -m "Release v<VERSION>"
   git push origin main --tags
   ```

6. **Deploy website to gh-pages**

   ```bash
   git checkout claude-dev
   ./claude-dev/deploy-site.sh
   ```

7. **Clean up**

   ```bash
   git branch -d release/v<VERSION>
   git checkout claude-dev
   ```

8. **Create GitHub release** (if applicable)

   ```bash
   gh release create v<VERSION> --title "v<VERSION>" --notes "Release notes here"
   ```

### Post-Release

- Update PLAN.md on claude-dev with next phase goals
- Update RESUME.md with release summary
- Verify icswatchdog.com is serving the updated site
- Verify all config download links on the site point to main branch and work correctly
