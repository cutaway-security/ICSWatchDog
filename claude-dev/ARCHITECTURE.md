# ARCHITECTURE.md

## System Overview

ICS Watch Dog consists of two components: (1) a progressive set of Sysmon XML configuration files targeting enterprise IT and ICS/OT Windows environments, and (2) a Jekyll-based documentation website deployed via GitHub Pages. The project provides a progression path from IT baseline monitoring through OT-specific advanced configurations, mapped to the SANS ICS 5 Critical Controls.

## Components

| Component | Purpose | Technology |
|-----------|---------|------------|
| Curated Configs | Progressive IT-to-OT Sysmon configs | Sysmon XML schema 4.50+ |
| Community Configs | User-contributed configs for specific use cases | Sysmon XML schema 4.50+ |
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

### Progression Model

```
IT Baseline  -->  OT Baseline  -->  OT Enhanced  -->  OT Advanced
(general IT)     (IT + OT basics)  (broader OT)     (role-specific)
```

The IT Baseline is the universal starting point for any Windows system. Each subsequent config builds on the previous, adding OT-specific rules. This is explicitly documented so admins understand the progression.

### File Organization

```
sysmonconfig-baseline-it.xml          # IT baseline, enterprise Windows, schema 4.50
sysmonconfig-baseline-ot.xml          # OT baseline, adds ICS/OT rules, schema 4.50
sysmonconfig-enhanced-ot.xml          # Broader OT coverage, may use newer schema
sysmonconfig-advanced-ot.xml          # Advanced, newer Sysmon features, role-specific guidance
community/                            # Community-contributed configs (use at your own risk)
    sysmonconfig-filecreate-only.xml  # Aaron Boyd (icsblitz) - file creation monitoring
reference/                            # Reference configs for learning (not maintained)
    sysmonconfig-swiftonsecurity-v74.xml  # SwiftOnSecurity original, schema 4.50
```

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

## Sysmon Config File Structure

Each config XML follows:
- Disclaimer in header comment block
- Version, author, attribution, minimum Sysmon version, SANS control mapping
- `<Sysmon schemaversion="X.XX">` root element
- `<HashAlgorithms>` and `<CheckRevocation/>` meta config
- `<EventFiltering>` containing `<RuleGroup>` elements per Event ID
- Each rule uses `onmatch="include"` or `onmatch="exclude"` logic
- Rules tagged with descriptive `name` attributes for log traceability

## File Structure

```
ICSWatchDog/
    CLAUDE.md                              # Project rules (dev only)
    README.md                              # Public-facing project description
    License                                # CC BY 4.0
    CNAME                                  # icswatchdog.com
    images/                                # Branding assets
    sysmonconfig-baseline-it.xml           # IT baseline config
    sysmonconfig-baseline-ot.xml           # OT baseline config
    sysmonconfig-enhanced-ot.xml           # OT enhanced config
    sysmonconfig-advanced-ot.xml           # OT advanced config
    community/                             # Community-contributed configs
        sysmonconfig-filecreate-only.xml
    reference/                             # Reference configs for learning
        sysmonconfig-swiftonsecurity-v74.xml
    claude-dev/                            # Development planning (dev only)
        ARCHITECTURE.md                    # This file
        PLAN.md
        RESUME.md
        GIT_RELEASE_STEPS.md
        html-css-jekyll.md                 # Code standard
    docs/                                  # Jekyll website source (dev only)
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
