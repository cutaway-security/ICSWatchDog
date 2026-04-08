# TOOL_CODING_STANDARD.md

Conventions for the developer tools that ship under `tools/` and the JSON / text artifacts they read or produce. SYSMON_CODING_STANDARD.md owns Sysmon XML conventions; this document owns everything else under `tools/`.

This standard applies to:

- PowerShell scripts under `tools/` (`*.ps1`)
- Python helpers under `tools/` (`*.py`)
- Test harnesses (`tools/Test-*.ps1`)
- JSON I/O artifacts produced or consumed by any tool above (inventory captures, coverage reports, diff reports)
- Shipped fixture-style examples (NOT dev-only test fixtures, which live under `claude-dev/test-fixtures/`)

---

## 1. Scope and Philosophy

ICS Watch Dog tools must run on locked-down OT Windows hosts with minimal privileges and minimal dependencies. The defaults are conservative:

- **Read-only by default.** A tool that inspects a system must not modify it.
- **No external dependencies.** PowerShell tools target stock PowerShell; Python tools target the standard library.
- **Single responsibility.** One script does one thing. Composition happens at the user's command line, not inside a monolithic script.
- **Honest output.** No fake percentages, no padded "100% covered" claims, no silent failures. If a tool cannot measure something, it says so.
- **Deterministic tests.** Test harnesses must run against fixtures, not live systems.

---

## 2. Language and Runtime Requirements

### 2.1 PowerShell

| Item | Requirement |
|------|-------------|
| Minimum PowerShell version | 3.0 |
| Compatible with PowerShell Core (Linux/macOS) | Yes, where the cmdlets used exist on those platforms |
| External modules | None. Stock cmdlets only. |
| Execution policy assumptions | Tool must run under `RemoteSigned` or `AllSigned`; no `Set-ExecutionPolicy` calls inside the script |
| Admin privileges | Read-only inventory tools must NOT require admin. State-changing tools must check and exit cleanly if not elevated. |
| Error handling | `$ErrorActionPreference = 'Stop'` at top of script. Wrap risky operations in try/catch. |
| Comment-based help | Required (`.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`, `.NOTES`) |
| `[CmdletBinding()]` | Required on the param block |
| Strict mode | Optional but recommended (`Set-StrictMode -Version 3.0`) |

### 2.2 Python

| Item | Requirement |
|------|-------------|
| Minimum Python version | 3.8 |
| External packages | None. Standard library only. |
| Shebang | `#!/usr/bin/env python3` |
| Type hints | Encouraged for new code, not required |
| Argparse | Required for CLI argument handling |

---

## 3. File and Script Naming

| Type | Pattern | Example |
|------|---------|---------|
| PowerShell verb-noun script | `Verb-Noun.ps1` (PascalCase, approved verb) | `Get-SysmonCoverage.ps1`, `Export-SystemInventory.ps1` |
| PowerShell test harness | `Test-<ScriptUnderTest>.ps1` | `Test-GetSysmonCoverage.ps1` |
| Python helper | `kebab-case.py` or `snake_case.py` | `check-rule-preservation.py` |
| Shell scripts | Avoided. Use PowerShell or Python instead. |  |

PowerShell verbs must be on the approved list (`Get-Verb`). Common choices in this project: `Get`, `Set`, `Test`, `Export`, `Import`, `Compare`, `Merge`, `Invoke`, `New`, `Remove`.

---

## 4. Parameter Conventions

### 4.1 Naming

- Use full PascalCase parameter names. No abbreviations: `-ConfigPath`, not `-cfg` or `-c`.
- Path parameters end in `Path`: `-ConfigPath`, `-OutputPath`, `-InventoryPath`.
- Boolean toggles use positive phrasing: `-Redact` (off by default), not `-NoRedact` (on by default), unless the safer behavior is the default-on case.
- Multi-value parameters use plural names: `-AdditionalModules`, not `-AdditionalModule`.

### 4.2 Common parameters

Tools that produce reports SHOULD support:

| Parameter | Type | Behavior |
|-----------|------|----------|
| `-OutputFormat` | `Console`, `JSON`, `Markdown` | Default `Console` |
| `-OutputPath` | path | Optional. If omitted, write to stdout. |
| `-VerboseLogging` | switch | Extra diagnostic output. Distinct from PowerShell's built-in `-Verbose`. |

### 4.3 Mutually exclusive parameters

When two parameters represent alternative input sources (e.g., live system vs. JSON file), declare them in separate parameter sets so PowerShell rejects ambiguous calls at parse time.

---

## 5. JSON I/O Schema Versioning

