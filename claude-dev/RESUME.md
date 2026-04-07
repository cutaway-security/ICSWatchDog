# RESUME.md

## Current State

**Last Session**: 2026-04-06
**Branch**: claude-dev
**Status**: Phase 8, 9 complete. Phase 10a-10e complete. New LOLBAS Detection website page published. All planning, configs, modules, tooling, and documentation deliverables ready. Phase 10f (combined v4.0 release) is the only remaining work.

## What Was Accomplished

### Phases 1-6e: Complete (see previous sessions)

All configs built, documented, deployed. v2 released.

### Phase 7: Efficacy Testing (In Progress)

#### Phase 7a: Deep Research (Complete)

Researched Sysmon efficacy testing approaches:
- Atomic Red Team: 1,070+ ATT&CK-mapped tests, heavyweight framework
- MITRE Caldera: full C2 platform, too invasive for OT
- Scythe: commercial AEV platform, overkill for config validation
- SysmonSimulator (Securonix): C binary, covers 25 event types but uses unsafe techniques
- PSSysmonTools (Matt Graeber): schema validation only, not runtime
- Key gap: no existing lightweight PS script validates Sysmon config efficacy at runtime

Findings: safe PS techniques exist for EIDs 1, 3, 5, 11, 12/13, 15, 17/18, 19/20/21, 22, 26.
Unsafe/disabled EIDs skipped: 2, 6, 7, 8, 9, 10, 23, 25.

#### Phase 7b: Script Design and Implementation (In Progress)

Analyzed all 8 curated configs to understand include/exclude rule logic. Designed test
triggers to match actual config include rules (not just generate events, but generate
events that the configs are designed to capture).

Implemented tools/Test-SysmonConfig.ps1:
- Pre-flight checks: admin privileges, Sysmon service, event log access, PS version
- Planned changes display: full list of every action with warnings
- Confirmation prompt (with -SkipConfirmation override)
- 14 event triggers across 11 Event IDs, all safe and reversible
- Configurable wait for event log propagation (-WaitSeconds, default 10)
- Event verification via Get-WinEvent with FilterHashtable and XPath
- Per-artifact cleanup with success/failure reporting
- Summary report with pass/fail, cleanup status, manual remediation reference
- Skipped EID documentation with pointers to external tools

Added -AllowSystemChanges flag: registry and WMI tests require explicit opt-in.
OT admins run observation-only tests by default (9 EIDs); system-modifying tests
(5 EIDs) only execute when the flag is provided.

Pending: testing on Windows system with Sysmon installed.

## In Progress

Phase 10a-10e complete. Phase 10f (combined v4.0 release: Phase 8 + 9 + 10 together) is the only remaining work. All artifacts ready: 8 curated configs, 48 modules, merge tool + test harness, 4 new website pages (attack-tagging, modules, related-projects, lolbas-detection), updated README and ARCHITECTURE.md.

## Blockers

None. Efficacy test script cannot be tested on current Linux dev environment -- requires Windows + Sysmon. Merge tooling test harness CAN be tested on Linux (pure XML manipulation).

## Completed This Session (2026-04-06)

