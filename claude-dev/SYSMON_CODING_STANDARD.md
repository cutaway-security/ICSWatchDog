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
| License | Required | CC BY-SA 4.0 &#124; Commercial licensing available (info@cutawaysecurity.com) |
| Minimum Sysmon | Required | e.g., v15+ (schema 4.90) |
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
  Copyright:    (c) 2024-2026 Cutaway Security, LLC
  License:      CC BY-SA 4.0 | Commercial licensing available (info@cutawaysecurity.com)

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
  Schema:       4.90 (standard) or 4.23 (legacy Win7 only)
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

Use **schema 4.90** for all new configs and modules. Schema 4.90 is the project standard and requires Sysmon v15+.

Testing confirmed that Sysmon 15.20 (schema 4.91) **rejects** configs at schema 4.50 ("No rules installed"). Schema 4.90 loads successfully. All curated configs and modules MUST use schema 4.90 or higher.

### 3.2 Legacy Schema 4.23

A single legacy config (`sysmonconfig-legacy-win7.xml`) targets Windows 7 systems running Sysmon 10.42 (schema 4.23). This config is a reduced-feature variant of the OT Baseline with these restrictions:

- No FileDelete (Event ID 23), ProcessTampering (25), or FileDeleteDetected (26)
- No `contains any` or `excludes any` conditions (introduced in schema 4.50)
- LOLBAS rules simplified to single-binary `end with` matching

New modules and configs MUST NOT target schema 4.23 unless specifically adding Win7 legacy support.

### 3.3 Schema Mismatch Warning

The merge tooling warns when modules with mismatched schema versions are merged. The merge succeeds, but the resulting config requires the higher schema version to load.

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

### 5.3 Composite Rules with `<Rule groupRelation="and">`

Composite rules use the `<Rule>` element with `groupRelation="and"` to require multiple field conditions to match together. This is necessary for high-precision LOLBAS detections that need to scope by both binary name AND command-line pattern to avoid false positives.

**Schema compatibility**: Composite `<Rule>` elements are supported in schema 4.20 and later. The ICS Watch Dog standard schema 4.90 (Sysmon v15+) supports them. The legacy Win7 config (schema 4.23) also supports composite rules but cannot use `contains any` conditions.

**Example -- LOLBAS detection requiring binary + command-line pattern**:
```xml
<Rule name="technique_id=T1218.005|T1105,technique=Mshta,detection=Mshta executing remote HTA over HTTP"
      groupRelation="and">
  <Image condition="end with">\mshta.exe</Image>
  <CommandLine condition="contains">http</CommandLine>
</Rule>
```

This rule fires only when both conditions match: the process is `mshta.exe` AND its command line contains `http`. Either condition alone would not trigger.

**Tagging composite rules**: Per the rule naming convention (Section 6.1), tag the parent `<Rule>` element only. Inner field conditions (`<Image>`, `<CommandLine>`, etc.) inside a composite rule do NOT receive their own `name` attribute. This avoids duplicate names in the event log.

**When to use composite rules**:
- High-precision LOLBAS detection (binary + specific command-line argument)
- Process + command-line pattern combinations where individual conditions would be too noisy
- Parent process + child process combinations
- File path + extension combinations

**When NOT to use composite rules**:
- Simple field condition rules (use a flat `<RuleGroup groupRelation="or">` with field-level rules instead)
- Cases where any one of multiple conditions should fire independently
- Simple exclusions

### 5.4 RuleGroup Comments

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

### 6.6 LOLBAS Detection Three-Tier Strategy

Living off the Land Binaries and Scripts (LOLBAS) detection is organized into three tiers based on signal-to-noise ratio. The tiering is intentional: it lets baseline configs ship with high-precision detections while allowing advanced configs and modules to add broader, noisier coverage.

#### Tier 1: Core LOLBAS (all 8 curated configs)

Highest signal, lowest false positive. Each rule must satisfy these criteria:
- The detection corresponds to a behavior that should rarely or never occur in normal admin or OT operations
- The rule is scoped by **command-line pattern**, not just executable name (use composite `<Rule groupRelation="and">` from Section 5.3)
- Every match warrants investigation
- The rule is acceptable in OT environments where false positives are operationally costly

Tier 1 rules live in a `ProcessCreate-LOLBAS-Core` RuleGroup added to all 8 curated configurations. Approximately 12 rules.

#### Tier 2: Advanced LOLBAS (advanced-ot, enhanced-ot, jumphost, server-ad, server-services)

