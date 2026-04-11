# RESUME.md

## Current State

**Last Session**: 2026-04-11
**Branch**: claude-dev
**Last Session**: 2026-04-11
**Status**: Phases 1-10 complete (released as tag v6). Phase 11 (all subphases 11a-11g) complete. Ready for commit, push, and release tag v7.

## Phase History Summary (v6 and earlier)

| Phase | Scope | Outcome |
|---|---|---|
| Phase 1-6 | Project foundation, website, configs (workstation/server/AD/services/OT/jumphost), documentation | v1, v2 released |
| Phase 7 | Efficacy testing script (`tools/Test-SysmonConfig.ps1`) | Shipped in v3 |
| Phase 8 | Per-rule MITRE ATT&CK technique tagging across all 8 curated configs (871 include rules tagged, 342 exclude rules tagged, 1213 rules preserved) | Shipped in v6 |
| Phase 9 | Module library (35 initial modules across 6 categories), PowerShell merge tool, test harness | Shipped in v6 |
| Phase 10 | LOLBAS three-tier detection (Tier 1 in all 8 configs, Tier 2 in 5 advanced configs, Tier 3 as 13 modules with 153 rules), composite-rule-aware diff-check tool | Shipped in v6 |
| Phase 10f | Combined v6 release (Phase 8 + 9 + 10) | Released 2026-04-06 as tag v6 |

## Current Phase: Phase 11 - Module Validation, Provenance, and Coverage Assessment

**Origin**: User feedback (2026-04-07) flagging the gap that vendor-ot modules and other OT-based modules were built from public information without validation against actual deployments. Phase 11 introduces honest provenance, a coverage assessment toolchain (capture / measure / compare), a usage guide, a Build Your Own Module guide, and a community contribution intake process. Targets release tag v7.

### Phase 11a: COMPLETE

- Added section 8.5 Provenance Metadata to SYSMON_CODING_STANDARD.md
- Defined four confidence levels: verified-in-lab, vendor-documented, security-research, theoretical
- Applied provenance metadata to all 48 existing modules
- Honest count: 0 verified-in-lab, 33 vendor-documented, 17 security-research, 2 mixed-label sector modules
- All modules bumped to v1.1
- 48/48 pass xmllint, end-to-end merge test passes, PS test harness 7/7

### Phase 11b: COMPLETE

Built `tools/Get-SysmonCoverage.ps1`: PowerShell 3+ compatible coverage assessment tool. PowerShell 3+ compatible, no external dependencies. Reports process/software/port/ATT&CK technique coverage and gaps. Three output formats (Console, JSON, Markdown). Inventory is read-only and safe for production OT systems.

Built test harness `tools/Test-GetSysmonCoverage.ps1` with 10 test cases. All 10 passing on pwsh 7.6.0 (Linux). Test fixtures in `tools/test-fixtures/coverage/`.

Sample real coverage output (baseline-ot vs mock OT engineering workstation): 25% process coverage, 60% software coverage (3/5 vendors covered), 0% industrial port coverage, 48 ATT&CK techniques detected. Adding 5 modules brought process coverage to 50%, port coverage to 100%, ATT&CK to 51. Demonstrates the value of the modular approach.

## Cleanup This Session

- Deleted `claude-dev/PHASE8A_TAGGING_WORKSHEET.md` (Phase 8a deliverable, now historical)
- Deleted `claude-dev/PHASE10A_LOLBAS_WORKSHEET.md` (Phase 10a deliverable, now historical)
- Removed worksheet reference from `claude-dev/ARCHITECTURE.md` file structure tree
- Consolidated `claude-dev/RESUME.md` to focus on current state and recent activity

## Schema 4.50 to 4.90 Bump and Testing Infrastructure (2026-04-11)

### Critical finding: Sysmon 15.20 rejects schema 4.50

Tested on Win11Pro-Dev VM: `sysmon64.exe -c sysmonconfig-baseline-ot.xml` (schema 4.50) resulted in "No rules installed". Schema 4.90 loaded successfully ("Configuration updated", 24 rule groups active). This confirmed the user's report and invalidated the project's "4.50 for legacy" strategy.

