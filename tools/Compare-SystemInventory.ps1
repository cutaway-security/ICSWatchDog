<#
.SYNOPSIS
    Compares two system inventory JSON files and reports differences.

.DESCRIPTION
    Reads two SystemInventory JSON files (produced by Export-SystemInventory.ps1)
    and reports what was added and removed between them. Useful for:
    - Tracking changes after a patch or software install
    - Comparing two different hosts (e.g., lab vs. production)
    - Reviewing community-submitted inventories

    Reports changes only (not unchanged items). No system modifications.

.PARAMETER ReferencePath
    Path to the baseline inventory JSON (the "before" or "expected" state).

.PARAMETER DifferencePath
    Path to the comparison inventory JSON (the "after" or "actual" state).

.PARAMETER OutputFormat
    One of: Console (default), JSON, Markdown.

.PARAMETER OutputPath
    Optional file path to write the diff report. If omitted, output goes to stdout.

.PARAMETER VerboseLogging
    Print detailed progress information.

.EXAMPLE
    .\Compare-SystemInventory.ps1 -ReferencePath before.json -DifferencePath after.json

    Console diff of two inventory captures.

.EXAMPLE
    .\Compare-SystemInventory.ps1 -ReferencePath host-a.json -DifferencePath host-b.json -OutputFormat Markdown

    Markdown diff for documentation or AI analysis.

.NOTES
    Requirements: PowerShell 3.0 or later (ConvertFrom-Json required for both inputs).
    No external modules. Console and Markdown output use StringBuilder (PS 2.0 compatible
    internally) but the script itself requires PS 3.0+ for JSON parsing.
    Project:  ICS Watch Dog (https://icswatchdog.com)
    Source:   https://github.com/cutaway-security/ICSWatchDog
    License:  Creative Commons Attribution 4.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({
        if (-not (Test-Path -LiteralPath $_)) { throw "Reference inventory not found: $_" }
        $true
    })]
    [string]$ReferencePath,

    [Parameter(Mandatory=$true)]
    [ValidateScript({
        if (-not (Test-Path -LiteralPath $_)) { throw "Difference inventory not found: $_" }
        $true
    })]
    [string]$DifferencePath,

    [ValidateSet('Console', 'JSON', 'Markdown')]
    [string]$OutputFormat = 'Console',

    [string]$OutputPath,
    [switch]$VerboseLogging
)

if ($PSVersionTable.PSVersion.Major -lt 3) {
    Write-Error "This script requires PowerShell 3.0 or later (ConvertFrom-Json). Current version: $($PSVersionTable.PSVersion)"
    exit 1
}

$ErrorActionPreference = 'Stop'
$ScriptVersion = '1.0'

function Write-Info { param([string]$Message) Write-Host $Message }
function Write-Detail { param([string]$Message) if ($VerboseLogging) { Write-Host "  $Message" -ForegroundColor DarkGray } }

# ==============================================================================
# SCHEMA VALIDATION
# ==============================================================================

function Test-SchemaVersion {
    param([PSCustomObject]$Data, [string]$FilePath)
    if (-not $Data.SchemaName) {
        Write-Warning "File $FilePath is missing SchemaName field. Proceeding with best-effort parsing."
        return
    }
    if ($Data.SchemaName -ne 'SystemInventory') {
        throw "Schema mismatch in $FilePath. Expected SchemaName 'SystemInventory', got '$($Data.SchemaName)'."
    }
    if ($Data.SchemaVersion) {
        $major = ($Data.SchemaVersion -split '\.')[0]
        if ($major -ne '1') {
            throw "Schema major version mismatch in $FilePath. Expected major version 1, got '$major'."
        }
    }
}

# ==============================================================================
# DIFF COMPUTATION
# ==============================================================================

