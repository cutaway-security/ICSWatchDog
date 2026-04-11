<#
.SYNOPSIS
    ICS Watch Dog - Sysmon Configuration Efficacy Test
    Tests whether your deployed Sysmon configuration generates expected events.

.DESCRIPTION
    This script performs safe, non-destructive actions that should trigger Sysmon
    event logging, then verifies the events appeared in the Sysmon event log.
    It validates that your Sysmon configuration is actively monitoring and logging
    the security-relevant activities it is designed to detect.

    This is a focused smoke test, not an adversary emulation tool. For deeper
    testing, see Atomic Red Team, MITRE Caldera, or Scythe.

    Tests are divided into two groups:

    DEFAULT TESTS (observation-only, ephemeral artifacts):
      1  - ProcessCreate        (start a benign process)
      3  - NetworkConnect       (TCP connection to example.com)
      5  - ProcessTerminate     (terminate the test process)
      11 - FileCreate           (create test files in Temp)
      15 - FileCreateStreamHash (create .exe file to trigger stream hash)
      17 - PipeCreate           (create a named pipe)
      18 - PipeConnect          (connect to the named pipe)
      22 - DnsQuery             (DNS lookup of test domain)
      26 - FileDeleteDetected   (delete a .bat test file)

    SYSTEM TESTS (require -AllowSystemChanges, modify system state):
      12 - RegistryCreate       (create HKCU Run key entry)
      13 - RegistryValueSet     (set value in HKCU Run key)
      19 - WmiFilterCreate      (create WMI event filter)
      20 - WmiConsumerCreate    (create WMI event consumer)
      21 - WmiBindingCreate     (create WMI filter-to-consumer binding)

    System tests modify registry and WMI state. While all changes are cleaned
    up automatically, failed cleanup could leave artifacts that affect system
    behavior (e.g., a Run key pointing to a non-existent executable). Use
    -AllowSystemChanges only when you understand the changes and have reviewed
    the manual cleanup steps in the Efficacy Testing Guide.

    Skipped Event IDs (unsafe or disabled by default):
      2  - FileCreateTime       (requires timestomping - risky)
      6  - DriverLoad           (requires loading a driver)
      7  - ImageLoad            (disabled by default in most configs)
      8  - CreateRemoteThread   (requires process injection)
      9  - RawAccessRead        (disabled by default in most configs)
      10 - ProcessAccess        (targets lsass.exe - unsafe to test)
      23 - FileDelete (archived)(disabled by default, consumes disk)
      25 - ProcessTampering     (requires process hollowing)

.PARAMETER AllowSystemChanges
    Enable tests that modify system state (registry and WMI). By default,
    only observation-only tests run (processes, files, network, pipes, DNS).
    System tests create a HKCU Run key entry and WMI event subscriptions,
    which are cleaned up automatically. If cleanup fails, artifacts remain
    on the system -- see the Efficacy Testing Guide for manual removal.

.PARAMETER WaitSeconds
    Seconds to wait for Sysmon event log propagation before verifying.
    Default: 10. Increase if events are not appearing (slow systems may
    need 15-30 seconds).

.PARAMETER SkipConfirmation
    Skip the confirmation prompt and run tests immediately.
    Use with caution -- review the planned changes list first.

.EXAMPLE
    .\Test-SysmonConfig.ps1
    Run default observation-only tests (9 Event IDs tested).

.EXAMPLE
    .\Test-SysmonConfig.ps1 -AllowSystemChanges
    Run all tests including registry and WMI (14 Event IDs tested).

.EXAMPLE
    .\Test-SysmonConfig.ps1 -AllowSystemChanges -WaitSeconds 20
    Run all tests with a longer wait for event log propagation.

.EXAMPLE
    .\Test-SysmonConfig.ps1 -SkipConfirmation
    Run default tests without the confirmation prompt.

.NOTES
    Project:  ICS Watch Dog (https://icswatchdog.com)
    Source:   https://github.com/cutaway-security/ICSWatchDog
    License:  Creative Commons Attribution 4.0
    Requires: Administrator privileges, Sysmon installed and running
    PowerShell: Version 3.0 or later

    DISCLAIMER:
    This script is provided as-is for educational and operational use.
    Cutaway Security, LLC and contributors assume no liability for any
    impact resulting from the use of this script. Users are responsible
    for testing in their own environments.

    For manual cleanup steps if automated cleanup fails, see the
    ICS Watch Dog Efficacy Testing Guide at https://icswatchdog.com
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage="Enable registry and WMI tests that modify system state")]
    [switch]$AllowSystemChanges,

    [Parameter(HelpMessage="Seconds to wait for event log propagation (default: 10)")]
    [ValidateRange(5, 120)]
    [int]$WaitSeconds = 10,

    [Parameter(HelpMessage="Skip the confirmation prompt")]
    [switch]$SkipConfirmation
)

