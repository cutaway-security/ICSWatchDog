# ARCHITECTURE.md

## System Overview

ICS Watch Dog consists of two components: (1) a set of tiered Sysmon XML configuration files targeting ICS/OT Windows environments, and (2) a Jekyll-based documentation website deployed via GitHub Pages. The project provides a progression path from basic monitoring (compatible with legacy Windows systems) through advanced configurations that leverage newer Sysmon features.

## Components

| Component | Purpose | Technology |
|-----------|---------|------------|
| Sysmon Configs | Tiered XML config files for endpoint monitoring | Sysmon XML schema 4.50+ |
| Standalone Configs | Use-case-specific configs outside tier progression | Sysmon XML schema 4.50+ |
| Website | Documentation, guides, config descriptions | Jekyll / Just the Docs theme |
| Branding | Logo, banner, background images | PNG assets |

## Branch Strategy

| Branch | Purpose | Contains |
|--------|---------|----------|
| main | Public release | Sysmon XML configs, README, License, images |
| claude-dev | Active development | Everything: configs, docs/ source, claude-dev/ planning |
| gh-pages | Deployed website | Built Jekyll site (deployed from claude-dev docs/) |

Key rules:
- All development happens on claude-dev
- Website source lives in docs/ on claude-dev
- All site links to configs and the repo point to main branch
- Release process merges configs to main (excluding docs/ and claude-dev/)
- Deploy process pushes docs/ contents to gh-pages
- For manual site review, GitHub Pages can be pointed to claude-dev branch /docs folder, then switched back when review is complete

## Config Tier Structure

```
Tier 1: Starter       - Bare minimum, schema 4.50, broadest OS compatibility
Tier 2: Baseline      - Core ICS/OT monitoring, schema 4.50, legacy OS safe
Tier 3: Enhanced      - Broader coverage with ICS/OT-aware filtering, may require newer schema
Tier 4: Advanced      - Role-specific starting points, leverages newer Sysmon features
Reference: Export     - SwiftOnSecurity original (attributed, kept as reference/example)
Standalone: Use-case configs (e.g., file-create-only) that serve specific monitoring needs
```

## Legacy OS Considerations

ICS/OT environments frequently run legacy Windows versions (Server 2008/2012, Windows 7/10 LTSC) that may not support the latest Sysmon versions. Tier 1 and Tier 2 configs must use schema 4.50 and features available in Sysmon v13 to ensure the widest compatibility. Tier 3 and Tier 4 configs may use newer schema versions and features, with documentation noting the minimum Sysmon version required.

## Standalone Configs

Some configs serve specific use cases outside the tier progression. The file-create-only config (authored by Aaron Boyd / icsblitz) is an example -- it provides focused monitoring for a single event type. These may eventually integrate into the tier structure but start as standalone options for teams with specific needs.

## Sysmon Config File Structure

Each config XML follows:
- Header comment block: version, author, attribution, minimum Sysmon version, notes
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
        icswatchdog_logo_0_250x250.png
        icswatchdog_logo_1_circle_sm1.png
        icswatchdog_web_background_grey.png
    icswatchdog_32x32.png                  # Favicon
    sysmonconfig-*.xml                     # Sysmon configuration files
    claude-dev/                            # Development planning (dev only)
        ARCHITECTURE.md                    # This file
        PLAN.md
        RESUME.md
        GIT_RELEASE_STEPS.md
    docs/                                  # Jekyll website source (dev only)
        _config.yml
        _pages/
        assets/
```

## Technology Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| Configs | Sysmon XML | Schema 4.50+ (tiered by OS compatibility) |
| Website | Jekyll + Just the Docs | remote_theme, no vendored theme files |
| Hosting | GitHub Pages | Served from gh-pages branch |
| Domain | icswatchdog.com | CNAME in gh-pages root |
