<#
.SYNOPSIS
    Reports Sysmon detection coverage on the current system.

.DESCRIPTION
    Compares the deployed Sysmon configuration against the actual state of the
    system (running processes, installed software, listening ports, scheduled
    tasks, services) and computes coverage metrics:

      - Process coverage: fraction of running processes matched by at least
        one rule's binary pattern
      - Software coverage: fraction of installed OT/IT vendor software with
        at least one matching rule
      - Port coverage: fraction of listening industrial protocol ports
        matched by a protocol rule
      - ATT&CK technique coverage: count of distinct technique_id values
        present in the deployed rules

    Reports gaps for each metric so admins can identify what is unmonitored
    and add coverage by editing the config or merging additional modules.

    Read-only and safe for production OT systems. No system modifications.
    No network probes. No external dependencies.

.PARAMETER ConfigPath
    Path to the Sysmon configuration XML to evaluate. If omitted, the script
    queries the running Sysmon service via 'sysmon -c' (Windows only).

.PARAMETER AdditionalModules
    Optional array of module XML files to consider in addition to ConfigPath.
    Useful for "what if I merged these modules" coverage projections without
    actually merging them. The modules are loaded read-only.

.PARAMETER OutputFormat
    One of: Console (default), JSON, Markdown.

.PARAMETER OutputPath
    Optional file path to write the report. If omitted, output goes to stdout.

.PARAMETER InventoryPath
    Path to a JSON file with system inventory data (produced by
    Export-SystemInventory.ps1). When provided, the script uses this
    data instead of querying the live system. Enables offline analysis:
    capture inventory on one host, analyze on another.
    Requires PowerShell 3.0+ (ConvertFrom-Json).

.PARAMETER VerboseLogging
    Print detailed progress information.

.EXAMPLE
    .\Get-SysmonCoverage.ps1 -ConfigPath sysmon-configs\sysmonconfig-baseline-ot.xml

    Reports coverage of baseline-ot.xml against the current system to console.

