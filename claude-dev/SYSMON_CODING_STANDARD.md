# Sysmon Coding Standard

This document is the single source of truth for Sysmon XML configuration and module file conventions in the ICS Watch Dog project. All curated configs, modules, community contributions, and reference material must follow these standards. Other planning documents (CLAUDE.md, ARCHITECTURE.md, PLAN.md) reference this document for Sysmon-specific rules rather than duplicating them.

---

## 1. Scope

This standard applies to:

- All curated Sysmon configurations under `sysmon-configs/`
- All module XML fragments under `sysmon-configs/modules/`
- Community-contributed configurations under `sysmon-configs/community/`
- Reference configurations under `sysmon-configs/reference/` (read-only; preserved as-is for attribution)

This standard does NOT apply to:

- Project documentation (Markdown, HTML)
- Jekyll website source (see html-css-jekyll.md)
- PowerShell scripts (see future tools standard)

---

## 2. File Structure

### 2.1 Header Comment Block

Every config and module file begins with a comment block containing:

| Field | Required | Description |
|-------|----------|-------------|
| Title | Required | Project name and config purpose |
| Version | Required | Semantic version (vMajor.Minor) |
| Author | Required | ICS Watch Dog Project (or community contributor name) |
| Project | Required | Project URL |
| License | Required | Creative Commons Attribution 4.0 |
| Minimum Sysmon | Required | e.g., v13+ (schema 4.50) |
| Target | Required | Intended deployment role (workstation, server, DC, OT, etc.) |
| SANS ICS 5 Critical Controls | Required for curated configs | Mapping of controls supported |
| CIS Benchmark Alignment | Required for curated configs | Relevant CIS benchmarks |
| MITRE ATT&CK Coverage | Required for curated configs | Top-level technique IDs covered |
| Description | Required | What this config monitors and any structural differences from baselines |
| Tuning | Required | Site-specific tuning guidance |
| Disclaimer | Required | Standard use-at-own-risk language |
| References | Required | URLs to relevant external documentation |

Header format example:

```xml
<!--
  ICS Watch Dog - <Config Purpose>
  Version:      vX.Y
  Author:       ICS Watch Dog Project (https://icswatchdog.com)
  Project:      https://github.com/cutaway-security/ICSWatchDog
  License:      Creative Commons Attribution 4.0

  Minimum Sysmon:   vNN+ (schema X.YZ)
  Target:           <deployment role>

  SANS ICS 5 Critical Controls Supported:
    #N <control name> - <how this config supports it>

  CIS Benchmark Alignment:
    <benchmark and section references>

  MITRE ATT&CK Coverage:
    TXXXX[.XXX]  - <short technique name>

  DESCRIPTION:
    <what this config does, structural differences, when to use>

  TUNING:
    <site-specific tuning notes>

  DISCLAIMER:
    This configuration is provided as-is for educational and operational use.
    It is NOT tested against all environments and may require tuning for your
    specific systems. Cutaway Security, LLC and contributors assume no liability
    for any impact resulting from the use of this configuration. Users are
    responsible for testing in their own environments before production deployment.

  REFERENCES:
    - <URL>
-->
```

### 2.2 Sysmon Element Structure

```xml
<Sysmon schemaversion="X.YZ">
  <HashAlgorithms>md5,sha256,IMPHASH</HashAlgorithms>
  <!-- CheckRevocation comment block -->
  <CheckRevocation>True|False</CheckRevocation>

  <EventFiltering>
    <!-- Event ID section comment -->
    <RuleGroup name="..." groupRelation="or">
      <ProcessCreate onmatch="exclude|include">
        <!-- Tagged rule comment block -->
        <Image name="..." condition="...">...</Image>
      </ProcessCreate>
    </RuleGroup>

    <!-- Additional RuleGroups -->
  </EventFiltering>
</Sysmon>
```

### 2.3 Module File Structure

Modules are partial XML fragments without a `<Sysmon>` root element. They contain one or more `<RuleGroup>` elements that the merge tooling inserts into a base config's `<EventFiltering>` section.