### Schema bump

Updated all 6 configs from schema 4.50 to 4.90: baseline-ot, baseline-it-server, baseline-it-workstation, enhanced-ot, server-ad, server-services. Also bumped the community filecreate-only config. Updated header comments (`Minimum Sysmon: v15+ (schema 4.90)`). All configs pass xmllint. The two advanced configs (advanced-ot, jumphost) were already at 4.90.

### Win7 legacy config

Created `sysmonconfig-legacy-win7.xml` at schema 4.23 for Windows 7 systems running Sysmon 10.42. Based on baseline-ot with:
- Removed FileDelete (ID 23), ProcessTampering (ID 25), FileDeleteDetected (ID 26)
- Replaced `contains any` conditions with `end with` for single-binary matching (powershell.exe only; pwsh.exe and powershell_ise.exe unavailable at schema 4.23)

### PS version checks

Added `$PSVersionTable.PSVersion.Major -lt 3` check to all 5 scripts: Merge-SysmonModules.ps1, Get-SysmonCoverage.ps1, Test-SysmonConfig.ps1, Test-GetSysmonCoverage.ps1, Test-MergeSysmonModules.ps1. Win7 (PS 2.0) now gets a clean error instead of cryptic failures.

### Testing infrastructure

- 6 dev VMs deployed on Proxmox NUCs (Win7, Win10, Win11, Server 2016/2019/2022). Server 2012 and 2025 not yet installed.
- SSH key auth confirmed working on Win7, Win10 (fixed ACL issue on administrators_authorized_keys), Win11.
- Win10 SSH fix: `NT AUTHORITY\Authenticated Users:(RX)` ACE on `C:\ProgramData\ssh\administrators_authorized_keys` caused silent key auth rejection. Fixed by removing inheritance and setting only SYSTEM:(F) and Administrators:(F).
- Created `claude-dev/TESTING_STANDARD.md` governing config, script, and efficacy testing procedures, pass/fail criteria, VM lifecycle rules (max 3 concurrent), and result recording.
- Created `claude-dev/dev-inventory.csv` (gitignored) with corrected VMIDs, Sysmon/PS versions from live probing.
- Created `claude-dev/proxmox-api.conf` (gitignored) with API credentials.
- Added compatibility matrix section to README.md (currently empty, to be filled during test runs).

### Standards updates

- CLAUDE.md: updated schema version constraint from "4.50 for starter/baseline" to "4.90 for standard, 4.23 for legacy Win7"
- SYSMON_CODING_STANDARD.md: Section 3 rewritten for 4.90 default with 4.23 legacy exception

## Phase 11d Checkpoint B1: COMPLETE

Standards and dev-doc foundation laid before the Phase 11d toolchain refactor (Checkpoint B2). All work targets release tag v7.

Deliverables:

- Planning sweep: replaced stale `v4.0`/`v4.1` references with `v6` (historical) and `v7` (forward target) across PLAN.md, RESUME.md. Confirmed git tags actually go v1-v6; the docs were labeling Phase 10f as "v4.0" which never matched reality.
- New `claude-dev/TOOL_CODING_STANDARD.md`: PowerShell/Python tool conventions, parameter naming, output formats (Console/JSON/Markdown), JSON I/O schema versioning (`SchemaName`/`SchemaVersion` envelope, warn-on-mismatch), test harness conventions, schema catalog (SystemInventory v1.0, CoverageReport v1.0, InventoryDiff v1.0).
- New `claude-dev/REMOTE_TESTING.md`: Proxmox VE Windows VM setup for remote automated testing. SSH-first (OpenSSH Server with key auth, password auth disabled). Public-branch hygiene rules: no real hostnames/IPs/keys/usernames in committed files. Generic placeholders only.
- New `claude-dev/remote-testing.example.conf`: template with placeholders. Real config goes in `claude-dev/remote-testing.local.conf` which is gitignored.
- New `.gitattributes`: `claude-dev/`, `docs/`, `CLAUDE.md` marked `export-ignore`. Defensive layer behind the manual `git rm` step in GIT_RELEASE_STEPS.md. Current force-push process unaffected.
- Updated `.gitignore`: added `claude-dev/remote-testing.local.conf`.
- Updated `claude-dev/GIT_RELEASE_STEPS.md`: Overview now documents the `.gitattributes` safety net; "Files Removed During Release" table now lists all current dev-only files (added TOOL_CODING_STANDARD.md, REMOTE_TESTING.md, SYSMON_CODING_STANDARD.md, remote-testing.example.conf, test-fixtures/).
- Updated `claude-dev/PLAN.md`: Phase 11d expanded into Checkpoint B1 + B2 task lists; current phase pointer set to "11d B1 in progress"; 5 new decision log entries (toolchain refactor scope, standards split, .gitattributes safety net, fixture relocation).

