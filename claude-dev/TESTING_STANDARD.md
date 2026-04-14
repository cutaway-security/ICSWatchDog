# TESTING_STANDARD.md

How to test ICS Watch Dog configuration files and scripts across the development VM fleet. This standard governs what is tested, how tests are run, and how results are recorded.

For VM setup, connectivity, and lifecycle details see `claude-dev/REMOTE_TESTING.md`.

---

## 1. Scope

This standard covers three categories of testing, performed in this order:

1. **Configuration testing** -- can a Sysmon config be loaded and does it apply the expected rules?
2. **Script testing** -- do the PowerShell tools run correctly on each target OS and PS version?
3. **Efficacy testing** -- does a loaded config detect the activity it claims to detect?

Each category has its own procedures and pass/fail criteria defined below. Do not proceed to a later category until the earlier one passes.

---

## 2. Test Environment

### 2.1 Available systems

| SSH Alias | VMID | Proxmox | OS | Sysmon | Schema | PS Version | Notes |
|---|---|---|---|---|---|---|---|
| Win7Pro-Dev | 107 | proxmox0 | Windows 7 Pro | 10.42 | 4.23 | 2.0 | Legacy. Needs dedicated 4.23 config. PS 2.0 is below tool minimum (3.0). |
| Win10Pro-Dev | 108 | proxmox0 | Windows 10 Pro | 15.20 | 4.91 | 5.1 | |
| Win11Pro-Dev | 102 | proxmox0 | Windows 11 Pro | 15.20 | 4.91 | 5.1 | |
| WinServer2016-Dev | 110 | proxmox0 | Windows Server 2016 | 15.20 | 4.91 | TBD | Start VM and verify before first test. |
| WinServer2019-Dev | 109 | proxmox0 | Windows Server 2019 | 15.20 | 4.91 | TBD | Start VM and verify before first test. |
| WinServer2022-Dev | 111 | proxmox0 | Windows Server 2022 | 15.20 | 4.91 | TBD | Start VM and verify before first test. |

Systems not yet available (VMID = N/A): WinServer2012-Dev, WinServer2025-Dev. Do not include in test runs until installed and added to this table.

### 2.2 VM lifecycle rules

- **Maximum 3 VMs running concurrently.** The Proxmox hosts are Intel NUCs with limited RAM.
- **Start before testing, stop when done.** Do not leave VMs running overnight or between sessions.
- Start/stop via SSH to the Proxmox host (use the VMID from the table above):
  ```
  ssh proxmox0 "qm start <VMID>"
  ssh proxmox0 "qm stop <VMID>"
  ssh proxmox0 "qm status <VMID>"
  ```
- **Single source of truth: `~/.ssh/config`.** The developer workstation's SSH config holds the host alias, IP, user, key, and VMID for every test VM. The VMID is stored as a structured comment on each host entry (format: `# VMID=<id> PROXMOX=<alias>`). Use SSH aliases (e.g., `Win10Pro-Dev`) for all test commands, not raw IPs.

### 2.3 File transfer pattern

```
# Copy a config or script to a VM
scp <local-file> <SSH-Alias>:Temp/<filename>

# Retrieve results
scp <SSH-Alias>:Temp/<filename> <local-dest>
```

The `C:\Temp` directory must exist on the VM. Create it with `ssh <alias> "mkdir C:\Temp"` if needed.

---

## 3. Schema Version Compatibility

### 3.1 Schema tiers

| Schema | Sysmon Minimum | Supported Systems | Config Tier |
|---|---|---|---|
| 4.23 | Sysmon 10.42 | Win7 only | Legacy |
| 4.90 | Sysmon 14+ | Win10, Win11, Server 2016-2025 | Standard (all curated configs) |

### 3.2 Features unavailable at schema 4.23

The following Sysmon event types do not exist at schema 4.23 and MUST be removed from any legacy config:

- FileDelete (Event ID 23) -- added in schema 4.30 / Sysmon 11
- ClipboardChange (Event ID 24) -- added in schema 4.35 / Sysmon 12
- ProcessTampering (Event ID 25) -- added in schema 4.50 / Sysmon 13
- FileDeleteDetected (Event ID 26) -- added in schema 4.50 / Sysmon 13
- FileBlockExecutable (Event ID 27) -- added in schema 4.80 / Sysmon 14
- FileBlockShredding (Event ID 28) -- added in schema 4.80 / Sysmon 14
- FileExecutableDetected (Event ID 29) -- added in schema 4.80 / Sysmon 14

All core detection event types remain available at 4.23: ProcessCreate, FileCreateTime, NetworkConnect, ProcessTerminate, DriverLoad, ImageLoad, CreateRemoteThread, RawAccessRead, ProcessAccess, FileCreate, RegistryEvent, FileCreateStreamHash, PipeEvent, WmiEvent, DnsQuery.

### 3.3 Schema validation rule

Before any config is tested on a VM, verify the config's `schemaversion` attribute is compatible:

