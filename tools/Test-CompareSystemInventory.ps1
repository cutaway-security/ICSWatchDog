<#
.SYNOPSIS
    Test harness for Compare-SystemInventory.ps1.

.DESCRIPTION
    Runs the compare tool against fixture inventory files and validates
    the diff output across all three output formats.

.NOTES
    Requirements: PowerShell 3.0 or later. Compatible with PS Core 7+ on Linux.
#>

[CmdletBinding()]
param(
    [string]$CompareScriptPath = (Join-Path $PSScriptRoot 'Compare-SystemInventory.ps1'),
    [string]$FixturesPath      = (Join-Path (Split-Path -Parent $PSScriptRoot) 'claude-dev/test-fixtures/coverage'),
    [string]$ProjectRoot       = (Split-Path -Parent $PSScriptRoot)
)

if ($PSVersionTable.PSVersion.Major -lt 3) {
    Write-Error "This script requires PowerShell 3.0 or later. Current version: $($PSVersionTable.PSVersion)"
    exit 1
}

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $CompareScriptPath)) {
    throw "Compare script not found: $CompareScriptPath"
}
if (-not (Test-Path -LiteralPath $FixturesPath)) {
    Write-Host "Fixtures directory not found: $FixturesPath" -ForegroundColor Yellow
    Write-Host "Fixture-based tests require the claude-dev/ directory (dev branch only). Skipping." -ForegroundColor Yellow
    exit 0
}

$refInventory  = Join-Path $FixturesPath 'mock-inventory-ot-engineering.json'
$diffInventory = Join-Path $FixturesPath 'mock-inventory-ot-engineering-after.json'

if (-not (Test-Path -LiteralPath $refInventory)) {
    Write-Host "Reference fixture not found: $refInventory. Skipping." -ForegroundColor Yellow
    exit 0
}
if (-not (Test-Path -LiteralPath $diffInventory)) {
    Write-Host "Difference fixture not found: $diffInventory. Skipping." -ForegroundColor Yellow
    exit 0
}

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

# Test 1: Console output detects changes
$results += Invoke-Test -Name "Console output detects changes" -ScriptBlock {
    $output = & $CompareScriptPath -ReferencePath $refInventory -DifferencePath $diffInventory -OutputFormat Console 2>&1
    $text = $output -join "`n"
    if (-not $text.Contains('Processes')) { throw "Output missing Processes section" }
    if (-not $text.Contains('+')) { throw "Output missing added items" }
    if (-not $text.Contains('-')) { throw "Output missing removed items" }
    return $true
}

# Test 2: JSON output is valid and well-structured
$results += Invoke-Test -Name "JSON output is valid with schema envelope" -ScriptBlock {
    $output = & $CompareScriptPath -ReferencePath $refInventory -DifferencePath $diffInventory -OutputFormat JSON 2>&1
    $json = $output -join "`n" | ConvertFrom-Json
    if ($json.SchemaName -ne 'InventoryDiff') { throw "SchemaName should be InventoryDiff, got $($json.SchemaName)" }
    if ($json.SchemaVersion -ne '1.0') { throw "SchemaVersion should be 1.0, got $($json.SchemaVersion)" }
    if (-not $json.Diff) { throw "Missing Diff field" }
    if (-not $json.Diff.Processes) { throw "Missing Diff.Processes" }
    return $true
}

# Test 3: Detects added process (ScadaAgent)
$results += Invoke-Test -Name "Detects added process" -ScriptBlock {
    $output = & $CompareScriptPath -ReferencePath $refInventory -DifferencePath $diffInventory -OutputFormat JSON 2>&1
    $json = $output -join "`n" | ConvertFrom-Json
    $addedNames = @($json.Diff.Processes.Added | ForEach-Object { $_.Name })
    if ($addedNames -notcontains 'ScadaAgent') { throw "Expected ScadaAgent in added processes, got: $($addedNames -join ', ')" }
    return $true
}

# Test 4: Detects removed process (OPC.UaServer)
$results += Invoke-Test -Name "Detects removed process" -ScriptBlock {
    $output = & $CompareScriptPath -ReferencePath $refInventory -DifferencePath $diffInventory -OutputFormat JSON 2>&1
    $json = $output -join "`n" | ConvertFrom-Json
    $removedPaths = @($json.Diff.Processes.Removed | ForEach-Object { $_.Path })
    $found = $false
    foreach ($p in $removedPaths) { if ($p -match 'OPCUaServer') { $found = $true; break } }
    if (-not $found) { throw "Expected OPCUaServer in removed processes" }
    return $true
}

# Test 5: Detects port changes
$results += Invoke-Test -Name "Detects port changes" -ScriptBlock {
    $output = & $CompareScriptPath -ReferencePath $refInventory -DifferencePath $diffInventory -OutputFormat JSON 2>&1
    $json = $output -join "`n" | ConvertFrom-Json
    # Before: 135, 445, 502, 4840, 8088, 49152
    # After:  135, 445, 502, 4840, 2404, 49152
    # Added: 2404, Removed: 8088
    if ($json.Diff.ListeningPorts.Added -notcontains 2404) { throw "Expected port 2404 in added" }
    if ($json.Diff.ListeningPorts.Removed -notcontains 8088) { throw "Expected port 8088 in removed" }
    return $true
}

# Test 6: Markdown output renders correctly
$results += Invoke-Test -Name "Markdown output renders correctly" -ScriptBlock {
    $output = & $CompareScriptPath -ReferencePath $refInventory -DifferencePath $diffInventory -OutputFormat Markdown 2>&1
    $text = $output -join "`n"
    if (-not $text.Contains('# System Inventory Diff')) { throw "Missing top-level header" }
    if (-not $text.Contains('## Change Summary')) { throw "Missing Change Summary" }
    if (-not $text.Contains('| Category | Added | Removed |')) { throw "Missing summary table" }
    return $true
}

# Test 7: Identical files produce no changes
$results += Invoke-Test -Name "Identical files produce no changes" -ScriptBlock {
    $output = & $CompareScriptPath -ReferencePath $refInventory -DifferencePath $refInventory -OutputFormat Console 2>&1
    $text = $output -join "`n"
    if (-not $text.Contains('No differences found')) { throw "Expected 'No differences found' for identical files" }
    return $true
}

# Test 8: OutputPath writes to file
$results += Invoke-Test -Name "OutputPath writes report to file" -ScriptBlock {
    $tmp = [System.IO.Path]::GetTempFileName()
    try {
        & $CompareScriptPath -ReferencePath $refInventory -DifferencePath $diffInventory -OutputFormat Markdown -OutputPath $tmp | Out-Null
        if (-not (Test-Path -LiteralPath $tmp)) { throw "Output file not created" }
        $content = Get-Content -LiteralPath $tmp -Raw
        if (-not $content.Contains('# System Inventory Diff')) { throw "Output file missing expected content" }
        return $true
    } finally {
        Remove-Item -LiteralPath $tmp -ErrorAction SilentlyContinue
    }
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