## Config and Script Testing Results (2026-04-11)

### Config test results

All configs loaded on their target VMs ("Configuration updated" + expected rule group counts).

| Config | Win7 | Win10 | Win11 | Srv 2016 | Srv 2019 | Srv 2022 |
|---|---|---|---|---|---|---|
| baseline-it-workstation | N/A | PASS (20) | PASS (20) | N/A | N/A | N/A |
| baseline-it-server | N/A | N/A | N/A | PASS (20) | PASS (20) | PASS (20) |
| baseline-ot | N/A | PASS (20) | PASS (20) | N/A | PASS (20) | PASS (20) |
| enhanced-ot | N/A | PASS (21) | PASS (21) | N/A | PASS (21) | PASS (21) |
| advanced-ot | N/A | PASS (24) | PASS (24) | N/A | PASS (24) | PASS (24) |
| jumphost | N/A | N/A | N/A | PASS (21) | PASS (21) | PASS (21) |
| server-ad | N/A | N/A | N/A | PASS (21) | PASS (21) | PASS (21) |
| server-services | N/A | N/A | N/A | PASS (21) | PASS (21) | PASS (21) |
| legacy-win7 | PASS (15) | N/A | N/A | N/A | N/A | N/A |

Note: Server 2016 has `Sysmon.exe` (not `Sysmon64.exe`). All other systems use `Sysmon64.exe`.

### Legacy config issues fixed during testing

1. `<CheckRevocation>False</CheckRevocation>`: text content not supported at schema 4.23. Removed (omission = disabled).
2. `<RuleGroup>`: not supported at schema 4.23. Complete rewrite to flat `<EventFiltering>` format.
3. Composite `<Rule groupRelation="and">`: not supported at schema 4.23. LOLBAS composite rules removed; broad `onmatch="exclude"` on ProcessCreate catches activity without precision targeting.

### Script test results (Win10)

- Merge-SysmonModules.ps1: PASS. Merged baseline-ot + modbus-tcp. Loaded output into Sysmon: 21 rule groups.
- Get-SysmonCoverage.ps1: PASS. Live coverage report: 63.3% process coverage.
- Test-SysmonConfig.ps1: PASS. Executed without errors. Efficacy results deferred to post-commit.

### PS 2.0 coverage tool compatibility (2026-04-11)

Made Get-SysmonCoverage.ps1 compatible with PS 2.0 via runtime detection:
- Replaced `Get-Content -Raw` with `[System.IO.File]::ReadAllText()`
- Replaced `New-TemporaryFile` with `[System.IO.Path]::GetTempFileName()`
- Replaced `Select-Object -Unique` with `Sort-Object -Unique`
- Added null guards for `.ToLower()` calls on potentially null DisplayName values (PS 2.0 registry enumeration)
- Removed PS 3.0 version gate; JSON output gated behind runtime PS version check
- Win7 Console: PASS (32.6% process coverage, 43 processes)
- Win7 Markdown: PASS (tables, headers, unmonitored list)
- Win7 JSON: PASS (clean rejection: "JSON output requires PowerShell 3.0 or later")
- Win10 regression: none (10/10 local tests, Console/JSON/Markdown verified on VM)

Updated TOOL_CODING_STANDARD.md:
- PS minimum changed from 3.0 to 2.0 (with runtime feature detection)
- All three output formats (Console/JSON/Markdown) now mandatory on report-producing scripts
- Markdown for AI consumption use case codified
- PS 2.0 compatibility table added (which features to avoid, which alternatives to use)