- Sysmon 15.20 (schema 4.91): accepts configs at schema **4.90 or 4.91**. Rejects schema 4.50 (confirmed by testing).
- Sysmon 10.42 (schema 4.23): accepts configs at schema **4.23 or below**.

A config that fails to load due to schema mismatch is a **configuration defect**, not a test environment issue.

---

## 4. Configuration Testing

### 4.1 What to test

Every curated configuration file under `sysmon-configs/sysmonconfig-*.xml` and any legacy config must be loaded and verified on at least one system per OS family where the config is applicable.

### 4.2 Test matrix

The following table defines which configs are tested on which systems. Mark N/A for configs that are not intended for that system type.

**Workstation configs** (baseline-it-workstation, baseline-ot, enhanced-ot, advanced-ot):

| Config | Win7 | Win10 | Win11 |
|---|---|---|---|
| sysmonconfig-baseline-it-workstation.xml | N/A (use legacy) | Test | Test |
| sysmonconfig-baseline-ot.xml | N/A (use legacy) | Test | Test |
| sysmonconfig-enhanced-ot.xml | N/A (use legacy) | Test | Test |
| sysmonconfig-advanced-ot.xml | N/A (use legacy) | Test | Test |
| sysmonconfig-legacy-win7.xml | Test | N/A | N/A |

**Server configs** (baseline-it-server, server-ad, server-services, jumphost):

| Config | Server 2016 | Server 2019 | Server 2022 |
|---|---|---|---|
| sysmonconfig-baseline-it-server.xml | Test | Test | Test |
| sysmonconfig-server-ad.xml | Test | Test | Test |
| sysmonconfig-server-services.xml | Test | Test | Test |
| sysmonconfig-jumphost.xml | Test | Test | Test |

### 4.3 Procedure per config per VM

1. **Copy the config to the VM:**
   ```
   scp sysmon-configs/<config>.xml <SSH-Alias>:Temp/<config>.xml
   ```

2. **Load the config into Sysmon:**
   ```
   ssh <SSH-Alias> "C:\Windows\Sysmon64.exe -c C:\Temp\<config>.xml"
   ```
   On Win7 (PS 2.0), commands must be run via `cmd` syntax, not PowerShell cmdlets.

3. **Verify the config loaded:**
   ```
   ssh <SSH-Alias> "C:\Windows\Sysmon64.exe -c"
   ```
   Check for:
   - "Rule configuration (version X.XX):" line appears (not "No rules installed")
   - The expected rule groups are listed (ProcessCreate, NetworkConnect, etc.)

4. **Check the Application event log for Sysmon errors:**
   ```
   ssh <SSH-Alias> "powershell -Command \"Get-WinEvent -LogName 'Microsoft-Windows-Sysmon/Operational' -MaxEvents 5 | Select-Object TimeCreated, Id, Message\""
   ```
   No errors or warnings from Sysmon within the last 30 seconds.

5. **Reset the config** after testing (so the next test starts clean):
   ```
   ssh <SSH-Alias> "C:\Windows\Sysmon64.exe -c --"
   ```

### 4.4 Pass criteria

A config **passes** on a given system if:
- `Sysmon64.exe -c <config>` outputs "Configuration updated."
- `Sysmon64.exe -c` shows the expected rule groups (not "No rules installed")
- No Sysmon errors in the event log after loading

A config **fails** if:
- Loading produces "No rules installed"
- Loading produces an error message (schema mismatch, XML parse error, unsupported event type)
- Sysmon crashes or becomes unresponsive after loading

### 4.5 Recording results

Update the compatibility matrix in README.md (Section 7) with the date and result for each cell. Format:

```
| Config | Win10 (15.20/4.91/5.1) | Win11 (15.20/4.91/5.1) | Server 2019 (15.20/4.91/5.1) |
|---|---|---|---|
| baseline-ot | PASS 2026-04-11 | PASS 2026-04-11 | PASS 2026-04-11 |
```

---

## 5. Script Testing

### 5.1 What to test

Every user-facing script under `tools/` that is not a test harness:
- `tools/Merge-SysmonModules.ps1`
- `tools/Test-SysmonConfig.ps1`
- `tools/Get-SysmonCoverage.ps1` (and future tools: `Export-SystemInventory.ps1`, `Compare-SystemInventory.ps1`)

### 5.2 PowerShell version requirements

| PS Version | Minimum Required | Systems |
|---|---|---|
| 2.0 | NOT SUPPORTED. Scripts must detect PS 2.0 and exit with a clear message. | Win7 |
| 3.0+ | Supported | All others |

Scripts must include a PS version check near the top:

```powershell
if ($PSVersionTable.PSVersion.Major -lt 3) {
    Write-Error "This script requires PowerShell 3.0 or later. Current version: $($PSVersionTable.PSVersion)"
    exit 1
}
```

### 5.3 Script test matrix