if ($PSVersionTable.PSVersion.Major -lt 3) {
    Write-Error "This script requires PowerShell 3.0 or later. Current version: $($PSVersionTable.PSVersion)"
    exit 1
}

# Enforce strict mode for reliable error handling
Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

# --------------------------------------------------------------------------
# Constants
# --------------------------------------------------------------------------
$SYSMON_LOG      = "Microsoft-Windows-Sysmon/Operational"
$TEST_PREFIX     = "ICSWatchDog-EfficacyTest"
$TEMP_DIR        = $env:TEMP
$REG_PATH        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$REG_VALUE_NAME  = "$TEST_PREFIX"
$PIPE_NAME       = "$TEST_PREFIX-Pipe"
$WMI_FILTER_NAME = "$TEST_PREFIX-Filter"
$WMI_CONSUMER_NAME = "$TEST_PREFIX-Consumer"
$TEST_FILE_BAT   = Join-Path $TEMP_DIR "$TEST_PREFIX.bat"
$TEST_FILE_EXE   = Join-Path $TEMP_DIR "$TEST_PREFIX.exe"
$DNS_TEST_DOMAIN = "icswatchdog-efficacy-test.example.com"

# --------------------------------------------------------------------------
# Helper: Write-Status
# Consistent output formatting without emoji
# --------------------------------------------------------------------------
function Write-Status {
    param(
        [string]$Label,
        [string]$Message,
        [ValidateSet("Info","Pass","Fail","Warn","Section")]
        [string]$Type = "Info"
    )
    switch ($Type) {
        "Section" { Write-Host "`n==== $Message ====" -ForegroundColor Cyan }
        "Info"    { Write-Host "  [INFO]  $Label - $Message" }
        "Pass"    { Write-Host "  [PASS]  $Label - $Message" -ForegroundColor Green }
        "Fail"    { Write-Host "  [FAIL]  $Label - $Message" -ForegroundColor Red }
        "Warn"    { Write-Host "  [WARN]  $Label - $Message" -ForegroundColor Yellow }
    }
}

# --------------------------------------------------------------------------
# Helper: Test-SysmonEvent
# Query the Sysmon event log for a specific Event ID after $StartTime
# Returns $true if at least one matching event is found
# --------------------------------------------------------------------------
function Test-SysmonEvent {
    param(
        [int]$EventId,
        [datetime]$StartTime,
        [string]$XPathFilter = $null
    )
    try {
        if ($XPathFilter) {
            $events = Get-WinEvent -LogName $SYSMON_LOG -FilterXPath $XPathFilter -MaxEvents 1 -ErrorAction SilentlyContinue
        } else {
            $events = Get-WinEvent -FilterHashtable @{
                LogName   = $SYSMON_LOG
                Id        = $EventId
                StartTime = $StartTime
            } -MaxEvents 1 -ErrorAction SilentlyContinue
        }
        return ($null -ne $events -and $events.Count -gt 0)
    } catch {
        return $false
    }
}

# --------------------------------------------------------------------------
# Pre-flight Checks
# --------------------------------------------------------------------------
function Invoke-PreFlightChecks {
    Write-Status -Type Section -Message "PRE-FLIGHT CHECKS"

    # Check administrator privileges
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
    if (-not $isAdmin) {
        Write-Status "Admin" "This script requires Administrator privileges. Re-run from an elevated prompt." -Type Fail
        return $false
    }
    Write-Status "Admin" "Running with Administrator privileges" -Type Pass

    # Check Sysmon service is running
    $sysmonService = Get-Service -Name "Sysmon*" -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Running" }
    if (-not $sysmonService) {
        Write-Status "Sysmon" "Sysmon service not found or not running. Install and start Sysmon first." -Type Fail
        return $false
    }
    Write-Status "Sysmon" "Service running ($($sysmonService.Name))" -Type Pass

    # Check Sysmon event log is accessible
    try {
        $null = Get-WinEvent -LogName $SYSMON_LOG -MaxEvents 1 -ErrorAction Stop
        Write-Status "EventLog" "Sysmon event log accessible ($SYSMON_LOG)" -Type Pass
    } catch {
        Write-Status "EventLog" "Cannot read Sysmon event log. Verify Sysmon is configured." -Type Fail
        return $false
    }

    # Check PowerShell version
    $psVersion = $PSVersionTable.PSVersion.Major
    if ($psVersion -lt 3) {
        Write-Status "PowerShell" "Version $psVersion detected. Version 3+ required." -Type Fail
        return $false
    }
    Write-Status "PowerShell" "Version $psVersion" -Type Pass

    return $true
}

