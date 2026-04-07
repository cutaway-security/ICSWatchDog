# RESUME.md

## Current State

**Last Session**: 2026-04-07
**Branch**: claude-dev
**Status**: Phases 1-10 complete (v4.0 shipped). Phase 11a and 11b complete. Phase 11c (Validation Framework) ready to begin.

## Phase History Summary (v4.0 and earlier)

| Phase | Scope | Outcome |
|---|---|---|
| Phase 1-6 | Project foundation, website, configs (workstation/server/AD/services/OT/jumphost), documentation | v1, v2 released |
| Phase 7 | Efficacy testing script (`tools/Test-SysmonConfig.ps1`) | Shipped in v3 |
| Phase 8 | Per-rule MITRE ATT&CK technique tagging across all 8 curated configs (871 include rules tagged, 342 exclude rules tagged, 1213 rules preserved) | Shipped in v4.0 |
| Phase 9 | Module library (35 initial modules across 6 categories), PowerShell merge tool, test harness | Shipped in v4.0 |
| Phase 10 | LOLBAS three-tier detection (Tier 1 in all 8 configs, Tier 2 in 5 advanced configs, Tier 3 as 13 modules with 153 rules), composite-rule-aware diff-check tool | Shipped in v4.0 |
| Phase 10f | Combined v4.0 release (Phase 8 + 9 + 10) | Released 2026-04-06 |

## Current Phase: Phase 11 - Module Validation, Provenance, and Coverage Assessment

**Origin**: User feedback (2026-04-07) flagging the gap that vendor-ot modules and other OT-based modules were built from public information without validation against actual deployments. Phase 11 introduces honest provenance, a coverage assessment tool, a Build Your Own Module guide, and a community contribution intake process. Targets v4.1 release.

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

## Blockers

None. Coverage tool can be tested on Linux pwsh against mock inventory data; full Windows-specific cmdlet validation requires a Windows system.

## Next Steps

1. Review Phase 11b deliverables: `tools/Get-SysmonCoverage.ps1`, test harness, and sample output
2. Approve Phase 11c to begin module validation framework
3. Phase 11c: Validation framework (per-module checklist, companion `<module>.validation.md` format, evidence requirements)
4. Phase 11d: Build Your Own Module guide (website page with detection cookbook)
5. Phase 11e: Community contribution intake process (PR template, three acceptance levels)
6. Phase 11f: v4.1 documentation and release (combine all of Phase 11)

## Files Modified This Session

| File | Change |
|---|---|
| `claude-dev/PLAN.md` | Phase 11 plan added (11a-11f); 4 decision log entries; Phase 11a marked complete; current phase pointer to Phase 11b |
| `claude-dev/RESUME.md` | Consolidated and trimmed: focus on current state and Phase 11; historical phases summarized in table |
| `claude-dev/SYSMON_CODING_STANDARD.md` | Section 8.5 Provenance Metadata added |
| `claude-dev/ARCHITECTURE.md` | Removed PHASE8A_TAGGING_WORKSHEET.md from file structure tree |
| `sysmon-configs/modules/*/*.xml` (48) | Phase 11a: provenance block added; v1.0 → v1.1 |
| `sysmon-configs/modules/sector/water-wastewater.xml` | Also fixed XML double-hyphen issue in provenance text |
| `claude-dev/PHASE8A_TAGGING_WORKSHEET.md` | DELETED (Phase 8a worksheet, historical) |
| `claude-dev/PHASE10A_LOLBAS_WORKSHEET.md` | DELETED (Phase 10a worksheet, historical) |
| `tools/Get-SysmonCoverage.ps1` | NEW: Phase 11b coverage assessment tool |
| `tools/Test-GetSysmonCoverage.ps1` | NEW: Phase 11b test harness |
| `tools/test-fixtures/coverage/` | NEW: mock inventory and expected output fixtures |