### NLA fix (2026-04-11)

Applied GPO startup script to set network category to Private on all 6 VMs. Root cause: Proxmox virtual bridge gateway MAC changes between reboots, causing NLA to see a "new" network every time. All VMs verified Private after reboot. Win7 uses COM API variant; others use Get-NetConnectionProfile.

### Server 2016 and Win7 resolved

- Server 2016: network adapter issue fixed by user. SSH working. All 4 server configs pass. Note: uses Sysmon.exe (32-bit), not Sysmon64.exe.
- Win7: NLA fix resolved the persistent networking issue.

## Phase 11d Checkpoint B2: COMPLETE (2026-04-11)

Toolchain refactor and usage guide:

- Refactored `Get-SysmonCoverage.ps1`: renamed `-MockInventoryPath` to `-InventoryPath`. Inventory JSON is now a first-class artifact, not a test hack.
- Built `Export-SystemInventory.ps1`: captures live system to JSON with schema v1.0 envelope (`SchemaName`, `SchemaVersion`, `GeneratedBy`, `GeneratedAt`). Opt-in `-Redact` for sanitization. Console/Markdown on PS 2.0, JSON on PS 3+.
- Built `Compare-SystemInventory.ps1`: diffs two inventory JSONs. Reports added/removed per category. Console/JSON/Markdown. Schema validation on input (checks `SchemaName` and major version).
- Moved coverage test fixtures from `tools/test-fixtures/coverage/` to `claude-dev/test-fixtures/coverage/`. Updated fixture with schema v1.0 envelope. Created second fixture for diff testing.
- Updated `Test-GetSysmonCoverage.ps1`: fixture path to `claude-dev/`, parameter rename, skip-on-missing behavior.
- Created `Test-CompareSystemInventory.ps1`: 8 tests covering Console/JSON/Markdown output, change detection (process add/remove, port add/remove), no-changes case, output file writing.
- Fixed `Test-MergeSysmonModules.ps1`: updated expected schema version from 4.50 to 4.90 (was broken by schema bump).
- All test harnesses pass: Coverage 10/10, Compare 8/8, Merge 7/7 = 25/25.
- Created `docs/_pages/coverage-assessment.html`: usage guide covering the three-tool workflow, output formats, honest interpretation, community submission, troubleshooting.
- Added Coverage Assessment link to nav dropdown. Jekyll build passes (0.014s).
- Updated ARCHITECTURE.md file structure tree with all new files and tools.

## Phase 11c: Module Validation Framework: COMPLETE (2026-04-11)

- Added SYSMON_CODING_STANDARD.md Section 9.5 with:
  - 9.5.1 Validation checklist: 7 universal items + category-specific items per module type
  - 9.5.2 Evidence requirements per confidence level (theoretical, security-research, vendor-documented, verified-in-lab)
  - 9.5.3 Confidence promotion path with explicit requirements
  - 9.5.4 Companion `<module>.validation.md` file format
  - 9.5.5 Validation file lifecycle
- Created initial validation files for all 48 modules alongside their XMLs
- Detailed validation file for siemens-tia-portal.xml (full evidence, complete checklist)
- Skeleton validation files for remaining 47 modules (honest: all mark "Merged config loads" as UNTESTED)

### Tools dev/release classification (2026-04-11)

Classified all tools/ contents:

**Ship to users (in main releases):**
- Get-SysmonCoverage.ps1, Export-SystemInventory.ps1, Compare-SystemInventory.ps1 (coverage toolchain)
- Merge-SysmonModules.ps1 (module merge)
- Test-SysmonConfig.ps1 (efficacy testing against live system)
- check-rule-preservation.py (rule diff checker)

**Dev-only (excluded from releases):**
- Test-GetSysmonCoverage.ps1, Test-CompareSystemInventory.ps1, Test-MergeSysmonModules.ps1 (fixture-dependent harnesses)
- tools/test-fixtures/ (merge tool fixtures)

Added to .gitattributes export-ignore and GIT_RELEASE_STEPS.md git rm step. Test-SysmonConfig.ps1 ships because it tests the live system without fixture dependency.