# --------------------------------------------------------------------------
# Display Planned Changes
# --------------------------------------------------------------------------
function Show-PlannedChanges {
    Write-Status -Type Section -Message "PLANNED CHANGES"

    if ($AllowSystemChanges) {
        Write-Host ""
        Write-Host "  Mode: ALL TESTS (observation + system modification)" -ForegroundColor Yellow
    } else {
        Write-Host ""
        Write-Host "  Mode: OBSERVATION-ONLY (default)"
        Write-Host "  To include registry and WMI tests, re-run with -AllowSystemChanges"
    }

    Write-Host ""
    Write-Host "  This script will perform the following actions on this system:"
    Write-Host ""
    Write-Host "  PROCESSES:"
    Write-Host "    - Start notepad.exe (will be closed automatically)"
    Write-Host ""
    Write-Host "  FILES (in $TEMP_DIR):"
    Write-Host "    - Create: $TEST_FILE_BAT"
    Write-Host "    - Create: $TEST_FILE_EXE"
    Write-Host "    - Delete: $TEST_FILE_BAT (to test deletion detection)"
    Write-Host "    - Delete: $TEST_FILE_EXE (cleanup)"
    Write-Host ""
    Write-Host "  NETWORK:"
    Write-Host "    - TCP connection to example.com port 80 (IANA reserved, no data sent)"
    Write-Host "    - DNS query for $DNS_TEST_DOMAIN (non-existent, will fail harmlessly)"
    Write-Host ""
    Write-Host "  NAMED PIPES:"
    Write-Host "    - Create and connect to: \\.\pipe\$PIPE_NAME"
    Write-Host "      (local only, removed when script completes)"

    if ($AllowSystemChanges) {
        Write-Host ""
        Write-Host "  REGISTRY (system test):" -ForegroundColor Yellow
        Write-Host "    - Create value: $REG_PATH\$REG_VALUE_NAME" -ForegroundColor Yellow
        Write-Host "      (HKCU Run key -- will be removed during cleanup)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  WMI (system test):" -ForegroundColor Yellow
        Write-Host "    - Create temporary WMI event filter: $WMI_FILTER_NAME" -ForegroundColor Yellow
        Write-Host "    - Create temporary WMI event consumer: $WMI_CONSUMER_NAME" -ForegroundColor Yellow
        Write-Host "    - Create temporary WMI filter-to-consumer binding" -ForegroundColor Yellow
        Write-Host "    - All three will be removed during cleanup" -ForegroundColor Yellow
    } else {
        Write-Host ""
        Write-Host "  SKIPPED (requires -AllowSystemChanges):"
        Write-Host "    - Registry: HKCU Run key modification (EID 12, 13)"
        Write-Host "    - WMI: Event subscription creation (EID 19, 20, 21)"
    }

    Write-Host ""
    Write-Host "  EVENT LOG:"
    Write-Host "    - Read from $SYSMON_LOG (verification only, no writes)"
    Write-Host ""
    Write-Host "  WAIT:"
    Write-Host "    - $WaitSeconds second pause after triggers for event log propagation"
    Write-Host ""

    if ($AllowSystemChanges) {
        Write-Host "  WARNING: System tests modify registry and WMI state." -ForegroundColor Yellow
        Write-Host "  If cleanup fails, artifacts will remain on the system:" -ForegroundColor Yellow
        Write-Host "    - A Run key entry could cause an error at next logon" -ForegroundColor Yellow
        Write-Host "      (it points to a non-existent executable)" -ForegroundColor Yellow
        Write-Host "    - A WMI subscription could persist (points to non-existent executable," -ForegroundColor Yellow
        Write-Host "      will not execute but pollutes WMI namespace)" -ForegroundColor Yellow
        Write-Host "  See manual cleanup steps in the Efficacy Testing Guide." -ForegroundColor Yellow
        Write-Host ""
    }
}

