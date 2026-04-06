<#
.SYNOPSIS
    Merges ICS Watch Dog module XML fragments into a base curated Sysmon configuration.

.DESCRIPTION
    Reads a base curated config and a list of module files, inserts each module's
    <RuleGroup> elements into the base config's <EventFiltering> section, validates
    the output XML, and writes the merged result to a new file.

    The base config's meta configuration (HashAlgorithms, CheckRevocation,
    schemaversion) is preserved as-is. Modules contribute only RuleGroup elements.

    Bounded scope: this script exists only to merge ICS Watch Dog modules into
    ICS Watch Dog base configs. It is not a general-purpose Sysmon config generator.

.PARAMETER BaseConfig
    Path to the base curated Sysmon configuration file.

.PARAMETER Modules
    Array of paths to module XML fragment files to merge.

.PARAMETER OutputPath
    Path where the merged output configuration will be written.

.PARAMETER VerboseLogging
    Print detailed progress information.

.EXAMPLE
    .\Merge-SysmonModules.ps1 `
        -BaseConfig sysmon-configs\sysmonconfig-baseline-ot.xml `
        -Modules @(
            'sysmon-configs\modules\vendor-ot\siemens-tia-portal.xml',
            'sysmon-configs\modules\protocol\modbus-tcp.xml',
            'sysmon-configs\modules\cloud-storage\include_dropbox.xml'
        ) `
        -OutputPath sysmonconfig-site-acmeplant.xml

.NOTES
    Requirements: PowerShell 3.0 or later. No external modules.
    Compatible with Windows PowerShell 5.1+ and PowerShell Core 7+ (Windows/Linux/macOS).
    See: https://icswatchdog.com/modules/
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({
        if (-not (Test-Path -LiteralPath $_)) { throw "BaseConfig file not found: $_" }
        $true
    })]
    [string]$BaseConfig,

    [Parameter(Mandatory=$true)]
    [string[]]$Modules,

    [Parameter(Mandatory=$true)]
    [string]$OutputPath,

    [switch]$VerboseLogging
)

$ErrorActionPreference = 'Stop'

function Write-Info {
    param([string]$Message)
    Write-Host $Message
}

function Write-Detail {
    param([string]$Message)
    if ($VerboseLogging) { Write-Host "  $Message" -ForegroundColor DarkGray }
}

function Write-WarnLine {
    param([string]$Message)
    Write-Warning $Message
}

# Banner
Write-Info "ICS Watch Dog - Sysmon Module Merge Tool"
Write-Info "========================================"
Write-Info ""

# Validate base config exists and is well-formed XML
Write-Info "Reading base config: $BaseConfig"
[xml]$baseXml = $null
try {
    $baseXml = [xml](Get-Content -LiteralPath $BaseConfig -Raw)
} catch {
    throw "Failed to parse base config XML: $($_.Exception.Message)"
}

# Verify base config structure
if ($null -eq $baseXml.Sysmon) {
    throw "Base config does not contain a <Sysmon> root element."
}
if ($null -eq $baseXml.Sysmon.EventFiltering) {
    throw "Base config does not contain an <EventFiltering> element."
}

$baseSchema = $baseXml.Sysmon.schemaversion
Write-Info "Base config schemaversion: $baseSchema"
Write-Detail "Base config has $($baseXml.Sysmon.EventFiltering.ChildNodes.Count) immediate children in <EventFiltering>"

# Module schema mismatch detection: warn if 4.90-only features in a 4.50 base
$schema490Features = @('FileBlockExecutable', 'FileBlockShredding', 'FileExecutableDetected', 'ClipboardChange')

# Process each module
Write-Info ""
Write-Info "Processing $($Modules.Count) module(s):"
$mergedManifest = @()
$warnings = @()

foreach ($modulePath in $Modules) {
    if (-not (Test-Path -LiteralPath $modulePath)) {
        throw "Module file not found: $modulePath"
    }

    Write-Info "  - $modulePath"
    $moduleContent = Get-Content -LiteralPath $modulePath -Raw

    # Wrap module content in synthetic root for XML parsing
    $wrapped = "<icswatchdog-module-root>" + $moduleContent + "</icswatchdog-module-root>"

    [xml]$moduleXml = $null
    try {
        $moduleXml = [xml]$wrapped
    } catch {
        throw ("Failed to parse module XML '{0}': {1}" -f $modulePath, $_.Exception.Message)
    }

    $root = $moduleXml.DocumentElement

    # Validate module contents: only RuleGroup elements allowed (plus comments and whitespace)
    $forbiddenElements = @('Sysmon', 'HashAlgorithms', 'CheckRevocation', 'EventFiltering',
                            'ArchiveDirectory', 'CopyOnDeletePE', 'DnsLookup', 'DriverName')
    $ruleGroupCount = 0
    foreach ($child in $root.ChildNodes) {
        if ($child.NodeType -eq [System.Xml.XmlNodeType]::Element) {
            if ($child.LocalName -eq 'RuleGroup') {
                $ruleGroupCount++
            } elseif ($forbiddenElements -contains $child.LocalName) {
                throw ("Module '{0}' contains forbidden element <{1}>. Modules must only contain <RuleGroup> elements." -f $modulePath, $child.LocalName)
            } else {
                throw ("Module '{0}' contains unexpected top-level element <{1}>. Modules must only contain <RuleGroup> elements." -f $modulePath, $child.LocalName)
            }
        }
    }

    if ($ruleGroupCount -eq 0) {
        $warnings += "Module '$modulePath' contains no <RuleGroup> elements (skipped)."
        Write-WarnLine "  No <RuleGroup> elements found in $modulePath. Skipping."
        continue
    }

    Write-Detail "  Module has $ruleGroupCount RuleGroup element(s)"

    # Schema mismatch check: warn if module references 4.90-only features
    foreach ($feature in $schema490Features) {
        if ($moduleContent -match "<$feature\b") {
            if ($baseSchema -ne '4.90') {
                $msg = "Module '$modulePath' uses <$feature> which requires schema 4.90; base config is schema $baseSchema. Merged config may not load on Sysmon versions earlier than v15."
                $warnings += $msg
                Write-WarnLine $msg
            }
        }
    }

    # Insert each RuleGroup from module into base config's EventFiltering
    foreach ($child in $root.ChildNodes) {
        if ($child.NodeType -eq [System.Xml.XmlNodeType]::Element -and $child.LocalName -eq 'RuleGroup') {
            $imported = $baseXml.ImportNode($child, $true)
            $null = $baseXml.Sysmon.EventFiltering.AppendChild($imported)
            Write-Detail "  Inserted RuleGroup: $($child.GetAttribute('name'))"
        }
    }

    $mergedManifest += [pscustomobject]@{
        Module     = $modulePath
        RuleGroups = $ruleGroupCount
    }
}

# Validate output XML well-formedness via re-parse
Write-Info ""
Write-Info "Validating merged output..."
$outputString = $baseXml.OuterXml
try {
    [xml]$verify = $outputString
} catch {
    throw "Merged output is not valid XML: $($_.Exception.Message)"
}

# Re-verify structure
if ($null -eq $verify.Sysmon -or $null -eq $verify.Sysmon.EventFiltering) {
    throw "Merged output is missing required <Sysmon> or <EventFiltering> element."
}

# Pretty-print output to preserve indentation
$settings = New-Object System.Xml.XmlWriterSettings
$settings.Indent = $true
$settings.IndentChars = '  '
$settings.OmitXmlDeclaration = $true
$settings.NewLineOnAttributes = $false
$settings.Encoding = New-Object System.Text.UTF8Encoding($false)

$outputDir = Split-Path -Parent $OutputPath
if ($outputDir -and -not (Test-Path -LiteralPath $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$writer = [System.Xml.XmlWriter]::Create($OutputPath, $settings)
try {
    $baseXml.Save($writer)
} finally {
    $writer.Close()
}

Write-Info "Output written to: $OutputPath"

# Report manifest
Write-Info ""
Write-Info "Merge Manifest"
Write-Info "--------------"
Write-Info "Base config:        $BaseConfig"
Write-Info "Schema version:     $baseSchema"
Write-Info "Modules merged:     $($mergedManifest.Count)"
$totalGroups = ($mergedManifest | Measure-Object -Property RuleGroups -Sum).Sum
Write-Info "Total RuleGroups:   $totalGroups"
Write-Info "Output:             $OutputPath"

foreach ($entry in $mergedManifest) {
    Write-Info "  + $($entry.Module) ($($entry.RuleGroups) RuleGroups)"
}

if ($warnings.Count -gt 0) {
    Write-Info ""
    Write-Info "Warnings ($($warnings.Count)):"
    foreach ($w in $warnings) {
        Write-Info "  ! $w"
    }
}

Write-Info ""
Write-Info "Merge complete."