function Get-InventoryDiff {
    param([PSCustomObject]$Reference, [PSCustomObject]$Difference)

    # Process diff by Path (unique identifier)
    $refProcs = @{}
    if ($Reference.Processes) {
        foreach ($p in $Reference.Processes) { $key = if ($p.Path) { $p.Path } else { $p.Name }; $refProcs[$key] = $p }
    }
    $diffProcs = @{}
    if ($Difference.Processes) {
        foreach ($p in $Difference.Processes) { $key = if ($p.Path) { $p.Path } else { $p.Name }; $diffProcs[$key] = $p }
    }
    $addedProcs = @($diffProcs.Keys | Where-Object { -not $refProcs.ContainsKey($_) } | ForEach-Object { $diffProcs[$_] })
    $removedProcs = @($refProcs.Keys | Where-Object { -not $diffProcs.ContainsKey($_) } | ForEach-Object { $refProcs[$_] })

    # Software diff by DisplayName + Publisher
    $refSw = @{}
    if ($Reference.Software) {
        foreach ($s in $Reference.Software) { $key = "$($s.DisplayName)|$($s.Publisher)"; $refSw[$key] = $s }
    }
    $diffSw = @{}
    if ($Difference.Software) {
        foreach ($s in $Difference.Software) { $key = "$($s.DisplayName)|$($s.Publisher)"; $diffSw[$key] = $s }
    }
    $addedSw = @($diffSw.Keys | Where-Object { -not $refSw.ContainsKey($_) } | ForEach-Object { $diffSw[$_] })
    $removedSw = @($refSw.Keys | Where-Object { -not $diffSw.ContainsKey($_) } | ForEach-Object { $refSw[$_] })

    # Port diff
    $refPorts = @{}
    if ($Reference.ListeningPorts) {
        foreach ($port in $Reference.ListeningPorts) { $refPorts[[int]$port] = $true }
    }
    $diffPorts = @{}
    if ($Difference.ListeningPorts) {
        foreach ($port in $Difference.ListeningPorts) { $diffPorts[[int]$port] = $true }
    }
    $addedPorts = @($diffPorts.Keys | Where-Object { -not $refPorts.ContainsKey($_) } | Sort-Object)
    $removedPorts = @($refPorts.Keys | Where-Object { -not $diffPorts.ContainsKey($_) } | Sort-Object)

    # Service diff by Name
    $refSvcs = @{}
    if ($Reference.Services) {
        foreach ($svc in $Reference.Services) { $refSvcs[$svc.Name] = $svc }
    }
    $diffSvcs = @{}
    if ($Difference.Services) {
        foreach ($svc in $Difference.Services) { $diffSvcs[$svc.Name] = $svc }
    }
    $addedSvcs = @($diffSvcs.Keys | Where-Object { -not $refSvcs.ContainsKey($_) } | ForEach-Object { $diffSvcs[$_] })
    $removedSvcs = @($refSvcs.Keys | Where-Object { -not $diffSvcs.ContainsKey($_) } | ForEach-Object { $refSvcs[$_] })

    # Scheduled task diff by Name + Path
    $refTasks = @{}
    if ($Reference.ScheduledTasks) {
        foreach ($t in $Reference.ScheduledTasks) { $refTasks["$($t.Path)$($t.Name)"] = $t }
    }
    $diffTasks = @{}
    if ($Difference.ScheduledTasks) {
        foreach ($t in $Difference.ScheduledTasks) { $diffTasks["$($t.Path)$($t.Name)"] = $t }
    }
    $addedTasks = @($diffTasks.Keys | Where-Object { -not $refTasks.ContainsKey($_) } | ForEach-Object { $diffTasks[$_] })
    $removedTasks = @($refTasks.Keys | Where-Object { -not $diffTasks.ContainsKey($_) } | ForEach-Object { $refTasks[$_] })

    return @{
        Processes      = @{ Added = $addedProcs;  Removed = $removedProcs }
        Software       = @{ Added = $addedSw;     Removed = $removedSw }
        ListeningPorts = @{ Added = $addedPorts;   Removed = $removedPorts }
        Services       = @{ Added = $addedSvcs;    Removed = $removedSvcs }
        ScheduledTasks = @{ Added = $addedTasks;   Removed = $removedTasks }
    }
}

function Test-HasChanges {
    param([hashtable]$Diff)
    foreach ($cat in $Diff.Keys) {
        if ($Diff[$cat].Added.Count -gt 0 -or $Diff[$cat].Removed.Count -gt 0) { return $true }
    }
    return $false
}

# ==============================================================================
# OUTPUT FORMATTING
# ==============================================================================

