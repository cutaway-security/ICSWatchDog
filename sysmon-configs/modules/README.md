# ICS Watch Dog Module Library

The module library provides opt-in XML fragments that advanced users merge into a base curated configuration to add vendor-specific, sector-specific, protocol-specific, or software-specific monitoring without editing the curated configs directly.

**Curated configs remain the primary supported deployment artifact**. The module library is for users who have outgrown the baselines and want to compose customized configs without forking.

## How Modules Work

A module is a partial Sysmon XML fragment containing one or more `<RuleGroup>` elements. It is **not** a complete Sysmon config -- it has no `<Sysmon>` root element, no `<HashAlgorithms>`, no `<CheckRevocation>`, and no `<EventFiltering>` wrapper.

The merge tool (`tools/Merge-SysmonModules.ps1`) reads a base curated config plus a list of modules, inserts each module's `<RuleGroup>` elements into the base config's `<EventFiltering>` section, and writes the merged result to a new file.

```
Base config + Module A + Module B + ... = Merged config
```

The base config's meta configuration (HashAlgorithms, CheckRevocation, schemaversion) is preserved as-is.

## Categories

| Category | Directory | Rule Type | Purpose |
|----------|-----------|-----------|---------|
| OT Vendor | [vendor-ot/](vendor-ot/) | Include | Monitor OT vendor software (Siemens, Rockwell, Schneider, AVEVA, Ignition, etc.) |
| IT Vendor | [vendor-it/](vendor-it/) | Exclude (noise reduction) | Suppress noise from IT software present in OT environments (browsers, Adobe, Office) |
| Cloud Storage | [cloud-storage/](cloud-storage/) | Dual-use | Detect or suppress cloud storage clients (Dropbox, OneDrive, Google Drive, Box) |
| Sector | [sector/](sector/) | Include | Sector-specific monitoring (electric, water, oil/gas, manufacturing, pharma) |
| Protocol | [protocol/](protocol/) | Include | Industrial protocol port monitoring (Modbus, OPC-UA, DNP3, S7comm, etc.) |
| Remote Access | [remote-access/](remote-access/) | Dual-use | Per-tool RMM detection or noise reduction (TeamViewer, AnyDesk, ScreenConnect, etc.) |
| LOLBAS | [lolbas/](lolbas/) | Include (Tier 3 comprehensive) | Comprehensive Living off the Land Binaries and Scripts detection (T1218 family, T1059.001 offensive PowerShell, T1047 WMIC, T1140/T1105 certutil, T1197 BITS, T1059.005/007 script hosts, T1127 trusted developer, T1220 XSL, T1547/T1053/T1543 persistence, discovery/recon, T1562.001 AMSI bypass, .NET unmanaged abuse, long-tail rare LOLBAS including WSL) |

## Dual-Use Convention (cloud-storage, remote-access)

Cloud storage and remote access tools are dual-use: a sanctioned tool needs noise reduction, while unsanctioned use needs active detection. The library provides both stances for each tool:

| File | Use If | Effect |
|------|--------|--------|
| `exclude_<tool>.xml` | The tool is sanctioned at your site | Suppresses Sysmon events from the tool to reduce noise |
| `include_<tool>.xml` | The tool is NOT sanctioned at your site | Generates detection events when the tool is observed |

**Pick exactly one per tool based on site policy.** The merge tool does not enforce mutual exclusion -- it is your responsibility to choose the right variant for your environment. Merging both `exclude_<tool>.xml` and `include_<tool>.xml` for the same tool produces unpredictable results.

## Schema Versions

Modules default to **schema 4.50** for broadest compatibility with legacy OT systems. Modules that require newer Sysmon features (Event IDs 24, 27, 28, 29) declare schema 4.90 in their header. The merge tool warns when a 4.90 module is merged into a 4.50 base config.

## ATT&CK Tagging

All include rules in modules use the same ATT&CK structured tagging convention as the curated configs. See [icswatchdog.com/attack-tagging/](https://icswatchdog.com/attack-tagging/) for the full specification.

## Using the Merge Tool

Basic usage:

```powershell
.\tools\Merge-SysmonModules.ps1 `
    -BaseConfig sysmon-configs\sysmonconfig-baseline-ot.xml `
    -Modules @(
        'sysmon-configs\modules\vendor-ot\siemens-tia-portal.xml',
        'sysmon-configs\modules\protocol\modbus-tcp.xml',
        'sysmon-configs\modules\cloud-storage\include_dropbox.xml'
    ) `
    -OutputPath sysmonconfig-site-acmeplant.xml
```

The merge tool:
- Reads the base config and validates its structure
- Reads each module and validates that it contains only `<RuleGroup>` elements
- Inserts module `<RuleGroup>` elements into the base config's `<EventFiltering>` section
- Preserves the base config's meta section (`<HashAlgorithms>`, `<CheckRevocation>`)
- Validates the output XML before writing
- Reports which modules were merged

## Listing Available Modules

See [INDEX.md](INDEX.md) for a complete list of available modules with descriptions and ATT&CK references.

## Contributing Modules

Module contributions are welcome via pull request. New modules must:

1. Follow the file format described above (XML fragment, no `<Sysmon>` root)
2. Include the standard module header (see [INDEX.md](INDEX.md) for the template)
3. Use the ATT&CK structured tagging convention for all include rules
4. Use the `exclude=<context>` convention for exclude rules
5. Default to schema 4.50 unless 4.90 features are essential
6. Pass `xmllint --noout` validation when wrapped in a synthetic root element
7. Be added to [INDEX.md](INDEX.md) with description and ATT&CK references

For dual-use cloud storage and remote access modules, contribute both `exclude_<tool>.xml` and `include_<tool>.xml` variants together.

## Disclaimer

These modules are provided as-is for educational and operational use. They are NOT tested against all environments and may require tuning for your specific systems. Cutaway Security, LLC and contributors assume no liability for any impact resulting from the use of these modules. Users are responsible for testing in their own environments before production deployment.
