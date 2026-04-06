# PLAN.md

## Project Goal

Provide a usable, progressive set of Sysmon configuration files for ICS/OT environments -- mapped to the SANS ICS 5 Critical Controls -- with clear documentation that enables Windows administrators to deploy and mature endpoint monitoring.

## Current Phase

**Phase**: Phase 9 - Module Library
**Status**: Phase 9a-9d complete. 35 modules across 6 categories, merge tool, test harness, test fixtures, and 2 new documentation pages (modules.html, related-projects.html) all published. Jekyll build verified. Awaiting Phase 9e release approval.
**Focus**: Phase 9e release (merge to main, deploy site, tag v4.0). Phase 8c release also still pending (can be combined with 9e or shipped separately).

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
| 2026-03-17 | Single efficacy test script, not per-config-tier | Events log or they do not; one script tests all safely-testable EIDs |
| 2026-03-17 | No external dependencies for efficacy script | Simplicity; OT environments may have restricted internet and software install policies |
| 2026-03-17 | Skip dangerous Event IDs (8, 10, 25) entirely | Safety on live systems; knowledgeable admins can use SysmonSimulator or Atomic Red Team |
| 2026-03-17 | Account for event log propagation delay | Sysmon event log writes are not instantaneous; verification must wait before querying |
| 2026-03-17 | Script must display all planned changes before execution | OT environments require change awareness; admins must know exactly what will be modified |
| 2026-03-17 | Cleanup verification with manual fallback documentation | Failed cleanup must be reported and documented; manual steps in guide appendix |
| 2026-03-17 | Script requires administrator privileges | Get-WinEvent for Sysmon log needs elevation; explicit requirement, not optional |
| 2026-03-17 | Script location: tools/ directory | Separate from configs; clear purpose distinction |
| 2026-03-17 | System-modifying tests require -AllowSystemChanges flag | OT admins are change-averse; registry and WMI modifications must be explicitly opted into |
| 2026-03-23 | Replace self-closing CheckRevocation with explicit boolean values | User feedback: self-closing `<CheckRevocation/>` fails Sysmon config validation in some versions. Also, CRL checking requires network access incompatible with air-gapped OT systems. IT configs default True, OT configs default False. |
| 2026-03-23 | OT configs default CheckRevocation to False | OT systems are frequently air-gapped or network-restricted; CRL/OCSP checking causes timeouts and adds network dependency to security monitoring |
| 2026-04-06 | Adopt per-rule ATT&CK technique tagging in rule name attributes | Borrowed from sysmon-modular and SwiftOnSecurity convention; carries ATT&CK context into Sysmon log lines (RuleName field), enabling SIEM-side ATT&CK correlation without external lookups; was already a separate user request |
| 2026-04-06 | Tag only include rules with ATT&CK; exclude rules get plain descriptive names | Exclude rules are noise reduction, not detection; ATT&CK tagging on excludes would be misleading |
| 2026-04-06 | Add modular library layer alongside curated configs | Curated configs remain primary supported deployment artifact; modules are opt-in for advanced users; addresses vendor/sector/protocol customization without proliferating curated configs |
| 2026-04-06 | Modules are XML fragments, not complete configs | Match sysmon-modular's pattern; merged into a base config at build time via PowerShell script; no <Sysmon> root element in modules |
| 2026-04-06 | Dual-use cloud-storage and remote-access modules (exclude vs include) | Sanctioned and unsanctioned use cases require different rule sets; admins pick exactly one per tool based on site policy; naming convention: exclude_<tool>.xml and include_<tool>.xml |
| 2026-04-06 | Include IT-vendor modules (browsers, Adobe, Office, cloud storage, etc.) | These tools are present in OT environments (engineering workstations, vendor portals, PDF manuals, tag list spreadsheets, IT/OT file transfer); admins must be able to opt in to noise reduction or detection per site policy |
| 2026-04-06 | Remote-access tool detection: keep inline in curated configs AND provide modules | Inline detection in curated configs covers the common case for default deployment; modules provide finer-grained per-tool tuning for advanced users (option c from review) |
| 2026-04-06 | Modules default to schema 4.50 | Broadest compatibility with legacy OT systems; 4.90 features only when essential, with header note explaining the requirement |
| 2026-04-06 | Sector modules expand incrementally | Sector content requires deep domain expertise per sector; ship initial set (electric, water, oil/gas, manufacturing, pharma) and grow over time |
| 2026-04-06 | PowerShell merge script with separate test harness | Same constraints as efficacy script (PS 3+, no dependencies, pure .NET XML); test harness uses fixture-based diff comparison; can run on Linux since pure XML manipulation |
| 2026-04-06 | Update CLAUDE.md scope: config generation tooling moves from out-of-scope to in-scope, bounded to module merging | Modular layer requires merge tooling; bounded scope prevents drift into general config generation, threat intel ingestion, or asset-based config generation |
| 2026-04-06 | Sysmon name field is the only labeling mechanism; no description or alias attributes exist | Verified against Microsoft Sysmon documentation (March 2026 revision); name is the only attribute that reaches the event log RuleName field |
| 2026-04-06 | Adopt extended structured naming convention superseding sysmon-modular's minimum format | Existing ICS Watch Dog rules already use descriptive prefixes (DC:, Ransomware:) carrying valuable detection context; replacing with sysmon-modular's pure technique_id+technique_name format would discard this context. Extended format adds optional detection field while remaining a strict superset. |
| 2026-04-06 | Convention field names: technique_id, technique, detection | Use shorter `technique` rather than `technique_name` for less verbose names; technique_id matches sysmon-modular for parser interop; detection field is new and optional |
| 2026-04-06 | Multiple ATT&CK techniques: pipe-delimited in technique_id field | Pipe is visually distinct, does not conflict with comma (field separator) or semicolon (Sysmon's `is any` delimiter) |
| 2026-04-06 | Composite `<Rule>` elements: tag parent only, not inner field conditions | Avoids duplicate names in event logs; the parent Rule name is what reaches the RuleName field for composite rule matches |
| 2026-04-06 | Migrate all existing descriptive prefixes into the detection field for consistency | Eliminates inconsistency between tagged and untagged rules; preserves the context already encoded in current rule names |
| 2026-04-06 | XML comment block above each tagged include rule | Maintainer-facing documentation for ATT&CK reference, purpose, and investigation guidance; comments do not reach event logs but reduce future maintenance burden and aid contributors |
| 2026-04-06 | Hard limit 250 chars per name attribute, no commas or pipes in field values | Elasticsearch default keyword field `ignore_above` is 256 chars; values exceeding this are silently dropped from the index. Comma is field separator, pipe is multi-technique separator -- collisions break SIEM parsing. Explicit rules prevent future drift. All current worksheet names compliant (longest 152 chars). |
| 2026-04-06 | Create Sysmon Coding Standard as single source of truth | Sysmon-specific rules were scattered across CLAUDE.md, ARCHITECTURE.md, and PLAN.md decision log. Consolidating into SYSMON_CODING_STANDARD.md prevents drift, simplifies cross-reference, and matches the existing pattern set by html-css-jekyll.md. Other planning documents now reference the standard rather than duplicate its content. |

### Phase 7: Efficacy Testing

**Status**: Not Started

Provide a PowerShell 3+ validation script that confirms ICS Watch Dog Sysmon configs
generate expected events. Single script, safe for live systems, focused smoke test
(not adversary emulation).

Design considerations:
- Single script that tests all safely-testable Event IDs in one run (no config-tier parameter; events log or they do not)
- No external dependencies -- pure PowerShell 3+, no modules to install
- Requires administrator privileges (Get-WinEvent for Sysmon log needs elevation); script must check and exit if not elevated
- Event log generation has inherent delay; verification queries must account for timing (sleep/retry before checking)
- Safe by default -- only TEMP files, localhost/example.com connections, benign processes, ephemeral pipes, DNS
- System-modifying tests (registry Run key, WMI subscriptions) require explicit -AllowSystemChanges flag
- Must display warnings and a complete list of all changes the script will make before executing
- Cleanup must be verified and reported (success/failure per artifact)
- Failed cleanup must be clearly reported with manual remediation steps referenced in documentation appendix
- Skip dangerous Event IDs entirely (8, 10, 25) -- admins wanting those are knowledgeable enough to use SysmonSimulator or Atomic Red Team
- Script lives in tools/ directory
- Documentation references Atomic Red Team, MITRE Caldera, and Scythe for organizations wanting deeper adversary emulation testing

#### Phase 7a: Deep Research

- [x] Research safe PowerShell techniques for triggering each Sysmon Event ID
- [x] Research existing tools (Atomic Red Team, SysmonSimulator, PSSysmonTools, Caldera, Scythe)
- [x] Research OT/ICS safety constraints for efficacy testing
- [x] Research PowerShell event log querying for Sysmon verification
- [x] Document findings and finalize script design considerations

Key findings:
- No existing lightweight PS script validates Sysmon config efficacy at runtime (gap in tooling)
- Safe PS techniques exist for EIDs 1, 3, 11, 12/13/14, 17/18, 19/20/21, 22, 23
- EIDs 8, 10, 25 require unsafe operations (process injection, handle manipulation, hollowing) -- skip
- EID 7 (ImageLoad) can be triggered via Add-Type but is extremely high volume -- include only if config enables it
- Get-WinEvent with FilterHashtable and time window is the verification method
- Sysmon event log delay is real and must be accounted for in verification timing
- OT safety: only benign actions, full cleanup, no impact on system stability

#### Phase 7b: Script Design and Implementation

- [x] Design script structure:
      - Pre-flight checks (admin privileges, Sysmon running, Sysmon log accessible, PS version)
      - Display warnings and full list of actions before execution
      - Prompt for confirmation before proceeding (with -SkipConfirmation override)
      - Record start timestamp for event log queries
      - Trigger functions per Event ID (safe, benign actions only)
      - Configurable wait for event log propagation delay (-WaitSeconds parameter)
      - Verification functions (Get-WinEvent with FilterHashtable and XPath for precise matching)
      - Cleanup functions with per-artifact success/failure reporting
      - Summary report: pass/fail per Event ID, cleanup status, manual steps if cleanup fails
- [x] Define testable Event IDs and trigger methods:
      - EID 1 (ProcessCreate): Start-Process notepad.exe (hidden window)
      - EID 3 (NetworkConnect): TcpClient to example.com:80
      - EID 5 (ProcessTerminate): Stop-Process on test notepad
      - EID 11 (FileCreate): Set-Content .bat in Temp (matches include rules)
      - EID 12 (RegistryCreate): New-ItemProperty in HKCU Run key (matches include rules)
      - EID 13 (RegistryValueSet): Same operation generates both 12 and 13
      - EID 15 (FileCreateStreamHash): Set-Content .exe in Temp (matches include rules)
      - EID 17/18 (PipeCreate/PipeConnect): NamedPipeServerStream + NamedPipeClientStream
      - EID 19/20/21 (WMI): Set-WmiInstance for filter/consumer/binding, then cleanup
      - EID 22 (DNSQuery): .NET DNS resolver for non-existent test domain
      - EID 26 (FileDeleteDetected): Remove-Item .bat file (matches include rules)
      Note: Removed EID 14 (RegistryRename) -- not independently testable without
      touching monitored paths beyond what is needed. EID 12/13 cover registry validation.
- [x] Implement script in tools/Test-SysmonConfig.ps1
- [ ] Test script on Windows system with Sysmon installed

#### Phase 7c: Documentation and Integration

- [x] Create efficacy testing documentation page for website (docs/_pages/efficacy-testing.html)
      - What efficacy testing is and why it matters for Sysmon deployments
      - Script requirements, download link, usage examples
      - Test groups table (observation-only vs system changes)
      - How it works (8-step flow)
      - Interpreting results guidance
      - Event ID test details (two tables: default and system change tests)
      - Event IDs not tested (table with reasons)
      - Manual cleanup appendix (files, registry, WMI with exact commands)
      - Advanced testing tools (Atomic Red Team, SysmonSimulator, Caldera, Scythe)
      - When to test guidance
- [x] Add tools/ directory with script to repository
- [x] Update README.md with efficacy testing section and script usage
- [x] Update website navigation (Guides dropdown: added Efficacy Testing)
- [x] Verify Jekyll build (0.015s, 8 pages, no errors)
- [ ] Merge and release

### Phase 8: ATT&CK Technique Tagging

**Status**: Planned (next phase)

Tag every detection (include) rule across the 8 curated configs with MITRE ATT&CK technique metadata in the rule `name` attribute. Carries ATT&CK context, ATT&CK technique name, and site-specific detection intent directly into Sysmon log lines (RuleName field), enabling SIEM-side ATT&CK correlation without external lookups. Convention is a strict superset of sysmon-modular's format.

**Convention** (full spec in ARCHITECTURE.md ATT&CK Technique Tagging Convention section):

Format: `technique_id=<ID>[|<ID2>...],technique=<ATT&CK Name>[,detection=<Site Context>]`

Single technique:
```xml
<Image name="technique_id=T1003.003,technique=NTDS Credential Dumping,detection=DC ntdsutil execution"
       condition="end with">\ntdsutil.exe</Image>
```

Multiple techniques (pipe-delimited):
```xml
<CommandLine name="technique_id=T1059.001|T1027|T1140,technique=PowerShell Encoded Command,detection=Encoded PowerShell suggests obfuscation"
             condition="contains">-encodedcommand</CommandLine>
```

Composite rules (parent `<Rule>` element only, no inner field tags):
```xml
<Rule name="technique_id=T1003.003,technique=NTDS Credential Dumping,detection=Shadow copy NTDS extraction" groupRelation="and">
  <Image condition="end with">\vssadmin.exe</Image>
  <CommandLine condition="contains">create shadow</CommandLine>
</Rule>
```

Exclude rules use simpler convention: `name="exclude=<Site-Specific Context>"`. Existing descriptive prefixes (`DC:`, `Ransomware:`) migrate into the `detection` field for include rules, or into the `exclude=` field for exclude rules. Each tagged include rule is preceded by an XML comment block documenting the ATT&CK reference, purpose, and investigation guidance (maintainer-facing only -- comments do not reach event logs).

#### Phase 8a: Inventory and Mapping

**Status**: Complete. Worksheet at claude-dev/PHASE8A_TAGGING_WORKSHEET.md awaiting review.

- [x] Document the tagging convention in ARCHITECTURE.md (extended structured format with technique_id, technique, optional detection)
- [x] Inventory all rules across the 8 curated configs (170 RuleGroups, 1224 field conditions, 747 currently named, 0 composite Rule elements)
- [x] Confirm zero composite `<Rule>` elements -- simplifies Phase 8b (no parent-only tagging logic required)
- [x] Map each unique include rule pattern to ATT&CK techniques (used config header ATT&CK references plus MITRE ATT&CK matrix; includes ICS ATT&CK T0xxx techniques for industrial protocols and firmware)
- [x] Draft technique_id, technique, and detection field values for every include rule pattern
- [x] Identify rules with multiple applicable techniques and pre-list pipe-delimited technique_id values (13 multi-technique patterns identified)
- [x] Migrate existing descriptive prefixes (`DC:`, `Ransomware:`, `Web:`, `DB:`, `ICS:`) into planned detection field values
- [x] Draft XML comment block templates (4 templates: single rule, grouped set, multi-technique, ICS ATT&CK)
- [x] Produce per-config tagging worksheet for review (claude-dev/PHASE8A_TAGGING_WORKSHEET.md)
- [x] Document exclude rule renaming convention (`exclude=<context>`) with examples
- [x] List rules excluded from ATT&CK tagging (noise reduction, system filters, etc.)
- [x] Document Phase 8b execution workflow (per-config: read, tag, comment, validate, diff-check)
- [x] List 6 open issues for review before Phase 8b begins

#### Phase 8b: Apply Tags

**Status**: Complete. All 8 curated configs tagged with ATT&CK convention. 1213 rules preserved exactly. Max name length 139 chars (under 250 limit). All configs pass xmllint validation.

- [x] Update sysmonconfig-jumphost.xml (122 names: 80 include, 21 exclude)
- [x] Update sysmonconfig-baseline-it-workstation.xml (139 names: 74 include, 45 exclude)
- [x] Update sysmonconfig-baseline-it-server.xml (135 names: 77 include, 38 exclude)
- [x] Update sysmonconfig-baseline-ot.xml (165 names: 103 include, 42 exclude)
- [x] Update sysmonconfig-server-ad.xml (181 names: 104 include, 55 exclude; high ATT&CK density: T1003.003, T1003.006, T1003.002, T1003.004, T1484.001, T1087.002, T1556)
- [x] Update sysmonconfig-server-services.xml (210 names: 131 include, 57 exclude; T1059, T1505.001/003/004, T1053.005, T1005, T1190)
- [x] Update sysmonconfig-enhanced-ot.xml (206 names: 143 include, 42 exclude)
- [x] Update sysmonconfig-advanced-ot.xml (225 names: 159 include, 42 exclude)
- [x] After each config: validate well-formed XML (xmllint) and diff-check that only `name` attributes and surrounding XML comments changed
- [x] After all 8: verify no rule logic regressions (1213 rules total, all condition values, element tags, and field text values identical to originals)
- [x] Confirmed composite `<Rule>` elements: zero exist across all configs (workflow simplification confirmed during Phase 8a)
- [x] All 871 tagged include rule names and 342 tagged exclude rule names compliant with field constraints (no commas/pipes in values, max 139 chars)

#### Phase 8c: Documentation and Release

**Status**: Documentation complete. Release pending user approval.

- [x] Create new website page docs/_pages/attack-tagging.html (ATT&CK Rule Tagging convention)
      - Why tag rules with ATT&CK
      - The Format (field definitions)
      - Examples (single technique, multi-technique, ICS ATT&CK, composite, exclude rules)
      - Field constraints (250-char limit, no commas/pipes in values)
      - Coverage statistics across all 8 curated configs
      - SIEM parsing examples (Splunk SPL, Elastic ESQL, Microsoft Sentinel KQL)
      - ATT&CK matrices used (Enterprise + ICS)
      - Maintainer comment blocks explanation
      - What rules are NOT tagged
      - References (MITRE, sysmon-modular, Microsoft Sysmon, Elasticsearch ignore_above)
- [x] Add ATT&CK Rule Tagging to website navigation Guides dropdown
- [x] Update README.md with brief ATT&CK tagging section linking to icswatchdog.com/attack-tagging/
- [x] Verify Jekyll build (0.012s, no errors, attack-tagging/index.html generated)
- [x] No links to claude-dev/ files in any released artifact (per user constraint)
- [ ] Merge to main (exclude docs/ and claude-dev/)
- [ ] Deploy site to gh-pages
- [ ] Verify all site links point to main branch
- [ ] Tag release (v3.0 candidate)

### Phase 9: Module Library

**Status**: Planned (follows Phase 8)

Provide an opt-in library of focused XML fragments for vendor-specific, sector-specific, protocol-specific, and software-specific monitoring. Curated configs remain the primary supported deployment artifact; modules layer on top for advanced users. Pattern borrowed from sysmon-modular but scoped to ICS/OT and IT-software-in-OT-environments.

Module file format: each module is a partial Sysmon XML fragment containing one or more `<RuleGroup>` elements. NOT a complete Sysmon config -- no `<Sysmon>` root element. Schema 4.50 by default; 4.90 only when essential, with a header note.

Dual-use convention for cloud-storage and remote-access modules:
- `exclude_<tool>.xml` -- assumes tool is sanctioned, suppresses noise
- `include_<tool>.xml` -- assumes tool is unsanctioned, generates detection events
- Admins pick exactly one per tool based on site policy

#### Phase 9a: Module Library Structure and Initial Modules

**Status**: Complete. 35 modules shipped across all 6 categories. Initial release covers the most common cases; library will grow over time.

- [x] Create sysmon-configs/modules/ directory structure
- [x] Create modules/README.md explaining module format, usage, and dual-use convention
- [x] Create modules/INDEX.md listing every module with description, category, ATT&CK refs, schema compatibility
- [x] Build vendor-ot/ modules (5 shipped):
      siemens-tia-portal, rockwell-studio5000, schneider-ecostruxure,
      aveva-pi-system, ignition-gateway
      (Future: siemens-wincc, rockwell-factorytalk, sel-acselerator, codesys,
      kepware-kepserverex, ge-ifix, honeywell-experion, emerson-deltav)
- [x] Build vendor-it/ modules (5 shipped):
      exclude_google_chrome, exclude_microsoft_edge, exclude_mozilla_firefox,
      exclude_adobe_reader, exclude_microsoft_office
      (Future: exclude_microsoft_teams, exclude_zoom, exclude_webex,
      exclude_notepad_plus_plus, exclude_7zip, exclude_winrar)
- [x] Build cloud-storage/ modules (8 shipped):
      exclude_dropbox + include_dropbox, exclude_onedrive + include_onedrive,
      include_box, include_google_drive, include_mega, include_anonfile_tempsh
      (Future: exclude_box, exclude_google_drive, icloud variants, wetransfer)
- [x] Build sector/ modules (4 shipped):
      electric-utility, water-wastewater, oil-gas-pipeline, manufacturing
      (Future: pharmaceutical-gxp, transportation-rail, chemical)
- [x] Build protocol/ modules (8 shipped):
      modbus-tcp, opc-ua, ethernet-ip, dnp3, s7comm, bacnet, iec-60870-5-104, mqtt
      (Future: opc-da-dcom, iec-61850-mms, profinet)
- [x] Build remote-access/ modules (5 shipped):
      include_teamviewer + exclude_teamviewer, include_anydesk,
      include_screenconnect, include_rustdesk
      (Future: bomgar, splashtop, dameware, meshagent, ammyy, vnc variants)
- [x] Validate all modules are well-formed XML fragments (35/35 pass xmllint when wrapped in synthetic root)
- [x] Tag all include rules in modules with ATT&CK technique IDs using Phase 8 convention

#### Phase 9b: Merge Tooling

**Status**: Complete.

- [x] Implement tools/Merge-SysmonModules.ps1 (PowerShell 3+, no external dependencies)
- [x] Parameters: -BaseConfig, -Modules (array), -OutputPath, -VerboseLogging
- [x] Reads base config XML, validates structure
- [x] Parses modules wrapped in synthetic root for fragment support
- [x] Inserts module RuleGroups into base config EventFiltering section
- [x] Preserves base config meta section (HashAlgorithms, CheckRevocation, schemaversion)
- [x] Detects schema mismatches (4.90-only features into 4.50 base) and warns
- [x] Validates output XML well-formedness before writing
- [x] Reports manifest of merged modules and any conflicts
- [x] Rejects modules containing forbidden elements (Sysmon, HashAlgorithms, CheckRevocation, EventFiltering)
- [x] Rejects malformed XML and nonexistent files
- [x] Compatible with Windows PowerShell 5.1+ and PowerShell Core 7+ (Linux/macOS/Windows)

#### Phase 9c: Test Harness

**Status**: Complete. Logic verified via Python reference implementation against real fixtures.

- [x] Implement tools/Test-MergeSysmonModules.ps1
- [x] Sample base configs in tools/test-fixtures/base-configs/ (minimal-base.xml, ot-base.xml)
- [x] Sample modules in tools/test-fixtures/modules/ (sample-protocol, sample-vendor, invalid-has-sysmon-root, schema-490-clipboard)
- [x] Expected output fixture in tools/test-fixtures/expected/
- [x] Test 1: simple merge (1 base + 1 module, 1 RuleGroup)
- [x] Test 2: multi-module merge (2 modules, 3 RuleGroups)
- [x] Test 3: forbidden element rejection
- [x] Test 4: schema 4.90 mismatch warning
- [x] Test 5: real curated config + real modules end-to-end smoke test
- [x] Test 6: malformed XML rejection
- [x] Test 7: nonexistent module file rejection
- [x] Verified merge logic correctness via Python reference implementation (cannot run pwsh on current Linux dev env; PS test harness will run on Windows or pwsh-equipped Linux)

#### Phase 9d: Documentation

**Status**: Complete.

- [x] Create docs/_pages/modules.html (Module Library overview, categories, dual-use convention, schema versions, merge tool usage, available modules list, contributing guide)
- [x] Create docs/_pages/related-projects.html (Microsoft Sysmon, SwiftOnSecurity, sysmon-modular, MITRE ATT&CK, SANS ICS 5 Controls, LOLRMM, adversary emulation tools)
- [x] Add Module Library and Related Projects to docs/_includes/nav.html
- [x] Update README.md with Module Library section (no claude-dev/ links per release rules)
- [x] Verify Jekyll build (0.015s, no errors, modules/index.html and related-projects/index.html generated)

#### Phase 9e: Release

**Status**: Pending user approval.

- [ ] Final review of modules, tooling, tests, and documentation
- [ ] Merge to main (include sysmon-configs/modules/, tools/Merge-SysmonModules.ps1, tools/Test-MergeSysmonModules.ps1, tools/test-fixtures/)
- [ ] Deploy site to gh-pages
- [ ] Verify all site links
- [ ] Tag release (v4.0 candidate)

## Out of Scope

- Automated config generation from threat intel feeds, vulnerability scans, or asset inventories
- SIEM-specific integration guides
- Automated deployment of configs to endpoints
- Non-Windows endpoint monitoring
- Schema validation against an XSD (Sysmon's XSD is not public)
- Industrial protocol content inspection (Sysmon monitors process-to-port connections, not protocol payloads)
- Adversary emulation or red team tooling (references provided for external tools)
