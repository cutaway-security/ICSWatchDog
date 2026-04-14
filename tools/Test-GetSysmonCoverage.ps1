# Copyright (c) 2024-2026 Cutaway Security, LLC
# License: CC BY-SA 4.0 | Commercial licensing available (info@cutawaysecurity.com)
# Project: https://github.com/cutaway-security/ICSWatchDog

<#
.SYNOPSIS
    Test harness for Get-SysmonCoverage.ps1.

.DESCRIPTION
    Runs the coverage tool against mock system inventory data and validates the
    coverage metrics and gap reports.

.NOTES
    Requirements: PowerShell 3.0 or later. Compatible with PS Core 7+ on Linux.
#>

[CmdletBinding()]
param(
    [string]$CoverageScriptPath = (Join-Path $PSScriptRoot 'Get-SysmonCoverage.ps1'),
    [string]$FixturesPath       = (Join-Path (Split-Path -Parent $PSScriptRoot) 'claude-dev/test-fixtures/coverage'),
    [string]$ProjectRoot        = (Split-Path -Parent $PSScriptRoot)
)

if ($PSVersionTable.PSVersion.Major -lt 3) {
    Write-Error "This script requires PowerShell 3.0 or later. Current version: $($PSVersionTable.PSVersion)"
    exit 1
}

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $CoverageScriptPath)) {
    throw "Coverage script not found: $CoverageScriptPath"
}

# Fixtures live under claude-dev/test-fixtures/ (dev-only, stripped from releases).
# Skip cleanly if absent (e.g., running from a release tarball).
if (-not (Test-Path -LiteralPath $FixturesPath)) {
    Write-Host "Fixtures directory not found: $FixturesPath" -ForegroundColor Yellow
    Write-Host "Fixture-based tests require the claude-dev/ directory (dev branch only). Skipping." -ForegroundColor Yellow
    exit 0
}

$inventoryFixture = Join-Path $FixturesPath 'mock-inventory-ot-engineering.json'
$baseConfig       = Join-Path $ProjectRoot 'sysmon-configs/sysmonconfig-baseline-ot.xml'

if (-not (Test-Path -LiteralPath $inventoryFixture)) {
    Write-Host "Inventory fixture not found: $inventoryFixture. Skipping." -ForegroundColor Yellow
    exit 0
}
if (-not (Test-Path -LiteralPath $baseConfig)) { throw "Base config not found: $baseConfig" }

$results = @()

function Invoke-Test {
    param([string]$Name, [scriptblock]$ScriptBlock)
    Write-Host ""
    Write-Host "TEST: $Name" -ForegroundColor Cyan
    try {
        $result = & $ScriptBlock
        if ($result -eq $false) {
            Write-Host "  FAIL: $Name" -ForegroundColor Red
            return [pscustomobject]@{ Name = $Name; Pass = $false; Error = '' }
        }
        Write-Host "  PASS: $Name" -ForegroundColor Green
        return [pscustomobject]@{ Name = $Name; Pass = $true; Error = '' }
    } catch {
        Write-Host "  FAIL: $Name" -ForegroundColor Red
        Write-Host "    $($_.Exception.Message)" -ForegroundColor Red
        return [pscustomobject]@{ Name = $Name; Pass = $false; Error = $_.Exception.Message }
    }
}

# Test 1: Console output runs and returns non-empty report
$results += Invoke-Test -Name "Console output with mock inventory" -ScriptBlock {
    $output = & $CoverageScriptPath -ConfigPath $baseConfig -InventoryPath $inventoryFixture -OutputFormat Console 2>&1
    $reportText = $output -join "`n"
    if (-not $reportText.Contains('Process Coverage')) { throw "Output missing Process Coverage section" }
    if (-not $reportText.Contains('OT Software Coverage')) { throw "Output missing OT Software Coverage section" }
    if (-not $reportText.Contains('Industrial Port Coverage')) { throw "Output missing Industrial Port Coverage section" }
    if (-not $reportText.Contains('ATT&CK Technique Coverage')) { throw "Output missing ATT&CK Technique Coverage section" }
    return $true
}

# Test 2: JSON output is valid JSON with expected structure
$results += Invoke-Test -Name "JSON output is valid and well-structured" -ScriptBlock {
    $output = & $CoverageScriptPath -ConfigPath $baseConfig -InventoryPath $inventoryFixture -OutputFormat JSON 2>&1
    $json = $output -join "`n" | ConvertFrom-Json
    if (-not $json.Coverage) { throw "JSON missing Coverage field" }
    if (-not $json.Coverage.ProcessCoverage) { throw "JSON missing ProcessCoverage" }
    if (-not $json.Coverage.SoftwareCoverage) { throw "JSON missing SoftwareCoverage" }
    if (-not $json.Coverage.PortCoverage) { throw "JSON missing PortCoverage" }
    if (-not $json.Coverage.AttackCoverage) { throw "JSON missing AttackCoverage" }
    return $true
}

# Test 3: Process coverage detects unmatched processes
$results += Invoke-Test -Name "Process coverage identifies unmonitored processes" -ScriptBlock {
    $output = & $CoverageScriptPath -ConfigPath $baseConfig -InventoryPath $inventoryFixture -OutputFormat JSON 2>&1
    $json = $output -join "`n" | ConvertFrom-Json
    # Mock inventory has 8 processes; baseline-ot doesn't include OT vendor binaries
    # so most should be unmatched
    if ($json.Coverage.ProcessCoverage.Total -ne 8) {
        throw "Expected 8 processes, got $($json.Coverage.ProcessCoverage.Total)"
    }
    if (-not $json.Coverage.ProcessCoverage.UnmatchedProcesses) {
        throw "Expected unmatched processes list"
    }
    return $true
}