# --------------------------------------------------------------------------
# Trigger Functions
# --------------------------------------------------------------------------
function Invoke-Triggers {
    param([datetime]$StartTime)

    Write-Status -Type Section -Message "EXECUTING TESTS"

    # ---- EID 1 + 5: ProcessCreate and ProcessTerminate ----
    Write-Status "EID 1,5" "Starting and stopping notepad.exe" -Type Info
    try {
        $proc = Start-Process -FilePath "notepad.exe" -PassThru -WindowStyle Hidden
        Start-Sleep -Milliseconds 500
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        Write-Status "EID 1,5" "Process started (PID $($proc.Id)) and stopped" -Type Info
    } catch {
        Write-Status "EID 1,5" "Failed to start/stop notepad: $_" -Type Warn
    }

    # ---- EID 3: NetworkConnect ----
    Write-Status "EID 3" "TCP connection to example.com:80" -Type Info
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $tcp.Connect("example.com", 80)
        $tcp.Close()
        Write-Status "EID 3" "Connection completed and closed" -Type Info
    } catch {
        Write-Status "EID 3" "Connection attempt made (may have failed, event may still log): $_" -Type Warn
    }

    # ---- EID 11: FileCreate (.bat in Temp) ----
    Write-Status "EID 11" "Creating test file: $TEST_FILE_BAT" -Type Info
    try {
        Set-Content -Path $TEST_FILE_BAT -Value "@echo off`r`nrem $TEST_PREFIX efficacy test file" -Force
        Write-Status "EID 11" "File created" -Type Info
    } catch {
        Write-Status "EID 11" "Failed to create file: $_" -Type Warn
    }

    # ---- EID 15: FileCreateStreamHash (.exe in Temp) ----
    Write-Status "EID 15" "Creating test file: $TEST_FILE_EXE" -Type Info
    try {
        # Write minimal content -- Sysmon hashes the stream on creation of monitored extensions
        Set-Content -Path $TEST_FILE_EXE -Value "$TEST_PREFIX efficacy test - not a real executable" -Force
        Write-Status "EID 15" "File created" -Type Info
    } catch {
        Write-Status "EID 15" "Failed to create file: $_" -Type Warn
    }

    # ---- EID 12 + 13: RegistryCreate and RegistryValueSet (system test) ----
    if ($AllowSystemChanges) {
        Write-Status "EID 12,13" "Creating registry value in HKCU Run key" -Type Info
        try {
            New-ItemProperty -Path $REG_PATH -Name $REG_VALUE_NAME -Value "C:\$TEST_PREFIX-DoesNotExist.exe" -PropertyType String -Force | Out-Null
            Write-Status "EID 12,13" "Registry value created" -Type Info
        } catch {
            Write-Status "EID 12,13" "Failed to create registry value: $_" -Type Warn
        }
    } else {
        Write-Status "EID 12,13" "SKIPPED (requires -AllowSystemChanges)" -Type Info
    }

    # ---- EID 17 + 18: PipeCreate and PipeConnect ----
    Write-Status "EID 17,18" "Creating and connecting to named pipe: $PIPE_NAME" -Type Info
    try {
        $pipeServer = New-Object System.IO.Pipes.NamedPipeServerStream(
            $PIPE_NAME,
            [System.IO.Pipes.PipeDirection]::InOut,
            1,
            [System.IO.Pipes.PipeTransmissionMode]::Byte,
            [System.IO.Pipes.PipeOptions]::Asynchronous
        )
        $connectAsync = $pipeServer.WaitForConnectionAsync()

        $pipeClient = New-Object System.IO.Pipes.NamedPipeClientStream(
            ".",
            $PIPE_NAME,
            [System.IO.Pipes.PipeDirection]::InOut
        )
        $pipeClient.Connect(2000)

        # Brief pause to let Sysmon observe the connection
        Start-Sleep -Milliseconds 200

        $pipeClient.Close()
        $pipeServer.Close()
        Write-Status "EID 17,18" "Pipe created, connected, and closed" -Type Info
    } catch {
        Write-Status "EID 17,18" "Pipe test encountered an error: $_" -Type Warn
        # Ensure cleanup
        if ($pipeClient) { try { $pipeClient.Close() } catch {} }
        if ($pipeServer) { try { $pipeServer.Close() } catch {} }
    }

    # ---- EID 19 + 20 + 21: WMI Event Subscription (system test) ----
    if ($AllowSystemChanges) {
        Write-Status "EID 19,20,21" "Creating WMI event subscription" -Type Info
        try {
            # EID 19: Create WMI event filter
            $filterArgs = @{
                EventNamespace = "root/cimv2"
                Name           = $WMI_FILTER_NAME
                QueryLanguage  = "WQL"
                Query          = "SELECT * FROM __InstanceCreationEvent WITHIN 9999 WHERE TargetInstance ISA 'Win32_LogonSession'"
            }
            $filter = Set-WmiInstance -Namespace "root/subscription" -Class "__EventFilter" -Arguments $filterArgs

            # EID 20: Create WMI event consumer (CommandLine -- points to non-existent path)
            $consumerArgs = @{
                Name               = $WMI_CONSUMER_NAME
                CommandLineTemplate = "C:\$TEST_PREFIX-DoesNotExist.exe"
            }
            $consumer = Set-WmiInstance -Namespace "root/subscription" -Class "CommandLineEventConsumer" -Arguments $consumerArgs

            # EID 21: Create filter-to-consumer binding
            $bindingArgs = @{
                Filter   = $filter.__PATH
                Consumer = $consumer.__PATH
            }
            $null = Set-WmiInstance -Namespace "root/subscription" -Class "__FilterToConsumerBinding" -Arguments $bindingArgs

            Write-Status "EID 19,20,21" "WMI filter, consumer, and binding created" -Type Info
        } catch {
            Write-Status "EID 19,20,21" "WMI subscription test encountered an error: $_" -Type Warn
        }
    } else {
        Write-Status "EID 19,20,21" "SKIPPED (requires -AllowSystemChanges)" -Type Info
    }

    # ---- EID 22: DnsQuery ----
    Write-Status "EID 22" "DNS query for $DNS_TEST_DOMAIN" -Type Info
    try {
        # Use .NET DNS resolver (works on PS 3+, triggers Sysmon DNS logging)
        [System.Net.Dns]::GetHostAddresses($DNS_TEST_DOMAIN) | Out-Null
    } catch {
        # Expected to fail (non-existent domain) -- the DNS query still triggers Sysmon
        Write-Status "EID 22" "DNS query sent (resolution failure expected)" -Type Info
    }

    # ---- EID 26: FileDeleteDetected ----
    Write-Status "EID 26" "Deleting test file: $TEST_FILE_BAT" -Type Info
    try {
        if (Test-Path $TEST_FILE_BAT) {
            Remove-Item -Path $TEST_FILE_BAT -Force
            Write-Status "EID 26" "File deleted" -Type Info
        } else {
            Write-Status "EID 26" "Test file not found (EID 11 may have failed)" -Type Warn
        }
    } catch {
        Write-Status "EID 26" "Failed to delete file: $_" -Type Warn
    }
}

