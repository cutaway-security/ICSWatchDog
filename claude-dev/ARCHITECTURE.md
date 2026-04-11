# ARCHITECTURE.md

## System Overview

ICS Watch Dog consists of two components: (1) a progressive set of Sysmon XML configuration files targeting enterprise IT and ICS/OT Windows environments, and (2) a Jekyll-based documentation website deployed via GitHub Pages. The project provides a progression path from IT baseline monitoring through OT-specific advanced configurations, mapped to the SANS ICS 5 Critical Controls.

## Components

| Component | Purpose | Technology |
|-----------|---------|------------|
| Curated Configs | Progressive IT-to-OT Sysmon configs | Sysmon XML schema 4.90 (4.23 for legacy Win7) |
| Community Configs | User-contributed configs for specific use cases | Sysmon XML schema 4.90 |
| Reference Configs | Third-party configs retained for learning | Sysmon XML (SwiftOnSecurity) |
| Website | Documentation, guides, SANS control mapping | Jekyll with custom CutSec design system |
| Branding | Logo, banner, background images | PNG assets |

## Branch Strategy

| Branch | Purpose | Contains |
|--------|---------|----------|
| main | Public release | Sysmon XML configs (curated + community/ + reference/), README, License, images |
| claude-dev | Active development | Everything: configs, docs/ source, claude-dev/ planning |
| gh-pages | Deployed website | Built Jekyll site (deployed from claude-dev docs/) |

Key rules:
- All development happens on claude-dev
- Website source lives in docs/ on claude-dev
- All site links to configs and the repo point to main branch
- Release process merges configs to main (excluding docs/ and claude-dev/)
- Deploy process pushes docs/ contents to gh-pages
- For manual site review, GitHub Pages can be pointed to claude-dev branch /docs folder, then switched back when review is complete

## Config Structure

### Config Model

Configs branch by role (workstation/server) and environment (IT/OT). Each config is self-contained and deployable without editing. Only separate configs exist where structural Sysmon differences justify them (enabling/disabling Event IDs, fundamentally different exclusion logic). OT-specific tuning is handled through documentation guidance rather than a proliferation of config files.

```
IT Baseline Workstation ---- OT Baseline (general-purpose, workstation-centric)
  (enterprise workstation)      |-- OT Enhanced (broader OT, industrial ports)
                                |-- OT Advanced (newer Sysmon features, schema 4.90)

IT Baseline Server
  (enterprise server)
  |-- Server: AD / DC (structural: enables RawAccessRead, NTDS/SYSVOL paths, LSASS tuning)
  |-- Server: Services (combined database + web server monitoring, all engines)
  |     Covers: MSSQL, PostgreSQL, MySQL/MariaDB, Oracle, MongoDB, InfluxDB
  |     Covers: IIS, Apache httpd, Nginx, Tomcat/Java
  |     Structural: enables ImageLoad scoped to web worker processes

Jump Host (standalone, comprehensive monitoring, schema 4.90)
```

All standard configs use schema 4.90 (Sysmon v15+). A single legacy config (sysmonconfig-legacy-win7.xml) uses schema 4.23 for Windows 7 with Sysmon 10.42. Config headers include SANS ICS 5 Critical Controls mapping, MITRE ATT&CK references, and CIS Benchmark alignment labels.

**Design principles:**
- Configs for roles, not for vendors or individual software products
- Rules for absent services have zero cost (never match, no noise, no performance impact)
- OT historians (PI, Ignition, AVEVA) are database+web servers -- use server-services config + OT vendor guidance
- Admins MUST tune for their environment; configs are starting points, not final deployments

### File Organization

