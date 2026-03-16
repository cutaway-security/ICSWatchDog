# PLAN.md

## Project Goal

Provide a usable, tiered set of Sysmon configuration files for ICS/OT environments with clear documentation that enables Windows administrators to deploy and mature endpoint monitoring.

## Current Phase

**Phase**: Phase 2 - Website Build
**Status**: Complete
**Focus**: Awaiting review before proceeding to Phase 3a

## Phases

### Phase 1: Project Foundation

**Status**: Complete

- [x] Update CLAUDE.md with project-specific content
- [x] Update ARCHITECTURE.md with system design
- [x] Update PLAN.md with development roadmap
- [x] Update RESUME.md with current session state
- [x] Update GIT_RELEASE_STEPS.md to include site/ exclusion and gh-pages deploy step
- [x] Remove index.html from claude-dev branch (replaced by Jekyll site and descriptive README)
- [x] Create deploy script for pushing site/ to gh-pages

### Phase 2: Website Build

**Status**: Complete (pending review, deploy deferred to Phase 5)

- [x] Initialize site/ directory with Jekyll project structure
- [x] Configure Just the Docs theme (gem-based, dark color scheme)
- [x] Migrate branding assets (logo, banner, background, favicon) into site/assets/images/
- [x] Create landing page (project overview, value proposition, quick links)
- [x] Create config listing page (all tiers with descriptions and links to main branch)
- [x] Create getting-started page (what is Sysmon, why use it in ICS/OT, deployment steps)
- [x] Update README.md to be descriptive and helpful as the repo landing page for GitHub visitors
- [x] Set up CNAME for icswatchdog.com in site/
- [x] Test local Jekyll build (successful, 0.339s)
- [ ] Deploy to gh-pages and verify (deferred to Phase 5 release)

### Phase 3a: Sysmon Research and Audit

**Status**: Not Started

- [ ] Research current Sysmon version, schema history, and feature additions since schema 4.50
- [ ] Research SwiftOnSecurity sysmon-config for newer versions
- [ ] Document which Sysmon features require which minimum version/schema
- [ ] Audit existing configs for ICS/OT relevance vs generic IT rules
- [ ] Document findings in RESUME.md for reference during 3b/3c

### Phase 3b: Config Restructuring and Naming

**Status**: Not Started

- [ ] Rename sysmonconfig-export.xml to indicate it is the SwiftOnSecurity reference with proper attribution
- [ ] Retain sysmonconfig-filecreate-only.xml as standalone use-case config with proper attribution to Aaron Boyd (icsblitz)
- [ ] Establish consistent naming convention across all configs (tiers, standalone, reference)
- [ ] Document minimum Sysmon version required per config file in XML headers

### Phase 3c: Tier Implementation

**Status**: Not Started

Each tier may have multiple config variants (e.g., a legacy-safe version using schema 4.50 and a current version using the latest schema). The research in Phase 3a will determine which tiers need separate variants based on feature differences between schema versions.

- [ ] Define and implement Tier 1 (Starter) config -- legacy variant (schema 4.50) and current variant if applicable
- [ ] Define and implement Tier 2 (Baseline) config -- legacy variant (schema 4.50) and current variant if applicable
- [ ] Define and implement Tier 3 (Enhanced) config -- legacy variant if feasible, current variant using newer schema features
- [ ] Review sysmonconfig-adv-workstation.xml as basis for Tier 4 -- current variant only, leverages newest Sysmon features
- [ ] Establish naming convention for legacy vs current variants within each tier
- [ ] Update site documentation pages with per-config details including version compatibility

### Phase 4: Documentation

**Status**: Not Started

- [ ] Write deployment guide (Sysmon installation, config application, verification)
- [ ] Write config selection guide (which tier for which situation)
- [ ] Write customization guide (adding exclusions, tuning for specific environments)
- [ ] Write advancement guide (progressing through tiers, specializing for ICS roles)
- [ ] Document legacy OS considerations and Sysmon version compatibility per tier
- [ ] Include guidance on how standalone configs (like file-create-only) can complement tier configs
- [ ] Add per-config documentation pages to the site
- [ ] Review all documentation for accuracy and completeness

### Phase 5: Release

**Status**: Not Started

- [ ] Final review of all configs and documentation
- [ ] Merge configs, README, License, and images to main (exclude site/ and claude-dev/)
- [ ] Remove index.html from main during merge (if not already removed)
- [ ] Deploy site to gh-pages
- [ ] Verify all site links point to main branch
- [ ] Verify README.md on main is descriptive and current
- [ ] Tag release
- [ ] Create GitHub release

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-03-16 | Website source in site/ on claude-dev, deployed to gh-pages | Users cloning main for configs should not get website source files |
| 2026-03-16 | Just the Docs theme via remote_theme | Documentation-focused, lightweight, hierarchical navigation, no vendored files |
| 2026-03-16 | Tiered config progression (Starter through Advanced) | Lowers barrier to entry, provides growth path for maturity |
| 2026-03-16 | SwiftOnSecurity config retained as reference with attribution | Provides familiar baseline, proper credit to source project |
| 2026-03-16 | All site links to configs and repo point to main branch | Public-facing content must reference stable release branch |
| 2026-03-16 | Start with general configs, specialize later | Vendor/client-specific configs vary too much; provide guidance instead |
| 2026-03-16 | Tier 1/2 use schema 4.50 for legacy OS compatibility | ICS/OT environments frequently run legacy Windows; starter configs must work everywhere |
| 2026-03-16 | File-create-only config starts as standalone, may integrate later | Authored by experienced ICS/OT team member, serves specific use case outside tier progression |
| 2026-03-16 | Remove index.html, use README as repo landing page | Jekyll site serves as the public website; README serves GitHub visitors; index.html is redundant |
| 2026-03-16 | Existing configs are starting points, not sacred | Updates and restructuring are expected as the project matures |

## Out of Scope

- Automated config generation tooling
- SIEM-specific integration guides
- Non-Windows endpoint monitoring
- Vendor-specific ICS application rule sets (guidance only, not configs)
- Config testing on live ICS systems (testing is on general Windows)
