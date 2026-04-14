#!/usr/bin/env python3
# Copyright (c) 2024-2026 Cutaway Security, LLC
# License: CC BY-SA 4.0 | Commercial licensing available (info@cutawaysecurity.com)
# Project: https://github.com/cutaway-security/ICSWatchDog
"""Diff-check tool for verifying Sysmon config rule preservation across edits.

Verifies that an edit to a curated Sysmon config preserved all existing rule
logic and added only expected new content. Handles both flat field-condition
rules (the existing convention) and composite <Rule groupRelation="and">
elements introduced in Phase 10 for LOLBAS detection.

Usage:
    python3 tools/check-rule-preservation.py <old.xml> <new.xml>

Exit code 0: rule logic preserved (existing rules unchanged, new rules added)
Exit code 1: rule logic regression (existing rules removed or changed)
Exit code 2: input error

The tool extracts:
  - Flat field conditions: <Image>, <CommandLine>, <TargetFilename>, etc.
  - Composite <Rule> elements with their inner field conditions
  - Reports added, removed, and unchanged rules

Phase 8b verified rule logic preservation by extracting flat field conditions
only. Phase 10b adds composite Rules for the first time. This tool extends the
Phase 8b approach to handle both rule types.
"""

import re
import sys
import xml.etree.ElementTree as ET


def strip_comments(content):
    """Remove XML comments from content (regex; ET also strips on parse)."""
    return re.sub(r'<!--[\s\S]*?-->', '', content)


def extract_rules(path):
    """Extract all rules from a Sysmon config file.

    Returns a tuple (flat_rules, composite_rules) where:
      flat_rules    = sorted list of (element, condition, value) tuples for
                      simple field conditions (<Image condition="...">x</Image>)
                      that are NOT inside a composite <Rule> element.
      composite_rules = sorted list of (group_relation, frozenset of inner
                        (element, condition, value) tuples) for each composite
                        <Rule> element.
    """
    with open(path) as f:
        content = f.read()

    # Strip XML comments first so they don't interfere with regex extraction
    content = strip_comments(content)

    # Extract composite <Rule>...</Rule> blocks first
    composite_pattern = re.compile(
        r'<Rule\s+(?:name="[^"]*"\s+)?(?:groupRelation="([^"]*)"\s*)?>([\s\S]*?)</Rule>'
    )
    composite_rules = []
    for match in composite_pattern.finditer(content):
        group_relation = match.group(1) or 'or'
        inner = match.group(2)
        # Extract field conditions inside this composite Rule
        inner_conditions = tuple(sorted(re.findall(
            r'<(\w+)\s+(?:name="[^"]*"\s+)?condition="([^"]+)"[^>]*>([^<]*)</\1>',
            inner)))
        composite_rules.append((group_relation, inner_conditions))
    composite_rules.sort()

    # Remove composite Rule blocks from content so flat extraction doesn't
    # double-count their inner conditions
    content_no_composite = composite_pattern.sub('', content)

    # Extract flat field conditions from the remaining content
    flat_rules = sorted(re.findall(
        r'<(\w+)\s+(?:name="[^"]*"\s+)?condition="([^"]+)"[^>]*>([^<]*)</\1>',
        content_no_composite))

    return flat_rules, composite_rules


def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <old.xml> <new.xml>", file=sys.stderr)
        sys.exit(2)

    old_path, new_path = sys.argv[1], sys.argv[2]

    try:
        old_flat, old_comp = extract_rules(old_path)
        new_flat, new_comp = extract_rules(new_path)
    except FileNotFoundError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(2)

    print(f"=== Rule Preservation Check ===")
    print(f"Old: {old_path}")
    print(f"New: {new_path}")
    print()
    print(f"Flat rules:")
    print(f"  Old: {len(old_flat)}")
    print(f"  New: {len(new_flat)}")
    print(f"Composite Rules:")
    print(f"  Old: {len(old_comp)}")
    print(f"  New: {len(new_comp)}")
    print()

    # Check 1: existing flat rules must all still exist (no removals or changes)
    old_flat_set = set(old_flat)
    new_flat_set = set(new_flat)
    removed_flat = old_flat_set - new_flat_set
    added_flat = new_flat_set - old_flat_set

    # Check 2: existing composite rules must all still exist
    old_comp_set = set(old_comp)
    new_comp_set = set(new_comp)
    removed_comp = old_comp_set - new_comp_set
    added_comp = new_comp_set - old_comp_set

    print(f"Flat rules removed: {len(removed_flat)}")
    print(f"Flat rules added:   {len(added_flat)}")
    print(f"Composite Rules removed: {len(removed_comp)}")
    print(f"Composite Rules added:   {len(added_comp)}")
    print()

    failure = False

    if removed_flat:
        print(f"FAIL: {len(removed_flat)} flat rule(s) removed:")
        for r in sorted(removed_flat)[:20]:
            print(f"  REMOVED: {r}")
        if len(removed_flat) > 20:
            print(f"  ... and {len(removed_flat) - 20} more")
        failure = True

    if removed_comp:
        print(f"FAIL: {len(removed_comp)} composite Rule(s) removed:")
        for r in sorted(removed_comp)[:10]:
            print(f"  REMOVED: groupRelation={r[0]}, inner={r[1]}")
        failure = True

    if added_flat:
        print(f"INFO: {len(added_flat)} flat rule(s) added:")
        for r in sorted(added_flat)[:10]:
            print(f"  ADDED: {r}")
        if len(added_flat) > 10:
            print(f"  ... and {len(added_flat) - 10} more")

    if added_comp:
        print(f"INFO: {len(added_comp)} composite Rule(s) added:")
        for r in sorted(added_comp)[:10]:
            print(f"  ADDED: groupRelation={r[0]}, {len(r[1])} inner condition(s)")
        if len(added_comp) > 10:
            print(f"  ... and {len(added_comp) - 10} more")

    print()
    if failure:
        print("RESULT: FAIL -- existing rule logic was modified or removed")
        sys.exit(1)
    else:
        print("RESULT: PASS -- all existing rules preserved, only additions detected")
        sys.exit(0)


if __name__ == '__main__':
    main()
