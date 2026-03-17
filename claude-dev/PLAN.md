# PLAN.md

## Project Goal

Provide a usable, progressive set of Sysmon configuration files for ICS/OT environments -- mapped to the SANS ICS 5 Critical Controls -- with clear documentation that enables Windows administrators to deploy and mature endpoint monitoring.

## Current Phase

**Phase**: All phases complete.
**Status**: Complete
**Focus**: v2 released with expanded config set.

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

**Status**: Complete

- [x] Create community/ directory
- [x] Move sysmonconfig-filecreate-only.xml to community/ with attribution preserved
- [x] Create reference/ directory
- [x] Rename sysmonconfig-export.xml to sysmonconfig-swiftonsecurity-v74.xml and move to reference/
- [x] Remove sysmonconfig-adv-workstation.xml (identical to SwiftOnSecurity, replaced by new configs)
- [x] Remove sysmonconfig-minimal.xml (replaced by new baseline-it)
- [x] Add disclaimer to all retained config XML headers (community and reference)
- [x] Update README.md with new file structure, disclaimer, and contributing section
- [x] Update site config listing page for new structure (SANS control mapping, tuning warning, updated links)
- [x] Update site landing page config cards (IT/OT progression, SANS references)
- [x] Update site navigation dropdown (IT Baseline, OT Baseline, OT Enhanced, OT Advanced, Community, Reference)
- [x] Verify Jekyll build (0.012s, no errors)

### Phase 3c: Config Implementation

**Status**: Complete

Built all configs from scratch (not forked from SwiftOnSecurity). Enterprise-focused, designed for the IT-to-OT progression. Admins MUST tune for their environment.

- [x] Build sysmonconfig-baseline-it.xml (schema 4.50, enterprise IT, 14 event IDs configured, MITRE ATT&CK references, well-commented)
- [x] Build sysmonconfig-baseline-ot.xml (progression of IT baseline, schema 4.50, OT vendor directory monitoring, ICS file types, less aggressive exclusions for OT context)
- [x] Stub sysmonconfig-enhanced-ot.xml (schema 4.50 placeholder, documents planned features including industrial port monitoring)
- [x] Stub sysmonconfig-advanced-ot.xml (schema 4.90 placeholder, documents planned features including Event IDs 27-29 and role-specific tuning)
- [x] Fixed pre-existing XML error in community/sysmonconfig-filecreate-only.xml (malformed onmatch attribute)
- [x] Validate all configs are well-formed XML (6/6 valid via xmllint)

### Phase 4: Documentation

**Status**: Complete

**Existing page updates:**
- [x] Update Getting Started page with performance/latency section for OT environments
- [x] Update Configuration Files page with jump host, updated paths, SANS control references
- [x] Update landing page with SANS ICS 5 Controls framing, jump host card
- [x] Add disclaimer to website footer

**New pages:**
- [x] Create SANS ICS 5 Critical Controls page (dedicated mapping per control, config-to-control table, references)
- [x] Create Deployment Considerations page (performance impact, latency, phased rollout, criticality-based decisions, tuning guide, rollback plan)
- [x] Create Community Contributions page (PR and issue process, naming convention, review process, disclaimer)