Broader coverage with moderate false positive risk. Tier 2 rules:
- May match on binary execution alone (without command-line scoping)
- May trigger on legitimate admin scripting in some environments
- Are acceptable in configs where the operator has a mature tuning program
- Are NOT added to baseline configs (`baseline-it-workstation`, `baseline-it-server`, `baseline-ot`) to protect their false positive profile

Tier 2 rules live in a `ProcessCreate-LOLBAS-Advanced` RuleGroup added to the 5 advanced configs. Approximately 20 rules. Tier 2 builds on Tier 1 (configs that have Tier 2 also have Tier 1).

#### Tier 3: Comprehensive (modules/lolbas/)

Sigma-level coverage organized as opt-in modules per ATT&CK sub-technique. Tier 3:
- Targets users who want full LOLBAS coverage and have time to tune
- Splits coverage across ~13 modules organized by ATT&CK technique family
- Includes long-tail rare LOLBAS techniques
- May produce significant noise without environment-specific tuning

Tier 3 modules live in `sysmon-configs/modules/lolbas/`. Modules are detection-only (include rules); no exclude/dual-use variants.

#### LOLBAS Tuning Guidance

Each LOLBAS rule (Tier 1 and Tier 2) is preceded by an XML maintainer comment block that documents:
- The ATT&CK technique reference
- Why the detection is high-signal
- Known legitimate use cases (and how to suppress them with site-specific exclusions)
- Investigation guidance

