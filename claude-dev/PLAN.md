# PLAN.md

## Project Goal

Provide a usable, progressive set of Sysmon configuration files for ICS/OT environments -- mapped to the SANS ICS 5 Critical Controls -- with clear documentation that enables Windows administrators to deploy and mature endpoint monitoring.

## Current Phase

**Phase**: Phase 3a - Sysmon Research and Audit
**Status**: Complete
**Focus**: Updating planning documents with research findings and revised approach

## Phases

### Phase 1: Project Foundation

**Status**: Complete

- [x] Update CLAUDE.md with project-specific content
- [x] Update ARCHITECTURE.md with system design
- [x] Update PLAN.md with development roadmap
- [x] Update RESUME.md with current session state
- [x] Update GIT_RELEASE_STEPS.md to include docs/ exclusion and gh-pages deploy step
- [x] Remove index.html from claude-dev branch (replaced by Jekyll site and descriptive README)
- [x] Create deploy script for pushing docs/ to gh-pages

### Phase 2: Website Build

**Status**: Complete (pending review, deploy deferred to Phase 5)

- [x] Initialize docs/ directory with Jekyll project structure
- [x] Configure custom Jekyll site with CutSec design system (slate + gold, dark/light toggle)
- [x] Copy CutSec branding assets (logos, favicon) into docs/img/
- [x] Copy ICS Watch Dog project images into docs/img/
- [x] Create layout template (_layouts/default.html) with nav and footer includes
- [x] Create navigation include with dropdown menus (Configurations, Guides) and mobile hamburger toggle
- [x] Create CSS based on CutSec workshop design system (no AI chat components)
- [x] Create JS for dark/light theme toggle with localStorage persistence
- [x] Create landing page with hero, config card grid, overview, and contributors
- [x] Create config listing page (all tiers with descriptions and links to main branch)
- [x] Create getting-started page (Sysmon overview, ICS/OT relevance, deployment steps)
- [x] Update README.md to be descriptive and helpful as the repo landing page for GitHub visitors
- [x] Set up CNAME for icswatchdog.com in docs/
- [x] Test local Jekyll build (successful, 0.01s, no warnings)
- [ ] Deploy to gh-pages and verify (deferred to Phase 5 release)

### Phase 3a: Sysmon Research and Audit

**Status**: Complete

- [x] Research current Sysmon version, schema history, and feature additions since schema 4.50
- [x] Research SwiftOnSecurity sysmon-config for newer versions
- [x] Document which Sysmon features require which minimum version/schema
- [x] Audit existing configs for ICS/OT relevance vs generic IT rules
- [x] Research SANS ICS 5 Critical Controls and map to Sysmon capabilities
- [x] Research remote access tool monitoring (CISA/NSA RMM guidance)
- [x] Research vendor software for OT configs (Siemens, Rockwell, Schneider, AVEVA/OSIsoft PI, Ignition, SEL)
- [x] Document findings and update plan with revised approach