- Reviewed sysmon-modular project (https://github.com/olafhartong/sysmon-modular)
  - Established it as relevant reference: 3007 stars, MIT, last push 2024-08-21, slowing maintenance
  - Identified two patterns worth borrowing: ATT&CK rule tagging and modular vendor/sector layer
  - Confirmed it has zero ICS/OT content -- value is architectural pattern, not rules
- Drafted Phase 8 (ATT&CK Technique Tagging) and Phase 9 (Module Library) plans
- Refined plan based on user feedback:
  - IT software (browsers, Adobe, Office) IS used in OT -- include vendor-it modules
  - External storage (Dropbox, Box, OneDrive) is dual-use -- exclude vs include per policy
  - Sector modules expand incrementally over time
  - Remote access: keep inline in curated configs AND provide modules (option c)
  - ATT&CK tagging on includes only, excludes get plain descriptive names
  - Modules default to schema 4.50; 4.90 only when essential
  - Test harness for merge tooling
- Researched Sysmon rule labeling capabilities via Microsoft documentation
  - Confirmed `name` is the only labeling mechanism; no description, alias, or multiple-name support
  - XML comments work in source files only, never reach event logs
- Finalized ATT&CK tagging convention based on user decisions:
  - Extended structured format: `technique_id=<ID>[|<ID2>],technique=<ATT&CK Name>[,detection=<Site Context>]`
  - Strict superset of sysmon-modular's format
  - Field name `technique` (shorter) instead of `technique_name`
  - Multiple techniques: pipe-delimited
  - Migrate all existing descriptive prefixes (`DC:`, `Ransomware:`) into the detection field
  - Composite `<Rule>` elements: parent-only tagging, no inner-field tags
  - XML comment block above each tagged include rule for maintainer documentation
  - Exclude rules: `name="exclude=<context>"` simpler convention
- Updated CLAUDE.md scope: config generation tooling moves from out-of-scope to in-scope (bounded to module merging)
- Updated PLAN.md with Phase 8 (3 sub-phases) and Phase 9 (5 sub-phases), 19 new decision log entries, current phase pointer; refined Phase 8a/8b task lists for the finalized convention
- Updated ARCHITECTURE.md with full ATT&CK Tagging Convention section (field definitions, rules for includes/excludes/composite, maintainer XML comment guidance, sysmon-modular interop note), Module Architecture section, file structure additions
- Executed Phase 8a:
  - Read all 8 curated configs in full (4457 lines total)
  - Inventoried 170 RuleGroups, 1224 field conditions, 747 currently named rules, 0 composite Rule elements
  - Confirmed zero composite Rule elements -- simplifies Phase 8b execution
  - Mapped every unique include rule pattern to ATT&CK techniques (enterprise + ICS ATT&CK)
  - Drafted full tagged name strings for ~150 unique include rule patterns
  - Identified 13 multi-technique pattern groups requiring pipe-delimited technique_id
  - Migrated existing DC:/Ransomware:/Web:/DB:/ICS: descriptive prefixes into planned detection field values
  - Drafted 4 XML comment block templates
  - Documented exclude rule renaming convention with examples
  - Listed rules intentionally excluded from ATT&CK tagging
  - Documented per-config Phase 8b execution workflow (read, tag, comment, validate, diff-check)
  - Identified 6 open issues for user review before Phase 8b begins
  - Produced claude-dev/PHASE8A_TAGGING_WORKSHEET.md as Phase 8a deliverable
- Updated PLAN.md Phase 8a tasks to reflect completion
- Researched SIEM field length limits and parsing risks for worksheet Issue 5
  - Confirmed Elasticsearch default keyword `ignore_above: 256` is the only practical limit
  - All worksheet names verified compliant (longest 152 chars, none contain commas/pipes in values)
  - Established 250-char hard limit, 80-180 char target, no commas or pipes in field values
- Created claude-dev/SYSMON_CODING_STANDARD.md as single source of truth for all Sysmon XML conventions
  - 15 sections: scope, file structure, schema, meta config, RuleGroups, rule naming, comments, modules, validation, attribution, disclaimer, style, versioning, references, maintenance
  - Encodes all Phase 8 conventions (rule naming, ATT&CK tagging, field constraints, exclude convention, comment templates)
  - Encodes Phase 9 module conventions (file format, dual-use, schema floor, categories)
  - Encodes prior decisions (CheckRevocation, schema 4.50 default, attribution requirements)
- Trimmed CLAUDE.md Code Quality Standards section: replaced 5-bullet Sysmon list with reference to SYSMON_CODING_STANDARD.md
- Trimmed ARCHITECTURE.md: removed Sysmon Config File Structure section, ATT&CK Technique Tagging Convention section (~100 lines), Module Architecture file format/dual-use/schema details. Kept architectural rationale (module categories table, merge tooling purpose, test harness purpose). Replaced with reference to SYSMON_CODING_STANDARD.md.
- Updated ARCHITECTURE.md file structure tree with SYSMON_CODING_STANDARD.md and PHASE8A_TAGGING_WORKSHEET.md
- Marked all 6 worksheet open issues resolved with user decisions; updated Convention Recap section to reference standard
- Added 2 decision log entries to PLAN.md: 250-char hard limit + parsing rules; Sysmon Coding Standard creation
- Updated PLAN.md current phase status
- Executed Phase 8b: applied ATT&CK tagging to all 8 curated configs
  - jumphost.xml: 122 names (80 include, 21 exclude); 101 rules preserved
  - baseline-it-workstation.xml: 139 names (74 include, 45 exclude); 119 rules preserved
  - baseline-it-server.xml: 135 names (77 include, 38 exclude); 115 rules preserved
  - baseline-ot.xml: 165 names (103 include, 42 exclude); 145 rules preserved
  - server-ad.xml: 181 names (104 include, 55 exclude); 159 rules preserved
  - server-services.xml: 210 names (131 include, 57 exclude); 188 rules preserved
  - enhanced-ot.xml: 206 names (143 include, 42 exclude); 185 rules preserved
  - advanced-ot.xml: 225 names (159 include, 42 exclude); 201 rules preserved
  - Per-config workflow: read, tag, comment, validate, diff-check
  - All 8 configs pass xmllint validation
  - Total: 1213 rules preserved exactly, 871 include + 342 exclude tagged
  - Max name length across all configs: 139 chars (under 250 limit)
  - All field constraint rules satisfied (no commas/pipes in values)
  - Zero rule logic regressions
- Updated PLAN.md Phase 8b tasks marked complete with statistics
- Phase 8c documentation:
  - Created docs/_pages/attack-tagging.html (~10 sections, full convention reference, field definitions, single/multi-technique/ICS/composite/exclude examples, field constraints, coverage stats table, SIEM parsing examples for Splunk/Elastic/Sentinel, ATT&CK matrix references, maintainer comment guidance, untagged rule list, references)
  - Added "ATT&CK Rule Tagging" to docs/_includes/nav.html Guides dropdown
  - Updated README.md with brief ATT&CK tagging section (no link to claude-dev/ per user constraint; links to icswatchdog.com/attack-tagging/ for the full convention)
  - Verified Jekyll build (0.012s, no errors)
  - Confirmed _site/attack-tagging/index.html generated
- Removed claude-dev/ references from all 8 curated config XML headers, replaced with https://icswatchdog.com/attack-tagging/
- Phase 9 (Module Library) execution:
  - Phase 9a: Built foundation and 35 modules across 6 categories
    - sysmon-configs/modules/ directory with README.md and INDEX.md
    - vendor-ot/ (5): siemens-tia-portal, rockwell-studio5000, schneider-ecostruxure, aveva-pi-system, ignition-gateway
    - vendor-it/ (5): exclude_google_chrome, exclude_microsoft_edge, exclude_mozilla_firefox, exclude_adobe_reader, exclude_microsoft_office
    - cloud-storage/ (8): exclude_dropbox + include_dropbox, exclude_onedrive + include_onedrive, include_box, include_google_drive, include_mega, include_anonfile_tempsh
    - sector/ (4): electric-utility, water-wastewater, oil-gas-pipeline, manufacturing
    - protocol/ (8): modbus-tcp, opc-ua, ethernet-ip, dnp3, s7comm, bacnet, iec-60870-5-104, mqtt
    - remote-access/ (5): include_teamviewer + exclude_teamviewer, include_anydesk, include_screenconnect, include_rustdesk
    - All 35 modules pass xmllint validation when wrapped in synthetic root
    - All include rules use the Phase 8 ATT&CK structured tagging convention
    - Fixed XML comment double-hyphen issues in 5 modules
  - Phase 9b: tools/Merge-SysmonModules.ps1
    - PowerShell 3+ compatible, no external dependencies
    - Reads base config, validates structure, parses modules wrapped in synthetic root
    - Inserts module RuleGroups into base EventFiltering
    - Preserves meta config (HashAlgorithms, CheckRevocation, schemaversion)
    - Rejects forbidden elements (Sysmon, HashAlgorithms, CheckRevocation, EventFiltering)
    - Detects schema 4.90 mismatch and warns
    - Validates output XML before writing, reports merge manifest
  - Phase 9c: Test harness
    - tools/Test-MergeSysmonModules.ps1 with 7 test cases
    - Test fixtures: tools/test-fixtures/{base-configs, modules, expected}/
    - 2 base configs (minimal-base, ot-base), 4 sample modules, 1 expected output
    - Verified merge logic correctness via Python reference implementation against real curated configs and real modules (cannot execute pwsh on current Linux dev env; PS test harness will run on Windows or pwsh-equipped Linux)
    - Tested: simple merge, multi-module merge, forbidden element rejection, schema mismatch warning, real config end-to-end, malformed XML rejection, nonexistent file rejection
    - All test scenarios pass when executed via reference implementation
  - Phase 9d: Documentation
    - Created docs/_pages/modules.html (module library overview, categories table, dual-use convention, schema versions, merge tool usage, test harness, available modules list, contributing guide)
    - Created docs/_pages/related-projects.html (Sysmon, SwiftOnSecurity, sysmon-modular, MITRE ATT&CK, SANS ICS 5 Controls, LOLRMM, adversary emulation tools)
    - Added Module Library and Related Projects to docs/_includes/nav.html
    - Updated README.md with Module Library section (links to icswatchdog.com/modules/, no claude-dev/ links)
    - Verified Jekyll build (0.015s, no errors, _site/modules/index.html and _site/related-projects/index.html generated)
- Updated PLAN.md Phase 9 sub-phases (9a-9e) marked complete or pending
- Verified PowerShell merge tool: pwsh 7.6.0 installed on Linux dev environment, ran tools/Test-MergeSysmonModules.ps1, all 7 tests pass (simple merge, multi-module merge, forbidden element rejection, schema 4.90 mismatch warning, real curated config + real modules end-to-end, malformed XML rejection, nonexistent file rejection)
- Investigated LOLBAS coverage in current configs:
  - Found minimal LOLBAS coverage: 7-12 rules per config (ransomware indicators, DC-specific NTDS extraction, IIS module installation)
  - Documented gap vs SwiftOnSecurity (heavy inline LOLBAS), olafhartong/sysmon-modular (dedicated include_living_off_the_land.xml module + others), Florian Roth signature-base, Sigma rules
  - Confirmed no LOLBAS-only Sysmon project exists (universal feature in mature configs)
- Phase 10 LOLBAS detection planning:
  - Three-tier strategy designed: Tier 1 core (12 rules in all 8 configs), Tier 2 advanced (~20 rules in 5 configs), Tier 3 comprehensive (~13 modules, ~150 rules)
  - User approved all 10 plan considerations: Tier 1 size, Tier 2 scope, OT baseline gets Tier 1, lolbas/ category name, Sigma-level Tier 3, dedicated lolbas-detection page, Option B versioning (v4.0 combined release), conservative-to-comprehensive FP philosophy, high-level + XML comment tuning, AND logic acceptable
  - Updated SYSMON_CODING_STANDARD.md:
    - New section 5.3 Composite Rules with `<Rule groupRelation="and">` (schema compatibility, examples, when to use, tagging)
    - New section 6.6 LOLBAS Detection Three-Tier Strategy (Tier 1 criteria, Tier 2 criteria, Tier 3 modules, tuning guidance, selection reference)
    - Renumbered RuleGroup Comments section from 5.3 to 5.4
  - Added 9 new decision log entries to PLAN.md covering Phase 10 design decisions
  - Added Phase 10 (10a-10f) to PLAN.md with full task lists
  - Updated current phase pointer to Phase 10
  - Combined Phase 8c, 9e, and 10f releases into single v4.0 release
- Executed Phase 10a:
  - Cross-referenced LOLBAS Project, MITRE ATT&CK Enterprise, SwiftOnSecurity v74, olafhartong/sysmon-modular, and Sigma rules
  - Drafted 12 Tier 1 detections implemented as 19 composite XML Rules covering: certutil download, certutil decode, mshta http, regsvr32 Squiblydoo, bitsadmin transfer, PowerShell encoded, PowerShell DownloadString, PowerShell IEX cradle, WMIC XSL, WMIC remote process create, rundll32 javascript, msdt Follina
  - Drafted 20 Tier 2 detections implemented as 22 XML Rules (14 composite, 8 Image-only)
  - Drafted 13 Tier 3 modules with ~153 total rules listed by focus area and key detections
  - Each Tier 1 rule includes full XML, ATT&CK technique mapping, and OT-specific tuning notes
  - Documented composite Rule (`<Rule groupRelation="and">`) validation considerations including diff-check tooling update needed
  - Documented per-config impact: 3 configs get Tier 1 only (+19 rules each), 5 configs get Tier 1+2 (+41 rules each), 13 new modules add ~153 rules
  - Documented Phase 10b/c/d execution workflow per config
  - Listed 10 open issues for review before Phase 10b begins
  - Produced claude-dev/PHASE10A_LOLBAS_WORKSHEET.md as Phase 10a deliverable
- Executed Phase 10b:
  - Built tools/check-rule-preservation.py: composite-rule-aware diff-check tool that extracts both flat field conditions and composite <Rule> elements, verifies existing rules preserved, and reports composite rule additions. Self-tested with identical-file comparison (0 changes detected).
  - Applied Tier 1 LOLBAS RuleGroup (ProcessCreate-LOLBAS-Core) to sysmonconfig-jumphost.xml as validation target
  - Validated jumphost: xmllint pass, diff-check confirmed 0 flat rules removed/added and 17 composite Rules added, max name length 131 chars, 0 constraint violations
  - Tested merge tool with composite-rule-containing base config: pwsh execution succeeded, output XML valid
  - Programmatically applied identical LOLBAS RuleGroup to remaining 7 configs (baseline-it-workstation, baseline-it-server, server-ad, server-services, baseline-ot, enhanced-ot, advanced-ot)
  - Bumped versions: jumphost v1.1->v1.2, baseline-ot v1.1->v1.2, others v2.1->v2.2
  - Added concise LOLBAS Tier 1 line to MITRE ATT&CK Coverage section in each config header (single 2-line entry to avoid header bloat per user direction)
  - Final validation across all 8 configs: xmllint 8/8 valid, diff-check 8/8 PASS, 17 composite Rules per config, 136 total composite Rules added
  - Field constraints: 0 violations, longest name 139 chars (well under 250 limit)
  - Re-ran PowerShell test harness: 7/7 still passing, confirming merge tool compatibility with composite Rules in base configs
  - PowerShell rules cover powershell.exe, pwsh.exe, AND powershell_ise.exe via `contains any` operator (consolidates 6+ rules into 2 per pattern)
  - 12 conceptual detections implemented as 17 actual XML Rules (some detections need 2 rules for pattern variants like /node: vs process call create)
- Executed Phase 10c:
  - Built ProcessCreate-LOLBAS-Advanced RuleGroup with 22 rules (13 composite + 9 flat Image-only)
  - Detections cover: certutil -encode, mshta vbscript:/javascript:, generic mshta/bitsadmin, PowerShell -w hidden -nop combo, PowerShell -ep bypass, PowerShell from temp dir, InstallUtil /U, regasm/regsvcs, msxsl, cmstp /au /s, wuauclt UpdateDeploymentProvider, msbuild generic, csc parented by powershell/cmd (with contains any for parent), mavinject, pcalua, forfiles spawning cmd, finger
  - Applied to jumphost first (validation target), then propagated to server-ad, server-services, enhanced-ot, advanced-ot
  - advanced-ot header has different format ("MITRE ATT&CK Coverage (in addition to Enhanced config coverage)") so it lacked the Tier 1 LOLBAS line from Phase 10b; added BOTH Tier 1 and Tier 2 LOLBAS lines to its header during Phase 10c
  - Bumped versions: jumphost v1.2->v1.3, server-ad/server-services/enhanced-ot/advanced-ot v2.2->v2.3
  - Final validation: 8/8 xmllint PASS, 8/8 diff-check PASS, 0 constraint violations, max name length 139 chars
  - PowerShell test harness 7/7 still passing
  - Per-config statistics: baseline configs (workstation, IT server, OT baseline) have 17 composite Rules; advanced configs (jumphost, server-ad, server-services, enhanced-ot, advanced-ot) have 30 composite Rules
  - Total composite Rules across project: 201 (17 * 3 + 30 * 5 = 51 + 150 = 201)
- Executed Phase 10d:
  - Created sysmon-configs/modules/lolbas/ directory
  - Built 13 modules with exactly 153 rules total (matching worksheet target):
    - include_signed_binary_proxy.xml: 25 rules (T1218 family)
    - include_powershell_offensive.xml: 15 rules (T1059.001 offensive patterns)
    - include_wmic_abuse.xml: 10 rules (T1047 lateral, recon, XSL)
    - include_certutil_abuse.xml: 8 rules (T1140/T1105/T1132 all modes)
    - include_bitsadmin_abuse.xml: 6 rules (T1197 all variants)
    - include_script_host_abuse.xml: 10 rules (T1059.005/.007 cscript/wscript)
    - include_trusted_developer_utilities.xml: 12 rules (T1127 msbuild/csc/etc.)
    - include_xsl_script_processing.xml: 6 rules (T1220 WMIC/msxsl)
    - include_persistence_via_lolbas.xml: 10 rules (at, schtasks, sc, reg)
    - include_discovery_recon.xml: 15 rules (whoami, net, nltest, etc.)
    - include_amsi_bypass_patterns.xml: 8 rules (T1562.001 AMSI patches)
    - include_dotnet_unmanaged_abuse.xml: 8 rules (csi, jsc, dotnet, InstallUtil)
    - include_uncommon_lolbas.xml: 20 rules (rare LOLBAS + WSL detection)
  - All 13 modules pass xmllint validation when wrapped in synthetic root
  - All include rules use Phase 8 ATT&CK structured tagging convention
  - Mix of composite Rules (binary + command-line scoping where appropriate) and flat Image rules (binary-only where binary execution is the detection)
  - PowerShell rules cover all 3 binaries (powershell.exe, pwsh.exe, powershell_ise.exe) via `contains any` operator
  - Updated sysmon-configs/modules/README.md to add lolbas as 7th category
  - Updated sysmon-configs/modules/INDEX.md with all 13 modules and new LOLBAS section
  - End-to-end merge test passes: PowerShell merge tool successfully merges baseline-ot + 3 LOLBAS modules into deployable config
  - PowerShell test harness still 7/7 passing
  - Field constraints: 0 violations across all lolbas modules, max name length 132 chars
  - Total module library: 48 modules across 7 categories (was 35 across 6 in Phase 9)
- Executed Phase 10e:
  - Created docs/_pages/lolbas-detection.html (new website page)
    - What LOLBAS is and why it matters specifically in OT environments
    - Three-tier strategy explanation with table summarizing Tier 1/2/3 placement and FP expectations
    - Tier 1: 12 detections with full ATT&CK mapping table
    - Tier 2: 20 detections with full ATT&CK mapping table
    - Tier 3: 13 modules with rule counts and ATT&CK focus
    - AMSI bypass limitation note (threat actors rotate strings)
    - OT false positive tuning guide (common FP sources, tuning approach)
    - Composite Rule logic explanation with example
    - Comparison table: SwiftOnSecurity, sysmon-modular, SigmaHQ, ICS Watch Dog
    - References section
  - Updated docs/_pages/modules.html: added LOLBAS as 7th category in categories table; added 13 LOLBAS modules to available modules list; statistics updated 35->48 modules
  - Updated docs/_pages/configurations.html: added LOLBAS Detection overview block at top of curated configurations section explaining Tier 1/2/3 inclusion
  - Updated docs/_includes/nav.html: added "LOLBAS Detection" link to Guides dropdown (between ATT&CK Rule Tagging and Module Library)
  - Updated README.md: added LOLBAS Detection section with three-tier strategy summary and link to icswatchdog.com/lolbas-detection/
  - Verified Jekyll build: 0.018s, no errors, _site/lolbas-detection/index.html generated successfully

## Previous Session (2026-03-23)

### Previous Session (2026-03-23)

- Analyzed user feedback: CheckRevocation self-closing element causing Sysmon config validation failure
- Root cause analysis: self-closing `<CheckRevocation/>` syntax incompatible with some Sysmon versions; also operationally problematic for air-gapped OT systems needing CRL access
- Audited all 10 config files -- confirmed CheckRevocation was the only self-closing element in use; no other similar syntax risks
- Fixed 9 configs (8 curated + 1 community) with explicit boolean values and explanatory comments
- IT configs (workstation, server, AD, services, jumphost): set to True
- OT configs (baseline, enhanced, advanced): set to False
- Community filecreate-only: set to True
- Reference SwiftOnSecurity: unchanged
- All 9 modified configs pass xmllint validation
- Updated ARCHITECTURE.md (CheckRevocation documentation)

### Previous Session (2026-03-17)

- Conducted Phase 7a deep research (efficacy testing tools, safe PS techniques, OT constraints)
- Reviewed user feedback and incorporated design decisions into plan
- Updated PLAN.md with Phase 7 (three sub-phases, 8 decision log entries)
- Analyzed all 8 curated Sysmon configs for Event ID coverage and rule logic
- Implemented tools/Test-SysmonConfig.ps1 (PowerShell 3+, ~450 lines)
- Updated PLAN.md Phase 7b task list with actual implementation details

## Next Steps

1. Review Phase 10e results: new LOLBAS Detection website page, updated nav/README/modules/configurations pages, Jekyll build verified
2. Approve Phase 10f to execute the combined v4.0 release
3. Phase 10f: combined v4.0 release (Phase 8 ATT&CK tagging + Phase 9 module library + Phase 10 LOLBAS detection)
   - Final review of all configs, modules, tooling, and documentation
   - Run final validation pass: 8/8 xmllint, 8/8 diff-check (composite-aware), 7/7 PowerShell test harness, 48/48 modules valid
   - Commit all Phase 8, 9, 10 changes on claude-dev branch
   - Merge to main following claude-dev/GIT_RELEASE_STEPS.md (excludes docs/ and claude-dev/)
   - Deploy site to gh-pages
   - Verify all site links point to main branch
   - Tag release v4.0 on main

## Files Modified This Session

| File | Change |
|------|--------|
| CLAUDE.md | Scope update: module library, merge tooling, ATT&CK tagging in scope; replaced Sysmon-specific Code Quality bullets with reference to SYSMON_CODING_STANDARD.md |
| claude-dev/PLAN.md | Added Phase 8 (3 sub-phases), Phase 9 (5 sub-phases), 21 decision log entries (including 250-char limit and Sysmon Coding Standard creation), updated current phase pointer, updated out-of-scope list, marked Phase 8a tasks complete |
| claude-dev/ARCHITECTURE.md | Removed duplicated Sysmon details (Config File Structure section, full ATT&CK Tagging Convention, Module Architecture file format/dual-use/schema specifics). Replaced with concise references to SYSMON_CODING_STANDARD.md. Kept architectural rationale: module categories table, merge tooling purpose, test harness purpose. Updated file structure tree. |
| claude-dev/SYSMON_CODING_STANDARD.md | NEW: 15-section single source of truth for Sysmon XML conventions. Encodes file structure, schema selection, meta config, RuleGroup conventions, rule naming with ATT&CK tagging, field constraints (250-char limit, no commas/pipes), comment templates, module conventions, validation requirements, attribution, disclaimer, style, versioning |
| claude-dev/PHASE8A_TAGGING_WORKSHEET.md | Phase 8a deliverable updated: marked all 6 open issues RESOLVED with user decisions. Convention Recap section now references SYSMON_CODING_STANDARD.md and includes field constraints. Status updated to "Phase 8b ready to begin". |
| claude-dev/RESUME.md | Updated with full Phase 8a, 8b, and standard creation activity; completion summary; next steps |
| sysmon-configs/sysmonconfig-jumphost.xml | ATT&CK tagging applied: 80 include + 21 exclude rules + maintainer comment blocks |
| sysmon-configs/sysmonconfig-baseline-it-workstation.xml | ATT&CK tagging applied: 74 include + 45 exclude rules tagged |
| sysmon-configs/sysmonconfig-baseline-it-server.xml | ATT&CK tagging applied: 77 include + 38 exclude rules tagged |
| sysmon-configs/sysmonconfig-baseline-ot.xml | ATT&CK tagging applied: 103 include + 42 exclude rules tagged (includes ICS ATT&CK T0857) |
| sysmon-configs/sysmonconfig-server-ad.xml | ATT&CK tagging applied: 104 include + 55 exclude rules (DC-specific T1003.002/003/004, T1556) |
| sysmon-configs/sysmonconfig-server-services.xml | ATT&CK tagging applied: 131 include + 57 exclude rules (T1505.001/003/004) |
| sysmon-configs/sysmonconfig-enhanced-ot.xml | ATT&CK tagging applied: 143 include + 42 exclude rules (industrial protocol T0830/T0855) |
| sysmon-configs/sysmonconfig-advanced-ot.xml | ATT&CK tagging applied: 159 include + 42 exclude rules (FileBlockExecutable T1204.002/T1036.005) |
| docs/_pages/attack-tagging.html | NEW: ATT&CK Rule Tagging convention page |
| docs/_pages/modules.html | NEW: Module Library overview, dual-use convention, merge tool usage, available modules list |
| docs/_pages/related-projects.html | NEW: Microsoft Sysmon, SwiftOnSecurity, sysmon-modular, MITRE ATT&CK, SANS, LOLRMM, adversary emulation |
| docs/_includes/nav.html | Added ATT&CK Rule Tagging, Module Library, and Related Projects to Guides dropdown |
| README.md | Added ATT&CK Rule Tagging and Module Library sections (links to public icswatchdog.com pages, no claude-dev/ links) |
| sysmon-configs/sysmonconfig-*.xml (all 8) | claude-dev/ references replaced with icswatchdog.com/attack-tagging/ URL |
| sysmon-configs/modules/README.md | NEW: module library README (format, dual-use, merge tool usage, contributing) |
| sysmon-configs/modules/INDEX.md | NEW: complete module index with descriptions, ATT&CK refs, schema |
| sysmon-configs/modules/vendor-ot/*.xml | NEW: 5 OT vendor modules |
| sysmon-configs/modules/vendor-it/*.xml | NEW: 5 IT vendor noise reduction modules |
| sysmon-configs/modules/cloud-storage/*.xml | NEW: 8 cloud storage modules (dual-use) |
| sysmon-configs/modules/sector/*.xml | NEW: 4 sector modules |
| sysmon-configs/modules/protocol/*.xml | NEW: 8 industrial protocol modules |
| sysmon-configs/modules/remote-access/*.xml | NEW: 5 remote access modules (dual-use) |
| tools/Merge-SysmonModules.ps1 | NEW: PowerShell module merge tool (PS 3+, no deps) |
| tools/Test-MergeSysmonModules.ps1 | NEW: PowerShell test harness with 7 test cases |
| tools/test-fixtures/base-configs/ | NEW: 2 base config fixtures |
| tools/test-fixtures/modules/ | NEW: 4 sample modules including invalid/schema-mismatch test cases |
| tools/test-fixtures/expected/ | NEW: 1 expected output fixture |
| claude-dev/SYSMON_CODING_STANDARD.md | Added section 5.3 Composite Rules with `<Rule groupRelation="and">`, added section 6.6 LOLBAS Detection Three-Tier Strategy, renumbered RuleGroup Comments to 5.4 |
| claude-dev/PLAN.md | Added Phase 10 (10a-10f) with full task lists, 9 new decision log entries for Phase 10 design decisions, updated current phase pointer to Phase 10, marked Phase 9e release as combined with Phase 10f into v4.0, marked Phase 10a tasks complete |
| claude-dev/PHASE10A_LOLBAS_WORKSHEET.md | NEW: Phase 10a deliverable. 12 Tier 1 detections with full XML, 20 Tier 2 detections, 13 Tier 3 modules, composite Rule validation notes, per-config impact summary, Phase 10b/c/d workflow, 10 open issues for review |
| tools/check-rule-preservation.py | NEW: Composite-rule-aware diff-check tool. Extracts flat field conditions and composite Rules separately, verifies existing rules preserved on edits, reports added rules. Phase 10b deliverable. |
| sysmon-configs/sysmonconfig-jumphost.xml | Phase 10b: +Tier 1 LOLBAS (17 composite). Phase 10c: +Tier 2 LOLBAS (13 composite + 9 flat). Version v1.1->v1.3. |
| sysmon-configs/sysmonconfig-baseline-it-workstation.xml | Phase 10b: +Tier 1 LOLBAS only. Version v2.1->v2.2. |
| sysmon-configs/sysmonconfig-baseline-it-server.xml | Phase 10b: +Tier 1 LOLBAS only. Version v2.1->v2.2. |
| sysmon-configs/sysmonconfig-server-ad.xml | Phase 10b: +Tier 1. Phase 10c: +Tier 2. Version v2.1->v2.3. |
| sysmon-configs/sysmonconfig-server-services.xml | Phase 10b: +Tier 1. Phase 10c: +Tier 2. Version v2.1->v2.3. |
| sysmon-configs/sysmonconfig-baseline-ot.xml | Phase 10b: +Tier 1 LOLBAS only. Version v1.1->v1.2. |
| sysmon-configs/sysmonconfig-enhanced-ot.xml | Phase 10b: +Tier 1. Phase 10c: +Tier 2. Version v2.1->v2.3. |
| sysmon-configs/sysmonconfig-advanced-ot.xml | Phase 10b: +Tier 1. Phase 10c: +Tier 2 (header LOLBAS lines added during Phase 10c due to different header format). Version v2.1->v2.3. |
| sysmon-configs/modules/lolbas/include_signed_binary_proxy.xml | NEW: 25 rules covering T1218 family |
| sysmon-configs/modules/lolbas/include_powershell_offensive.xml | NEW: 15 PowerShell offensive pattern rules |
| sysmon-configs/modules/lolbas/include_wmic_abuse.xml | NEW: 10 WMIC abuse rules |
| sysmon-configs/modules/lolbas/include_certutil_abuse.xml | NEW: 8 certutil abuse mode rules |
| sysmon-configs/modules/lolbas/include_bitsadmin_abuse.xml | NEW: 6 BITSAdmin abuse rules |
| sysmon-configs/modules/lolbas/include_script_host_abuse.xml | NEW: 10 cscript/wscript/jscript rules |
| sysmon-configs/modules/lolbas/include_trusted_developer_utilities.xml | NEW: 12 T1127 developer utility rules |
| sysmon-configs/modules/lolbas/include_xsl_script_processing.xml | NEW: 6 T1220 XSL processing rules |
| sysmon-configs/modules/lolbas/include_persistence_via_lolbas.xml | NEW: 10 persistence command-line rules |
| sysmon-configs/modules/lolbas/include_discovery_recon.xml | NEW: 15 discovery/recon command rules |
| sysmon-configs/modules/lolbas/include_amsi_bypass_patterns.xml | NEW: 8 AMSI bypass pattern rules |
| sysmon-configs/modules/lolbas/include_dotnet_unmanaged_abuse.xml | NEW: 8 .NET unmanaged abuse rules |
| sysmon-configs/modules/lolbas/include_uncommon_lolbas.xml | NEW: 20 rare LOLBAS rules including WSL detection |
| sysmon-configs/modules/INDEX.md | Updated: added LOLBAS category section with all 13 modules, statistics updated 35->48 total |
| sysmon-configs/modules/README.md | Updated: added lolbas to categories table as 7th category |
| docs/_pages/lolbas-detection.html | NEW: full LOLBAS Detection website page with three-tier strategy, full Tier 1/2/3 rule lists, OT tuning guide, comparison with other Sysmon projects |
| docs/_pages/modules.html | Updated: added LOLBAS as 7th category, all 13 LOLBAS modules in available modules list, statistics 35->48 |
| docs/_pages/configurations.html | Updated: added LOLBAS Detection overview block at top of curated configurations section |
| docs/_includes/nav.html | Updated: added "LOLBAS Detection" link to Guides dropdown |
| README.md | Updated: added LOLBAS Detection section with three-tier strategy summary, link to icswatchdog.com/lolbas-detection/ |