```xml
<!--
  ICS Watch Dog Module: <Module Name>
  Category:     <vendor-ot|vendor-it|cloud-storage|sector|protocol|remote-access>
  Version:      vX.Y
  Schema:       4.50 (default) or 4.90 (with explicit reason)
  Dependencies: <other modules required, if any>
  ATT&CK:       <technique IDs covered>

  PURPOSE:
    <what this module monitors>

  WHEN TO USE:
    <conditions under which this module is appropriate>

  WHEN NOT TO USE:
    <conditions under which this module should be omitted>

  DUAL-USE NOTE: (cloud-storage and remote-access modules only)
    Use exclude_<tool>.xml if the tool is sanctioned (suppresses noise).
    Use include_<tool>.xml if the tool is unsanctioned (generates detection events).
    Pick exactly one per tool.
-->
<RuleGroup name="..." groupRelation="or">
  <!-- rules -->
</RuleGroup>
```

---

## 3. Schema Version

### 3.1 Default

Use **schema 4.50** for all new configs and modules unless newer features are essential. Schema 4.50 supports Sysmon v13+ and runs on legacy Windows versions common in OT environments (Windows 7, Server 2008/2012, LTSC editions).

### 3.2 Schema 4.90 Use

Schema 4.90 (Sysmon v15+) is permitted only when the config or module requires features not available in 4.50:

- Event ID 27 (FileBlockExecutable)
- Event ID 28 (FileBlockShredding)
- Event ID 29 (FileExecutableDetected)
- Event ID 24 (ClipboardChange)

When using schema 4.90, the config or module header MUST include an explicit note explaining the requirement and the legacy compatibility impact.

### 3.3 Schema Mismatch Warning

The merge tooling warns when a 4.90 module is merged into a 4.50 base config. The merge succeeds, but the resulting config requires Sysmon v15+ to load.

---

## 4. Meta Configuration

### 4.1 HashAlgorithms

Standard value across all configs:

```xml
<HashAlgorithms>md5,sha256,IMPHASH</HashAlgorithms>
```

- `md5` and `sha256` are industry standard for file identification
- `IMPHASH` enables import hash matching for malware family clustering
- Do NOT use `*` (all algorithms) -- it adds CPU overhead with no detection value

### 4.2 CheckRevocation

Use explicit boolean values, never the self-closing `<CheckRevocation/>` form (incompatible with some Sysmon versions and schema validators).

```xml
<!-- CheckRevocation: checks loaded driver code-signing certificate revocation status.
     Requires network access to CRL distribution points / OCSP responders.
     Set to False if this system has no internet or restricted network access. -->
<CheckRevocation>True</CheckRevocation>
```

**Defaults by config category**:

| Config Category | Default | Reasoning |
|----------------|---------|-----------|
| IT workstation, IT server, AD, Server services, Jump host | `True` | Network/PKI access expected |
| OT baseline, OT enhanced, OT advanced | `False` | Air-gapped or network-restricted environments |
| Community / Reference | `True` | General-purpose default; reference configs untouched |

The CheckRevocation comment must be present and explain the choice. OT configs use a longer comment noting the air-gap rationale.

---

## 5. RuleGroup Conventions

### 5.1 Naming

RuleGroup `name` attributes describe the group's purpose, not ATT&CK technique IDs. Examples:

- `ProcessCreate-Exclude` (general noise reduction)
- `ProcessCreate-DC-Detection` (DC-specific include rules)
- `ProcessCreate-RansomwareIndicators` (ransomware indicators across all configs)
- `NetworkConnect-IndustrialPorts` (industrial protocol port monitoring)
- `PipeCreated-C2Detection` (C2 framework named pipes)

### 5.2 groupRelation

Default `groupRelation="or"` for most RuleGroups. Use `"and"` only when matching multiple field conditions in a single rule (e.g., process name + command line argument together).

### 5.3 RuleGroup Comments

Each RuleGroup is preceded by a section comment block describing the Event ID and purpose:

```xml
<!--
================================================================
EVENT ID 1: PROCESS CREATION [ProcessCreate]
<purpose for this config>
================================================================
-->
<RuleGroup name="ProcessCreate" groupRelation="or">
```

---

## 6. Rule Naming Convention

This is the core of the standard. The `name` attribute is the only field that reaches the Windows event log RuleName field (Sysmon supports no alternate names, aliases, or description attributes).

### 6.1 Include Rule Format (Detection Rules)

```
technique_id=<ID>[|<ID2>],technique=<ATT&CK Name>[,detection=<Site Context>]
```

**Field definitions**:

| Field | Required | Format | Purpose |
|-------|----------|--------|---------|
| `technique_id` | Required | `Txxxx[.xxx]` or pipe-delimited list `T1003.003\|T1003.006` | ATT&CK technique ID(s); machine parseable |
| `technique` | Required | Free text, canonical short ATT&CK name | Human readable without lookup |
| `detection` | Optional but recommended | Free text | Site-specific detection intent (formerly the `DC:`, `Ransomware:`, `Web:`, `DB:`, `ICS:` prefixes) |