# --------------------------------------------------------------------------
# Verification
# --------------------------------------------------------------------------
function Invoke-Verification {
    param([datetime]$StartTime)

    Write-Status -Type Section -Message "VERIFYING EVENTS (checking log after $WaitSeconds second wait)"
    Write-Host "  Waiting $WaitSeconds seconds for event log propagation..."
    Start-Sleep -Seconds $WaitSeconds

    $results = @{}

    # Build XPath filters for precise matching where possible
    # For time-based filtering, we use FilterHashtable with StartTime

    # EID 1: ProcessCreate - look for notepad.exe
    $xpath1 = "*[System[EventID=1 and TimeCreated[@SystemTime>='" + $StartTime.ToUniversalTime().ToString("o") + "']] and EventData[Data[@Name='Image']='C:\Windows\System32\notepad.exe']]"
    $results["EID  1 - ProcessCreate"] = Test-SysmonEvent -EventId 1 -StartTime $StartTime -XPathFilter $xpath1

    # EID 3: NetworkConnect - look for PowerShell connecting to port 80
    $results["EID  3 - NetworkConnect"] = Test-SysmonEvent -EventId 3 -StartTime $StartTime

    # EID 5: ProcessTerminate - look for notepad.exe
    $xpath5 = "*[System[EventID=5 and TimeCreated[@SystemTime>='" + $StartTime.ToUniversalTime().ToString("o") + "']] and EventData[Data[@Name='Image']='C:\Windows\System32\notepad.exe']]"
    $results["EID  5 - ProcessTerminate"] = Test-SysmonEvent -EventId 5 -StartTime $StartTime -XPathFilter $xpath5

    # EID 11: FileCreate
    $results["EID 11 - FileCreate"] = Test-SysmonEvent -EventId 11 -StartTime $StartTime

    # EID 12: RegistryCreate (system test)
    if ($AllowSystemChanges) {
        $results["EID 12 - RegistryCreate"] = Test-SysmonEvent -EventId 12 -StartTime $StartTime
    }

    # EID 13: RegistryValueSet (system test)
    if ($AllowSystemChanges) {
        $results["EID 13 - RegistryValueSet"] = Test-SysmonEvent -EventId 13 -StartTime $StartTime
    }

    # EID 15: FileCreateStreamHash
    $results["EID 15 - FileCreateStreamHash"] = Test-SysmonEvent -EventId 15 -StartTime $StartTime

    # EID 17: PipeCreate
    $results["EID 17 - PipeCreate"] = Test-SysmonEvent -EventId 17 -StartTime $StartTime

    # EID 18: PipeConnect
    $results["EID 18 - PipeConnect"] = Test-SysmonEvent -EventId 18 -StartTime $StartTime

    # EID 19: WmiFilterCreate (system test)
    if ($AllowSystemChanges) {
        $results["EID 19 - WmiFilterCreate"] = Test-SysmonEvent -EventId 19 -StartTime $StartTime
    }

    # EID 20: WmiConsumerCreate (system test)
    if ($AllowSystemChanges) {
        $results["EID 20 - WmiConsumerCreate"] = Test-SysmonEvent -EventId 20 -StartTime $StartTime
    }

    # EID 21: WmiBindingCreate (system test)
    if ($AllowSystemChanges) {
        $results["EID 21 - WmiBindingCreate"] = Test-SysmonEvent -EventId 21 -StartTime $StartTime
    }

    # EID 22: DnsQuery
    $results["EID 22 - DnsQuery"] = Test-SysmonEvent -EventId 22 -StartTime $StartTime

    # EID 26: FileDeleteDetected
    $results["EID 26 - FileDeleteDetected"] = Test-SysmonEvent -EventId 26 -StartTime $StartTime

    return $results
}

