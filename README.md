# ICS Watch Dog

<img align="left" width="100" height="100" src="images/icswatchdog_logo_1_circle_sm1.png">

[Microsoft Sysinternals Sysmon](https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon) is one of the best tools for improving visibility into what happens on your Windows servers and workstations. The [ICS Watch Dog](https://icswatchdog.com) project provides ready-to-use Sysmon configurations designed for ICS/OT environments, helping your team deploy endpoint monitoring from the start of your program through its maturity.

<br clear="left"/>

## Configuration Files

ICS Watch Dog configurations are organized into tiers. Start simple and advance as your monitoring program matures.

| Tier | Config File | Description | Sysmon Version |
|------|-------------|-------------|----------------|
| Tier 1: Starter | [sysmonconfig-minimal.xml](sysmonconfig-minimal.xml) | Bare minimum to get Sysmon running | v13+ (schema 4.50) |
| Tier 4: Advanced | [sysmonconfig-adv-workstation.xml](sysmonconfig-adv-workstation.xml) | Advanced workstation monitoring | v13+ (schema 4.50) |
| Standalone | [sysmonconfig-filecreate-only.xml](sysmonconfig-filecreate-only.xml) | File creation monitoring only | v13+ (schema 4.50) |
| Reference | [sysmonconfig-export.xml](sysmonconfig-export.xml) | SwiftOnSecurity original (v74, 2021-07-08) | v13+ (schema 4.50) |

Additional tier configs (Baseline, Enhanced) are in development. Visit [icswatchdog.com](https://icswatchdog.com) for documentation, deployment guides, and config selection guidance.

## Quick Start

1. Download [Sysmon](https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon) from Microsoft
2. Download a configuration file from this repository
3. Install from an elevated command prompt:

```
sysmon.exe -accepteula -i sysmonconfig-minimal.xml
```

4. Verify in Windows Event Viewer under: `Applications and Services Logs > Microsoft > Windows > Sysmon > Operational`

For detailed instructions, see the [Getting Started](https://icswatchdog.com/getting-started/) guide on the project website.

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
