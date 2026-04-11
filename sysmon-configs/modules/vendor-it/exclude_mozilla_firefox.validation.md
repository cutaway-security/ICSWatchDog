# Module Validation: Mozilla Firefox (noise reduction)

**Module**: sysmon-configs/modules/vendor-it/exclude_mozilla_firefox.xml
**Version**: v1.1
**Confidence**: vendor-documented
**Last Validated**: 2026-04-11
**Validated By**: ICS Watch Dog Project (initial assessment)

## Evidence

Source: Mozilla Firefox default install paths from vendor documentation; common deployment knowledge.

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
