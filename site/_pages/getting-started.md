---
title: Getting Started
nav_order: 2
permalink: /getting-started/
---

# Getting Started with Sysmon in ICS/OT

This guide covers what Sysmon is, why it matters for ICS/OT environments, and how to get started with ICS Watch Dog configurations.

---

## What is Sysmon?

[Microsoft Sysinternals Sysmon](https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon) (System Monitor) is a Windows system service and device driver that logs detailed system activity to the Windows Event Log. Once installed with a configuration file, Sysmon monitors and logs events such as:

- **Process creation and termination** -- what programs run on the system
- **Network connections** -- what the system talks to and on which ports
- **File creation** -- what files are written to disk
- **Registry modifications** -- changes to system configuration
- **Driver and DLL loading** -- what code loads into processes
- **DNS queries** -- what domains the system resolves

Sysmon runs as a background service and survives reboots. It does not require a SIEM or centralized logging to be useful -- the events are viewable directly in Windows Event Viewer.

## Why Sysmon for ICS/OT?

Many ICS/OT environments have limited visibility into what happens on Windows-based systems such as HMIs, engineering workstations, historians, and domain controllers. Common challenges include:

- **No centralized logging** -- Many OT networks lack a SIEM or log aggregation platform
- **Legacy operating systems** -- Older Windows versions are common and may not support modern EDR tools
- **Change-averse environments** -- OT teams are cautious about installing new software on production systems
- **Limited security staff** -- Windows administrators may not have security monitoring experience

Sysmon addresses these challenges because:

- It is a lightweight, signed Microsoft tool (no third-party agent)
- It works on older Windows versions (Windows 7, Server 2008 R2 and later)
- It requires no network infrastructure to provide value (logs are local)
- A well-tuned configuration file controls exactly what is logged, minimizing noise and performance impact

## How to Deploy Sysmon

### 1. Download Sysmon

Download Sysmon from Microsoft:
[https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon](https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon)

Extract the archive to a location on the target system (e.g., `C:\Tools\Sysmon\`).

### 2. Choose a Configuration File

Visit the [Configuration Files]({% link _pages/configurations.md %}) page and select the tier that matches your environment. For first-time deployments, start with **Tier 1: Starter**.

Download the XML configuration file to the same directory as Sysmon (e.g., `C:\Tools\Sysmon\sysmonconfig-minimal.xml`).

### 3. Install Sysmon

Open an elevated (Administrator) command prompt and run:

```
sysmon.exe -accepteula -i sysmonconfig-minimal.xml
```

Replace `sysmonconfig-minimal.xml` with the name of your chosen configuration file.

### 4. Verify Installation

Open **Windows Event Viewer** and navigate to:

```
Applications and Services Logs > Microsoft > Windows > Sysmon > Operational
```

You should see events appearing. If the log is empty, wait a few minutes for activity to generate events.

You can also verify Sysmon is running:

```
sc query Sysmon
```

Or for 64-bit systems:

```
sc query Sysmon64
```

### 5. Update a Configuration

To change the configuration on a system where Sysmon is already installed:

```
sysmon.exe -c sysmonconfig-new.xml
```

### 6. Uninstall Sysmon

If you need to remove Sysmon:

```
sysmon.exe -u
```

---

## Centralized Log Collection (Optional)

While Sysmon works without centralized logging, forwarding events to a central location improves visibility across multiple systems. Options include:

- **Windows Event Forwarding (WEF)** -- Built into Windows, no additional software needed. See [Microsoft WEF documentation](https://aka.ms/WEF).
- **Syslog forwarding** -- Third-party tools can forward Windows events to a syslog collector
- **SIEM integration** -- Most SIEMs can ingest Sysmon events via agents or WEF

To allow the Network Service to access Sysmon logs for forwarding:

```
wevtutil.exe sl Microsoft-Windows-Sysmon/Operational /ca:O:BAG:SYD:(A;;0xf0005;;;SY)(A;;0x5;;;BA)(A;;0x1;;;S-1-5-32-573)(A;;0x1;;;NS)
```

---

## Next Steps

- Browse the [Configuration Files]({% link _pages/configurations.md %}) to find the right config for your environment
- Read the configuration XML comments to understand what each rule monitors
- As your team gains experience, advance to higher-tier configurations

---

## Similar and Inspiring Projects

- [Microsoft Sysinternals Sysmon](https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon)
- [SwiftOnSecurity Sysmon Config](https://github.com/SwiftOnSecurity/sysmon-config)
- [Working With Sysmon Configurations Like a Pro Through Better Tooling - Matt Graeber](https://posts.specterops.io/working-with-sysmon-configurations-like-a-pro-through-better-tooling-be7ad7f99a47)
- [Sysinternals Sysmon suspicious activity guide](https://learn.microsoft.com/en-us/archive/blogs/motiba/sysinternals-sysmon-suspicious-activity-guide)