## Phase 11e: Build Your Own Module Guide: COMPLETE (2026-04-11)

Created `docs/_pages/build-your-own-module.html` with 8 sections:
1. When to build vs. extend vs. exclude
2. Coverage assessment step (links to coverage-assessment page)
3. Module file structure with complete header template
4. Detection pattern cookbook: 7 worked examples (binary, file creation, protocol port, composite binary+CL, registry persistence, named pipe, noise exclusion)
5. ATT&CK tagging rules and constraints
6. Validation steps (xmllint, merge, Sysmon load, coverage re-check)
7. Provenance and validation file creation
8. Contributing back (GitHub, sanitization, community page link)

Added to nav dropdown between "Module Library" and "Coverage Assessment". Jekyll build passes.

## GitHub Issue Templates and Labels (2026-04-11)

- Created `claude-dev/GITHUB_ISSUE_STANDARD.md`: portable standard for issue templates, label taxonomy, template chooser config. Reusable across projects.
- Created `.github/ISSUE_TEMPLATE/`:
  - `bug_report.md`: component selector, version fields, reproduction steps, sanitization warning
  - `feature_request.md`: type selector, use case, evidence fields for module requests
  - `module_submission.md`: category, confidence level, provenance, validation checklist, testing environment, file attachments, sanitization warning
  - `config.yml`: template chooser, blank issues disabled, documentation link
- Created 10 custom GitHub labels via `gh label create`: module-submission, config, module, tool, documentation, tier-a, tier-b, tier-c, needs-validation, windows-7
- `.github/` ships to main (added to GIT_RELEASE_STEPS.md verify checklist)

## Phase 11f: Community Contribution Intake Process: COMPLETE (2026-04-11)

Rewrote `docs/_pages/community.html` with structured contribution intake:
- Contribution types table with direct links to issue templates (bug_report, feature_request, module_submission)
- 5-step module submission workflow
- Three acceptance tiers: Tier A (verified-in-lab, main library), Tier B (vendor-documented, community/), Tier C (theoretical, GitHub issue for testing)
- Sanitization requirements (mechanical + manual review checklist)
- 8-item maintainer review checklist
- Preserved existing community configs table and disclaimer
- Jekyll build passes (0.016s)

## Phase 11g: Documentation and v7 Release: COMPLETE (2026-04-11)

Website redesign:
- Home page: replaced 6 config cards with 6 capability cards (Deploy/Extend/Measure/Detect/Build/Contribute). Updated hero subtitle. Moved "New to Sysmon?" above cards. Removed "Why ICS Watch Dog?", sponsor/contributors, and tuning warning from home.
- Created About page: mission, 8-item "what the project provides" list, 5-step "how it works" progression, SANS ICS 5 mapping table, project history, sponsor/contributors.
- Nav: Guides dropdown reorganized with section labels (Deploy/Detect/Extend/Community). About link added.
- CSS: overview-section padding tightened from 2rem to 1rem.
- Next-step callout links added to Getting Started, Configurations, Deployment, Coverage Assessment pages.

Documentation updates:
- modules.html: schema version section updated to 4.90 standard, provenance/confidence table added, test harness section replaced with user-facing validation steps.
- README.md: added Coverage Assessment section (three-tool table + examples), Module Provenance section, BYO guide link.

Final validation: 10/10 configs xmllint, 25/25 tests pass, Jekyll builds (0.017s), all pages generated.

## Blockers

None. Phase 11 complete. Ready for commit, push, and v7 release.

## Next Steps

1. **Commit and push** to claude-dev
2. **Release v7** per GIT_RELEASE_STEPS.md (tag dev-v7, release branch, strip dev files, force-push to main, tag v7, deploy site)
3. Apply PS 2.0 compatibility pattern to Merge-SysmonModules.ps1 and Test-SysmonConfig.ps1 (post-v7)

## Files Modified This Session

