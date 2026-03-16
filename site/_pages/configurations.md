---
title: Configuration Files
nav_order: 3
permalink: /configurations/
---

# Sysmon Configuration Files

ICS Watch Dog provides Sysmon configurations organized into tiers. Start with Tier 1 and advance as your monitoring program matures.

All configuration files can be downloaded from the [ICS Watch Dog GitHub repository](https://github.com/cutaway-security/ICSWatchDog).

---

## Tiered Configurations

### Tier 1: Starter

**Status**: In Development

The bare minimum to get Sysmon running and producing useful logs. Designed for the broadest OS compatibility using Sysmon schema 4.50 (Sysmon v13+).

**Best for**: Teams deploying Sysmon for the first time, legacy Windows environments.

- [sysmonconfig-minimal.xml](https://github.com/cutaway-security/ICSWatchDog/blob/main/sysmonconfig-minimal.xml)

### Tier 2: Baseline

**Status**: In Development

Core ICS/OT-relevant monitoring covering process creation, network connections, and file creation events. Uses Sysmon schema 4.50 for legacy OS compatibility.

**Best for**: Teams with basic Sysmon experience ready to expand coverage.

### Tier 3: Enhanced

**Status**: In Development

Broader coverage with ICS/OT-aware filtering. May use newer Sysmon schema features depending on the variant.

**Best for**: Teams with established monitoring looking to increase visibility.

### Tier 4: Advanced

**Status**: In Development

Detailed monitoring leveraging the newest Sysmon features. Intended as a starting point for customization based on specific system roles (HMI stations, engineering workstations, historians, etc.).

**Best for**: Experienced teams ready for comprehensive endpoint monitoring.

- [sysmonconfig-adv-workstation.xml](https://github.com/cutaway-security/ICSWatchDog/blob/main/sysmonconfig-adv-workstation.xml) -- Advanced configuration for workstations

---

## Standalone Configurations

These configs serve specific monitoring use cases and can be deployed independently or alongside a tiered config.

### File Create Only

**Status**: In Development
**Author**: Aaron Boyd (icsblitz)

Monitors file creation events, tracking dangerous attachment types, scripts, executables, and other files of interest. Useful for environments where file creation monitoring is the immediate priority.

- [sysmonconfig-filecreate-only.xml](https://github.com/cutaway-security/ICSWatchDog/blob/main/sysmonconfig-filecreate-only.xml)

---

## Reference Configurations

### SwiftOnSecurity Sysmon Config

**Source Version**: 74 (2021-07-08)
**Source Project**: [SwiftOnSecurity/sysmon-config](https://github.com/SwiftOnSecurity/sysmon-config)

The original SwiftOnSecurity configuration that inspired many of the ICS Watch Dog configs. Retained as a reference for comparison and learning. This is an IT-focused general-purpose configuration.

- [sysmonconfig-export.xml](https://github.com/cutaway-security/ICSWatchDog/blob/main/sysmonconfig-export.xml)

---

## Choosing a Configuration

| Situation | Recommended Config |
|-----------|-------------------|
| First time deploying Sysmon | Tier 1: Starter |
| Legacy Windows (Server 2008/2012, Win 7) | Tier 1 or Tier 2 (schema 4.50 variants) |
| Established monitoring, want more coverage | Tier 3: Enhanced |
| Experienced team, specific system roles | Tier 4: Advanced |
| Only need file creation monitoring | Standalone: File Create Only |
| Learning Sysmon, want a reference | Reference: SwiftOnSecurity |