Key findings:
- All four existing configs have zero ICS/OT-specific content
- sysmonconfig-adv-workstation.xml is identical to SwiftOnSecurity export (header-only fork)
- Sysmon current: v15.14, schema 4.90; native Windows integration announced for 2026
- Schema 4.82 adds IDs 27-28 (FileBlock*); schema 4.90 adds ID 29 (FileExecutableDetected)
- SwiftOnSecurity config unchanged since v74 (2021-07-08), still at schema 4.50
- SANS ICS 5 Controls map directly to Sysmon capabilities (Controls #1, #3, #4 especially)
- Remote access tool detection is critical (SANS Control #4, CISA/NSA advisories)

### Phase 3b: Config Restructuring

**Status**: Not Started

- [ ] Create community/ directory
- [ ] Move sysmonconfig-filecreate-only.xml to community/ with attribution preserved
- [ ] Create reference/ directory
- [ ] Rename sysmonconfig-export.xml to sysmonconfig-swiftonsecurity-v74.xml and move to reference/
- [ ] Remove sysmonconfig-adv-workstation.xml (identical to SwiftOnSecurity, replaced by new configs)
- [ ] Remove sysmonconfig-minimal.xml (replaced by new baseline-it)
- [ ] Add disclaimer to all retained config XML headers
- [ ] Update README.md with new file structure and disclaimer section
- [ ] Update site config listing page for new structure

### Phase 3c: Config Implementation

**Status**: Not Started

Build all configs from scratch (not forked from SwiftOnSecurity). Enterprise-focused, designed for the IT-to-OT progression. All configs include remote access tool detection by default. Admins MUST tune for their environment.

- [ ] Build sysmonconfig-baseline-it.xml (schema 4.50, enterprise IT starting point, remote access tool detection, well-commented for Windows admins new to Sysmon)
- [ ] Build sysmonconfig-baseline-ot.xml (progression of IT baseline, schema 4.50, adds OT vendor process monitoring examples, ICS file types, adjusted OT exclusions)
- [ ] Build sysmonconfig-enhanced-ot.xml (broader OT coverage, network connection monitoring for industrial ports, may use newer schema)
- [ ] Stub sysmonconfig-advanced-ot.xml (newer Sysmon features IDs 27-29, role-specific customization guidance, developed further as project matures)
- [ ] Update community/sysmonconfig-filecreate-only.xml with ICS/OT file type examples
- [ ] Validate all configs are well-formed XML

### Phase 4: Documentation

**Status**: Not Started

**Existing page updates:**
- [ ] Update Getting Started page with performance/latency section for OT environments
- [ ] Update Configuration Files page with new structure, naming, and SANS control references
- [ ] Update landing page with SANS ICS 5 Controls framing and disclaimer
- [ ] Add disclaimer to website footer

**New pages:**
- [ ] Create SANS ICS 5 Critical Controls page (dedicated mapping of controls to Sysmon/configs)
- [ ] Create Deployment Considerations page (performance impact, latency, phased rollout, criticality-based decisions, testing recommendations)
- [ ] Create Community Contributions page (how to contribute via PR or issue, review process, disclaimer for community configs)

**Documentation content:**
- [ ] Write config selection guide framed around SANS controls
- [ ] Write customization/tuning guide (admins MUST tune, remote access tool tuning, vendor-specific additions)
- [ ] Write advancement guide (IT baseline to OT advanced progression)
- [ ] Document vendor software examples with accuracy notes (Siemens, Rockwell, Schneider, AVEVA/OSIsoft PI, Ignition, SEL)
- [ ] Document remote access tool monitoring (what is detected, how to tune, CISA/NSA references)
- [ ] Document legacy OS considerations and Sysmon version compatibility
- [ ] Review all documentation for accuracy and completeness

**Navigation updates:**
- [ ] Update site nav to include new pages (SANS Controls, Deployment, Community)

### Phase 5: Release

**Status**: Not Started

- [ ] Final review of all configs and documentation
- [ ] Merge configs (including community/ and reference/ directories), README, License, and images to main (exclude docs/ and claude-dev/)
- [ ] Remove index.html from main during merge (if not already removed)
- [ ] Deploy site to gh-pages
- [ ] Verify all site links point to main branch
- [ ] Verify README.md on main is descriptive and current
- [ ] Verify disclaimer appears on site and in all config headers
- [ ] Tag release
- [ ] Create GitHub release

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-03-16 | Website source in docs/ on claude-dev, deployed to gh-pages | Users cloning main for configs should not get website source files |
| 2026-03-16 | Custom Jekyll + CutSec design system (replaced Just the Docs) | Consistent branding across CutSec projects; full control over styling |
| 2026-03-16 | Progressive config structure: IT Baseline to OT Advanced | Lowers barrier to entry; IT baseline is the universal starting point; OT configs build on it |
| 2026-03-16 | SwiftOnSecurity config retained as reference only | Familiar baseline for learning; our configs are original ICS Watch Dog work |
| 2026-03-16 | All site links to configs and repo point to main branch | Public-facing content must reference stable release branch |
| 2026-03-16 | Schema 4.50 for baseline configs (legacy OS compatibility) | ICS/OT environments frequently run legacy Windows; baseline configs must work everywhere |
| 2026-03-16 | File-create-only config moved to community/ directory | Community-contributed configs separated from curated project configs |
| 2026-03-16 | Remove index.html, use README as repo landing page | Jekyll site serves as the public website; README serves GitHub visitors |
| 2026-03-16 | Existing configs are starting points, replaced by new builds | All new configs built from scratch for the IT-to-OT progression |
| 2026-03-16 | Renamed site/ to docs/ | GitHub Pages only supports / or /docs as source directories |
| 2026-03-16 | Generate configs from scratch, not forked from SwiftOnSecurity | Cleaner attribution; rules structured for IT-to-OT progression; comments for ICS/OT audience |
| 2026-03-16 | Map project to SANS ICS 5 Critical Controls | Provides ICS/OT teams justification for deployment and management buy-in |
| 2026-03-16 | Include-log all known remote access tools by default | Aligns with SANS Control #4 and CISA/NSA RMM guidance; admins tune for approved tools |
| 2026-03-16 | Create community/ directory for contributed configs | Encourages contributions without polluting curated config set |
| 2026-03-16 | Add performance/latency documentation | Critical concern for OT admins; addresses top objection to Sysmon in production OT |
| 2026-03-16 | Uniform disclaimer across all configs and site | All configs are use-at-your-own-risk; community configs not maintained by CutSec |
| 2026-03-16 | Enterprise-focused configs, no personal application exclusions | Configs for enterprise/industrial environments, not developer workstations |
| 2026-03-16 | OT vendor examples: Siemens, Rockwell, Schneider, AVEVA/OSIsoft PI, Ignition, SEL | Major ICS/OT vendors; rules must be accurate; documented as examples to validate |

## Out of Scope

- Automated config generation tooling
- SIEM-specific integration guides
- Non-Windows endpoint monitoring
- Comprehensive vendor-specific ICS application rule sets (examples and guidance provided, not exhaustive configs)
- Config testing on live ICS systems (testing is on general Windows)
- Industrial protocol content inspection (Sysmon monitors process-to-port connections, not protocol payloads)