| Script | Win10 | Win11 | Server 2016 | Server 2019 | Server 2022 | Win7 (expect clean error) |
|---|---|---|---|---|---|---|
| Merge-SysmonModules.ps1 | Test | Test | Test | Test | Test | Test (expect PS version error) |
| Test-SysmonConfig.ps1 | Test | Test | Test | Test | Test | Test (expect PS version error) |
| Get-SysmonCoverage.ps1 | Test | Test | Test | Test | Test | Test (expect PS version error) |

### 5.4 Procedure

1. **Copy the script (and any dependencies) to the VM:**
   ```
   scp tools/<script>.ps1 <SSH-Alias>:Temp/
   scp sysmon-configs/<config>.xml <SSH-Alias>:Temp/  # if the script needs a config
   scp -r sysmon-configs/modules/ <SSH-Alias>:Temp/modules/  # if the script needs modules
   ```

2. **Run the script:**
   ```
   ssh <SSH-Alias> "powershell -ExecutionPolicy Bypass -File C:\Temp\<script>.ps1 <args>"
   ```

3. **Verify output matches expectations** (see per-script checks below).

### 5.5 Per-script checks

**Merge-SysmonModules.ps1:**
- Merges a base config with one or more modules
- Output XML is well-formed (no parse errors)
- Load the merged output into Sysmon on the same VM to confirm it works end-to-end

**Test-SysmonConfig.ps1:**
- Runs the efficacy test against a loaded config
- Expected output format and non-zero test count

**Get-SysmonCoverage.ps1:**
- Run with `-ConfigPath` pointing to a config on the VM
- Console output includes all four coverage sections
- JSON output is parseable
- Markdown output has expected headers
- If `-InventoryPath` is used, verify it reads the JSON correctly

### 5.6 Pass criteria

A script **passes** on a given system if:
- It runs to completion with exit code 0 (or expected exit code for negative tests)
- Output matches expected format and content
- On Win7 (PS 2.0): the script exits cleanly with a PS version error (does not crash or produce garbled output)

### 5.7 Merge testing on Windows

The merge tool must be tested end-to-end on at least one Windows system:

1. Copy the merge script, a base config, and one or more modules to the VM
2. Run the merge
3. Load the merged output into Sysmon on the same VM
4. Verify rules from both the base config and the modules are present

This validates that the merge output is acceptable to a real Sysmon installation, not just well-formed XML.

---

## 6. Efficacy Testing

### 6.1 Scope

Efficacy testing verifies that a loaded config detects the activity it claims to detect. This is performed AFTER configuration testing and script testing pass, and AFTER a commit and push.

### 6.2 Procedure

Use `tools/Test-SysmonConfig.ps1` on target systems with a loaded config. The test script generates known-detectable activity and checks the Sysmon event log for matching events.

### 6.3 When to run

- After the schema 4.50 to 4.90 bump, to confirm no detection regressions
- After merging modules into a base config
- Before any release tag

Detailed efficacy test procedures will be defined when this phase is reached. Configuration and script testing are prerequisites.

---

## 7. Version-Specific Notes

### 7.1 Win7 (Sysmon 10.42 / Schema 4.23 / PS 2.0)

- Only the legacy config (`sysmonconfig-legacy-win7.xml`) is tested on Win7.
- PowerShell scripts are expected to fail with a version check error. This is a PASS (the script handles the version gracefully) not a FAIL.
- SSH commands must use `cmd` syntax or PowerShell 2.0 compatible cmdlets. Not all PS 5.1 features are available.
- Sysmon binary is `Sysmon64.exe` on 64-bit Win7 (confirmed).

### 7.2 Server VMs (2016, 2019, 2022)

- Use `Administrator` (not `devadm`) as the SSH user.
- These VMs are stopped by default. Start them before testing and stop them when done.
- PS version and specific Sysmon behavior should be verified on first test and recorded in the Section 2.1 table above.

---

## 8. Test Run Documentation

### 8.1 During a test run

Record the following for each test:
- Date
- VM alias (e.g., Win10Pro-Dev)
- Config or script tested
- Result (PASS / FAIL)
- If FAIL: the error message or symptom
- The Sysmon version and schema version on the target (to confirm test environment)

### 8.2 After a test run

Update two locations:

1. **README.md compatibility matrix** (public-facing): the summary result per config/script per OS.
2. **claude-dev/RESUME.md** (dev-facing): what was tested, any issues found, any fixes applied.

### 8.3 Re-testing after changes

If a config or script is modified after testing (e.g., schema bump, bug fix), all previously-passing tests for that artifact must be re-run. The compatibility matrix dates should reflect the most recent test run, not the original.

---

## 9. Adding a New Test System

When a new VM is added to the fleet (e.g., Server 2012, Server 2025):

1. Add a `Host <alias>` block to `~/.ssh/config` with `HostName`, `IdentityFile`, and a `# VMID=<id> PROXMOX=<alias>` comment line
2. Add a row to the "Available systems" table in Section 2.1 above (SSH alias, VMID, Proxmox, OS, Sysmon, Schema, PS Version)
3. Add a column to the test matrices in Sections 4 and 5
4. Run the full config and script test suite against the new system
5. Update README.md compatibility matrix with results
