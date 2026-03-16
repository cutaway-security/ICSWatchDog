# RESUME.md

## Current State

**Last Session**: 2026-03-16
**Branch**: claude-dev
**Status**: WIP

## What Was Accomplished

### Phase 1: Project Foundation (Complete)
- Updated all planning documents from templates to project-specific content
- Updated GIT_RELEASE_STEPS.md, created deploy-site.sh, removed index.html

### Phase 2: Website Build (Complete)
- Custom Jekyll site with CutSec design system (slate + gold, dark/light toggle, mobile nav)
- Three pages: landing, configurations, getting started
- Approved after live preview via GitHub Pages

### Phase 3a: Sysmon Research and Audit (Complete)
- Sysmon current: v15.14, schema 4.90; native Windows integration announced for 2026
- Schema 4.82 adds IDs 27-28 (FileBlock*); schema 4.90 adds ID 29 (FileExecutableDetected)
- SwiftOnSecurity config unchanged since v74 (2021-07-08), still schema 4.50
- All four existing configs have zero ICS/OT-specific content
- sysmonconfig-adv-workstation.xml identical to SwiftOnSecurity (header-only fork)
- sysmonconfig-minimal.xml is SwiftOnSecurity + CutSec personal app exclusions (not enterprise)
- Mapped SANS ICS 5 Critical Controls to Sysmon capabilities (Controls #1, #3, #4 key)
- Identified remote access tool monitoring as critical capability (CISA/NSA advisories)
- Identified OT vendor list: Siemens, Rockwell, Schneider, AVEVA/OSIsoft PI, Ignition, SEL
- Revised config structure: IT Baseline -> OT Baseline -> OT Enhanced -> OT Advanced
- Decision: build all configs from scratch (not SwiftOnSecurity forks)
- Decision: enterprise-focused, no personal app exclusions
- Decision: include-log all remote access tools by default
- Decision: uniform disclaimer across all configs and site
- Decision: community/ directory for contributed configs
- Decision: performance/latency documentation critical for OT adoption
- Updated all planning documents with revised approach

## In Progress

- Planning documents updated, ready for next development phase

## Blockers

- None

## Next Steps

1. Begin Phase 3b: Config Restructuring (directories, file moves/renames, disclaimers)
2. Phase 3c: Build new configs from scratch
3. Phase 4: Documentation expansion (SANS controls page, deployment considerations, community contributions)

## Open Questions

- None currently blocking

## Files Modified This Session

| File | Change |
|------|--------|
| claude-dev/PLAN.md | Comprehensive rewrite: new config structure, SANS controls, remote access, community, disclaimer, vendor list |
| claude-dev/ARCHITECTURE.md | Comprehensive rewrite: progression model, SANS mapping, remote access monitoring, vendor table, updated file structure |
| claude-dev/RESUME.md | Updated with Phase 3a findings and revised approach |