# --------------------------------------------------------------------------
# Cleanup
# --------------------------------------------------------------------------
function Invoke-Cleanup {
    Write-Status -Type Section -Message "CLEANUP"

    $cleanupResults = @{}

    # Remove test .exe file
    if (Test-Path $TEST_FILE_EXE) {
        try {
            Remove-Item -Path $TEST_FILE_EXE -Force
            $cleanupResults["File: $TEST_FILE_EXE"] = $true
            Write-Status "Cleanup" "Removed $TEST_FILE_EXE" -Type Pass
        } catch {
            $cleanupResults["File: $TEST_FILE_EXE"] = $false
            Write-Status "Cleanup" "FAILED to remove $TEST_FILE_EXE -- $_" -Type Fail
        }
    } else {
        $cleanupResults["File: $TEST_FILE_EXE"] = $true
        Write-Status "Cleanup" "$TEST_FILE_EXE already removed or was not created" -Type Info
    }

    # Remove test .bat file (may already be deleted by EID 26 test)
    if (Test-Path $TEST_FILE_BAT) {
        try {
            Remove-Item -Path $TEST_FILE_BAT -Force
            $cleanupResults["File: $TEST_FILE_BAT"] = $true
            Write-Status "Cleanup" "Removed $TEST_FILE_BAT" -Type Pass
        } catch {
            $cleanupResults["File: $TEST_FILE_BAT"] = $false
            Write-Status "Cleanup" "FAILED to remove $TEST_FILE_BAT -- $_" -Type Fail
        }
    } else {
        $cleanupResults["File: $TEST_FILE_BAT"] = $true
        Write-Status "Cleanup" "$TEST_FILE_BAT already removed (expected -- deleted during EID 26 test)" -Type Info
    }

    # Remove registry value (system test only)
    if ($AllowSystemChanges) {
        try {
            $regValue = Get-ItemProperty -Path $REG_PATH -Name $REG_VALUE_NAME -ErrorAction SilentlyContinue
            if ($regValue) {
                Remove-ItemProperty -Path $REG_PATH -Name $REG_VALUE_NAME -Force
                $cleanupResults["Registry: $REG_PATH\$REG_VALUE_NAME"] = $true
                Write-Status "Cleanup" "Removed registry value $REG_VALUE_NAME from Run key" -Type Pass
            } else {
                $cleanupResults["Registry: $REG_PATH\$REG_VALUE_NAME"] = $true
                Write-Status "Cleanup" "Registry value not found (was not created or already removed)" -Type Info
            }
        } catch {
            $cleanupResults["Registry: $REG_PATH\$REG_VALUE_NAME"] = $false
            Write-Status "Cleanup" "FAILED to remove registry value -- $_" -Type Fail
        }
    }

    # Remove WMI objects (system test only; binding first, then consumer, then filter)
    if ($AllowSystemChanges) {
        # Binding
        try {
            $binding = Get-WmiObject -Namespace "root/subscription" -Class "__FilterToConsumerBinding" -ErrorAction SilentlyContinue |
                Where-Object { $_.Filter -like "*$WMI_FILTER_NAME*" }
            if ($binding) {
                $binding | Remove-WmiObject
                $cleanupResults["WMI: Binding"] = $true
                Write-Status "Cleanup" "Removed WMI filter-to-consumer binding" -Type Pass
            } else {
                $cleanupResults["WMI: Binding"] = $true
                Write-Status "Cleanup" "WMI binding not found (was not created or already removed)" -Type Info
            }
        } catch {
            $cleanupResults["WMI: Binding"] = $false
            Write-Status "Cleanup" "FAILED to remove WMI binding -- $_" -Type Fail
        }

        # Consumer
        try {
            $consumer = Get-WmiObject -Namespace "root/subscription" -Class "CommandLineEventConsumer" -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -eq $WMI_CONSUMER_NAME }
            if ($consumer) {
                $consumer | Remove-WmiObject
                $cleanupResults["WMI: Consumer"] = $true
                Write-Status "Cleanup" "Removed WMI event consumer" -Type Pass
            } else {
                $cleanupResults["WMI: Consumer"] = $true
                Write-Status "Cleanup" "WMI consumer not found (was not created or already removed)" -Type Info
            }
        } catch {
            $cleanupResults["WMI: Consumer"] = $false
            Write-Status "Cleanup" "FAILED to remove WMI consumer -- $_" -Type Fail
        }

        # Filter
        try {
            $filter = Get-WmiObject -Namespace "root/subscription" -Class "__EventFilter" -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -eq $WMI_FILTER_NAME }
            if ($filter) {
                $filter | Remove-WmiObject
                $cleanupResults["WMI: Filter"] = $true
                Write-Status "Cleanup" "Removed WMI event filter" -Type Pass
            } else {
                $cleanupResults["WMI: Filter"] = $true
                Write-Status "Cleanup" "WMI filter not found (was not created or already removed)" -Type Info
            }
        } catch {
            $cleanupResults["WMI: Filter"] = $false
            Write-Status "Cleanup" "FAILED to remove WMI filter -- $_" -Type Fail
        }
    }

    # Kill any lingering notepad from our test (best effort)
    try {
        # Only kill notepad instances started very recently (within our test window)
        $notepad = Get-Process -Name "notepad" -ErrorAction SilentlyContinue
        if ($notepad) {
            # We cannot reliably distinguish our notepad from user's notepad
            # so we do NOT kill it -- just note it
            Write-Status "Cleanup" "notepad.exe process(es) still running -- not killed (may be user's)" -Type Info
        }
        $cleanupResults["Process: notepad.exe"] = $true
    } catch {
        $cleanupResults["Process: notepad.exe"] = $true
    }

    return $cleanupResults
}

