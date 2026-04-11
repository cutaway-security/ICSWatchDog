# GITHUB_ISSUE_STANDARD.md

Conventions for GitHub issue templates, labels, and the template chooser. This document is portable across projects -- adapt the template fields and label taxonomy for each project's domain.

---

## 1. Purpose

GitHub issue templates standardize how users report bugs, request features, and submit contributions. They reduce incomplete submissions, route issues to the right category, and make triage faster.

---

## 2. File Structure

Issue templates are managed as files in the repository, not configured via the GitHub GUI.

```
.github/
    ISSUE_TEMPLATE/
        bug_report.md          # Bug report template
        feature_request.md     # Feature request template
        module_submission.md   # Contribution submission (project-specific)
        config.yml             # Template chooser configuration
```

### 2.1 Shipping to main

The `.github/` directory MUST ship to the default branch (usually `main`). Issue templates only take effect from the default branch. Do NOT add `.github/` to `.gitattributes` export-ignore or to the release `git rm` step.

---

## 3. Template Chooser (config.yml)

The `config.yml` file controls the "New Issue" page.

```yaml
blank_issues_enabled: false
contact_links:
  - name: Project Documentation
    url: https://example.com
    about: Check the documentation before opening an issue
```

Key settings:

| Setting | Value | Rationale |
|---------|-------|-----------|
| `blank_issues_enabled` | `false` | Forces users to pick a template. Prevents unstructured issues that are harder to triage. |
| `contact_links` | Documentation URL | Redirects questions that are not bugs or features to the docs. |

---

## 4. Template Format

Each template file uses YAML frontmatter followed by Markdown body.

### 4.1 Frontmatter fields

```yaml
---
name: Template Display Name
about: One-line description shown in the template chooser
title: "[PREFIX] "
labels: default-label
assignees: ''
---
```

| Field | Purpose |
|-------|---------|
| `name` | Shown in the template chooser list |
| `about` | Description below the template name |
| `title` | Pre-filled issue title (with a prefix tag) |
| `labels` | Auto-applied label(s) when this template is used |
| `assignees` | Auto-assigned user(s). Usually left blank. |

### 4.2 Body conventions

- Use checkboxes (`- [ ]`) for selectors (component type, category, etc.)
- Include version fields (tool version, OS version, runtime version) for bug reports
- Include a sanitization warning for any template that accepts file uploads
- Keep the template short. Users skip long forms.

---

## 5. Template Types

### 5.1 Bug Report

Purpose: report a problem with existing functionality.

Required sections:
- **Component selector** (checkboxes for major project areas)
- **Version information** (tool version, OS, runtime)
- **Problem description**
- **Steps to reproduce**
- **Expected behavior**
- **Sanitization reminder** (no hostnames, IPs, credentials in attachments)

Auto-label: `bug`

### 5.2 Feature Request

Purpose: suggest a new capability or improvement.

Required sections:
- **Type selector** (what kind of enhancement)
- **Description** (what to add or change)
- **Use case** (why it matters)
- **Evidence** (optional: links, references, example data)

Auto-label: `enhancement`

### 5.3 Contribution Submission (project-specific)

Purpose: submit new content (modules, configs, rules, etc.) for review.

Required sections:
- **Name and category**
- **Provenance** (where the content came from, confidence level)
- **Validation checklist** (what has been tested)
- **Testing environment** (if lab-validated)
- **File attachments** (the contribution itself)
- **Sanitization warning**

Auto-label: project-specific (e.g., `module-submission`)

---

## 6. Label Taxonomy

Labels are NOT stored in the repository. They are created once per repo via the GitHub GUI or `gh label create` CLI. The taxonomy below is a starting point; adapt for each project.

### 6.1 Standard labels (keep GitHub defaults)

GitHub creates these by default: `bug`, `enhancement`, `duplicate`, `good first issue`, `help wanted`, `invalid`, `question`, `wontfix`. Keep them.

### 6.2 Project-specific labels

Create with `gh label create`:

```bash
gh label create "<name>" --color "<hex>" --description "<description>"
```

#### Category labels (what area of the project)

| Label | Color | Description |
|-------|-------|-------------|
| Adapt per project | Blue family | One label per major component area |

#### Workflow labels (where in the process)

| Label | Color | Description |
|-------|-------|-------------|
| `needs-validation` | `#E4E669` (light yellow) | Submission needs testing/validation |
| `needs-triage` | `#D93F0B` (orange) | New issue, not yet reviewed |

#### Acceptance tier labels (for contribution-accepting projects)

| Label | Color | Description |
|-------|-------|-------------|
| `tier-a` | `#0E8A16` (green) | Validated, ships in main |
| `tier-b` | `#FBCA04` (yellow) | Documented but unvalidated, ships in community |
| `tier-c` | `#D93F0B` (orange) | Theoretical, needs community testing |

### 6.3 Label color conventions

| Color Family | Hex Range | Use For |
|--------------|-----------|---------|
| Green | `#0E8A16` | Validated, approved, good |
| Blue | `#0075CA`, `#1D76DB` | Categories, informational |
| Yellow | `#FBCA04`, `#E4E669` | Needs attention, moderate |
| Orange/Red | `#D93F0B` | Urgent, unvalidated, blocking |
| Purple | `#5319E7` | Special categories |
| Light blue | `#C5DEF5` | Platform/environment tags |

---

## 7. ICS Watch Dog Label Commands

The following commands create the project-specific labels for this repository. Run once from a machine authenticated with `gh`:

```bash
# Category labels
gh label create "module-submission" --color "0E8A16" --description "Community module submission for review"
gh label create "config" --color "1D76DB" --description "Related to curated Sysmon configs"
gh label create "module" --color "5319E7" --description "Related to the module library"
gh label create "tool" --color "FBCA04" --description "Related to PowerShell/Python tools"
gh label create "documentation" --color "0075CA" --description "Documentation or website"

# Acceptance tier labels
gh label create "tier-a" --color "0E8A16" --description "Validated contribution, main library"
gh label create "tier-b" --color "FBCA04" --description "Vendor-documented, community directory"
gh label create "tier-c" --color "D93F0B" --description "Theoretical, needs community testing"

# Workflow labels
gh label create "needs-validation" --color "E4E669" --description "Submission needs lab validation"

# Platform labels
gh label create "windows-7" --color "C5DEF5" --description "Related to Win7/legacy support"
```

---

## 8. Adapting for a New Project

To use this standard on another project:

1. Copy this file to the new project's dev directory
2. Update Section 5.3 (contribution template) for the project's domain
3. Update Section 7 (label commands) with project-specific labels
4. Create the `.github/ISSUE_TEMPLATE/` directory and template files
5. Run the `gh label create` commands
6. Verify templates appear on the "New Issue" page after pushing to the default branch