Any JSON file produced or consumed by an ICS Watch Dog tool is a **schema-versioned artifact**. The same JSON may be re-read months later by a newer tool, so schema evolution must be explicit.

### 5.1 Required envelope fields

Every tool-produced JSON file MUST include these fields at the top level:

```json
{
  "SchemaName": "SystemInventory",
  "SchemaVersion": "1.0",
  "GeneratedBy": "Export-SystemInventory.ps1",
  "GeneratedByVersion": "1.0",
  "GeneratedAt": "2026-04-07T14:32:00Z",
  "...": "...payload fields below..."
}
```

| Field | Type | Purpose |
|-------|------|---------|
| `SchemaName` | string | Identifies the schema (e.g., `SystemInventory`, `CoverageReport`, `InventoryDiff`). Stable. |
| `SchemaVersion` | string | `MAJOR.MINOR`. Bump MINOR for additive changes; bump MAJOR for breaking changes. |
| `GeneratedBy` | string | Script filename that produced this artifact. |
| `GeneratedByVersion` | string | Version of the script (read from a `$ScriptVersion` constant in the script). |
| `GeneratedAt` | string | ISO 8601 UTC timestamp. |

### 5.2 Reading and warning on mismatch

Any tool that reads a versioned JSON artifact MUST:

1. Check `SchemaName` matches what the tool expects. Refuse to proceed on mismatch.
2. Check `SchemaVersion` MAJOR matches. Refuse to proceed on MAJOR mismatch.
3. Warn (not fail) if the file's MINOR is greater than what the tool understands (forward compatibility).
4. Warn (not fail) if the file's MINOR is less than what the tool understands (backward compatibility — tool may use defaults for missing optional fields).

### 5.3 Schema evolution rules

- **Additive change (new optional field)**: bump MINOR.
- **Renaming a field**: bump MAJOR. Provide a one-time migration path or document a manual migration step.
- **Removing a field**: bump MAJOR.
- **Changing a field's type**: bump MAJOR.

### 5.4 Documenting schemas

Each schema MUST be documented in this file in the Schema Catalog (Section 11) below. The catalog is the source of truth.

---

## 6. Output Formats

When a tool produces a human-readable report, support three formats with consistent semantics:

| Format | Use case | Conventions |
|--------|----------|-------------|
| `Console` | Interactive, color OK if available | Default. Plain text when not a TTY. Human-readable summaries first, raw data after. |
| `JSON` | Pipelines, automation, SIEM ingest | Conforms to a versioned schema (Section 5). No console-only formatting characters. |
| `Markdown` | Tickets, reports, copy/paste into wikis | Use tables and headers. No HTML. No emoji. |

The Console format is for humans; the JSON format is for machines; the Markdown format is for tickets. A tool should not try to make one format do all three jobs.

---

## 7. Error Handling and Exit Codes

| Exit code | Meaning |
|-----------|---------|
| 0 | Success |
| 1 | General failure (validation, file not found, parse error) |
| 2 | Test failures in a test harness |
| 3 | Schema version incompatibility |

PowerShell scripts SHOULD use `throw` for terminating errors and let the engine surface the message. Test harnesses MUST exit with non-zero on any test failure so CI can detect them.

---

## 8. Logging and User Messages