# --------------------------------------------------------------------------
# Summary Report
# --------------------------------------------------------------------------
function Show-Summary {
    param(
        [hashtable]$TestResults,
        [hashtable]$CleanupResults
    )

    Write-Status -Type Section -Message "RESULTS SUMMARY"

    # Test results
    $passCount = 0
    $failCount = 0
    Write-Host ""
    Write-Host "  Event Detection Results:"
    Write-Host "  ------------------------"
    foreach ($key in $TestResults.Keys | Sort-Object) {
        if ($TestResults[$key]) {
            Write-Host "    [PASS] $key" -ForegroundColor Green
            $passCount++
        } else {
            Write-Host "    [FAIL] $key" -ForegroundColor Red
            $failCount++
        }
    }
    $totalTests = $passCount + $failCount
    Write-Host ""
    Write-Host "  Detection: $passCount of $totalTests events verified"

    if ($failCount -gt 0) {
        Write-Host ""
        Write-Host "  FAILED events may indicate:" -ForegroundColor Yellow
        Write-Host "    - The Sysmon config does not monitor this event type (by design)" -ForegroundColor Yellow
        Write-Host "    - The event type is disabled in the config (e.g., ImageLoad, FileDelete)" -ForegroundColor Yellow
        Write-Host "    - Event log propagation was slower than the $WaitSeconds second wait" -ForegroundColor Yellow
        Write-Host "      (try re-running with -WaitSeconds 30)" -ForegroundColor Yellow
        Write-Host "    - The config uses include rules that do not match the test action" -ForegroundColor Yellow
    }

    # Cleanup results
    Write-Host ""
    Write-Host "  Cleanup Results:"
    Write-Host "  ----------------"
    $cleanupFailed = @()
    foreach ($key in $CleanupResults.Keys | Sort-Object) {
        if ($CleanupResults[$key]) {
            Write-Host "    [OK]   $key" -ForegroundColor Green
        } else {
            Write-Host "    [FAIL] $key" -ForegroundColor Red
            $cleanupFailed += $key
        }
    }

    if ($cleanupFailed.Count -gt 0) {
        Write-Host ""
        Write-Host "  WARNING: Some cleanup operations failed." -ForegroundColor Red
        Write-Host "  The following artifacts remain on the system:" -ForegroundColor Red
        foreach ($item in $cleanupFailed) {
            Write-Host "    - $item" -ForegroundColor Red
        }
        Write-Host ""
        Write-Host "  Manual cleanup steps:" -ForegroundColor Yellow
        Write-Host "  See the ICS Watch Dog Efficacy Testing Guide appendix for" -ForegroundColor Yellow
        Write-Host "  detailed manual removal instructions for each artifact type." -ForegroundColor Yellow
        Write-Host "  Guide: https://icswatchdog.com/efficacy-testing/" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Quick reference:" -ForegroundColor Yellow
        Write-Host "    Files:    Remove-Item -Path <path> -Force" -ForegroundColor Yellow
        Write-Host "    Registry: Remove-ItemProperty -Path '$REG_PATH' -Name '$REG_VALUE_NAME' -Force" -ForegroundColor Yellow
        Write-Host "    WMI:      Get-WmiObject -Namespace 'root/subscription' -Class '__EventFilter' |" -ForegroundColor Yellow
        Write-Host "                Where-Object { `$_.Name -eq '$WMI_FILTER_NAME' } | Remove-WmiObject" -ForegroundColor Yellow
        Write-Host "              (Repeat for CommandLineEventConsumer and __FilterToConsumerBinding)" -ForegroundColor Yellow
    } else {
        Write-Host ""
        Write-Host "  All test artifacts cleaned up successfully." -ForegroundColor Green
    }

    # System tests status
    if (-not $AllowSystemChanges) {
        Write-Host ""
        Write-Host "  System tests not run (use -AllowSystemChanges to include):"
        Write-Host "  ----------------------------------------------------------"
        Write-Host "    EID 12 - RegistryCreate       (modifies HKCU Run key)"
        Write-Host "    EID 13 - RegistryValueSet     (modifies HKCU Run key)"
        Write-Host "    EID 19 - WmiFilterCreate      (creates WMI subscription)"
        Write-Host "    EID 20 - WmiConsumerCreate     (creates WMI subscription)"
        Write-Host "    EID 21 - WmiBindingCreate      (creates WMI subscription)"
    }

    # Skipped Event IDs
    Write-Host ""
    Write-Host "  Skipped Event IDs (not safely testable):"
    Write-Host "  -----------------------------------------"
    Write-Host "    EID  2 - FileCreateTime       (requires timestomping)"
    Write-Host "    EID  6 - DriverLoad           (requires loading a driver)"
    Write-Host "    EID  7 - ImageLoad            (disabled by default, high volume)"
    Write-Host "    EID  8 - CreateRemoteThread   (requires process injection)"
    Write-Host "    EID  9 - RawAccessRead        (disabled by default)"
    Write-Host "    EID 10 - ProcessAccess        (targets lsass.exe)"
    Write-Host "    EID 23 - FileDelete (archived)(disabled by default)"
    Write-Host "    EID 25 - ProcessTampering     (requires process hollowing)"
    Write-Host ""
    Write-Host "  For testing skipped Event IDs, see:"
    Write-Host "    - SysmonSimulator: https://github.com/ScarredMonk/SysmonSimulator"
    Write-Host "    - Atomic Red Team: https://github.com/redcanaryco/atomic-red-team"
    Write-Host "    - MITRE Caldera:   https://caldera.mitre.org/"
    Write-Host "    - Scythe:          https://scythe.io/"
    Write-Host ""
}