function Format-ConsoleReport {
    param([hashtable]$Diff, [string]$RefPath, [string]$DiffPath, [bool]$HasChanges)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("ICS Watch Dog - System Inventory Diff")
    [void]$sb.AppendLine("=====================================")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("Reference:  $RefPath")
    [void]$sb.AppendLine("Compared:   $DiffPath")
    [void]$sb.AppendLine("")

    if (-not $HasChanges) {
        [void]$sb.AppendLine("No differences found.")
        return $sb.ToString()
    }

    $categories = @(
        @{ Key = 'Processes';      Label = 'Processes';       NameField = 'Name'; DetailField = 'Path' },
        @{ Key = 'Software';       Label = 'Software';        NameField = 'DisplayName'; DetailField = 'Publisher' },
        @{ Key = 'ListeningPorts'; Label = 'Listening Ports';  NameField = $null; DetailField = $null },
        @{ Key = 'Services';       Label = 'Services';        NameField = 'Name'; DetailField = 'DisplayName' },
        @{ Key = 'ScheduledTasks'; Label = 'Scheduled Tasks'; NameField = 'Name'; DetailField = 'Path' }
    )

    foreach ($cat in $categories) {
        $added = $Diff[$cat.Key].Added
        $removed = $Diff[$cat.Key].Removed
        if ($added.Count -eq 0 -and $removed.Count -eq 0) { continue }

        [void]$sb.AppendLine("$($cat.Label)")
        [void]$sb.AppendLine(("-" * $cat.Label.Length))
        if ($cat.Key -eq 'ListeningPorts') {
            if ($added.Count -gt 0) { [void]$sb.AppendLine("  + Added:   $($added -join ', ')") }
            if ($removed.Count -gt 0) { [void]$sb.AppendLine("  - Removed: $($removed -join ', ')") }
        } else {
            foreach ($item in $added) {
                $name = $item.($cat.NameField)
                $detail = if ($cat.DetailField) { $item.($cat.DetailField) } else { '' }
                [void]$sb.AppendLine(("  + {0,-35} {1}" -f $name, $detail))
            }
            foreach ($item in $removed) {
                $name = $item.($cat.NameField)
                $detail = if ($cat.DetailField) { $item.($cat.DetailField) } else { '' }
                [void]$sb.AppendLine(("  - {0,-35} {1}" -f $name, $detail))
            }
        }
        [void]$sb.AppendLine("")
    }
    return $sb.ToString()
}