| File | Change |
|---|---|
| `claude-dev/PLAN.md` | Phase 11 plan; 9 decision log entries (4 Phase 11 base + 5 new from 11d B1 work); v4.x→v6/v7 sweep; Phase 11d expanded into Checkpoint B1/B2 task list; current phase pointer to 11d B1 |
| `claude-dev/RESUME.md` | v4.x→v6/v7 sweep; B1 checkpoint section added; next steps re-sequenced |
| `claude-dev/SYSMON_CODING_STANDARD.md` | Section 8.5 Provenance Metadata added (Phase 11a) |
| `claude-dev/TOOL_CODING_STANDARD.md` | NEW (B1): PowerShell/Python tool standard with schema catalog |
| `claude-dev/REMOTE_TESTING.md` | NEW (B1): Proxmox Windows VM remote testing setup, SSH-first |
| `claude-dev/remote-testing.example.conf` | NEW (B1): local-config template with placeholders only |
| `claude-dev/GIT_RELEASE_STEPS.md` | B1: Overview documents .gitattributes safety net; files-removed table updated |
| `claude-dev/ARCHITECTURE.md` | Removed PHASE8A_TAGGING_WORKSHEET.md from file structure tree |
| `.gitattributes` | NEW (B1): export-ignore for claude-dev/, docs/, CLAUDE.md |
| `.gitignore` | B1: added claude-dev/remote-testing.local.conf |
| `sysmon-configs/modules/*/*.xml` (48) | Phase 11a: provenance block added; v1.0 → v1.1 |
| `sysmon-configs/modules/sector/water-wastewater.xml` | Also fixed XML double-hyphen issue in provenance text |
| `claude-dev/PHASE8A_TAGGING_WORKSHEET.md` | DELETED (Phase 8a worksheet, historical) |
| `claude-dev/PHASE10A_LOLBAS_WORKSHEET.md` | DELETED (Phase 10a worksheet, historical) |
| `tools/Get-SysmonCoverage.ps1` | Phase 11b coverage assessment tool; PS version check added (refactor pending in B2) |
| `tools/Test-GetSysmonCoverage.ps1` | Phase 11b test harness; PS version check added (update pending in B2) |
| `tools/test-fixtures/coverage/` | Phase 11b mock inventory (will move to claude-dev/test-fixtures/ in B2) |
| `sysmon-configs/sysmonconfig-baseline-ot.xml` | Schema 4.50 -> 4.90; header updated |
| `sysmon-configs/sysmonconfig-baseline-it-server.xml` | Schema 4.50 -> 4.90; header updated |
| `sysmon-configs/sysmonconfig-baseline-it-workstation.xml` | Schema 4.50 -> 4.90; header updated |
| `sysmon-configs/sysmonconfig-enhanced-ot.xml` | Schema 4.50 -> 4.90; header updated |
| `sysmon-configs/sysmonconfig-server-ad.xml` | Schema 4.50 -> 4.90; header updated |
| `sysmon-configs/sysmonconfig-server-services.xml` | Schema 4.50 -> 4.90; header updated |
| `sysmon-configs/sysmonconfig-advanced-ot.xml` | Header updated (legacy reference 4.50 -> 4.90) |
| `sysmon-configs/community/sysmonconfig-filecreate-only.xml` | Schema 4.50 -> 4.90 |
| `sysmon-configs/sysmonconfig-legacy-win7.xml` | NEW: Win7 legacy config at schema 4.23 |
| `tools/Merge-SysmonModules.ps1` | PS version check added |
| `tools/Test-SysmonConfig.ps1` | PS version check added |
| `tools/Test-MergeSysmonModules.ps1` | PS version check added |
| `claude-dev/TESTING_STANDARD.md` | NEW: testing standard for configs and scripts across dev VMs |
| `claude-dev/dev-inventory.csv` | NEW (gitignored): VM inventory with corrected VMIDs and versions |
| `claude-dev/proxmox-api.conf` | NEW (gitignored): Proxmox API credentials |
| `CLAUDE.md` | Schema version constraint updated (4.90 standard, 4.23 legacy) |
| `claude-dev/SYSMON_CODING_STANDARD.md` | Section 3 rewritten for 4.90 default with 4.23 legacy exception |
| `README.md` | Curated configs table updated to v15+/4.90; legacy-win7 config added; compatibility matrix section added |
| `.gitignore` | Added gitignore patterns for dev config files |