**Example -- single technique**:
```xml
<Image name="technique_id=T1003.003,technique=NTDS,detection=DC ntdsutil execution"
       condition="end with">\ntdsutil.exe</Image>
```

**Example -- multiple techniques**:
```xml
<CommandLine name="technique_id=T1059.001|T1027|T1140,technique=PowerShell,detection=Encoded PowerShell suggests obfuscation"
             condition="contains">-encodedcommand</CommandLine>
```

**Example -- composite Rule (parent only)**:
```xml
<Rule name="technique_id=T1003.003,technique=NTDS,detection=Shadow copy NTDS extraction" groupRelation="and">
  <Image condition="end with">\vssadmin.exe</Image>
  <CommandLine condition="contains">create shadow</CommandLine>
</Rule>
```

### 6.2 Exclude Rule Format (Noise Reduction)

Exclude rules are noise reduction, not detection. They do NOT receive ATT&CK tags.

```
exclude=<Site-Specific Context>
```

**Examples**:
```xml
<Image name="exclude=Windows Defender MsMpEng" condition="is">C:\Program Files\Windows Defender\MsMpEng.exe</Image>
<Signature name="exclude=Microsoft signed driver" condition="contains">Microsoft</Signature>
<PipeName name="exclude=lsass system pipe" condition="is">\lsass</PipeName>
```

The `exclude=` prefix makes intent obvious in SIEM queries (e.g., to filter exclusion-related events when hunting).

### 6.3 Field Constraints

**Hard limit: 250 characters per `name` value**.

This stays under the Elasticsearch default `keyword` field `ignore_above: 256` setting. Many SIEMs that ingest Sysmon events into Elastic-based stacks (HELK, SOC Prime, Hunting ELK) use the keyword type for `winlog.event_data.RuleName`. Names exceeding 256 chars are silently dropped from the index and become unsearchable in keyword/term queries (though they remain visible in `_source`).

**Target length: 80-180 characters**.

Aspirational target, not a hard limit. Encourages concise detection descriptions. Longer rationale belongs in the maintainer XML comment block (which has no length constraint).

**Forbidden characters in field values**:

| Character | Reason |
|-----------|--------|
| `,` (comma) | Field separator -- collision breaks parsing |
| `\|` (pipe) | Multi-technique separator -- collision breaks parsing |

If a description needs a comma, use a semicolon or "and" instead. If a description needs a pipe, rephrase. Equals sign (`=`) in values is permitted but discouraged.

**Validation**: Phase 8b validation will scan all tagged names and flag any that:
- Exceed 250 characters
- Contain a comma in any field value
- Contain a pipe in any field value (other than the multi-technique separator in `technique_id`)

### 6.4 ATT&CK Technique Selection

| Use Case | Matrix | Format |
|----------|--------|--------|
| IT/host techniques | Enterprise ATT&CK | `T1xxx[.xxx]` |
| Industrial protocols, ICS firmware, ICS-specific behavior | ICS ATT&CK | `T0xxx` |
| Mixed (rule applies to both IT and OT context) | Both, pipe-delimited | `T1xxx\|T0xxx` |

**Canonical short names**: Use the most commonly recognized short form (e.g., `NTDS`, `Web Shell`, `PowerShell`, `Adversary-in-the-Middle`). Avoid full official names if they exceed ~40 characters.

### 6.5 Existing Descriptive Prefixes

Existing `DC:`, `Ransomware:`, `Web:`, `DB:`, `ICS:`, `C2:`, `Lateral:`, `Cred:` prefixes from prior versions migrate into the `detection` field. They are not preserved as raw `name` prefixes.

**Before**:
```xml
<Image name="DC: ntdsutil execution" condition="end with">\ntdsutil.exe</Image>
```

**After**:
```xml
<Image name="technique_id=T1003.003,technique=NTDS,detection=DC ntdsutil execution"
       condition="end with">\ntdsutil.exe</Image>
```

---

## 7. XML Comment Conventions

### 7.1 Header Block

See section 2.1 -- every file starts with a header block.

### 7.2 Section Block (per Event ID)

Each Event ID's RuleGroups are preceded by a section block:

