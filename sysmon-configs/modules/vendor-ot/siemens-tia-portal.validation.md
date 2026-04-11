# Module Validation: Siemens TIA Portal

**Module**: sysmon-configs/modules/vendor-ot/siemens-tia-portal.xml
**Version**: v1.1
**Confidence**: vendor-documented
**Last Validated**: 2026-04-11
**Validated By**: ICS Watch Dog Project (initial assessment)

## Evidence

Source documentation for process names, file extensions, and install paths:

- Siemens TIA Portal V17 online help: process names (Siemens.Automation.Portal.exe), default install path (C:\Program Files\Siemens\Automation\Portal V17)
- Siemens TIA Portal V15/V16 installation guides: confirmed same binary naming convention
- Siemens STEP 7 Classic documentation: s7tgtopx.exe (SIMATIC Manager)
- sysmon-modular project: cross-referenced process patterns
- Community threat reports: TIA Portal as engineering workstation attack surface (CHERNOVITE/PIPEDREAM)

No lab testing has been performed. Process names and paths are sourced from vendor public documentation only.

## Checklist

| Item | Status | Notes |
|------|--------|-------|
| XML well-formed | PASS | xmllint --noout passes |
| Schema version correct | PASS | Header declares schema 4.50 (module schema, valid for merge into 4.90 base) |
| Provenance block present | PASS | Confidence: vendor-documented |
| ATT&CK tagging correct | PASS | T1565.001, T0857 tagged on include rules |
| Rule name length | PASS | All under 250 chars |
| Merge test | PASS | Merged into baseline-ot via Merge-SysmonModules.ps1 |
| Merged config loads | PASS | Tested on Win10 (Sysmon 15.20), Win11 (Sysmon 15.20) |
| Process names verified | PASS | Vendor docs for V13-V17 |
| File extensions verified | PASS | .ap17, .ap18, .ap19 per TIA Portal documentation |
| Default install paths verified | PASS | C:\Program Files\Siemens\Automation\Portal V## per vendor docs |

## Observations

- TIA Portal V18 and V19 may change binary names or paths. The current rules target V13-V17 naming conventions.
- WinCC OA (Open Architecture) uses different processes not covered by this module.
- SCALANCE network device configuration tools are not covered.
- PCS 7 and SIMATIC Manager Classic are partially covered (s7tgtopx.exe) but not comprehensively.
- No false positive data available (no lab testing performed).

## History

| Date | Change | By |
|------|--------|----|
| 2026-04-07 | Initial provenance metadata added (Phase 11a), confidence: vendor-documented | ICS Watch Dog Project |
| 2026-04-11 | Initial validation file created (Phase 11c) | ICS Watch Dog Project |
