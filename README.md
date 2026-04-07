# ICS Watch Dog

<img align="left" width="100" height="100" src="images/icswatchdog_logo_1_circle_sm1.png">

[Microsoft Sysinternals Sysmon](https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon) is one of the best tools for improving visibility into what happens on your Windows servers and workstations. The [ICS Watch Dog](https://icswatchdog.com) project provides ready-to-use Sysmon configurations designed for enterprise IT and ICS/OT environments, mapped to the [SANS ICS 5 Critical Controls](https://www.sans.org/white-papers/five-ics-cybersecurity-critical-controls). Start with the IT baseline and progress through OT-specific configs as your monitoring program matures.

<br clear="left"/>

## Configuration Files

All configs are in the [`sysmon-configs/`](sysmon-configs/) directory.

### Curated Configs

| Config | Description | Sysmon Version |
|--------|-------------|----------------|
| [sysmonconfig-baseline-it-workstation.xml](sysmon-configs/sysmonconfig-baseline-it-workstation.xml) | IT workstation baseline - desktop/laptop monitoring, remote access tool detection | v13+ (schema 4.50) |
| [sysmonconfig-baseline-it-server.xml](sysmon-configs/sysmonconfig-baseline-it-server.xml) | IT server baseline - server-appropriate exclusions, minimal desktop noise | v13+ (schema 4.50) |
| [sysmonconfig-server-ad.xml](sysmon-configs/sysmonconfig-server-ad.xml) | Active Directory / Domain Controller - NTDS.dit monitoring, credential extraction detection, raw disk read enabled | v13+ (schema 4.50) |
| [sysmonconfig-server-services.xml](sysmon-configs/sysmonconfig-server-services.xml) | Database + web server - covers MSSQL, PostgreSQL, MySQL, Oracle, MongoDB, InfluxDB, IIS, Apache, Nginx, Tomcat | v13+ (schema 4.50) |
| [sysmonconfig-baseline-ot.xml](sysmon-configs/sysmonconfig-baseline-ot.xml) | OT baseline - adds ICS/OT vendor monitoring, ICS file types, adjusted OT exclusions | v13+ (schema 4.50) |
| [sysmonconfig-jumphost.xml](sysmon-configs/sysmonconfig-jumphost.xml) | Jump host / bastion host - comprehensive monitoring, clipboard tracking, minimal exclusions | v15+ (schema 4.90) |
| [sysmonconfig-enhanced-ot.xml](sysmon-configs/sysmonconfig-enhanced-ot.xml) | OT enhanced - industrial protocol port monitoring, expanded vendor coverage | v13+ (schema 4.50) |
| [sysmonconfig-advanced-ot.xml](sysmon-configs/sysmonconfig-advanced-ot.xml) | OT advanced - executable detection (Event IDs 27-29), file shredding detection | v15+ (schema 4.90) |

### Community Configs

Community-contributed configurations for specific use cases. See [sysmon-configs/community/](sysmon-configs/community/).

| Config | Author | Description |
|--------|--------|-------------|
| [sysmonconfig-filecreate-only.xml](sysmon-configs/community/sysmonconfig-filecreate-only.xml) | Aaron Boyd (icsblitz) | File creation monitoring |

### Reference Configs

Third-party configs retained for learning and comparison. Not maintained by ICS Watch Dog.

| Config | Source | Description |
|--------|--------|-------------|
| [sysmonconfig-swiftonsecurity-v74.xml](sysmon-configs/reference/sysmonconfig-swiftonsecurity-v74.xml) | [SwiftOnSecurity](https://github.com/SwiftOnSecurity/sysmon-config) | Original SwiftOnSecurity v74 (2021-07-08) |

## Quick Start

1. Download [Sysmon](https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon) from Microsoft
2. Download a configuration file from the `sysmon-configs/` directory:
   - **Workstations**: start with `sysmonconfig-baseline-it-workstation.xml`
   - **Servers**: start with `sysmonconfig-baseline-it-server.xml`
3. Install from an elevated command prompt:

```
sysmon.exe -accepteula -i sysmonconfig-baseline-it-workstation.xml
```

4. Verify in Windows Event Viewer under: `Applications and Services Logs > Microsoft > Windows > Sysmon > Operational`

For detailed instructions, see the [Getting Started](https://icswatchdog.com/getting-started/) guide on the project website.

## ATT&CK Rule Tagging

Every detection rule in the curated configurations is tagged with the MITRE ATT&CK technique it is designed to detect. The technique ID, technique name, and a site-specific detection description are embedded in the Sysmon rule `name` attribute, which Sysmon writes to the Windows Event Log `RuleName` field. SIEMs can extract this structured data directly without external lookup tables, enabling ATT&CK correlation and dashboards from raw Sysmon events.

For the full convention, format details, SIEM parsing examples, and field constraints, see the [ATT&CK Rule Tagging](https://icswatchdog.com/attack-tagging/) guide.

## LOLBAS Detection

Living off the Land Binaries and Scripts (LOLBAS) detection is built into the curated configurations using a three-tier strategy that balances high-signal coverage with the false positive sensitivity of OT environments:

- **Tier 1 (Core)**: 12 high-signal detections in all 8 curated configs. Each rule scoped by binary + command-line pattern. Should rarely or never fire in stable OT environments.
- **Tier 2 (Advanced)**: 20 broader detections in 5 advanced configs (jumphost, server-ad, server-services, enhanced-ot, advanced-ot). Accepts moderate false positives in exchange for broader coverage.
- **Tier 3 (Comprehensive)**: 13 opt-in modules in [`sysmon-configs/modules/lolbas/`](sysmon-configs/modules/lolbas/) providing 153 rules of Sigma-level coverage organized by ATT&CK technique family.

Tier 1 and Tier 2 use Sysmon composite `<Rule groupRelation="and">` logic for high-precision detection. All rules use the ATT&CK structured tagging convention.

For the three-tier strategy, full rule lists, OT tuning guide, and comparison with other Sysmon projects, see the [LOLBAS Detection](https://icswatchdog.com/lolbas-detection/) guide.

## Module Library

Advanced users can customize their Sysmon configuration by merging opt-in modules from the [`sysmon-configs/modules/`](sysmon-configs/modules/) directory into a curated base config. Modules are focused XML fragments organized into six categories: OT vendor (Siemens, Rockwell, Schneider, AVEVA, Ignition), IT vendor noise reduction (Chrome, Edge, Firefox, Adobe, Office), cloud storage (Dropbox, OneDrive, Google Drive, Box, MEGA), sector (electric, water, oil/gas, manufacturing), industrial protocol (Modbus, OPC-UA, DNP3, S7comm, EtherNet/IP, BACnet, IEC 60870-5-104, MQTT), and remote access (TeamViewer, AnyDesk, ScreenConnect, RustDesk).

The merge tool combines a base curated config with selected modules into a deployable configuration:

```
.\tools\Merge-SysmonModules.ps1 `
    -BaseConfig sysmon-configs\sysmonconfig-baseline-ot.xml `
    -Modules @(
        'sysmon-configs\modules\vendor-ot\siemens-tia-portal.xml',
        'sysmon-configs\modules\protocol\modbus-tcp.xml',
        'sysmon-configs\modules\cloud-storage\include_mega.xml'
    ) `
    -OutputPath sysmonconfig-site-acmeplant.xml
```

Requires: Windows PowerShell 5.1+ or PowerShell Core 7+. No external dependencies. The curated configs remain the primary supported deployment artifact -- modules are an opt-in layer for advanced users.

For module library overview, dual-use convention, and full module list, see the [Module Library](https://icswatchdog.com/modules/) guide.

## Efficacy Testing

After deploying Sysmon, validate that your configuration is generating the expected events. The included test script performs safe actions and checks the Sysmon event log for results:

```
# Run observation-only tests (no system changes)
.\tools\Test-SysmonConfig.ps1

# Include registry and WMI tests (modifies system state, cleaned up automatically)
.\tools\Test-SysmonConfig.ps1 -AllowSystemChanges
```

Requires: Administrator privileges, Sysmon installed and running, PowerShell 3+. No external dependencies.

For details, see the [Efficacy Testing](https://icswatchdog.com/efficacy-testing/) guide.

## Disclaimer

These configurations are provided as-is for educational and operational use. They are NOT tested against all environments and may require tuning for your specific systems. Cutaway Security, LLC and contributors assume no liability for any impact resulting from the use of these configurations. Users are responsible for testing in their own environments before production deployment. This is especially critical in ICS/OT environments where system availability and safety are paramount.

Community-contributed configurations are not maintained or tested by Cutaway Security, LLC. Users must perform their own due diligence, review, and testing before deploying community configurations in any environment.

## Contributing

Contributions are welcome via pull requests or GitHub issues (feature enhancements). Community configs are placed in the `sysmon-configs/community/` directory with author attribution. See the [Community Contributions](https://icswatchdog.com/community/) page for guidelines.

## Similar Projects

* [Microsoft Sysinternals Sysmon](https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon)
* [SwiftOnSecurity Sysmon Config](https://github.com/SwiftOnSecurity/sysmon-config)
* [Working With Sysmon Configurations Like a Pro Through Better Tooling - Matt Graeber](https://posts.specterops.io/working-with-sysmon-configurations-like-a-pro-through-better-tooling-be7ad7f99a47)
* [Sysinternals Sysmon suspicious activity guide](https://learn.microsoft.com/en-us/archive/blogs/motiba/sysinternals-sysmon-suspicious-activity-guide)

## Project License

[Creative Commons Attribution 4.0 International](https://choosealicense.com/licenses/cc-by-4.0/): You may privatize, fork, edit, teach, publish, or deploy for commercial use - with attribution in the text.

## Contributors

* [Don C. Weber (cutaway)](https://www.linkedin.com/in/cutaway/)
* [Aaron Boyd (icsblitz)](https://www.linkedin.com/in/aaron-b-2b620531/)
* [Gavin Dilworth (zDHD)](https://www.linkedin.com/in/gavin-dilworth/)

## Sponsor

This project was developed and is supported by [Cutaway Security, LLC.](https://www.cutawaysecurity.com/) in collaboration with each contributor.
