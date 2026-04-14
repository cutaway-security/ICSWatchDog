# Copyright (c) 2024-2026 Cutaway Security, LLC
# License: CC BY-SA 4.0 | Commercial licensing available (info@cutawaysecurity.com)
# Project: https://github.com/cutaway-security/ICSWatchDog

<#
.SYNOPSIS
    Test harness for Merge-SysmonModules.ps1.

.DESCRIPTION
    Runs a sequence of test cases that exercise the merge tool against fixture files
    in tools/test-fixtures/. Each test verifies one aspect of merge behavior:

    - Test 1: simple merge (one base, one module, one RuleGroup)
    - Test 2: multi-module merge (one base, two modules, three RuleGroups)
    - Test 3: forbidden element rejection (module with <Sysmon> root must error)
    - Test 4: schema mismatch warning (4.90 module into 4.50 base must warn)
    - Test 5: real curated config + real modules end-to-end smoke test
    - Test 6: malformed XML rejection
    - Test 7: nonexistent module file rejection

    Reports per-test pass/fail and a final summary.

.PARAMETER MergeScriptPath
    Path to Merge-SysmonModules.ps1. Defaults to the same directory as this script.

.PARAMETER FixturesPath
    Path to test-fixtures/ directory. Defaults to ./test-fixtures/ relative to this script.

.EXAMPLE
    .\Test-MergeSysmonModules.ps1

.NOTES
    Requirements: PowerShell 3.0 or later.
    Compatible with Windows PowerShell 5.1+ and PowerShell Core 7+.
#>

[CmdletBinding()]
param(
    [string]$MergeScriptPath = (Join-Path $PSScriptRoot 'Merge-SysmonModules.ps1'),
    [string]$FixturesPath    = (Join-Path $PSScriptRoot 'test-fixtures')
)

if ($PSVersionTable.PSVersion.Major -lt 3) {
    Write-Error "This script requires PowerShell 3.0 or later. Current version: $($PSVersionTable.PSVersion)"
    exit 1
}

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $MergeScriptPath)) {
    throw "Merge script not found: $MergeScriptPath"
}
if (-not (Test-Path -LiteralPath $FixturesPath)) {
    throw "Fixtures directory not found: $FixturesPath"
}

# Resolve fixture paths
$baseMinimal = Join-Path $FixturesPath 'base-configs/minimal-base.xml'
$baseOt      = Join-Path $FixturesPath 'base-configs/ot-base.xml'
$modProto    = Join-Path $FixturesPath 'modules/sample-protocol.xml'
$modVendor   = Join-Path $FixturesPath 'modules/sample-vendor.xml'
$modInvalid  = Join-Path $FixturesPath 'modules/invalid-has-sysmon-root.xml'
$modSchema90 = Join-Path $FixturesPath 'modules/schema-490-clipboard.xml'

# Real curated config and modules for end-to-end test
$projectRoot = Split-Path -Parent $PSScriptRoot
$realBase    = Join-Path $projectRoot 'sysmon-configs/sysmonconfig-baseline-ot.xml'
$realMod1    = Join-Path $projectRoot 'sysmon-configs/modules/vendor-ot/siemens-tia-portal.xml'
$realMod2    = Join-Path $projectRoot 'sysmon-configs/modules/protocol/modbus-tcp.xml'
$realMod3    = Join-Path $projectRoot 'sysmon-configs/modules/cloud-storage/include_mega.xml'

# Temp output directory
$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "icswatchdog-merge-tests-$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

$results = @()

function Invoke-Test {
    param(
        [string]$Name,
        [scriptblock]$ScriptBlock
    )
    Write-Host ""
    Write-Host "TEST: $Name" -ForegroundColor Cyan
    try {
        $result = & $ScriptBlock
        if ($result -eq $false) {
            Write-Host "  FAIL: $Name" -ForegroundColor Red
            return [pscustomobject]@{ Name=$Name; Pass=$false; Error='' }
        } else {
            Write-Host "  PASS: $Name" -ForegroundColor Green
            return [pscustomobject]@{ Name=$Name; Pass=$true; Error='' }
        }
    } catch {
        Write-Host "  FAIL: $Name" -ForegroundColor Red
        Write-Host "    $($_.Exception.Message)" -ForegroundColor Red
        return [pscustomobject]@{ Name=$Name; Pass=$false; Error=$_.Exception.Message }
    }
}

function Get-RuleGroupCount {
    param([string]$XmlPath)
    [xml]$x = Get-Content -LiteralPath $XmlPath -Raw
    return $x.Sysmon.EventFiltering.RuleGroup.Count
}

# Test 1: simple merge
$results += Invoke-Test -Name "Simple merge (1 module, 1 RuleGroup)" -ScriptBlock {
    $out = Join-Path $tempDir 'test1.xml'
    & $MergeScriptPath -BaseConfig $baseMinimal -Modules @($modProto) -OutputPath $out | Out-Null
    if (-not (Test-Path -LiteralPath $out)) { throw "Output file not created" }
    $count = Get-RuleGroupCount $out
    if ($count -ne 2) { throw "Expected 2 RuleGroups (1 base + 1 module), got $count" }
    return $true
}