function Format-MarkdownReport {
    param([hashtable]$Diff, [string]$RefPath, [string]$DiffPath, [bool]$HasChanges)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("# System Inventory Diff")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine(("**Tool**: ICS Watch Dog Compare-SystemInventory v{0}" -f $ScriptVersion))
    [void]$sb.AppendLine(("**Reference**: ``{0}``" -f $RefPath))
    [void]$sb.AppendLine(("**Compared**: ``{0}``" -f $DiffPath))
    [void]$sb.AppendLine(("**Timestamp**: {0}" -f (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')))
    [void]$sb.AppendLine("")

    if (-not $HasChanges) {
        [void]$sb.AppendLine("No differences found.")
        return $sb.ToString()
    }

    [void]$sb.AppendLine("## Change Summary")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("| Category | Added | Removed |")
    [void]$sb.AppendLine("|----------|-------|---------|")
    foreach ($key in @('Processes', 'Software', 'ListeningPorts', 'Services', 'ScheduledTasks')) {
        [void]$sb.AppendLine(("| {0} | {1} | {2} |" -f $key, $Diff[$key].Added.Count, $Diff[$key].Removed.Count))
    }
    [void]$sb.AppendLine("")

    # Detail sections for categories with changes
    if ($Diff.Processes.Added.Count -gt 0 -or $Diff.Processes.Removed.Count -gt 0) {
        [void]$sb.AppendLine("## Processes")
        [void]$sb.AppendLine("")
        foreach ($p in $Diff.Processes.Added) { [void]$sb.AppendLine(("- **+** ``{0}`` ({1})" -f $p.Name, $p.Path)) }
        foreach ($p in $Diff.Processes.Removed) { [void]$sb.AppendLine(("- **-** ``{0}`` ({1})" -f $p.Name, $p.Path)) }
        [void]$sb.AppendLine("")
    }
    if ($Diff.Software.Added.Count -gt 0 -or $Diff.Software.Removed.Count -gt 0) {
        [void]$sb.AppendLine("## Software")
        [void]$sb.AppendLine("")
        foreach ($s in $Diff.Software.Added) { [void]$sb.AppendLine(("- **+** {0} ({1})" -f $s.DisplayName, $s.Publisher)) }
        foreach ($s in $Diff.Software.Removed) { [void]$sb.AppendLine(("- **-** {0} ({1})" -f $s.DisplayName, $s.Publisher)) }
        [void]$sb.AppendLine("")
    }
    if ($Diff.ListeningPorts.Added.Count -gt 0 -or $Diff.ListeningPorts.Removed.Count -gt 0) {
        [void]$sb.AppendLine("## Listening Ports")
        [void]$sb.AppendLine("")
        if ($Diff.ListeningPorts.Added.Count -gt 0) { [void]$sb.AppendLine(("- **+** Added: {0}" -f ($Diff.ListeningPorts.Added -join ', '))) }
        if ($Diff.ListeningPorts.Removed.Count -gt 0) { [void]$sb.AppendLine(("- **-** Removed: {0}" -f ($Diff.ListeningPorts.Removed -join ', '))) }
        [void]$sb.AppendLine("")
    }
    if ($Diff.Services.Added.Count -gt 0 -or $Diff.Services.Removed.Count -gt 0) {
        [void]$sb.AppendLine("## Services")
        [void]$sb.AppendLine("")
        foreach ($svc in $Diff.Services.Added) { [void]$sb.AppendLine(("- **+** {0} ({1})" -f $svc.Name, $svc.DisplayName)) }
        foreach ($svc in $Diff.Services.Removed) { [void]$sb.AppendLine(("- **-** {0} ({1})" -f $svc.Name, $svc.DisplayName)) }
        [void]$sb.AppendLine("")
    }
    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine("Generated by [ICS Watch Dog Compare-SystemInventory](https://icswatchdog.com/coverage-assessment/)")
    return $sb.ToString()
}

function Format-JsonReport {
    param([hashtable]$Diff, [string]$RefPath, [string]$DiffPath)
    $report = @{
        SchemaName          = 'InventoryDiff'
        SchemaVersion       = '1.0'
        GeneratedBy         = 'Compare-SystemInventory.ps1'
        GeneratedByVersion  = $ScriptVersion
        GeneratedAt         = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
        ReferencePath       = $RefPath
        DifferencePath      = $DiffPath
        Diff                = @{
            Processes      = @{ Added = $Diff.Processes.Added;      Removed = $Diff.Processes.Removed }
            Software       = @{ Added = $Diff.Software.Added;       Removed = $Diff.Software.Removed }
            ListeningPorts = @{ Added = $Diff.ListeningPorts.Added;  Removed = $Diff.ListeningPorts.Removed }
            Services       = @{ Added = $Diff.Services.Added;        Removed = $Diff.Services.Removed }
            ScheduledTasks = @{ Added = $Diff.ScheduledTasks.Added;  Removed = $Diff.ScheduledTasks.Removed }
        }
    }
    return ($report | ConvertTo-Json -Depth 10)
}

# ==============================================================================
# MAIN
# ==============================================================================

Write-Detail "Loading reference: $ReferencePath"
$refJson = [System.IO.File]::ReadAllText($ReferencePath)
$refData = $refJson | ConvertFrom-Json
Test-SchemaVersion -Data $refData -FilePath $ReferencePath

Write-Detail "Loading difference: $DifferencePath"
$diffJson = [System.IO.File]::ReadAllText($DifferencePath)
$diffData = $diffJson | ConvertFrom-Json
Test-SchemaVersion -Data $diffData -FilePath $DifferencePath

Write-Detail "Computing diff..."
$diff = Get-InventoryDiff -Reference $refData -Difference $diffData
$hasChanges = Test-HasChanges -Diff $diff

$report = switch ($OutputFormat) {
    'JSON'     { Format-JsonReport -Diff $diff -RefPath $ReferencePath -DiffPath $DifferencePath }
    'Markdown' { Format-MarkdownReport -Diff $diff -RefPath $ReferencePath -DiffPath $DifferencePath -HasChanges $hasChanges }
    default    { Format-ConsoleReport -Diff $diff -RefPath $ReferencePath -DiffPath $DifferencePath -HasChanges $hasChanges }
}

if ($OutputPath) {
    Set-Content -LiteralPath $OutputPath -Value $report
    Write-Info "Diff report written to: $OutputPath"
} else {
    Write-Output $report
}
