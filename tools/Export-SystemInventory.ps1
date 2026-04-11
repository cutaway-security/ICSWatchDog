<#
.SYNOPSIS
    Captures a read-only system inventory for Sysmon coverage analysis.

.DESCRIPTION
    Collects running processes, installed software (registry), listening TCP
    ports, scheduled tasks, and Windows services from the current system and
    writes the result as a JSON file conforming to the SystemInventory schema
    v1.0.

    The exported JSON can be consumed by Get-SysmonCoverage.ps1 (-InventoryPath)
    and Compare-SystemInventory.ps1 for offline analysis, cross-system
    comparison, and community submission.

    Read-only and safe for production OT systems. No system modifications.
    No network probes. No external dependencies.

.PARAMETER OutputPath
    Path where the inventory JSON file will be written. Required.

.PARAMETER Redact
    Opt-in sanitization for sharing. When specified:
    - Hostname is replaced with "REDACTED"
    - Usernames in file paths (C:\Users\<name>\...) are replaced with REDACTED
    - OS version is preserved (useful for analysis, not identifying)

    Mechanical redaction is a best-effort safety net. Always review the output
    manually before sharing publicly or submitting to the community.

.PARAMETER OutputFormat
    One of: JSON (default), Console, Markdown.
    JSON: machine-readable inventory with schema envelope (requires PS 3.0+).
    Console: human-readable summary of inventory contents.
    Markdown: structured summary for AI analysis or documentation.

.PARAMETER IncludeHostname
    Include the real hostname in the output. Off by default for privacy.
    Ignored when -Redact is specified.

.PARAMETER VerboseLogging
    Print detailed progress information.

.EXAMPLE
    .\Export-SystemInventory.ps1 -OutputPath inventory.json

    Captures system inventory to inventory.json (hostname omitted by default).

.EXAMPLE
    .\Export-SystemInventory.ps1 -OutputPath inventory.json -Redact

    Captures and sanitizes inventory for community submission.

.EXAMPLE
    .\Export-SystemInventory.ps1 -OutputFormat Console

    Prints inventory summary to screen without writing a file.

.NOTES
    Requirements: PowerShell 2.0 or later. No external modules.
    PS 2.0: Console and Markdown output only (JSON requires PS 3.0+).
    PS 3.0+: All output formats (Console, JSON, Markdown).
    Compatible with Windows PowerShell 2.0+ and PowerShell Core 7+.
    Project:  ICS Watch Dog (https://icswatchdog.com)
    Source:   https://github.com/cutaway-security/ICSWatchDog
    License:  Creative Commons Attribution 4.0
#>

[CmdletBinding()]
param(
    [string]$OutputPath,
    [switch]$Redact,
    [ValidateSet('Console', 'JSON', 'Markdown')]
    [string]$OutputFormat = 'JSON',
    [switch]$IncludeHostname,
    [switch]$VerboseLogging
)

$ErrorActionPreference = 'Stop'
$ScriptVersion = '1.0'

$Script:PSv2 = ($PSVersionTable.PSVersion.Major -lt 3)
if ($Script:PSv2 -and $OutputFormat -eq 'JSON') {
    Write-Error "JSON output requires PowerShell 3.0 or later. Current version: $($PSVersionTable.PSVersion). Use -OutputFormat Console or Markdown."
    exit 1
}

function Write-Info { param([string]$Message) Write-Host $Message }
function Write-Detail { param([string]$Message) if ($VerboseLogging) { Write-Host "  $Message" -ForegroundColor DarkGray } }

# ==============================================================================
# INVENTORY COLLECTION
# ==============================================================================

function Get-Inventory {
    Write-Detail "Inventorying running processes..."
    $processes = @()
    try {
        $processes = @(Get-Process | Where-Object { $_.Path } | ForEach-Object {
            @{ Name = $_.Name; Path = $_.Path }
        })
    } catch {
        Write-Warning "Process inventory failed: $($_.Exception.Message)"
    }

    Write-Detail "Inventorying installed software (registry)..."
    $software = @()
    $uninstallKeys = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    foreach ($k in $uninstallKeys) {
        try {
            $items = @(Get-ItemProperty -Path $k -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName } |
                ForEach-Object {
                    @{
                        DisplayName = $_.DisplayName
                        Publisher   = $_.Publisher
                        InstallPath = $_.InstallLocation
                    }
                })
            $software += $items
        } catch {
            Write-Detail "Registry enumeration of $k failed: $($_.Exception.Message)"
        }
    }

    Write-Detail "Inventorying listening TCP ports..."
    $listeningPorts = @()
    try {
        $listeningPorts = @(Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
            ForEach-Object { [int]$_.LocalPort } | Sort-Object -Unique)
    } catch {
        Write-Detail "Get-NetTCPConnection unavailable; falling back to netstat"
        try {
            $netstat = & netstat -ano 2>$null
            $listeningPorts = @($netstat | Where-Object { $_ -match '^\s+TCP\s+\S+:(\d+)\s+\S+\s+LISTENING' } |
                ForEach-Object { [int]($_ -replace '^\s+TCP\s+\S+:(\d+).*', '$1') } | Sort-Object -Unique)
        } catch {
            Write-Warning "Port inventory failed: $($_.Exception.Message)"
        }
    }

    Write-Detail "Inventorying scheduled tasks..."
    $scheduledTasks = @()
    try {
        $scheduledTasks = @(Get-ScheduledTask -ErrorAction SilentlyContinue |
            Where-Object { $_.State -ne 'Disabled' } | ForEach-Object {
                @{ Name = $_.TaskName; Path = $_.TaskPath }
            })
    } catch {
        Write-Detail "Get-ScheduledTask unavailable on this system"
    }

    Write-Detail "Inventorying Windows services..."
    $services = @()
    try {
        $services = @(Get-Service | Where-Object { $_.Status -eq 'Running' } | ForEach-Object {
            @{ Name = $_.Name; DisplayName = $_.DisplayName }
        })
    } catch {
        Write-Detail "Service inventory failed: $($_.Exception.Message)"
    }

    # Metadata
    $hostname = if ($Redact) { 'REDACTED' } elseif ($IncludeHostname) { $env:COMPUTERNAME } else { 'OMITTED' }
    $osVersion = ''
    try {
        $osVersion = [System.Environment]::OSVersion.VersionString
    } catch {
        $osVersion = 'unknown'
    }

    return @{
        SchemaName          = 'SystemInventory'
        SchemaVersion       = '1.0'
        GeneratedBy         = 'Export-SystemInventory.ps1'
        GeneratedByVersion  = $ScriptVersion
        GeneratedAt         = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
        Hostname            = $hostname
        OSVersion           = $osVersion
        Redacted            = [bool]$Redact
        Processes           = $processes
        Software            = $software
        ListeningPorts      = $listeningPorts
        ScheduledTasks      = $scheduledTasks
        Services            = $services
    }
}

