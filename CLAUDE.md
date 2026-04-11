# CLAUDE.md - Project Rules and Guidelines

## Project Overview

**Project**: ICS Watch Dog
**Repository**: https://github.com/cutaway-security/ICSWatchDog
**Development Branch**: claude-dev
**Description**: ICS Watch Dog provides curated Microsoft Sysmon configuration files for ICS/OT environments, with documentation to help Windows administrators deploy and mature their endpoint monitoring. The project offers a tiered progression from starter to advanced configurations, lowering the barrier to Sysmon adoption in industrial and critical infrastructure settings.

---

## Essential Documents (Read in Order)

Before starting any development session, read these documents in order:

1. **CLAUDE.md** - This file. Project rules, constraints, and conventions
2. **claude-dev/ARCHITECTURE.md** - System design, data structures, protocol details
3. **claude-dev/PLAN.md** - Project roadmap, current phase, milestones, completion status
4. **claude-dev/RESUME.md** - Development status, what is in progress, blockers, session context

**At session start**: Confirm you have read these documents before proceeding. List your understanding of the current state and next steps. Wait for confirmation before proceeding.

---

## Development Process Rules

When encountering issues during development:

1. **STOP** - Do not continue to next task
2. **DIAGNOSE** - Identify root cause with specific error messages and line numbers
3. **FIX** - Implement a solution
4. **VERIFY** - Confirm the fix works with actual testing
5. **DOCUMENT** - Record the issue and solution in RESUME.md
6. **ASK** - If unable to resolve after reasonable attempts, STOP and ask for clarifying directions

**Never assume code works without testing. Never move forward with unresolved issues.**

### Phase Completion Process

Before moving to the next phase:

1. **Verify** - All components of current phase working
2. **Test** - Run tests relevant to the phase
3. **Document** - Update RESUME.md with session activity
4. **Summarize** - Provide summary of completed work
5. **Plan** - List steps for next phase
6. **Confirm** - Wait for user confirmation before proceeding

---

## Absolute Requirements

- NO emoji, icons, or Unicode symbols in source code, output, or documentation
- NO stubs, placeholders, or fake data -- implement real functionality or mark clearly as TODO with explanation
- NO claiming code works without testing -- be honest about untested code
- NO moving forward when issues are unresolved
- NO spaces in file or folder names

---

## Technical Constraints

### Sysmon Configuration Files

| Constraint | Value |
|------------|-------|
| Primary Artifacts | Sysmon XML configuration files |
| Schema Version | 4.90 for all standard configs; 4.23 for legacy Win7 config |
| Sysmon Minimum | v15+ for standard configs (schema 4.90); v10+ for legacy Win7 config (schema 4.23) |
| License | Creative Commons Attribution 4.0 International |

### Website

| Constraint | Value |
|------------|-------|
| Framework | Jekyll with custom CutSec design system |
| Theme Method | Custom _layouts, _includes, css/, js/ (no theme gem) |
| Hosting | GitHub Pages, served from gh-pages branch |
| Source Location | docs/ directory on claude-dev branch |
| Domain | icswatchdog.com (CNAME) |
| Config/Repo Links | All site links to configs and repo MUST point to main branch |

---

## Code Quality Standards

### XML (Sysmon Configs and Modules)

All Sysmon XML files (curated configs, modules, community contributions) MUST follow `claude-dev/SYSMON_CODING_STANDARD.md`. That document is the single source of truth for file structure, header blocks, schema versions, meta configuration, RuleGroup conventions, rule naming (ATT&CK tagging), comment conventions, validation requirements, and attribution. Do not duplicate Sysmon-specific rules in other documents -- reference the standard.

### Markdown / Jekyll

- Standard Markdown conventions
- No vendored theme files -- use remote_theme only
- Keep custom overrides minimal
- See `claude-dev/html-css-jekyll.md` for HTML/CSS/Jekyll standards

---

## Project Scope

### In Scope

- Curated Sysmon XML configuration files for ICS/OT environments (starter through advanced)
- Standalone use-case configs (e.g., file-create-only) for specific monitoring needs
- Documentation: deployment guides, config selection, customization, advancement
- GitHub Pages website with config descriptions and download links
- Attribution and references to source projects (SwiftOnSecurity, Microsoft, sysmon-modular)
- Module library: vendor (OT and IT), sector, protocol, cloud-storage, and remote-access XML fragments
- PowerShell merge tooling (PS 3+, no external dependencies) bounded to merging modules into a base curated config
- Per-rule MITRE ATT&CK technique tagging in rule `name` attributes (include rules only)
- Test harness for validating module merge tooling output

### Out of Scope

- Automated config generation from threat intel feeds, vulnerability scans, or asset inventories
- SIEM integration or log analysis tools
- Automated deployment of configs to endpoints
- Non-Windows platforms
- Schema validation against an XSD (Sysmon's XSD is not public)
- Adversary emulation or red team tooling

---

## Testing

### XML Validation

- Well-formedness check (xmllint or equivalent)
- Sysmon schema validation where possible

### Website

- Local Jekyll build testing requires bundler installed locally:
  1. `cd docs/`
  2. Set BUNDLE variable: `BUNDLE="$HOME/.local/share/gem/ruby/3.2.0/bin/bundle"`
  3. `$BUNDLE config set --local path vendor/bundle`
  4. `$BUNDLE install`
  5. `$BUNDLE exec jekyll build` (or `jekyll serve` for local preview)
  NOTE: bundler is installed in the user gem directory which is not on PATH.
  Always use the full path or set the BUNDLE variable above.
  If bundler is not installed: `gem install bundler --user-install`
  The vendor/ directory is already in .gitignore.
- Link validation on the built site

---

## Communication Style

- Focus on substance, skip unnecessary praise
- Be direct about problems -- identify specific issues with line numbers
- Question assumptions and challenge problematic approaches
- Ground claims in evidence, not reflexive validation
- When stuck, explain what was tried and ask specific questions

---

## Documentation Updates Required

When making changes, update the appropriate documents:

| Change Type | Update |
|-------------|--------|
| Architecture change | claude-dev/ARCHITECTURE.md |
| Phase completion | claude-dev/PLAN.md |
| Session activity | claude-dev/RESUME.md |
| Problem encountered | claude-dev/RESUME.md |
| Config change | XML header, site docs |
| Website change | docs/ directory |
| Usage change | README.md |

---

## Session Workflow

### Starting a Session

1. Read CLAUDE.md (this file)
2. Read claude-dev/ARCHITECTURE.md
3. Read claude-dev/PLAN.md
4. Read claude-dev/RESUME.md
5. State your understanding of current status
6. List proposed next steps
7. Wait for confirmation before proceeding

### During Development

1. Work on one task at a time
2. Test each change before moving on
3. Document issues in RESUME.md
4. Stop and ask if encountering persistent issues

### Ending a Session

1. Update claude-dev/RESUME.md with what was accomplished
2. Update claude-dev/PLAN.md with completion status
3. List any blockers or open questions
4. Provide summary of session
