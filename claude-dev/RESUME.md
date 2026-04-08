# RESUME.md

## Current State

**Last Session**: 2026-04-07
**Branch**: claude-dev
**Status**: Phases 1-10 complete (released as tag v6). Phase 11a and 11b complete. Phase 11d (Coverage Toolchain Refactor + Usage Guide) in progress. Phase 11 work targets release tag v7.

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

## Blockers

None. Checkpoint B1 is documentation-only and contains no code changes. Checkpoint B2 will need a Windows host (manual or via the Proxmox setup in REMOTE_TESTING.md, when stood up) for full validation of `Export-SystemInventory.ps1`. Linux pwsh handles parameter-validation tests and JSON-roundtrip tests for the other two tools.

## Next Steps (Checkpoint B2)

1. Review B1 deliverables (this checkpoint) before proceeding
2. Refactor `tools/Get-SysmonCoverage.ps1`: drop `-MockInventoryPath`, add `-InventoryPath`
3. Build `tools/Export-SystemInventory.ps1` (schema v1.0, opt-in `-Redact`)
4. Build `tools/Compare-SystemInventory.ps1` (changes-only, console default)
5. Move existing fixture to `claude-dev/test-fixtures/coverage/`, regenerate via the new export tool
6. Update / add test harnesses (skip-on-missing-fixture)
7. Dogfood end-to-end against the regenerated fixture
8. Write `docs/_pages/coverage-assessment.html` usage guide
9. Update PLAN.md / RESUME.md / ARCHITECTURE.md for B2 deliverables
10. Then Phase 11c (Validation Framework) → 11e (Build Your Own Module) → 11f (Community Intake) → 11g (v7 release)

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
| `tools/Get-SysmonCoverage.ps1` | Phase 11b coverage assessment tool (refactor pending in B2) |
| `tools/Test-GetSysmonCoverage.ps1` | Phase 11b test harness (update pending in B2) |
| `tools/test-fixtures/coverage/` | Phase 11b mock inventory (will move to claude-dev/test-fixtures/ in B2) |