OT-specific tuning notes belong in the maintainer comments. The website [LOLBAS Detection page](https://icswatchdog.com/lolbas-detection/) provides high-level tuning guidance for environments with predictable admin scripting. Detailed per-rule tuning belongs in the XML comments only.

#### Selection Reference

Use the LOLBAS Project (https://lolbas-project.github.io) and the MITRE ATT&CK Enterprise matrix as the canonical sources for technique identification. SwiftOnSecurity sysmon-config and olafhartong/sysmon-modular are reference implementations for enterprise IT environments.

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
- Schema (4.90 standard; 4.23 for legacy Win7 only)
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

### 8.5 Provenance Metadata

Every module MUST include a `Provenance` block in its header documenting where the rule content came from, the confidence level, and known limitations. This is mandatory for new modules and was applied retroactively to existing modules in Phase 11a.

**Why provenance metadata exists**: Sysmon detection rules are useful only if admins can trust them. Without explicit provenance, a rule built from general knowledge looks identical to a rule validated against a live deployment. The Provenance block makes the difference visible so users know which rules to trust and which to validate themselves.

#### Required Fields

```
PROVENANCE:
  Source:           <where the rule data came from -- vendor doc URL,
                    project name, observed in lab, security research,
                    MITRE ATT&CK, LOLBAS Project, etc.>
  Confidence:       <verified-in-lab|vendor-documented|security-research|theoretical>
  Last Validated:   <YYYY-MM-DD>
  Validated By:     <contributor handle, project name, or "unvalidated">
  Known Limitations: <what is not covered, vendor versions not tested,
                    environment assumptions, known false positive sources>
```

#### Confidence Levels

| Level | Criteria | Example |
|-------|----------|---------|
| **verified-in-lab** | Validated against a live install in a lab or production environment by maintainers or trusted contributors. Vendor version range documented. Test evidence available. | Future state for top vendor modules |
| **vendor-documented** | Built from authoritative vendor public documentation (knowledge base, install guide, security bulletin). Not lab-tested. Vendor version range identified or noted as version-dependent. | Most current vendor-ot, vendor-it, cloud-storage, remote-access modules |
| **security-research** | Built from security research, threat intelligence reports, or community-maintained authoritative catalogs (LOLBAS Project, MITRE ATT&CK, Sigma rules). | Most lolbas/ modules |
| **theoretical** | General knowledge starting point. No authoritative source for the specific patterns. Pattern is plausible but unverified. | Some sector module content, some long-tail LOLBAS rules |

A `verified-in-lab` confidence level requires validation evidence (lab output, deployment observation period, false positive measurement) per Phase 11c validation framework.

#### Position in Module Header

The Provenance block goes immediately after the standard `WHEN NOT TO USE` and `DUAL-USE NOTE` (if applicable) sections, and before the `REFERENCES` section. Example:

```xml
<!--
  ICS Watch Dog Module: Siemens TIA Portal
  Category:     vendor-ot
  Version:      v1.1
  Schema:       4.90
  Dependencies: none
  ATT&CK:       T1565.001 Stored Data Manipulation, T0857 Modify Controller Tasking

  PURPOSE:
    Monitor Siemens TIA Portal engineering workstation activity...

  WHEN TO USE:
    Engineering workstations with TIA Portal installed (V13-V19+).

  WHEN NOT TO USE:
    Production HMIs and operator stations: TIA Portal should not be installed there.
    Use sysmonconfig-baseline-ot.xml or sysmonconfig-enhanced-ot.xml as the base.

  PROVENANCE:
    Source:           Siemens public knowledge base; vendor install documentation
                      for TIA Portal V13 through V17; sysmon-modular project
                      reference; community threat reports
    Confidence:       vendor-documented
    Last Validated:   2026-04-07 (initial draft, NOT lab-tested)
    Validated By:     unvalidated
    Known Limitations: Process names verified against publicly documented V13-V17
                      installs only. Newer TIA Portal V18 / V19 may rename
                      Siemens.Automation.Portal.exe or relocate it. WinCC OA
                      processes are not covered. SCALANCE configuration tools
                      are not covered.

  REFERENCES:
    https://attack.mitre.org/techniques/T1565/001/
    https://attack.mitre.org/techniques/T0857/
-->
```

#### Honest Labeling

The retroactive Phase 11a pass labels existing modules **honestly**, not aspirationally. The project has not validated any module against an actual ICS vendor install in a lab. Marking modules as `verified-in-lab` would be inaccurate. Most current OT modules are correctly marked `vendor-documented` because the source was vendor public documentation, even though the rules have not been tested in a real environment.

This is intentional. Users deserve to know that a `vendor-documented` module may have version-specific gaps and should be validated in their environment before being trusted as authoritative.

#### Promotion Path

Confidence promotion (`vendor-documented` → `verified-in-lab`) requires evidence per the Phase 11c validation framework. The promotion process is:

1. Run the module against a live install in a lab or pre-production environment
2. Verify each rule fires on its trigger condition
3. Observe a baseline period (recommended: 24-48 hours minimum) and measure false positive rate
4. Document the lab/test environment, vendor version, and evidence
5. Submit a community contribution (per Phase 11e intake process) with the validation report
6. After review, update the module's `Confidence` field and bump version

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

All configs and modules use schema 4.90 (the project standard). The only exception is the legacy Win7 config at schema 4.23.

### 9.5 Module Validation Framework

This section defines how modules are validated and how they promote between confidence levels (see Section 8.5 for the four confidence levels).

#### 9.5.1 Validation Checklist

Every module MUST be checked against the items relevant to its category. Not all items apply to every module. The checklist is recorded in a companion `<module>.validation.md` file alongside the module XML.

**Universal checklist (all modules):**

| Item | Description | Evidence |
|------|-------------|----------|
| XML well-formed | `xmllint --noout` passes | Command output |
| Schema version correct | Declares 4.90 in header | Visual inspection |
| Provenance block present | Header contains Provenance section with Confidence field | Visual inspection |
| ATT&CK tagging correct | All include-rule `name` attributes use the tagging convention | Visual inspection or grep |
| Rule name length | No `name` attribute exceeds 250 characters | `check-rule-preservation.py` or grep |
| Merge test | Module merges into at least one curated config without error | `Merge-SysmonModules.ps1` output |
| Merged config loads | Merged output loads into Sysmon without error on at least one target OS | `Sysmon64.exe -c` output |

**Category-specific checklist items:**

| Category | Item | Description | Evidence |
|----------|------|-------------|----------|
| vendor-ot | Process names verified | Binary names and paths match a real or documented installation | Vendor documentation URL, screenshot, or lab observation |
| vendor-ot | File extensions verified | Monitored file extensions (.ap17, .s7p, etc.) are correct for the vendor product | Vendor documentation URL |
| vendor-ot | Default install paths verified | Install path patterns match the vendor's documented defaults | Vendor documentation URL or lab observation |
| vendor-it | Exclusion patterns safe | Excluded processes are confirmed safe to exclude (not dual-use) | Security assessment |
| cloud-storage | Dual-use include/exclude | Both include and exclude modules present per convention | Visual inspection |
| protocol | Port numbers correct | Monitored ports match the protocol's registered/standard port | Protocol specification or RFC |
| protocol | Protocol name correct | Protocol name in rule description matches the standard name | Protocol specification |
| sector | Sector-specific relevance | Rules are relevant to the named sector's operational environment | Industry guidance or sector-specific documentation |
| remote-access | Tool binary names current | Process names match the current version of the RMM tool | Vendor website or LOLRMM reference |
| lolbas | LOLBAS Project alignment | Binary and abuse pattern match the LOLBAS Project entry | LOLBAS Project URL |

#### 9.5.2 Evidence Requirements by Confidence Level

Each confidence level requires specific evidence to claim. Evidence is recorded in the companion validation file.

| Confidence Level | Required Evidence |
|---|---|
| **theoretical** | Plausible rule patterns based on general knowledge. No specific source required. Validation file documents the reasoning and notes the lack of authoritative source. |
| **security-research** | Specific URL or citation to the authoritative source (LOLBAS Project entry, MITRE ATT&CK technique page, Sigma rule, threat intel report, security blog post). Source must be publicly accessible or clearly identified. |
| **vendor-documented** | Specific URL or citation to vendor-published documentation (knowledge base article, installation guide, security bulletin, release notes). Vendor product version or version range identified. Default install paths and process names sourced from vendor docs. |
| **verified-in-lab** | All `vendor-documented` evidence PLUS: (1) lab environment description (OS version, vendor product version, Sysmon version), (2) evidence that each rule fires on its trigger condition (screenshot, event log excerpt, or test script output), (3) baseline observation period of at least 24 hours with false positive count documented, (4) date of validation. |

#### 9.5.3 Confidence Promotion Path

Modules promote from lower to higher confidence when new evidence is provided:

```
theoretical
    |-- Provide authoritative source URL --> security-research
    |-- Provide vendor documentation URL --> vendor-documented

security-research
    |-- Provide vendor documentation URL and version --> vendor-documented

vendor-documented
    |-- Provide lab test evidence (Section 9.5.2) --> verified-in-lab
```

Promotion requires:
1. Updated evidence in the companion `<module>.validation.md` file
2. Updated `Confidence` field in the module XML header
3. Version bump on the module (MINOR bump for confidence promotion)
4. Pull request or commit with the promotion evidence

Demotion (e.g., `vendor-documented` to `security-research`) occurs when previously cited vendor documentation becomes unavailable, the vendor product is significantly restructured (new binaries, paths), or community testing reveals the rules do not match the documented behavior.

#### 9.5.4 Companion Validation File Format

Each module has a companion validation file at the same path with `.validation.md` extension:

```
sysmon-configs/modules/vendor-ot/siemens-tia-portal.xml
sysmon-configs/modules/vendor-ot/siemens-tia-portal.validation.md
```

The validation file uses this format:

```markdown
# Module Validation: <Module Name>

**Module**: <path/to/module.xml>
**Version**: vX.Y
**Confidence**: <verified-in-lab|vendor-documented|security-research|theoretical>
**Last Validated**: YYYY-MM-DD
**Validated By**: <name or GitHub handle>

## Evidence

<Evidence section per Section 9.5.2. URLs, citations, lab descriptions as appropriate.>

## Checklist

| Item | Status | Notes |
|------|--------|-------|
| XML well-formed | PASS/FAIL/N-A | |
| Schema version correct | PASS/FAIL/N-A | |
| Provenance block present | PASS/FAIL/N-A | |
| ATT&CK tagging correct | PASS/FAIL/N-A | |
| Rule name length | PASS/FAIL/N-A | |
| Merge test | PASS/FAIL/N-A | Merged into <config name> |
| Merged config loads | PASS/FAIL/N-A | Tested on <OS, Sysmon version> |
| <category-specific items> | PASS/FAIL/N-A | |

## Observations

<Any notes about false positives, version-specific behavior, tuning
recommendations, or known gaps discovered during validation.>

## History

| Date | Change | By |
|------|--------|----|
| YYYY-MM-DD | Initial validation at <confidence level> | <name> |
```

Validation files are committed alongside their modules and are included in releases. They are the public record of what has been validated and what has not.

#### 9.5.5 Validation File Lifecycle

- **New module**: validation file created with initial confidence level and available evidence.
- **Confidence promotion**: validation file updated with new evidence, checklist re-run, history entry added.
- **Module version bump**: validation file reviewed; if rules changed, checklist items re-validated.
- **Community contribution**: contributor provides validation file (or at minimum, evidence). Maintainer reviews and may adjust confidence level.

---

## 10. Attribution Requirements

### 10.1 Original ICS Watch Dog Configs

- Author: `ICS Watch Dog Project (https://icswatchdog.com)`
- Project URL: `https://github.com/cutaway-security/ICSWatchDog`
- Copyright: `(c) 2024-2026 Cutaway Security, LLC`
- License: `CC BY-SA 4.0 | Commercial licensing available (info@cutawaysecurity.com)`

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