# Test 2: multi-module merge
$results += Invoke-Test -Name "Multi-module merge (2 modules, 3 RuleGroups added)" -ScriptBlock {
    $out = Join-Path $tempDir 'test2.xml'
    & $MergeScriptPath -BaseConfig $baseMinimal -Modules @($modProto, $modVendor) -OutputPath $out | Out-Null
    $count = Get-RuleGroupCount $out
    if ($count -ne 4) { throw "Expected 4 RuleGroups (1 base + 1 from proto + 2 from vendor), got $count" }
    return $true
}

# Test 3: forbidden element rejection
$results += Invoke-Test -Name "Forbidden element rejection (<Sysmon> in module)" -ScriptBlock {
    $out = Join-Path $tempDir 'test3.xml'
    $threw = $false
    try {
        & $MergeScriptPath -BaseConfig $baseMinimal -Modules @($modInvalid) -OutputPath $out 2>&1 | Out-Null
    } catch {
        $threw = $true
    }
    if (-not $threw) { throw "Expected merge to fail on forbidden element, but it succeeded" }
    return $true
}

# Test 4: schema mismatch warning
$results += Invoke-Test -Name "Schema 4.90 module into 4.50 base (warning expected)" -ScriptBlock {
    $out = Join-Path $tempDir 'test4.xml'
    $output = & $MergeScriptPath -BaseConfig $baseMinimal -Modules @($modSchema90) -OutputPath $out 3>&1 6>&1
    if (-not (Test-Path -LiteralPath $out)) { throw "Output file not created" }
    # Check that a warning about schema was emitted
    $warningFound = $output | Where-Object { $_ -match 'schema 4.90' }
    if (-not $warningFound) { throw "Expected schema mismatch warning but none was emitted" }
    return $true
}

# Test 5: real curated config + real modules
$results += Invoke-Test -Name "Real curated config + real modules end-to-end" -ScriptBlock {
    if (-not (Test-Path -LiteralPath $realBase)) {
        throw "Real base config not found at $realBase (run from project root)"
    }
    $out = Join-Path $tempDir 'test5.xml'
    & $MergeScriptPath -BaseConfig $realBase -Modules @($realMod1, $realMod2, $realMod3) -OutputPath $out | Out-Null
    [xml]$x = Get-Content -LiteralPath $out -Raw
    if ($x.Sysmon.schemaversion -ne '4.90') { throw "Output schemaversion should be 4.90, got $($x.Sysmon.schemaversion)" }
    if ($x.Sysmon.CheckRevocation -notmatch 'False') { throw "Base CheckRevocation should be preserved as False" }
    $rgCount = $x.Sysmon.EventFiltering.RuleGroup.Count
    if ($rgCount -lt 5) { throw "Expected at least 5 RuleGroups in merged output, got $rgCount" }
    return $true
}

# Test 6: malformed XML rejection
$results += Invoke-Test -Name "Malformed XML rejection" -ScriptBlock {
    $bad = Join-Path $tempDir 'malformed.xml'
    Set-Content -LiteralPath $bad -Value '<RuleGroup name="bad"><not-closed>'
    $out = Join-Path $tempDir 'test6.xml'
    $threw = $false
    try {
        & $MergeScriptPath -BaseConfig $baseMinimal -Modules @($bad) -OutputPath $out 2>&1 | Out-Null
    } catch {
        $threw = $true
    }
    if (-not $threw) { throw "Expected merge to fail on malformed XML" }
    return $true
}

# Test 7: nonexistent module file rejection
$results += Invoke-Test -Name "Nonexistent module file rejection" -ScriptBlock {
    $out = Join-Path $tempDir 'test7.xml'
    $threw = $false
    try {
        & $MergeScriptPath -BaseConfig $baseMinimal -Modules @('does-not-exist-anywhere.xml') -OutputPath $out 2>&1 | Out-Null
    } catch {
        $threw = $true
    }
    if (-not $threw) { throw "Expected merge to fail on nonexistent module file" }
    return $true
}

# Summary
Write-Host ""
Write-Host "Test Summary"
Write-Host "============"
$passed = ($results | Where-Object { $_.Pass }).Count
$failed = ($results | Where-Object { -not $_.Pass }).Count
foreach ($r in $results) {
    $marker = if ($r.Pass) { 'PASS' } else { 'FAIL' }
    Write-Host ("  [{0}] {1}" -f $marker, $r.Name)
}
Write-Host ""
Write-Host "Total: $($results.Count)  Passed: $passed  Failed: $failed"

# Cleanup temp dir
Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue

if ($failed -gt 0) {
    exit 1
}