# Test 4: OT software detection identifies known vendors
$results += Invoke-Test -Name "OT software detection identifies vendor software" -ScriptBlock {
    $output = & $CoverageScriptPath -ConfigPath $baseConfig -InventoryPath $inventoryFixture -OutputFormat JSON 2>&1
    $json = $output -join "`n" | ConvertFrom-Json
    # Mock has 6 software; 5 OT-relevant (Siemens, Rockwell, Ignition, CODESYS, Kepware), 1 not (Office)
    if ($json.Coverage.SoftwareCoverage.TotalOTRelevant -lt 4) {
        throw "Expected at least 4 OT-relevant software, got $($json.Coverage.SoftwareCoverage.TotalOTRelevant)"
    }
    return $true
}

# Test 5: Industrial port coverage identifies industrial ports
$results += Invoke-Test -Name "Industrial port coverage identifies listening industrial ports" -ScriptBlock {
    $output = & $CoverageScriptPath -ConfigPath $baseConfig -InventoryPath $inventoryFixture -OutputFormat JSON 2>&1
    $json = $output -join "`n" | ConvertFrom-Json
    # Mock has 502 (Modbus), 4840 (OPC-UA), 8088 (Ignition) as industrial; 135, 445, 49152 as not
    if ($json.Coverage.PortCoverage.TotalIndustrial -ne 3) {
        throw "Expected 3 industrial ports listening, got $($json.Coverage.PortCoverage.TotalIndustrial)"
    }
    return $true
}

# Test 6: Additional modules increase port coverage
$results += Invoke-Test -Name "Additional protocol modules increase port coverage" -ScriptBlock {
    $modbus = Join-Path $ProjectRoot 'sysmon-configs/modules/protocol/modbus-tcp.xml'
    $opcua  = Join-Path $ProjectRoot 'sysmon-configs/modules/protocol/opc-ua.xml'
    $ignition = Join-Path $ProjectRoot 'sysmon-configs/modules/vendor-ot/ignition-gateway.xml'

    $baseOutput = & $CoverageScriptPath -ConfigPath $baseConfig -InventoryPath $inventoryFixture -OutputFormat JSON 2>&1
    $baseJson = $baseOutput -join "`n" | ConvertFrom-Json
    $baseCovered = $baseJson.Coverage.PortCoverage.Covered

    $withModulesOutput = & $CoverageScriptPath -ConfigPath $baseConfig -AdditionalModules @($modbus, $opcua, $ignition) -InventoryPath $inventoryFixture -OutputFormat JSON 2>&1
    $withModulesJson = $withModulesOutput -join "`n" | ConvertFrom-Json
    $withModulesCovered = $withModulesJson.Coverage.PortCoverage.Covered

    if ($withModulesCovered -le $baseCovered) {
        throw "Adding protocol modules should increase covered port count: was $baseCovered, now $withModulesCovered"
    }
    return $true
}

# Test 7: ATT&CK techniques detected
$results += Invoke-Test -Name "ATT&CK technique extraction from rules" -ScriptBlock {
    $output = & $CoverageScriptPath -ConfigPath $baseConfig -InventoryPath $inventoryFixture -OutputFormat JSON 2>&1
    $json = $output -join "`n" | ConvertFrom-Json
    if ($json.Coverage.AttackCoverage.DistinctTechniques -lt 10) {
        throw "Expected at least 10 ATT&CK techniques in baseline-ot, got $($json.Coverage.AttackCoverage.DistinctTechniques)"
    }
    return $true
}

# Test 8: Markdown output renders properly
$results += Invoke-Test -Name "Markdown output renders correctly" -ScriptBlock {
    $output = & $CoverageScriptPath -ConfigPath $baseConfig -InventoryPath $inventoryFixture -OutputFormat Markdown 2>&1
    $text = $output -join "`n"
    if (-not $text.Contains('# Sysmon Coverage Report')) { throw "Markdown missing top-level header" }
    if (-not $text.Contains('## Coverage Summary')) { throw "Markdown missing Coverage Summary section" }
    if (-not $text.Contains('| Metric | Value |')) { throw "Markdown missing summary table" }
    return $true
}

# Test 9: OutputPath writes to file
$results += Invoke-Test -Name "OutputPath writes report to file" -ScriptBlock {
    $tmp = [System.IO.Path]::GetTempFileName()
    try {
        & $CoverageScriptPath -ConfigPath $baseConfig -InventoryPath $inventoryFixture -OutputFormat Markdown -OutputPath $tmp | Out-Null
        if (-not (Test-Path -LiteralPath $tmp)) { throw "Output file not created" }
        $content = Get-Content -LiteralPath $tmp -Raw
        if (-not $content.Contains('# Sysmon Coverage Report')) { throw "Output file missing expected content" }
        return $true
    } finally {
        Remove-Item -LiteralPath $tmp -ErrorAction SilentlyContinue
    }
}

# Test 10: Nonexistent config rejection
$results += Invoke-Test -Name "Nonexistent config rejection" -ScriptBlock {
    $threw = $false
    try {
        & $CoverageScriptPath -ConfigPath '/nonexistent/path/to/config.xml' -InventoryPath $inventoryFixture 2>&1 | Out-Null
    } catch {
        $threw = $true
    }
    if (-not $threw) { throw "Expected exception for nonexistent config" }
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

if ($failed -gt 0) { exit 1 }