```
# IT Baselines
sysmonconfig-baseline-it-workstation.xml  # IT workstation baseline, schema 4.50
sysmonconfig-baseline-it-server.xml       # IT server baseline, schema 4.50

# Server Role Configs (self-contained, include server baseline rules)
sysmonconfig-server-ad.xml                # Active Directory / Domain Controller, schema 4.50
sysmonconfig-server-services.xml          # Database + web server (all engines), schema 4.50

# OT Configs (workstation-centric, build on IT workstation baseline)
sysmonconfig-baseline-ot.xml              # OT baseline (general-purpose), schema 4.50
sysmonconfig-enhanced-ot.xml              # Broader OT coverage, industrial ports, schema 4.50
sysmonconfig-advanced-ot.xml              # Advanced OT, newer features, schema 4.90

# Specialized
sysmonconfig-jumphost.xml                 # Jump host / bastion host, schema 4.90

# Community and Reference
community/                                # Community-contributed configs (use at your own risk)
    sysmonconfig-filecreate-only.xml      # Aaron Boyd (icsblitz) - file creation monitoring
reference/                                # Reference configs for learning (not maintained)
    sysmonconfig-swiftonsecurity-v74.xml  # SwiftOnSecurity original, schema 4.50
```

### Server Services Config Coverage

The server-services config covers all common database and web server engines in a single file. Rules for absent services never match and have zero cost.

**Database engines:**

| Engine | Process | Default Port | OT Relevance |
|--------|---------|-------------|--------------|
| Microsoft SQL Server | sqlservr.exe, sqlagent.exe | 1433 | AVEVA Historian, Wonderware |
| PostgreSQL | postgres.exe | 5432 | Ignition (supported), Timescale |
| MySQL / MariaDB | mysqld.exe, mariadbd.exe | 3306 | Ignition (default backend) |
| Oracle | oracle.exe, extjob.exe, extproc.exe | 1521 | Honeywell, some MES platforms |
| MongoDB | mongod.exe | 27017 | IIoT edge, metadata stores |
| InfluxDB | influxd.exe | 8086 | IIoT time-series, Telegraf+Grafana |

**Web server engines:**

| Engine | Process | OT Relevance |
|--------|---------|--------------|
| IIS | w3wp.exe | AVEVA System Platform, OT DMZ |
| Apache httpd | httpd.exe | HMI web interfaces, OPC UA gateways |
| Nginx | nginx.exe | Reverse proxy for OT web apps |
| Apache Tomcat | java.exe, tomcat9.exe | Ignition Gateway, GE iFIX |

**Common detection pattern across all engines:**
- Database/web process spawning cmd.exe, powershell.exe, or other shell = malicious
- Same Sysmon rule structure (ParentImage conditions), different process name lists
- Web script file creation in web roots (.aspx, .asp, .php, .jsp, .cfm, web.config)

### SANS ICS 5 Critical Controls Mapping

| SANS Control | How Sysmon Helps | Config Level |
|-------------|------------------|--------------|
| #1: ICS Incident Response | Forensic evidence: process chains, connections, file/registry changes | All configs |
| #2: Defensible Architecture | Detects processes crossing boundaries, unauthorized services/drivers | OT Baseline+ |
| #3: ICS Network Visibility | Host-side complement to network monitoring; identifies which process generated traffic | OT Baseline+ |
| #4: Secure Remote Access | Detects remote access tool execution (TeamViewer, AnyDesk, VNC, RDP, etc.) | IT Baseline+ |
| #5: Vulnerability Management | Logs software execution, driver loading, service changes; supports asset inventory | All configs |

### Remote Access Tool Monitoring

All configs (including IT Baseline) include-log known remote access tools by default. This aligns with SANS Control #4 and CISA/NSA RMM guidance. Tools monitored include:
- TeamViewer, AnyDesk, ScreenConnect (ConnectWise), LogMeIn
- Bomgar (BeyondTrust), Splashtop, Dameware
- RustDesk, MeshAgent, Ammyy Admin
- VNC variants (TightVNC, RealVNC, UltraVNC)
- Portable/renamed RMM executables

Admins MUST tune these rules for their approved remote access tools.

### OT Vendor Software (Examples)

OT configs include monitoring examples for major vendors. These MUST be validated against actual installations -- process names, file paths, and default install locations are based on vendor documentation.