# ==============================================================================
# REDACTION
# ==============================================================================

function Invoke-Redaction {
    param([hashtable]$Inventory)

    # Redact usernames in process paths
    $Inventory.Processes = @($Inventory.Processes | ForEach-Object {
        $p = $_
        if ($p.Path -match '\\Users\\[^\\]+\\') {
            $p.Path = $p.Path -replace '\\Users\\[^\\]+\\', '\Users\REDACTED\'
        }
        $p
    })

    # Redact usernames in software install paths
    $Inventory.Software = @($Inventory.Software | ForEach-Object {
        $s = $_
        if ($s.InstallPath -and $s.InstallPath -match '\\Users\\[^\\]+\\') {
            $s.InstallPath = $s.InstallPath -replace '\\Users\\[^\\]+\\', '\Users\REDACTED\'
        }
        $s
    })

    return $Inventory
}

# ==============================================================================
# OUTPUT FORMATTING
# ==============================================================================

function Format-ConsoleReport {
    param([hashtable]$Inv)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("ICS Watch Dog - System Inventory Export")
    [void]$sb.AppendLine("======================================")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine(("Hostname:    {0}" -f $Inv.Hostname))
    [void]$sb.AppendLine(("OS:          {0}" -f $Inv.OSVersion))
    [void]$sb.AppendLine(("Captured:    {0}" -f $Inv.GeneratedAt))
    [void]$sb.AppendLine(("Redacted:    {0}" -f $Inv.Redacted))
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine(("Processes:       {0}" -f $Inv.Processes.Count))
    [void]$sb.AppendLine(("Software:        {0}" -f $Inv.Software.Count))
    [void]$sb.AppendLine(("Listening Ports:  {0}" -f $Inv.ListeningPorts.Count))
    [void]$sb.AppendLine(("Scheduled Tasks: {0}" -f $Inv.ScheduledTasks.Count))
    [void]$sb.AppendLine(("Services:        {0}" -f $Inv.Services.Count))
    [void]$sb.AppendLine("")
    if ($Inv.Processes.Count -gt 0) {
        [void]$sb.AppendLine("Running Processes:")
        foreach ($p in $Inv.Processes) {
            [void]$sb.AppendLine(("  - {0,-30} {1}" -f $p.Name, $p.Path))
        }
        [void]$sb.AppendLine("")
    }
    if ($Inv.ListeningPorts.Count -gt 0) {
        [void]$sb.AppendLine(("Listening TCP Ports: {0}" -f ($Inv.ListeningPorts -join ', ')))
        [void]$sb.AppendLine("")
    }
    return $sb.ToString()
}