**Documentation content (integrated into pages above):**
- [x] Config selection guide framed around SANS controls (in SANS Controls page and Configurations page)
- [x] Customization/tuning guide (in Deployment Considerations: noise reduction, remote access tool tuning, vendor-specific additions)
- [x] Remote access tool monitoring documentation (in SANS Controls #4 section)
- [x] Legacy OS considerations (in Deployment Considerations: criticality-based decisions table)
- [x] Performance/latency documentation (in Deployment Considerations and Getting Started)

**Navigation updates:**
- [x] Update site nav Guides dropdown to include Deployment Considerations, SANS ICS 5 Controls, Community Contributions
- [x] Verify Jekyll build (0.013s, 6 pages generated, no errors)

### Phase 5: Release

**Status**: Complete

- [x] Final review of all configs and documentation
- [x] Merge configs (including community/ and reference/ directories), README, License, and images to main (exclude docs/ and claude-dev/)
- [x] Remove index.html from main during merge (if not already removed)
- [x] Deploy site to gh-pages
- [x] Verify all site links point to main branch (20 links checked, all correct)
- [x] Verify README.md on main is descriptive and current
- [x] Verify disclaimer appears on site and in all config headers (all 7 configs)
- [x] Tag release (v1 and release-v1)
- [N/A] Create GitHub release (not needed)

### Phase 6a: Config Expansion Research

**Status**: Complete

Research to inform config expansion. Findings drive config structure decisions below.

- [x] Research workstation vs server baseline differentiation in Sysmon terms
- [x] Review current sysmonconfig-baseline-it.xml for workstation vs server applicability
- [x] Research CIS Benchmark alignment: map CIS controls to Sysmon event IDs
- [x] Research CIS Benchmark tuning impact on Sysmon noise profiles
- [x] Confirm CIS role-specific benchmarks align with planned config structure
- [x] Research MITRE ATT&CK techniques specific to AD/DC attacks
- [x] Research MITRE ATT&CK techniques specific to database server attacks (all engines)
- [x] Research MITRE ATT&CK techniques specific to web server attacks (all engines)
- [x] Research Sysmon rules specific to AD/DC monitoring
- [x] Research Sysmon rules specific to database server monitoring (multi-engine)
- [x] Research Sysmon rules specific to web server monitoring (multi-engine)
- [x] Research non-MSSQL databases: PostgreSQL, MySQL/MariaDB, Oracle, MongoDB, InfluxDB
- [x] Research non-IIS web servers: Apache httpd, Nginx, Apache Tomcat
- [x] Evaluate sectioned config vs separate config files approach
- [x] Evaluate combined database+web server config for colocated services
- [x] Document findings and finalize config list, naming, and build order

Key findings:

Workstation vs Server:
- Fundamentally different noise profiles. Single config on both causes either event flood or missed detections.
- Current IT Baseline is workstation-biased (excludes desktop noise, does not address server service noise).
- Split into workstation and server baselines is justified.

CIS Benchmark:
- CIS alignment is documentation/labeling, NOT separate config variants.
- CIS L2 hardening modestly reduces Sysmon noise but does not warrant different configs.
- CIS role-specific benchmarks (Workstation, Server DC/MS, IIS, SQL) confirm the project's config structure.
- Sysmon extends beyond CIS native auditing in 15+ areas (hashes, parent process, network process attribution, DLL loading, named pipes, WMI, etc.).
- Note HVCI/Device Guard compatibility in deployment docs (historical issue, resolved in Sysmon v15.x).

AD/DC:
- Separate config justified. Structural changes required: RawAccessRead must be enabled (disabled in baselines), NTDS.dit and SYSVOL path monitoring, LSASS ProcessAccess needs DC-specific exclusions, DC-specific registry keys.
- Many AD attacks (DCSync, Golden Ticket, Kerberoasting) are NOT detectable by Sysmon -- require Windows Security Event Logs. Config header should document complementary audit requirements.
- MITRE ATT&CK: T1003.003, T1003.006, T1207, T1484.001, T1558.001, T1558.003, T1087.002.

Database servers:
- Detection pattern is identical across all engines: database process spawning shell = malicious.
- Covered engines: MSSQL (sqlservr.exe, sqlagent.exe), PostgreSQL (postgres.exe), MySQL/MariaDB (mysqld.exe, mariadbd.exe), Oracle (oracle.exe, extjob.exe, extproc.exe), MongoDB (mongod.exe), InfluxDB (influxd.exe).
- Database file extensions to monitor: .bak, .mdf, .ldf, .ndf, .bacpac, .dacpac, .trn, .sql, .dump, .dbf, .dmp, .wt, .tsm.
- OT relevance: Ignition uses MySQL, AVEVA Historian uses SQL Server, InfluxDB growing in IIoT.
- MITRE ATT&CK: T1059, T1505.001, T1053.005, T1005, T1190.

Web servers:
- Strongest case for separate config. Enables Event ID 7 (ImageLoad) scoped to web worker processes -- structural change not possible in a general config.
- Detection pattern is the same across all engines: web process spawns shell = webshell execution.
- Covered engines: IIS (w3wp.exe), Apache (httpd.exe), Nginx (nginx.exe), Tomcat (java.exe, tomcat9.exe), plus interpreters (php-cgi.exe, php.exe).
- Web script extensions to monitor: .aspx, .asp, .ashx, .asmx, .php, .jsp, .jspx, .cfm, .py, .cgi, web.config.
- java.exe caveat: many OT apps run as java.exe (Ignition). May need path-based scoping or accepted tuning.
- OT relevance: Ignition runs Tomcat/Jetty, AVEVA uses IIS, many HMI web interfaces use Apache.
- MITRE ATT&CK: T1505.003, T1505.004, T1059.

Combined database+web:
- OT servers commonly colocate database and web services (Ignition = MySQL + Tomcat, AVEVA = SQL Server + IIS).
- Sysmon loads ONE config file -- cannot layer/merge at runtime.
- Rules for absent services have zero cost (never match, no noise, no performance impact).
- Database and web server rules merged into single "server services" config.

Config approach:
- Separate complete files (not commented sections). Matches enterprise GPO deployment pattern.
- Commented XML sections are error-prone, no major Sysmon project uses them for role blocks.
- Each file is self-contained, valid, and deployable without editing.

### Phase 6b: Baseline Restructuring

**Status**: Complete

Split the current IT Baseline into workstation and server variants.

- [x] Rename sysmonconfig-baseline-it.xml to sysmonconfig-baseline-it-workstation.xml
- [x] Create sysmonconfig-baseline-it-server.xml (server-appropriate exclusions, remote management tool monitoring, no desktop/browser noise exclusions)
- [x] Validate both configs are well-formed XML (xmllint)
- [x] Update README.md for new file names
- [x] Update website config listing page
- [x] Update website getting-started page references

### Phase 6c: Complete OT Stubs

**Status**: Complete

- [x] Complete sysmonconfig-enhanced-ot.xml (industrial port monitoring via NetworkConnect, expanded vendor rules, OPC/DCOM registry monitoring, schema 4.50)
- [x] Complete sysmonconfig-advanced-ot.xml (Event IDs 27-29 for executable detection and file shredding, role-specific tuning guidance, schema 4.90)
- [x] Validate both configs are well-formed XML (xmllint)
- [x] Update README.md to remove "In Development" labels
- [x] Update website config listing page (descriptions, SANS controls, Sysmon version requirements)

### Phase 6d: Server Role Configs

**Status**: Complete

Two role-specific server configs, each self-contained (includes server baseline rules plus role additions).

- [x] Build sysmonconfig-server-ad.xml:
  - Enables RawAccessRead (Event ID 9) -- disabled in baselines
  - NTDS.dit and SYSVOL path monitoring (FileCreate)
  - DC-specific ProcessCreate include rules (ntdsutil, vssadmin, esentutl, diskshadow, csvde, ldifde)
  - DC-specific LSASS ProcessAccess exclusions (dns.exe, dfsr.exe, ntdsutil.exe)
  - DC-specific registry keys (NTDS, Netlogon, DNS, DFSR, LSA services)
  - DC-specific named pipes (drsuapi, samr, netlogon)
  - Documents complementary Windows audit requirements (4662, 4769, 4742, 5136/5137) in header
  - MITRE ATT&CK: T1003.003, T1003.006, T1207, T1484.001, T1087.002
- [x] Build sysmonconfig-server-services.xml (combined database + web server):
  - Database monitoring: ParentImage rules for all engines (sqlservr.exe, sqlagent.exe, postgres.exe, mysqld.exe, mariadbd.exe, oracle.exe, extjob.exe, mongod.exe, influxd.exe) spawning shell processes
  - Database file extension monitoring (.bak, .mdf, .ldf, .ndf, .bacpac, .sql, .dump, .dbf, .dmp, .wt, .tsm)
  - Database process NetworkConnect exclusions (labeled per engine for admin tuning)
  - Database named pipe monitoring (SQL Server, Oracle pipes)
  - Web server monitoring: ParentImage rules for all engines (w3wp.exe, httpd.exe, nginx.exe, java.exe, php-cgi.exe, php.exe, tomcat9.exe) spawning shell processes
  - Enables ImageLoad (Event ID 7) scoped to web worker processes (w3wp.exe, httpd.exe, java.exe) for IIS module/webshell DLL detection
  - Web script extension monitoring (.aspx, .asp, .ashx, .asmx, .php, .jsp, .jspx, .cfm, web.config) in web root paths
  - Web server NetworkConnect exclusions for inbound port 80/443
  - IIS registry key monitoring
  - MITRE ATT&CK: T1059, T1505.001, T1505.003, T1505.004, T1053.005, T1005, T1190
- [x] Validate both configs are well-formed XML (xmllint)
- [x] Update README.md and website (config table, selection guide, full descriptions)

### Phase 6e: Documentation and Release

**Status**: Complete

- [x] Add CIS Benchmark alignment labels to all config headers (8/8 curated configs)
- [x] Add MITRE ATT&CK references to all config headers where applicable
- [x] CIS Benchmark alignment integrated into all website config descriptions (8/8 sections)
- [x] Update website config listing with all new configs
- [x] Update website navigation for expanded config set
- [x] Update landing page config cards (6 cards)
- [x] Update deployment guide: performance table, criticality-based decisions, phased deployment
- [x] Update README.md with final config table
- [x] Verify Jekyll build
- [x] Merge to main
- [x] Deploy site to gh-pages
- [x] Verify all site links
- [x] Tag release

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
| 2026-03-16 | Split IT Baseline into workstation and server variants | Workstations and servers have fundamentally different process noise, services, and monitoring needs |
| 2026-03-16 | All configs schema 4.50 unless newer features required | OT environments run legacy OS; only jump host and advanced-ot use schema 4.90 |
| 2026-03-16 | OT Baseline remains general-purpose (workstation-centric) | Serves as the universal OT starting point; admins add OT vendor specifics with guidance |
| 2026-03-16 | Config tree model replaces linear progression | Configs branch by role (workstation/server) and environment (IT/OT) rather than a single linear chain |
| 2026-03-16 | CIS Benchmark alignment is documentation only, not separate configs | CIS L2 hardening modestly reduces noise but does not warrant config variants; add labels and mapping to headers/docs |
| 2026-03-16 | Complete OT stubs before new configs | Clear "In Development" debt on published configs before expanding the config set |
| 2026-03-16 | AD/DC gets a separate config (structural differences) | RawAccessRead must be enabled, NTDS/SYSVOL paths, LSASS tuning -- cannot be tuning notes |
| 2026-03-16 | Database and web server rules combined into single server-services config | OT servers commonly colocate database + web (Ignition = MySQL + Tomcat, AVEVA = SQL Server + IIS); rules for absent services have zero cost |
| 2026-03-16 | Multi-engine coverage in server-services config | Database: MSSQL, PostgreSQL, MySQL/MariaDB, Oracle, MongoDB, InfluxDB. Web: IIS, Apache, Nginx, Tomcat. Detection pattern is identical across engines (process spawns shell). |
| 2026-03-16 | No separate OT server baseline or OT historian configs | OT historians are specialized database/web servers; covered by server-services config + OT vendor tuning guidance in documentation |
| 2026-03-16 | Separate complete files, not commented sections | Commented XML sections are error-prone; no major Sysmon project uses them for role blocks; matches enterprise GPO deployment pattern |
| 2026-03-16 | Minimize config count to avoid overwhelming OT admins | Only create separate configs when structural Sysmon differences (enabling/disabling Event IDs, fundamentally different exclusion logic) justify it; tuning notes in documentation otherwise |

## Out of Scope

- Automated config generation tooling
- SIEM-specific integration guides
- Non-Windows endpoint monitoring
- Comprehensive vendor-specific ICS application rule sets (examples and guidance provided, not exhaustive configs)
- Config testing on live ICS systems (testing is on general Windows)
- Industrial protocol content inspection (Sysmon monitors process-to-port connections, not protocol payloads)
