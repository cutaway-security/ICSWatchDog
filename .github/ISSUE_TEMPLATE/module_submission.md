---
name: Module Submission
about: Submit a new module or module update for review
title: "[MODULE] "
labels: module-submission
assignees: ''
---

**Module name**:
**Category**: vendor-ot / vendor-it / cloud-storage / sector / protocol / remote-access / lolbas
**Confidence level**: verified-in-lab / vendor-documented / security-research / theoretical

**Provenance**
Where did the rule content come from? Include URLs to vendor documentation, LOLBAS Project entries, MITRE ATT&CK techniques, or other authoritative sources.

**Validation checklist**
- [ ] XML well-formed (`xmllint --noout` passes)
- [ ] Merges into a curated config without error (`Merge-SysmonModules.ps1`)
- [ ] Merged config loads into Sysmon (`Sysmon64.exe -c`)
- [ ] ATT&CK tagging convention followed (see https://icswatchdog.com/attack-tagging/)
- [ ] Validation file (`.validation.md`) included
- [ ] Provenance block in module header

**Testing environment** (if verified-in-lab)
- OS version:
- Sysmon version:
- Vendor product and version:
- Observation period:
- False positives observed:

**Attach files**
- Module XML file
- Validation file (`.validation.md`)
- Sanitized inventory JSON (optional, use `Export-SystemInventory.ps1 -Redact`)

**IMPORTANT**: Do NOT include hostnames, IP addresses, usernames, passwords, license keys, or other sensitive data in any attached files. Use `Export-SystemInventory.ps1 -Redact` if submitting inventory data, and review the output manually before attaching.
