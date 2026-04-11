# Module Validation: Rockwell Studio 5000 / RSLogix

**Module**: sysmon-configs/modules/vendor-ot/rockwell-studio5000.xml
**Version**: v1.1
**Confidence**: vendor-documented
**Last Validated**: 2026-04-11
**Validated By**: ICS Watch Dog Project (initial assessment)

## Evidence

Source: Rockwell Automation knowledge base; Studio 5000 install documentation; sysmon-modular project; community sources.

## Checklist

| Item | Status | Notes |
|------|--------|-------|
| XML well-formed | PASS | |
| Schema version correct | PASS | |
| Provenance block present | PASS | |
| ATT&CK tagging correct | PASS | |
| Rule name length | PASS | |
| Merge test | PASS | |
| Merged config loads | UNTESTED | Not yet tested on a Windows VM |

## Observations

No lab testing performed. See provenance block in module header for known limitations.

## History

| Date | Change | By |
|------|--------|----|
| 2026-04-07 | Provenance metadata added (Phase 11a) | ICS Watch Dog Project |
| 2026-04-11 | Initial validation file created (Phase 11c) | ICS Watch Dog Project |