# ==========================================================================
# Main Execution
# ==========================================================================

Write-Host ""
Write-Host "============================================================"
Write-Host "  ICS Watch Dog - Sysmon Configuration Efficacy Test"
Write-Host "  https://icswatchdog.com"
if ($AllowSystemChanges) {
    Write-Host "  Mode: ALL TESTS (observation + system modification)"
} else {
    Write-Host "  Mode: OBSERVATION-ONLY (default)"
}
Write-Host "============================================================"

# Pre-flight
if (-not (Invoke-PreFlightChecks)) {
    Write-Host ""
    Write-Host "Pre-flight checks failed. Resolve the issues above and re-run." -ForegroundColor Red
    exit 1
}

# Show planned changes
Show-PlannedChanges

# Confirmation
if (-not $SkipConfirmation) {
    $response = Read-Host "  Proceed with efficacy testing? (Y/N)"
    if ($response -notmatch "^[Yy]") {
        Write-Host ""
        Write-Host "  Test cancelled by user." -ForegroundColor Yellow
        exit 0
    }
}

# Record start time (for event log queries)
$startTime = (Get-Date).AddSeconds(-1)

# Execute triggers
Invoke-Triggers -StartTime $startTime

# Verify events
$testResults = Invoke-Verification -StartTime $startTime

# Cleanup
$cleanupResults = Invoke-Cleanup

# Summary
Show-Summary -TestResults $testResults -CleanupResults $cleanupResults

Write-Host "============================================================"
Write-Host "  Test complete."
Write-Host "============================================================"
Write-Host ""