```xml
<!--
================================================================
EVENT ID 1: PROCESS CREATION [ProcessCreate]
<purpose for this config>
<structural notes if applicable>
================================================================
-->
```

### 7.3 Per-Rule Maintainer Comment Block

Each tagged include rule (or logically grouped set of related rules) is preceded by a maintainer comment block. Comments do NOT reach the event log -- they exist for maintainers and contributors.

**Template A: Single rule, single technique**:
```xml
<!--
  T<ID> <Technique Name>
  <Brief description of what this rule detects and why it matters>
  <Investigation guidance: what to do when this fires>
  Reference: https://attack.mitre.org/techniques/T<ID>/
-->
<Image name="..." condition="...">...</Image>
```

**Template B: Grouped set of related rules**:
```xml
<!--
  T<ID> <Technique Name>
  <Brief description of the group's purpose>
  <Investigation guidance>
  Reference: https://attack.mitre.org/techniques/T<ID>/
-->
<Image name="..." condition="...">...</Image>
<Image name="..." condition="...">...</Image>
<Image name="..." condition="...">...</Image>
```

**Template C: Multi-technique rule**:
```xml
<!--
  T<ID1> <Primary Technique Name> + T<ID2> <Secondary Technique Name>
  <Why this rule maps to multiple techniques>
  <Investigation guidance>
  References:
    https://attack.mitre.org/techniques/T<ID1>/
    https://attack.mitre.org/techniques/T<ID2>/
-->
<CommandLine name="..." condition="...">...</CommandLine>
```

**Template D: ICS ATT&CK rule**:
```xml
<!--
  T0830 Adversary-in-the-Middle (ICS)
  <Industrial protocol context>
  <What an unexpected match indicates>
  Reference: https://attack.mitre.org/techniques/T0830/
-->
<DestinationPort name="..." condition="is">...</DestinationPort>
```

### 7.4 Comment Discipline

- Do not duplicate header information in per-rule comments
- Per-rule comments focus on the specific rule's purpose, not project background
- Excludes do not need maintainer comment blocks beyond their `exclude=` name
- Section comments at the Event ID level remain in addition to per-rule comments

---

## 8. Module Conventions

### 8.1 Categories

| Category | Directory | Rule Type | Notes |
|----------|-----------|-----------|-------|
| OT Vendor | `modules/vendor-ot/` | Include | Siemens, Rockwell, Schneider, AVEVA, etc. |
| IT Vendor | `modules/vendor-it/` | Exclude (noise reduction) | Browsers, Adobe, Office; admin opts in |
| Cloud Storage | `modules/cloud-storage/` | Dual-use | exclude_<tool> if sanctioned, include_<tool> if not |
| Sector | `modules/sector/` | Include | Electric, water, oil/gas, manufacturing, pharma |
| Protocol | `modules/protocol/` | Include | Modbus, OPC-UA, DNP3, etc. |
| Remote Access | `modules/remote-access/` | Dual-use | Per-tool granular detection |

### 8.2 Dual-Use Naming

Cloud storage and remote access modules use a strict naming convention:

- `exclude_<tool>.xml` -- assumes the tool is sanctioned (suppresses noise)
- `include_<tool>.xml` -- assumes the tool is unsanctioned (generates detection events)

Admins pick exactly ONE per tool based on site policy. The merge tooling does not enforce mutual exclusion -- this is documented in `modules/README.md`.

### 8.3 Module Header

Modules follow the header format in section 2.3, with these required additions:

- Category
- Schema (4.50 default; 4.90 with explicit reason)
- Dependencies (other modules required, if any)
- Dual-use note (cloud-storage and remote-access modules only)
- When to use / when NOT to use

### 8.4 Module File Format

Modules are XML fragments containing one or more `<RuleGroup>` elements. They have NO:

- `<Sysmon>` root element
- `<HashAlgorithms>` element
- `<CheckRevocation>` element
- `<EventFiltering>` wrapper

The merge tooling inserts `<RuleGroup>` elements directly into a base config's existing `<EventFiltering>`.

---

## 9. Validation Requirements

### 9.1 XML Well-Formedness

All configs and modules MUST pass `xmllint --noout <file>` with no errors.

### 9.2 Rule Name Validation

After tagging or modifying rule names, validate:

- No `name` attribute exceeds 250 characters
- No `technique`, `detection`, or other field value contains a comma
- No field value (other than `technique_id`) contains a pipe
- All `technique_id` values match the format `T\d{4}(\.\d{3})?` (with optional pipe-delimited extras)