function Format-MarkdownReport {
    param([hashtable]$Inv)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("# System Inventory Export")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine(("**Tool**: ICS Watch Dog Export-SystemInventory v{0}" -f $ScriptVersion))
    [void]$sb.AppendLine(("**Hostname**: {0}" -f $Inv.Hostname))
    [void]$sb.AppendLine(("**OS**: {0}" -f $Inv.OSVersion))
    [void]$sb.AppendLine(("**Captured**: {0}" -f $Inv.GeneratedAt))
    [void]$sb.AppendLine(("**Redacted**: {0}" -f $Inv.Redacted))
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("## Summary")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("| Category | Count |")
    [void]$sb.AppendLine("|----------|-------|")
    [void]$sb.AppendLine(("| Processes | {0} |" -f $Inv.Processes.Count))
    [void]$sb.AppendLine(("| Software | {0} |" -f $Inv.Software.Count))
    [void]$sb.AppendLine(("| Listening Ports | {0} |" -f $Inv.ListeningPorts.Count))
    [void]$sb.AppendLine(("| Scheduled Tasks | {0} |" -f $Inv.ScheduledTasks.Count))
    [void]$sb.AppendLine(("| Services | {0} |" -f $Inv.Services.Count))
    [void]$sb.AppendLine("")
    if ($Inv.Processes.Count -gt 0) {
        [void]$sb.AppendLine("## Processes")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("| Name | Path |")
        [void]$sb.AppendLine("|------|------|")
        foreach ($p in $Inv.Processes) {
            [void]$sb.AppendLine(("| {0} | ``{1}`` |" -f $p.Name, $p.Path))
        }
        [void]$sb.AppendLine("")
    }
    if ($Inv.Software.Count -gt 0) {
        [void]$sb.AppendLine("## Installed Software")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("| Name | Publisher |")
        [void]$sb.AppendLine("|------|-----------|")
        foreach ($s in $Inv.Software) {
            [void]$sb.AppendLine(("| {0} | {1} |" -f $s.DisplayName, $s.Publisher))
        }
        [void]$sb.AppendLine("")
    }
    if ($Inv.ListeningPorts.Count -gt 0) {
        [void]$sb.AppendLine(("## Listening TCP Ports"))
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine(("{0}" -f ($Inv.ListeningPorts -join ', ')))
        [void]$sb.AppendLine("")
    }
    if ($Inv.Services.Count -gt 0) {
        [void]$sb.AppendLine("## Running Services")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("| Name | Display Name |")
        [void]$sb.AppendLine("|------|--------------|")
        foreach ($svc in $Inv.Services) {
            [void]$sb.AppendLine(("| {0} | {1} |" -f $svc.Name, $svc.DisplayName))
        }
        [void]$sb.AppendLine("")
    }
    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine("Generated by [ICS Watch Dog Export-SystemInventory](https://icswatchdog.com/coverage-assessment/)")
    return $sb.ToString()
}

function Format-JsonReport {
    param([hashtable]$Inv)
    # Convert hashtable arrays to proper JSON-serializable structure
    $report = @{
        SchemaName          = $Inv.SchemaName
        SchemaVersion       = $Inv.SchemaVersion
        GeneratedBy         = $Inv.GeneratedBy
        GeneratedByVersion  = $Inv.GeneratedByVersion
        GeneratedAt         = $Inv.GeneratedAt
        Hostname            = $Inv.Hostname
        OSVersion           = $Inv.OSVersion
        Redacted            = $Inv.Redacted
        Processes           = @($Inv.Processes | ForEach-Object { New-Object PSObject -Property $_ })
        Software            = @($Inv.Software | ForEach-Object { New-Object PSObject -Property $_ })
        ListeningPorts      = $Inv.ListeningPorts
        ScheduledTasks      = @($Inv.ScheduledTasks | ForEach-Object { New-Object PSObject -Property $_ })
        Services            = @($Inv.Services | ForEach-Object { New-Object PSObject -Property $_ })
    }
    return ($report | ConvertTo-Json -Depth 10)
}

# ==============================================================================
# MAIN
# ==============================================================================

if ($OutputFormat -eq 'JSON' -and -not $OutputPath) {
    # JSON to stdout is valid (piping)
}

Write-Info "Collecting system inventory..."
$inventory = Get-Inventory

if ($Redact) {
    Write-Detail "Applying redaction..."
    $inventory = Invoke-Redaction -Inventory $inventory
}

$report = switch ($OutputFormat) {
    'JSON'     { Format-JsonReport -Inv $inventory }
    'Markdown' { Format-MarkdownReport -Inv $inventory }
    default    { Format-ConsoleReport -Inv $inventory }
}

if ($OutputPath) {
    Set-Content -LiteralPath $OutputPath -Value $report
    Write-Info "Inventory written to: $OutputPath"
} else {
    Write-Output $report
}