| Vendor | Products | OT Role |
|--------|----------|---------|
| Siemens | TIA Portal, WinCC, STEP 7 | PLC programming, HMI, SCADA |
| Rockwell/Allen-Bradley | Studio 5000, RSLogix, FactoryTalk | PLC programming, HMI, SCADA |
| Schneider Electric | EcoStruxure, Unity Pro, Citect | PLC programming, HMI, SCADA |
| AVEVA/Wonderware | InTouch, System Platform | HMI, SCADA |
| AVEVA/OSIsoft | PI System (PI Data Archive, PI Vision) | Historians |
| Inductive Automation | Ignition | HMI, SCADA, historian |
| SEL (Schweitzer) | SEL software tools, ACSELERATOR | Protective relays, power/utilities |

## Legacy OS Considerations

ICS/OT environments frequently run legacy Windows versions (Server 2008/2012, Windows 7/10 LTSC) that may not support the latest Sysmon versions. The IT Baseline and OT Baseline configs use schema 4.50 (Sysmon v13+) for the widest compatibility. Enhanced and Advanced configs may use newer schema versions (4.82/4.90) with features requiring Sysmon v14+/v15+.

Note: Microsoft announced native Sysmon integration in Windows 11 and Server 2025 (expected 2026). This does not affect legacy OT systems but will benefit newer deployments.

## Sysmon Config and Module Conventions

All Sysmon XML files (curated configs, modules, community contributions) follow the conventions defined in `claude-dev/SYSMON_CODING_STANDARD.md`. That document is the single source of truth for:

- File structure and header block requirements
- Schema version selection (4.50 default, 4.90 when essential)
- Meta configuration (HashAlgorithms, CheckRevocation defaults by config category)
- RuleGroup naming and `groupRelation` conventions
- Rule naming convention (ATT&CK structured tagging for includes, `exclude=` for excludes)
- Field constraints (250-char hard limit, 80-180 char target, no commas or pipes in field values)
- ATT&CK technique selection (Enterprise + ICS matrices)
- XML comment block templates for maintainers
- Validation requirements (xmllint, name length, diff verification)
- Module file format and dual-use naming convention
- Attribution and disclaimer requirements

This section documents the architectural rationale for the module library and merge tooling. Implementation details live in the standard.

## Module Architecture

The module library provides opt-in XML fragments for vendor-specific, sector-specific, protocol-specific, and software-specific monitoring. Modules layer on top of curated configs for advanced users. Curated configs remain the primary supported deployment artifact.

### Module Categories

| Category | Directory | Purpose | Rule Type |
|----------|-----------|---------|-----------|
| OT Vendor | modules/vendor-ot/ | OT vendor software monitoring | Include |
| IT Vendor | modules/vendor-it/ | Common IT software in OT environments | Exclude (noise reduction) |
| Cloud Storage | modules/cloud-storage/ | External storage clients | Dual-use (exclude or include) |
| Sector | modules/sector/ | Sector-specific concerns (electric, water, oil/gas, etc.) | Include |
| Protocol | modules/protocol/ | Industrial protocol port monitoring | Include |
| Remote Access | modules/remote-access/ | RMM tool detection (granular per-tool) | Dual-use (exclude or include) |

See SYSMON_CODING_STANDARD.md sections 8.1-8.4 for module file format, dual-use naming, schema floor, and header requirements.

### Merge Tooling

`tools/Merge-SysmonModules.ps1` (PowerShell 3+, no external dependencies):
- Reads a base curated config and a list of module files
- Inserts module RuleGroup elements into the base config's EventFiltering section
- Preserves base config meta section (HashAlgorithms, CheckRevocation)
- Validates output XML well-formedness before writing
- Reports merged manifest and any conflicts

Bounded scope: this tooling exists only to merge ICS Watch Dog modules into ICS Watch Dog base configs. It is not a general-purpose Sysmon config generator.

### Test Harness

`tools/Test-MergeSysmonModules.ps1` validates the merge script via fixture-based diff comparison. Sample inputs and expected outputs live in `tools/test-fixtures/`. Tests cover single/multi-module merges, dual-use conflict warnings, schema mismatch warnings, malformed module rejection, and base config preservation. The harness can run on Linux since it is pure XML manipulation.