### 9.3 Diff Verification

After ATT&CK tagging or other name-only edits, diff against the previous version and verify that ONLY:

- `name=` attribute values changed
- XML comment blocks were added
- Whitespace within edited lines may have changed

The following must NOT change:

- `condition=` values
- Element tag names
- `groupRelation` values
- Field values inside elements (e.g., file paths, registry keys, command line strings)

### 9.4 Schema Compatibility

Configs and modules using schema 4.90 features must declare schema 4.90 in the header. Modules using 4.90 features must include an explicit header note about Sysmon version requirements.

---

## 10. Attribution Requirements

### 10.1 Original ICS Watch Dog Configs

- Author: `ICS Watch Dog Project (https://icswatchdog.com)`
- Project URL: `https://github.com/cutaway-security/ICSWatchDog`
- License: `Creative Commons Attribution 4.0`

### 10.2 SwiftOnSecurity Reference

The `reference/sysmonconfig-swiftonsecurity-v74.xml` file is preserved unmodified for reference and learning. It retains its original SwiftOnSecurity attribution. ICS Watch Dog adds an external note explaining its purpose without modifying the file.

### 10.3 Community Contributions

Community-contributed configs:

- Original author retained in header
- ICS Watch Dog disclaimer block added
- File placed under `sysmon-configs/community/`
- Listed in README with attribution and category

---

## 11. Disclaimer Requirement

Every config and module includes a standard disclaimer block in its header:

```
DISCLAIMER:
  This configuration is provided as-is for educational and operational use.
  It is NOT tested against all environments and may require tuning for your
  specific systems. Cutaway Security, LLC and contributors assume no liability
  for any impact resulting from the use of this configuration. Users are
  responsible for testing in their own environments before production deployment.
```

OT-specific configs (baseline-ot, enhanced-ot, advanced-ot) extend the disclaimer with:

```
  This is especially critical in ICS/OT environments where system availability
  and safety are paramount.
```

---

## 12. Style Conventions

### 12.1 Indentation

- 2-space indentation throughout (matches existing configs)
- No tabs
- Consistent indentation within RuleGroups and rules

### 12.2 Attribute Order

Within an element, attributes appear in this order:

1. `name` (if present)
2. `groupRelation` (if present)
3. `condition`
4. `onmatch` (only on filter elements like `<ProcessCreate>`)

### 12.3 File and Folder Naming

- All file and folder names use lowercase with hyphens (no spaces, no underscores in filenames except for `exclude_` / `include_` module prefixes)
- Sysmon config files: `sysmonconfig-<role>[-<variant>].xml`
- Module files: `<vendor-or-tool>.xml` or `exclude_<tool>.xml` / `include_<tool>.xml` for dual-use

### 12.4 No Emojis or Non-ASCII

Per project rules in CLAUDE.md, no emojis, icons, or Unicode symbols in any source file, including comments and rule names. Use ASCII only.

---

## 13. Versioning

### 13.1 Config Version Bumps

- **Major version** (vX.0): structural changes (new Event IDs, schema upgrade, fundamentally different rule logic)
- **Minor version** (vX.Y): additive changes (new rules, expanded coverage, ATT&CK tagging)
- **Patch level**: not used; use minor version bumps for fixes

### 13.2 Version History

Major version changes are recorded in `claude-dev/PLAN.md` decision log. Minor changes appear in commit messages and release notes.

---

## 14. References

- Microsoft Sysmon documentation: https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon
- MITRE ATT&CK Enterprise: https://attack.mitre.org/matrices/enterprise/
- MITRE ATT&CK ICS: https://attack.mitre.org/matrices/ics/
- SwiftOnSecurity sysmon-config: https://github.com/SwiftOnSecurity/sysmon-config
- olafhartong sysmon-modular: https://github.com/olafhartong/sysmon-modular
- Elasticsearch keyword field `ignore_above`: https://www.elastic.co/guide/en/elasticsearch/reference/current/ignore-above.html

---

## 15. Document Maintenance

This standard is a living document. Updates require:

1. A clear rationale (link to relevant decision log entry in PLAN.md)
2. Backward compatibility consideration: existing configs may need updates to comply
3. Update of cross-references in CLAUDE.md, ARCHITECTURE.md, and PLAN.md if affected
4. Version bump and date in this file's header (when added)

Conflicts between this standard and other planning documents are resolved in favor of this standard. Other documents should reference this standard rather than restate its rules.
