# ICS Watch Dog

<img align="left" width="100" height="100" src="images/icswatchdog_logo_1_circle_sm1.png">

[Microsoft Sysinternals Sysmon](https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon) is one of the best tools for improving visibility into what happens on your Windows servers and workstations. The [ICS Watch Dog](https://icswatchdog.com) project provides ready-to-use Sysmon configurations designed for enterprise IT and ICS/OT environments, mapped to the [SANS ICS 5 Critical Controls](https://www.sans.org/white-papers/five-ics-cybersecurity-critical-controls). Start with the IT baseline and progress through OT-specific configs as your monitoring program matures.

<br clear="left"/>

## Configuration Files

All configs are in the [`sysmon-configs/`](sysmon-configs/) directory.

### Curated Configs

| Config | Description | Sysmon Version |
|--------|-------------|----------------|
| [sysmonconfig-baseline-it.xml](sysmon-configs/sysmonconfig-baseline-it.xml) | Enterprise IT starting point - general Windows monitoring, remote access tool detection | v13+ (schema 4.50) |
| [sysmonconfig-baseline-ot.xml](sysmon-configs/sysmonconfig-baseline-ot.xml) | OT baseline - adds ICS/OT vendor monitoring, ICS file types, adjusted OT exclusions | v13+ (schema 4.50) |
| [sysmonconfig-jumphost.xml](sysmon-configs/sysmonconfig-jumphost.xml) | Jump host / bastion host - comprehensive monitoring, clipboard tracking, minimal exclusions | v15+ (schema 4.90) |
| [sysmonconfig-enhanced-ot.xml](sysmon-configs/sysmonconfig-enhanced-ot.xml) | Broader OT coverage - industrial port awareness | In Development |
| [sysmonconfig-advanced-ot.xml](sysmon-configs/sysmonconfig-advanced-ot.xml) | Advanced OT - newer Sysmon features, role-specific | In Development |

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
2. Download a configuration file from the `sysmon-configs/` directory (start with the IT baseline)
3. Install from an elevated command prompt:

```
sysmon.exe -accepteula -i sysmonconfig-baseline-it.xml
```

4. Verify in Windows Event Viewer under: `Applications and Services Logs > Microsoft > Windows > Sysmon > Operational`

For detailed instructions, see the [Getting Started](https://icswatchdog.com/getting-started/) guide on the project website.

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
