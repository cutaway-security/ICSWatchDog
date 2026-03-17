# RESUME.md

## Current State

**Last Session**: 2026-03-16
**Branch**: claude-dev
**Status**: WIP

## What Was Accomplished

### Phases 1-3c: Complete (see previous sessions)

### Phase 4: Documentation (Complete)

**New pages created (3):**

1. **SANS ICS 5 Critical Controls** (`/sans-controls/`)
   - Dedicated section for each of the 5 controls with how Sysmon supports them
   - Config-to-control mapping table
   - Important note that Sysmon monitors process-to-port, not protocol payloads
   - References to SANS whitepaper, Dragos analysis, CISA/NSA advisories, SANS State of OT Security 2025

2. **Deployment Considerations** (`/deployment/`)
   - Performance impact table per config level
   - Network latency explanation (Sysmon does not introduce network latency)
   - Event log size management guidance
   - 4-phase deployment approach (Lab -> Non-critical -> Jump hosts -> Operational)
   - Criticality-based deployment decision table (system type -> recommended config -> priority)
   - Tuning guide: noise reduction, remote access tool tuning, vendor-specific rule additions
   - Rollback plan (uninstall, config swap, service stop)
   - Safety-critical system warning callout

3. **Community Contributions** (`/community/`)
   - Two contribution paths (PR and GitHub issue)
   - What to include in contributions (header, rule names, comments, schema version, testing notes)
   - Naming convention for community configs
   - Review process
   - Current community configs table
   - Disclaimer for community configs

**Existing page updates:**
- **Getting Started**: Added performance/latency section with link to Deployment Considerations
- **Footer**: Added disclaimer with link to Deployment Considerations
- **Navigation**: Guides dropdown now includes Deployment Considerations, SANS ICS 5 Controls, Community Contributions

**Build verification:** 0.013s, 6 pages generated, no errors

### CutSec Frontend Standards Adoption

Adopted updated CutSec base template standards across website components:

**CSS (docs/css/style.css):**
- Added missing design tokens: query/response block colors, timing badge BEM variants, --color-btn-text, --color-danger-light
- Added details/summary (.details-styled) styles for HTML5 collapsible sections
- Added JS-based .collapsible component styles (advanced use only)
- Added query-block and response-block component styles (copy-to-clipboard, toggleable content)
- Added module navigation (.module-nav) and progress (.module-progress) styles
- Added timing badge container styles (.timing-badges, .section-timing)
- Added blockquote styles
- Unified card grid classes (.card-grid alongside .config-grid)
- Updated --max-width from 920px to 960px (CutSec standard)
- Updated print styles to hide interactive buttons (copy-btn, toggle-btn, section-toggle)
- Updated responsive rules for new section classes

**JS (docs/js/main.js):**
- Replaced single-purpose theme toggle with full CutSec delegated-handler pattern
- Added delegated click handler on document (CSP-compatible, no inline event attributes)
- Added copy-to-clipboard handler for .copy-btn (with clipboard API fallback)
- Added response block toggle handler for .toggle-btn
- Added collapsible section toggle handler for .section-toggle
- Added mobile nav toggle handler (moved from inline onclick)
- Theme toggle now uses delegation instead of direct addEventListener

**HTML (docs/_includes/nav.html):**
- Removed inline onclick from mobile hamburger button (now handled via delegation)

**Verification:**
- Zero inline event handlers in all HTML files (confirmed via scan)
- details/summary collapsible sections work with JS disabled (native HTML5)
- Jekyll build not tested (Jekyll not installed in current environment; previous sessions verified builds successfully)

## In Progress

None. All phases complete. v2 released.

## Blockers

None.

## Completed This Session

- Verified Phase 5 release status: all items confirmed done
- Updated PLAN.md Phase 5 to Complete
- Planned Phase 6: Config Expansion
- Conducted Phase 6a research (4 parallel research tracks):
  1. Workstation vs server Sysmon differentiation (process noise, exclusions, monitoring targets)
  2. CIS Benchmark alignment (control mapping, Sysmon-extends-CIS, hardening impact)
  3. AD/DC-specific Sysmon monitoring (MITRE ATT&CK, structural config differences)
  4. Database + web server monitoring (multi-engine coverage, combined config approach)
- Additional research based on review feedback:
  5. Non-MSSQL databases (PostgreSQL, MySQL/MariaDB, Oracle, MongoDB, InfluxDB)
  6. Non-IIS web servers (Apache httpd, Nginx, Tomcat)
  7. Sectioned config vs separate files (community practices, enterprise deployment patterns)
  8. Combined database+web config for colocated services (common in OT: Ignition, AVEVA)
- Key decisions from research:
  - Workstation/server split: justified (fundamentally different noise profiles)
  - CIS alignment: documentation/labels only, not separate config variants
  - AD/DC: separate config (structural changes required)
  - Database + web server: combined into single server-services config (all engines)
  - No separate OT server baseline or historian configs (covered by server-services + guidance)
  - Separate complete files, not commented sections (matches enterprise GPO practice)
  - Total curated configs: 8 (4 new, 2 stubs to complete, 2 unchanged)
- Updated PLAN.md with research findings, revised phases (6a-6e), new decisions
- Updated ARCHITECTURE.md with revised config model, file organization, server services coverage tables

## Next Steps

1. Verify Jekyll build locally (requires bundle install with vendor/bundle path)
2. Merge to main (exclude docs/ and claude-dev/)
3. Deploy site to gh-pages
4. Verify all site links
5. Tag release (v2)

## Files Modified This Session

| File | Change |
|------|--------|
| claude-dev/PLAN.md | All phases 6a-6e tracked, decision log updated |
| claude-dev/ARCHITECTURE.md | Config model revised, file organization updated, coverage tables added |
| claude-dev/RESUME.md | Updated with session progress |
| sysmon-configs/sysmonconfig-baseline-it.xml | Renamed to sysmonconfig-baseline-it-workstation.xml, header updated (CIS, version) |
| sysmon-configs/sysmonconfig-baseline-it-server.xml | New: server baseline with server-specific exclusions |
| sysmon-configs/sysmonconfig-baseline-ot.xml | Added CIS Benchmark alignment label and reference |
| sysmon-configs/sysmonconfig-enhanced-ot.xml | Complete rewrite: industrial port monitoring, expanded vendor coverage |
| sysmon-configs/sysmonconfig-advanced-ot.xml | Complete rewrite: Event IDs 27-29, MITRE ATT&CK, role-specific guidance |
| sysmon-configs/sysmonconfig-jumphost.xml | Added CIS Benchmark alignment and MITRE ATT&CK labels |
| sysmon-configs/sysmonconfig-server-ad.xml | New: AD/DC config with RawAccessRead, NTDS/SYSVOL, LSASS tuning |
| sysmon-configs/sysmonconfig-server-services.xml | New: combined database + web server, all engines, ImageLoad for web |
| README.md | Updated config table, Quick Start, removed "In Development" |
| docs/_pages/configurations.html | Added server-ad and server-services sections, updated all descriptions |
| docs/_pages/getting-started.html | Updated download links for workstation/server split |
| docs/_includes/nav.html | Updated navigation dropdown for new config structure |
| docs/index.html | Updated landing page config cards (6 cards) |
| docs/_pages/deployment.html | Updated performance table, criticality-based decisions, phased deployment |