## File Structure

```
ICSWatchDog/
    .github/ISSUE_TEMPLATE/                        # GitHub issue templates (ships to main)
        bug_report.md, feature_request.md, module_submission.md, config.yml
    CLAUDE.md                                      # Project rules (dev only)
    README.md                                      # Public-facing project description
    License                                        # CC BY 4.0
    CNAME                                          # icswatchdog.com
    images/                                        # Branding assets
    sysmon-configs/                                # All Sysmon configuration files
        sysmonconfig-baseline-it-workstation.xml   # IT workstation baseline
        sysmonconfig-baseline-it-server.xml        # IT server baseline
        sysmonconfig-server-ad.xml                 # AD / Domain Controller
        sysmonconfig-server-services.xml           # Database + web server (all engines)
        sysmonconfig-baseline-ot.xml               # OT baseline (general-purpose)
        sysmonconfig-enhanced-ot.xml               # OT enhanced
        sysmonconfig-advanced-ot.xml               # OT advanced
        sysmonconfig-jumphost.xml                  # Jump host / bastion host
        sysmonconfig-legacy-win7.xml               # Legacy Win7 (schema 4.23)
        community/                                 # Community-contributed configs
            sysmonconfig-filecreate-only.xml
        reference/                                 # Reference configs for learning
            sysmonconfig-swiftonsecurity-v74.xml
        modules/                                   # Opt-in module library (Phase 9)
            README.md, INDEX.md
            vendor-ot/                             # OT vendor software (include rules)
            vendor-it/                             # IT software in OT (exclude/noise reduction)
            cloud-storage/                         # Dual-use exclude/include per tool
            sector/                                # Sector-specific (electric, water, oil/gas, etc.)
            protocol/                              # Industrial protocol port monitoring
            remote-access/                         # Granular per-tool RMM modules
    tools/                                         # Helper scripts
        Get-SysmonCoverage.ps1                     # Coverage assessment (PS 2.0+ compat)
        Export-SystemInventory.ps1                  # System inventory export (PS 2.0+ compat)
        Compare-SystemInventory.ps1                # Inventory diff (PS 3.0+ required)
        Test-SysmonConfig.ps1                      # Efficacy testing
        Merge-SysmonModules.ps1                    # Module merge tooling
        Test-GetSysmonCoverage.ps1                 # Coverage tool test harness
        Test-CompareSystemInventory.ps1            # Compare tool test harness
        Test-MergeSysmonModules.ps1                # Merge tool test harness
        test-fixtures/                             # Merge tool fixtures (shipped)
    .gitattributes                                 # export-ignore for dev-only paths
    claude-dev/                                    # Development planning (dev only)
        ARCHITECTURE.md                            # This file
        PLAN.md
        RESUME.md
        GIT_RELEASE_STEPS.md
        SYSMON_CODING_STANDARD.md                  # Sysmon XML and rule conventions
        TOOL_CODING_STANDARD.md                    # PowerShell/Python tool conventions
        TESTING_STANDARD.md                        # Config and script testing procedures
        REMOTE_TESTING.md                          # Proxmox VM test environment setup
        GITHUB_ISSUE_STANDARD.md                   # Issue template and label conventions
        html-css-jekyll.md                         # HTML/CSS/Jekyll code standard
        remote-testing.example.conf                # Local-config template (placeholders only)
        test-fixtures/coverage/                    # Coverage/compare tool fixtures (dev only)
    docs/                                          # Jekyll website source (dev only)
        _config.yml
        _layouts/default.html
        _includes/nav.html, footer.html
        _pages/
        css/style.css
        js/main.js
        img/
```

## Technology Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| Configs | Sysmon XML | Schema 4.50 (baseline), 4.82/4.90 (enhanced/advanced) |
| Website | Jekyll + custom CutSec CSS/JS | No theme gem; custom _layouts, _includes, css/, js/ |
| Hosting | GitHub Pages | Served from gh-pages branch |
| Domain | icswatchdog.com | CNAME in gh-pages root |