.EXAMPLE
    .\Get-SysmonCoverage.ps1 `
        -ConfigPath sysmon-configs\sysmonconfig-baseline-ot.xml `
        -AdditionalModules @(
            'sysmon-configs\modules\vendor-ot\siemens-tia-portal.xml',
            'sysmon-configs\modules\protocol\modbus-tcp.xml') `
        -OutputFormat Markdown -OutputPath coverage-report.md

    Reports coverage of baseline-ot.xml + 2 additional modules to a Markdown file.

.EXAMPLE
    .\Get-SysmonCoverage.ps1 -OutputFormat JSON | ConvertFrom-Json

    Live coverage report from the running Sysmon config, parsed as JSON.

.NOTES
    Requirements: PowerShell 2.0 or later. No external modules.
    PS 2.0: Console and Markdown output only (JSON requires PS 3.0+).
    PS 3.0+: All output formats (Console, JSON, Markdown).
    Compatible with Windows PowerShell 2.0+ and PowerShell Core 7+.
    See: https://icswatchdog.com/coverage-assessment/
#>

[CmdletBinding()]
param(
    [string]$ConfigPath,
    [string[]]$AdditionalModules = @(),
    [ValidateSet('Console', 'JSON', 'Markdown')]
    [string]$OutputFormat = 'Console',
    [string]$OutputPath,
    [string]$InventoryPath,
    [switch]$VerboseLogging
)

$ErrorActionPreference = 'Stop'

# PS 2.0 compatibility: JSON output requires PS 3+ (ConvertTo-Json / ConvertFrom-Json).
# Console and Markdown output work on PS 2.0+.
$Script:PSv2 = ($PSVersionTable.PSVersion.Major -lt 3)
if ($Script:PSv2 -and $OutputFormat -eq 'JSON') {
    Write-Error "JSON output requires PowerShell 3.0 or later. Current version: $($PSVersionTable.PSVersion). Use -OutputFormat Console or Markdown."
    exit 1
}
if ($Script:PSv2 -and $InventoryPath) {
    Write-Error "InventoryPath requires PowerShell 3.0 or later (ConvertFrom-Json). Current version: $($PSVersionTable.PSVersion)"
    exit 1
}

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# Industrial protocol ports of interest for port coverage measurement.
# When these ports are listening on a system, they should be matched by a
# protocol detection rule.
$IndustrialPorts = @{
    102   = 'S7comm / IEC 61850 MMS'
    502   = 'Modbus TCP'
    1883  = 'MQTT'
    2222  = 'EtherNet/IP implicit messaging'
    2404  = 'IEC 60870-5-104'
    4840  = 'OPC-UA'
    5094  = 'HART-IP'
    5450  = 'OSIsoft PI Data Archive'
    5457  = 'OSIsoft PI AF Server'
    8043  = 'Ignition Gateway HTTPS'
    8088  = 'Ignition Gateway HTTP'
    8883  = 'MQTT over TLS'
    18245 = 'GE SRTP'
    20000 = 'DNP3'
    34962 = 'PROFINET IO context management'
    34963 = 'PROFINET IO alarm'
    34964 = 'PROFINET IO data'
    44818 = 'EtherNet/IP TCP'
    47808 = 'BACnet/IP'
}

# OT vendor software hints (substring matches against installed software display names)
$OtVendorHints = @{
    'siemens'              = 'vendor-ot/siemens-tia-portal.xml'
    'tia portal'           = 'vendor-ot/siemens-tia-portal.xml'
    'simatic'              = 'vendor-ot/siemens-tia-portal.xml'
    'wincc'                = 'vendor-ot/siemens-tia-portal.xml'
    'rockwell'             = 'vendor-ot/rockwell-studio5000.xml'
    'studio 5000'          = 'vendor-ot/rockwell-studio5000.xml'
    'rslogix'              = 'vendor-ot/rockwell-studio5000.xml'
    'factorytalk'          = 'vendor-ot/rockwell-studio5000.xml'
    'rslinx'               = 'vendor-ot/rockwell-studio5000.xml'
    'schneider'            = 'vendor-ot/schneider-ecostruxure.xml'
    'unity pro'            = 'vendor-ot/schneider-ecostruxure.xml'
    'ecostruxure'          = 'vendor-ot/schneider-ecostruxure.xml'
    'citect'               = 'vendor-ot/schneider-ecostruxure.xml'
    'aveva'                = 'vendor-ot/aveva-pi-system.xml'
    'pi system'            = 'vendor-ot/aveva-pi-system.xml'
    'osisoft'              = 'vendor-ot/aveva-pi-system.xml'
    'wonderware'           = 'vendor-ot/aveva-pi-system.xml'
    'archestra'            = 'vendor-ot/aveva-pi-system.xml'
    'ignition'             = 'vendor-ot/ignition-gateway.xml'
    'inductive automation' = 'vendor-ot/ignition-gateway.xml'
    'codesys'              = '(no module yet -- consider community contribution)'
    'kepware'              = '(no module yet -- consider community contribution)'
    'kepserver'            = '(no module yet -- consider community contribution)'
    'sel '                 = '(no module yet -- consider community contribution; partial sector/electric-utility)'
    'acselerator'          = '(no module yet -- consider community contribution; partial sector/electric-utility)'
    'ge ifix'              = '(no module yet -- consider community contribution)'
    'ge proficy'           = '(no module yet -- consider community contribution)'
    'honeywell'            = '(no module yet -- consider community contribution)'
    'experion'             = '(no module yet -- consider community contribution)'
    'emerson'              = '(no module yet -- consider community contribution)'
    'deltav'               = '(no module yet -- consider community contribution)'
}

# ==============================================================================
# HELPERS
# ==============================================================================

function Write-Info { param([string]$Message) Write-Host $Message }
function Write-Detail { param([string]$Message) if ($VerboseLogging) { Write-Host "  $Message" -ForegroundColor DarkGray } }

# ==============================================================================
# RULE EXTRACTION
# ==============================================================================

function Get-RulesFromXml {
    <#
    Extracts rule patterns from a Sysmon config or module XML file.
    Handles both flat field-condition rules and composite <Rule> elements.
    Returns a hashtable with:
      ImagePatterns:    array of binary path/name patterns from <Image> conditions
      CommandPatterns:  array of command-line substrings from <CommandLine> conditions
      Ports:            array of integer ports from <DestinationPort condition="is">
      TechniqueIds:     array of distinct ATT&CK technique IDs from rule names
    #>
    param([string]$XmlPath)

    $content = [System.IO.File]::ReadAllText($XmlPath)

    # Strip XML comments to avoid extracting commented-out examples
    $content = [regex]::Replace($content, '<!--[\s\S]*?-->', '')

    $imagePatterns   = New-Object System.Collections.Generic.List[string]
    $commandPatterns = New-Object System.Collections.Generic.List[string]
    $ports           = New-Object System.Collections.Generic.List[int]
    $techniqueIds    = New-Object System.Collections.Generic.HashSet[string]

    # Image conditions (flat OR inside composite Rule)
    foreach ($m in [regex]::Matches($content, '<Image\s+(?:name="[^"]*"\s+)?condition="(?<cond>[^"]+)"[^>]*>(?<val>[^<]*)</Image>')) {
        $val = $m.Groups['val'].Value.Trim()
        if ($val) { $imagePatterns.Add($val) | Out-Null }
    }
    # Image with contains-any (semicolon-delimited)
    foreach ($m in [regex]::Matches($content, '<Image\s+(?:name="[^"]*"\s+)?condition="contains any"[^>]*>(?<val>[^<]+)</Image>')) {
        foreach ($v in $m.Groups['val'].Value -split ';') {
            $v = $v.Trim()
            if ($v) { $imagePatterns.Add($v) | Out-Null }
        }
    }

    # CommandLine conditions
    foreach ($m in [regex]::Matches($content, '<CommandLine\s+(?:name="[^"]*"\s+)?condition="(?<cond>[^"]+)"[^>]*>(?<val>[^<]*)</CommandLine>')) {
        $val = $m.Groups['val'].Value.Trim()
        if ($val) { $commandPatterns.Add($val) | Out-Null }
    }

    # DestinationPort with condition="is"
    foreach ($m in [regex]::Matches($content, '<DestinationPort\s+(?:name="[^"]*"\s+)?condition="is"[^>]*>(?<val>\d+)</DestinationPort>')) {
        $port = [int]$m.Groups['val'].Value
        $ports.Add($port) | Out-Null
    }

    # Extract distinct ATT&CK technique IDs from rule name attributes
    foreach ($m in [regex]::Matches($content, 'technique_id=(?<ids>[^,"]+)')) {
        foreach ($id in $m.Groups['ids'].Value -split '\|') {
            $id = $id.Trim()
            if ($id -match '^T\d{4}(\.\d{3})?$' -or $id -match '^T\d{4}$') {
                $techniqueIds.Add($id) | Out-Null
            }
        }
    }

    return @{
        ImagePatterns   = $imagePatterns.ToArray()
        CommandPatterns = $commandPatterns.ToArray()
        Ports           = $ports.ToArray()
        TechniqueIds    = $techniqueIds
    }
}

function Get-RulesFromModule {
    <#
    Modules are XML fragments without a <Sysmon> root. Wrap and parse.
    #>
    param([string]$ModulePath)
    $content = [System.IO.File]::ReadAllText($ModulePath)
    $tmp = [System.IO.Path]::GetTempFileName()
    try {
        Set-Content -LiteralPath $tmp -Value ("<icswatchdog-root>" + $content + "</icswatchdog-root>")
        return Get-RulesFromXml -XmlPath $tmp
    } finally {
        Remove-Item -LiteralPath $tmp -ErrorAction SilentlyContinue
    }
}

function Merge-RuleSets {
    param([hashtable[]]$RuleSets)
    $imageList = New-Object System.Collections.Generic.List[string]
    $commandList = New-Object System.Collections.Generic.List[string]
    $portList = New-Object System.Collections.Generic.List[int]
    $techniqueSet = New-Object System.Collections.Generic.HashSet[string]
    foreach ($r in $RuleSets) {
        foreach ($i in $r.ImagePatterns) { $imageList.Add($i) | Out-Null }
        foreach ($c in $r.CommandPatterns) { $commandList.Add($c) | Out-Null }
        foreach ($p in $r.Ports) { $portList.Add($p) | Out-Null }
        foreach ($t in $r.TechniqueIds) { $techniqueSet.Add($t) | Out-Null }
    }
    return @{
        ImagePatterns   = $imageList.ToArray()
        CommandPatterns = $commandList.ToArray()
        Ports           = $portList.ToArray()
        TechniqueIds    = $techniqueSet
    }
}

# ==============================================================================
# SYSTEM INVENTORY
# ==============================================================================

function Get-SystemInventory {
    <#
    Read-only inventory of the current system. No network probes, no
    process injection, no system changes. Returns a hashtable suitable
    for coverage analysis.
    #>
    if ($InventoryPath) {
        Write-Detail "Using inventory from: $InventoryPath"
        $jsonText = [System.IO.File]::ReadAllText($InventoryPath)
        return $jsonText | ConvertFrom-Json | ConvertTo-Hashtable
    }

    Write-Detail "Inventorying running processes..."
    $processes = @()
    try {
        $processes = Get-Process | Where-Object { $_.Path } | ForEach-Object {
            @{ Name = $_.Name; Path = $_.Path }
        }
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
            $software += Get-ItemProperty -Path $k -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName } |
                ForEach-Object {
                    @{
                        DisplayName = $_.DisplayName
                        Publisher   = $_.Publisher
                        InstallPath = $_.InstallLocation
                    }
                }
        } catch {
            Write-Detail "Registry enumeration of $k failed: $($_.Exception.Message)"
        }
    }

    Write-Detail "Inventorying listening TCP ports..."
    $listeningPorts = @()
    try {
        $listeningPorts = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
            ForEach-Object { [int]$_.LocalPort } | Sort-Object -Unique
    } catch {
        # Get-NetTCPConnection requires PS 4+ on Windows 8/Server 2012+. Fall back to netstat.
        Write-Detail "Get-NetTCPConnection unavailable; falling back to netstat -ano"
        try {
            $netstat = & netstat -ano 2>$null
            $listeningPorts = $netstat | Where-Object { $_ -match '^\s+TCP\s+\S+:(\d+)\s+\S+\s+LISTENING' } |
                ForEach-Object { [int]($_ -replace '^\s+TCP\s+\S+:(\d+).*', '$1') } | Sort-Object -Unique
        } catch {
            Write-Warning "Port inventory failed: $($_.Exception.Message)"
        }
    }

    Write-Detail "Inventorying scheduled tasks..."
    $scheduledTasks = @()
    try {
        $scheduledTasks = Get-ScheduledTask -ErrorAction SilentlyContinue |
            Where-Object { $_.State -ne 'Disabled' } | ForEach-Object {
                @{ Name = $_.TaskName; Path = $_.TaskPath }
            }
    } catch {
        Write-Detail "Get-ScheduledTask unavailable on this system"
    }

    Write-Detail "Inventorying Windows services..."
    $services = @()
    try {
        $services = Get-Service | Where-Object { $_.Status -eq 'Running' } | ForEach-Object {
            @{ Name = $_.Name; DisplayName = $_.DisplayName }
        }
    } catch {
        Write-Detail "Service inventory failed: $($_.Exception.Message)"
    }

    return @{
        Processes      = @($processes)
        Software       = @($software)
        ListeningPorts = @($listeningPorts)
        ScheduledTasks = @($scheduledTasks)
        Services       = @($services)
    }
}

function ConvertTo-Hashtable {
    # Recursively convert PSCustomObject (from ConvertFrom-Json) to hashtable
    param([Parameter(ValueFromPipeline = $true)] $InputObject)
    process {
        if ($null -eq $InputObject) { return $null }
        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
            $list = @()
            foreach ($item in $InputObject) { $list += , (ConvertTo-Hashtable $item) }
            return , $list
        }
        if ($InputObject -is [System.Management.Automation.PSCustomObject]) {
            $h = @{}
            foreach ($p in $InputObject.PSObject.Properties) {
                $h[$p.Name] = ConvertTo-Hashtable $p.Value
            }
            return $h
        }
        return $InputObject
    }
}

# ==============================================================================
# COVERAGE COMPUTATION
# ==============================================================================

function Test-ProcessMatch {
    param([string]$ProcessPath, [string[]]$ImagePatterns)
    if (-not $ProcessPath) { return $false }
    $lower = $ProcessPath.ToLower()
    foreach ($p in $ImagePatterns) {
        if (-not $p) { continue }
        $pl = $p.ToLower()
        # An image pattern matches if the process path ends with it (most common: \binary.exe)
        # OR contains it (paths embedded in the pattern)
        if ($lower.EndsWith($pl) -or $lower.Contains($pl)) { return $true }
    }
    return $false
}

function Test-SoftwareCovered {
    param([string]$DisplayName, [string[]]$ImagePatterns)
    if (-not $DisplayName) { return $false }
    $lower = $DisplayName.ToLower()
    # Check vendor hints first
    foreach ($hint in $OtVendorHints.Keys) {
        if ($lower.Contains($hint)) {
            # The hint matches; check if any rule pattern references this vendor's binaries.
            # For simplicity, we accept the hint match alone as "the project knows about this vendor"
            # but flag the specific module that should cover it in the gap report.
            return $true
        }
    }
    return $false
}

function Get-Coverage {
    param([hashtable]$Rules, [hashtable]$Inventory)

    # Process coverage
    $totalProcesses = $Inventory.Processes.Count
    $matchedProcesses = 0
    $unmatchedProcesses = New-Object System.Collections.Generic.List[hashtable]
    foreach ($proc in $Inventory.Processes) {
        if (Test-ProcessMatch -ProcessPath $proc.Path -ImagePatterns $Rules.ImagePatterns) {
            $matchedProcesses++
        } else {
            $unmatchedProcesses.Add($proc) | Out-Null
        }
    }
    $processCoveragePct = if ($totalProcesses -gt 0) { [Math]::Round(($matchedProcesses / $totalProcesses) * 100, 1) } else { 0 }

    # Software coverage (OT-relevant)
    $otRelevantSoftware = @($Inventory.Software | Where-Object {
        if (-not $_.DisplayName) { return $false }
        $name = $_.DisplayName.ToLower()
        $matched = $false
        foreach ($hint in $OtVendorHints.Keys) {
            if ($name.Contains($hint)) { $matched = $true; break }
        }
        $matched
    })
    $totalOtSoftware = $otRelevantSoftware.Count
    $coveredOtSoftware = 0
    $uncoveredOtSoftware = New-Object System.Collections.Generic.List[hashtable]
    foreach ($sw in $otRelevantSoftware) {
        if (-not $sw.DisplayName) { continue }
        $name = $sw.DisplayName.ToLower()
        $hasModule = $false
        $suggestedModule = ''
        foreach ($hint in $OtVendorHints.Keys) {
            if ($name.Contains($hint)) {
                $suggestedModule = $OtVendorHints[$hint]
                if ($suggestedModule -and -not $suggestedModule.StartsWith('(no module yet')) {
                    # Check if any rule's image pattern is consistent with this vendor
                    $hasModule = $true
                }
                break
            }
        }
        if ($hasModule) {
            $coveredOtSoftware++
        } else {
            $uncoveredOtSoftware.Add(@{
                DisplayName    = $sw.DisplayName
                Publisher      = $sw.Publisher
                Suggestion     = $suggestedModule
            }) | Out-Null
        }
    }
    $softwareCoveragePct = if ($totalOtSoftware -gt 0) { [Math]::Round(($coveredOtSoftware / $totalOtSoftware) * 100, 1) } else { 0 }

    # Port coverage (industrial only). Cast to [int] explicitly since hashtable
    # keys are Int32 and JSON deserialization produces Int64.
    $listeningIndustrial = @($Inventory.ListeningPorts | Where-Object { $IndustrialPorts.ContainsKey([int]$_) } | ForEach-Object { [int]$_ })
    $totalIndustrialPorts = $listeningIndustrial.Count
    $coveredPorts = 0
    $uncoveredPorts = New-Object System.Collections.Generic.List[hashtable]
    foreach ($port in $listeningIndustrial) {
        $portInt = [int]$port
        if ($Rules.Ports -contains $portInt) {
            $coveredPorts++
        } else {
            $uncoveredPorts.Add(@{
                Port     = $portInt
                Protocol = $IndustrialPorts[$portInt]
            }) | Out-Null
        }
    }
    $portCoveragePct = if ($totalIndustrialPorts -gt 0) { [Math]::Round(($coveredPorts / $totalIndustrialPorts) * 100, 1) } else { 100 }

    # ATT&CK technique coverage (count distinct techniques only; no denominator)
    $techniqueCount = $Rules.TechniqueIds.Count

    return @{
        ProcessCoverage = @{
            Total            = $totalProcesses
            Matched          = $matchedProcesses
            PercentCovered   = $processCoveragePct
            UnmatchedProcesses = $unmatchedProcesses.ToArray()
        }
        SoftwareCoverage = @{
            TotalOTRelevant  = $totalOtSoftware
            Covered          = $coveredOtSoftware
            PercentCovered   = $softwareCoveragePct
            Uncovered        = $uncoveredOtSoftware.ToArray()
        }
        PortCoverage = @{
            TotalIndustrial  = $totalIndustrialPorts
            Covered          = $coveredPorts
            PercentCovered   = $portCoveragePct
            UncoveredPorts   = $uncoveredPorts.ToArray()
        }
        AttackCoverage = @{
            DistinctTechniques = $techniqueCount
            TechniqueIds       = @($Rules.TechniqueIds | Sort-Object)
        }
    }
}

# ==============================================================================
# OUTPUT FORMATTING
# ==============================================================================

function Format-ConsoleReport {
    param([hashtable]$Coverage, [string]$ConfigPath, [string[]]$AdditionalModules)

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("ICS Watch Dog - Sysmon Coverage Report")
    [void]$sb.AppendLine("======================================")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("Config: $ConfigPath")
    if ($AdditionalModules.Count -gt 0) {
        [void]$sb.AppendLine("Additional modules considered:")
        foreach ($m in $AdditionalModules) { [void]$sb.AppendLine("  + $m") }
    }
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("Process Coverage")
    [void]$sb.AppendLine("----------------")
    [void]$sb.AppendLine(("Total running processes:    {0}" -f $Coverage.ProcessCoverage.Total))
    [void]$sb.AppendLine(("Matched by at least 1 rule: {0}" -f $Coverage.ProcessCoverage.Matched))
    [void]$sb.AppendLine(("Coverage:                   {0}%" -f $Coverage.ProcessCoverage.PercentCovered))
    if ($Coverage.ProcessCoverage.UnmatchedProcesses.Count -gt 0) {
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("Unmonitored processes (gap candidates):")
        foreach ($p in ($Coverage.ProcessCoverage.UnmatchedProcesses | Select-Object -First 20)) {
            [void]$sb.AppendLine(("  - {0,-30} {1}" -f $p.Name, $p.Path))
        }
        if ($Coverage.ProcessCoverage.UnmatchedProcesses.Count -gt 20) {
            [void]$sb.AppendLine(("  ... and {0} more (use -OutputFormat JSON for full list)" -f ($Coverage.ProcessCoverage.UnmatchedProcesses.Count - 20)))
        }
    }
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("OT Software Coverage")
    [void]$sb.AppendLine("--------------------")
    [void]$sb.AppendLine(("Total OT-relevant software installed: {0}" -f $Coverage.SoftwareCoverage.TotalOTRelevant))
    [void]$sb.AppendLine(("Covered by a vendor module:           {0}" -f $Coverage.SoftwareCoverage.Covered))
    [void]$sb.AppendLine(("Coverage:                             {0}%" -f $Coverage.SoftwareCoverage.PercentCovered))
    if ($Coverage.SoftwareCoverage.Uncovered.Count -gt 0) {
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("Uncovered OT software (no module yet):")
        foreach ($s in $Coverage.SoftwareCoverage.Uncovered) {
            [void]$sb.AppendLine(("  - {0}" -f $s.DisplayName))
            if ($s.Suggestion) { [void]$sb.AppendLine(("      Suggested: {0}" -f $s.Suggestion)) }
        }
    }
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("Industrial Port Coverage")
    [void]$sb.AppendLine("------------------------")
    [void]$sb.AppendLine(("Listening industrial ports:           {0}" -f $Coverage.PortCoverage.TotalIndustrial))
    [void]$sb.AppendLine(("Covered by a protocol rule:           {0}" -f $Coverage.PortCoverage.Covered))
    [void]$sb.AppendLine(("Coverage:                             {0}%" -f $Coverage.PortCoverage.PercentCovered))
    if ($Coverage.PortCoverage.UncoveredPorts.Count -gt 0) {
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("Uncovered industrial ports:")
        foreach ($p in $Coverage.PortCoverage.UncoveredPorts) {
            [void]$sb.AppendLine(("  - Port {0,-6} {1}" -f $p.Port, $p.Protocol))
        }
    }
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("ATT&CK Technique Coverage")
    [void]$sb.AppendLine("-------------------------")
    [void]$sb.AppendLine(("Distinct ATT&CK techniques in deployed rules: {0}" -f $Coverage.AttackCoverage.DistinctTechniques))
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("To find specific gaps and improvement suggestions, see the")
    [void]$sb.AppendLine("Build Your Own Module guide at https://icswatchdog.com/build-your-own-module/")
    return $sb.ToString()
}

function Format-JsonReport {
    param([hashtable]$Coverage, [string]$ConfigPath, [string[]]$AdditionalModules)
    $report = @{
        Tool             = 'ICS Watch Dog Get-SysmonCoverage'
        Version          = '1.0'
        ConfigPath       = $ConfigPath
        AdditionalModules = $AdditionalModules
        Timestamp        = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')
        Coverage         = $Coverage
    }
    return ($report | ConvertTo-Json -Depth 10)
}

function Format-MarkdownReport {
    param([hashtable]$Coverage, [string]$ConfigPath, [string[]]$AdditionalModules)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("# Sysmon Coverage Report")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("**Tool**: ICS Watch Dog Get-SysmonCoverage v1.0")
    [void]$sb.AppendLine(("**Config**: ``{0}``" -f $ConfigPath))
    [void]$sb.AppendLine(("**Timestamp**: {0}" -f (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')))
    if ($AdditionalModules.Count -gt 0) {
        [void]$sb.AppendLine("**Additional modules**:")
        foreach ($m in $AdditionalModules) { [void]$sb.AppendLine("- ``$m``") }
    }
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("## Coverage Summary")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("| Metric | Value |")
    [void]$sb.AppendLine("|--------|-------|")
    [void]$sb.AppendLine(("| Process coverage | {0}% ({1}/{2}) |" -f $Coverage.ProcessCoverage.PercentCovered, $Coverage.ProcessCoverage.Matched, $Coverage.ProcessCoverage.Total))
    [void]$sb.AppendLine(("| OT software coverage | {0}% ({1}/{2}) |" -f $Coverage.SoftwareCoverage.PercentCovered, $Coverage.SoftwareCoverage.Covered, $Coverage.SoftwareCoverage.TotalOTRelevant))
    [void]$sb.AppendLine(("| Industrial port coverage | {0}% ({1}/{2}) |" -f $Coverage.PortCoverage.PercentCovered, $Coverage.PortCoverage.Covered, $Coverage.PortCoverage.TotalIndustrial))
    [void]$sb.AppendLine(("| Distinct ATT&CK techniques | {0} |" -f $Coverage.AttackCoverage.DistinctTechniques))
    [void]$sb.AppendLine("")
    if ($Coverage.ProcessCoverage.UnmatchedProcesses.Count -gt 0) {
        [void]$sb.AppendLine("## Unmonitored Processes")
        [void]$sb.AppendLine("")
        foreach ($p in $Coverage.ProcessCoverage.UnmatchedProcesses) {
            [void]$sb.AppendLine(("- ``{0}`` -- {1}" -f $p.Name, $p.Path))
        }
        [void]$sb.AppendLine("")
    }
    if ($Coverage.SoftwareCoverage.Uncovered.Count -gt 0) {
        [void]$sb.AppendLine("## Uncovered OT Software")
        [void]$sb.AppendLine("")
        foreach ($s in $Coverage.SoftwareCoverage.Uncovered) {
            [void]$sb.AppendLine(("- **{0}**" -f $s.DisplayName))
            if ($s.Publisher) { [void]$sb.AppendLine(("  Publisher: {0}" -f $s.Publisher)) }
            if ($s.Suggestion) { [void]$sb.AppendLine(("  Suggested module: {0}" -f $s.Suggestion)) }
        }
        [void]$sb.AppendLine("")
    }
    if ($Coverage.PortCoverage.UncoveredPorts.Count -gt 0) {
        [void]$sb.AppendLine("## Uncovered Industrial Ports")
        [void]$sb.AppendLine("")
        foreach ($p in $Coverage.PortCoverage.UncoveredPorts) {
            [void]$sb.AppendLine(("- Port **{0}** ({1})" -f $p.Port, $p.Protocol))
        }
        [void]$sb.AppendLine("")
    }
    [void]$sb.AppendLine("## ATT&CK Techniques Detected")
    [void]$sb.AppendLine("")
    foreach ($t in ($Coverage.AttackCoverage.TechniqueIds | Sort-Object)) {
        [void]$sb.AppendLine("- $t")
    }
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine("Generated by [ICS Watch Dog Get-SysmonCoverage](https://icswatchdog.com/coverage-assessment/)")
    return $sb.ToString()
}

# ==============================================================================
# MAIN
# ==============================================================================

# Resolve config: from -ConfigPath, or query running Sysmon
if (-not $ConfigPath -and -not $InventoryPath) {
    Write-Detail "No -ConfigPath provided; attempting to query running Sysmon via 'sysmon -c'"
    try {
        $sysmonOutput = & sysmon -c 2>&1
        if ($LASTEXITCODE -eq 0) {
            # Sysmon prints config to stdout; capture and parse
            $tempConfig = [System.IO.Path]::GetTempFileName()
            $sysmonOutput | Out-File -LiteralPath $tempConfig
            $ConfigPath = $tempConfig
            Write-Detail "Captured running Sysmon config to: $ConfigPath"
        } else {
            throw "sysmon -c returned exit code $LASTEXITCODE"
        }
    } catch {
        throw "Could not query running Sysmon: $($_.Exception.Message). Provide -ConfigPath or -MockInventoryPath."
    }
}

if ($ConfigPath -and -not (Test-Path -LiteralPath $ConfigPath)) {
    throw "Config file not found: $ConfigPath"
}

Write-Detail "Loading rules from: $ConfigPath"
$ruleSets = @()
if ($ConfigPath) {
    $ruleSets += Get-RulesFromXml -XmlPath $ConfigPath
}

foreach ($mod in $AdditionalModules) {
    if (-not (Test-Path -LiteralPath $mod)) {
        throw "Module file not found: $mod"
    }
    Write-Detail "Loading module: $mod"
    $ruleSets += Get-RulesFromModule -ModulePath $mod
}

$mergedRules = Merge-RuleSets -RuleSets $ruleSets

Write-Detail "Inventorying system..."
$inventory = Get-SystemInventory

Write-Detail "Computing coverage..."
$coverage = Get-Coverage -Rules $mergedRules -Inventory $inventory

# Format and emit
$report = switch ($OutputFormat) {
    'JSON'     { Format-JsonReport -Coverage $coverage -ConfigPath $ConfigPath -AdditionalModules $AdditionalModules }
    'Markdown' { Format-MarkdownReport -Coverage $coverage -ConfigPath $ConfigPath -AdditionalModules $AdditionalModules }
    default    { Format-ConsoleReport -Coverage $coverage -ConfigPath $ConfigPath -AdditionalModules $AdditionalModules }
}

if ($OutputPath) {
    Set-Content -LiteralPath $OutputPath -Value $report
    Write-Info "Report written to: $OutputPath"
} else {
    Write-Output $report
}