- No emoji, icons, or Unicode symbols (per CLAUDE.md project rule).
- No ANSI escape sequences in non-Console output formats.
- Use `Write-Host` for user-facing status messages. Use `Write-Verbose` for diagnostic detail surfaced by `-Verbose`.
- Never print sensitive data (paths under `C:\Users\<name>\`, hostnames, IPs) without an explicit user opt-in.

---

## 9. Testing

### 9.1 Test harness conventions

- Every non-trivial tool MUST have a companion `Test-<Tool>.ps1` harness.
- Test harnesses are deterministic. They MUST run against fixtures, never the live system.
- Fixtures used only in development live under `claude-dev/test-fixtures/<tool>/`. They are NOT shipped to users.
- Fixtures intended as user-facing examples live under `tools/examples/` and ARE shipped.
- Test harnesses MUST skip cleanly (with a clear message, exit 0) if a required fixture is absent. They must not fail noisily on a release tarball that has no `claude-dev/`.

### 9.2 Test harness output

- Print a summary line at the end: `Total: N  Passed: N  Failed: N`.
- Exit non-zero on any failure.
- Each test should print `PASS:` or `FAIL:` with the test name.

### 9.3 What to test

At minimum:
- Happy-path execution with a representative fixture
- Each `-OutputFormat` produces parseable output of that format
- Parameter validation rejects bad input
- Schema-versioned JSON artifacts include all required envelope fields
- A tool that consumes JSON refuses to proceed on schema mismatch

---

## 10. Documentation Requirements

Each tool MUST have:

1. **Comment-based help** in the script header (PowerShell) or module docstring (Python).
2. **A README entry** in the project README under the Tools section describing what the tool does in one sentence.
3. **A website page** for tools the user is expected to invoke directly (not internal helpers). Lives under `docs/_pages/`.

---

## 11. Schema Catalog

The authoritative list of schemas produced or consumed by ICS Watch Dog tools.

### 11.1 SystemInventory (v1.0)

Produced by `Export-SystemInventory.ps1`. Consumed by `Get-SysmonCoverage.ps1` and `Compare-SystemInventory.ps1`.

Required envelope fields per Section 5.1, plus payload:

```json
{
  "SchemaName": "SystemInventory",
  "SchemaVersion": "1.0",
  "GeneratedBy": "Export-SystemInventory.ps1",
  "GeneratedByVersion": "1.0",
  "GeneratedAt": "2026-04-07T14:32:00Z",
  "Hostname": "string or REDACTED",
  "OSVersion": "string",
  "Redacted": false,
  "Processes": [
    { "Name": "string", "Path": "string" }
  ],
  "Software": [
    { "DisplayName": "string", "Publisher": "string", "InstallPath": "string" }
  ],
  "ListeningPorts": [502, 4840],
  "Services": [
    { "Name": "string", "DisplayName": "string" }
  ],
  "ScheduledTasks": [
    { "Name": "string", "Path": "string" }
  ]
}
```

`Redacted: true` indicates the export was run with `-Redact` and usernames in paths, hostname, and IPs have been mechanically scrubbed. Mechanical redaction is a best-effort safety net, not a substitute for human review before sharing.

### 11.2 CoverageReport (v1.0)

Produced by `Get-SysmonCoverage.ps1` with `-OutputFormat JSON`. Not currently consumed by any other tool.

Top-level shape (illustrative; see the script for the authoritative payload structure):

```json
{
  "SchemaName": "CoverageReport",
  "SchemaVersion": "1.0",
  "GeneratedBy": "Get-SysmonCoverage.ps1",
  "GeneratedByVersion": "1.0",
  "GeneratedAt": "2026-04-07T14:35:00Z",
  "ConfigPath": "string",
  "InventorySource": "live | <path-to-json>",
  "Coverage": {
    "ProcessCoverage": { "...": "..." },
    "SoftwareCoverage": { "...": "..." },
    "PortCoverage": { "...": "..." },
    "AttackCoverage": { "...": "..." }
  }
}
```

### 11.3 InventoryDiff (v1.0)

Produced by `Compare-SystemInventory.ps1` with `-OutputFormat JSON`.

```json
{
  "SchemaName": "InventoryDiff",
  "SchemaVersion": "1.0",
  "GeneratedBy": "Compare-SystemInventory.ps1",
  "GeneratedByVersion": "1.0",
  "GeneratedAt": "2026-04-07T14:40:00Z",
  "ReferencePath": "string",
  "DifferencePath": "string",
  "Diff": {
    "Processes":      { "Added": [], "Removed": [] },
    "Software":       { "Added": [], "Removed": [] },
    "ListeningPorts": { "Added": [], "Removed": [] },
    "Services":       { "Added": [], "Removed": [] },
    "ScheduledTasks": { "Added": [], "Removed": [] }
  }
}
```

The diff intentionally reports only changes, not unchanged items.

---

## 12. Adding a New Tool

When adding a new script under `tools/`:

1. Confirm it fits the single-responsibility principle. If it does two unrelated things, split it.
2. Pick an approved PowerShell verb and follow the naming convention (Section 3).
3. Write comment-based help (Section 2.1).
4. If it produces or consumes JSON, register the schema in the Schema Catalog (Section 11) and follow Section 5.
5. Write a `Test-<Tool>.ps1` harness with at least the test cases in Section 9.3.
6. Add a README entry and (if user-facing) a website page (Section 10).
7. Update PLAN.md, RESUME.md, and ARCHITECTURE.md as appropriate.

---

## 13. Out of Scope

This standard does NOT cover:

- Sysmon XML configuration files (see `SYSMON_CODING_STANDARD.md`)
- Jekyll / website code (see `html-css-jekyll.md`)
- Module library content (see `SYSMON_CODING_STANDARD.md`)
- Release process (see `GIT_RELEASE_STEPS.md`)
- Remote testing infrastructure (see `REMOTE_TESTING.md`)
