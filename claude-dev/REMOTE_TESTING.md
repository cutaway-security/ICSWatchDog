# REMOTE_TESTING.md

How to set up a remote Windows test environment on a Proxmox VE host so the ICS Watch Dog tools (`tools/*.ps1`) can be exercised against real Windows systems without needing a local Windows workstation.

This document is a development aid. It is not user-facing. It lives under `claude-dev/` and is stripped from releases.

---

## CRITICAL: Public Branch Hygiene

**The `claude-dev` branch is publicly accessible on GitHub.** Anything committed here is world-readable.

The following MUST NEVER appear in any file under this repository:

- Real hostnames, IP addresses, or DNS names of any test or production system
- SSH private keys or public keys (even public keys can identify hosts)
- Passwords, API tokens, license keys, certificate material
- Real usernames associated with real hosts
- Network names (SSIDs, VPN names, AD domain names)
- Internal URLs, internal paths that reveal organization structure

**Use only generic placeholders in this document and in committed config templates:**

| Placeholder | Meaning |
|-------------|---------|
| `<lab-host>` | The Proxmox host on the lab network |
| `<vm-name>` | A test VM, e.g. `<vm-win10-eng>`, `<vm-win11-hmi>` |
| `<lab-user>` | Local Windows account used for testing |
| `~/.ssh/icswd_dev_ed25519` | Local-only SSH key path. The key file itself is never committed. |
| `<lab-network>` | The lab subnet, e.g. `<lab-network>/24` |

If you find yourself wanting to type a real hostname into a committed file, stop. Put it in a local config file instead (see Section 7).

---

## 1. Goals

- Run `tools/Test-*.ps1` harnesses against real Windows installations of varying versions (Server 2016, Server 2019, Server 2022, Windows 10, Windows 11).
- Validate that `Get-SysmonCoverage.ps1`, `Export-SystemInventory.ps1`, and `Compare-SystemInventory.ps1` work end-to-end on a real registry, real `Get-Process`, real listening ports.
- Reproduce specific OT system roles (engineering workstation, HMI, domain controller, historian, jump host) for fixture generation and module validation.
- Be scriptable from a Linux developer workstation via SSH and key-based auth. No interactive RDP for routine test runs.

## 2. Non-Goals

- Production deployment infrastructure. This is dev-only.
- Multi-tenant lab access. One developer at a time.
- Domain joining or AD integration unless specifically testing AD-related modules.
- Hardening the test VMs against attack. They are throwaway.

---

## 3. Topology

```
+----------------------------------+
|  Developer workstation (Linux)   |
|  - tools/ scripts                |
|  - SSH client                    |
|  - claude-dev/remote-testing.local.conf  (gitignored)
+----------------------------------+
              |
              | SSH (key-based, port 22)
              v
+----------------------------------+
|  Proxmox VE host <lab-host>      |
|  - hosts Windows test VMs        |
|  - bridges VMs to <lab-network>  |
+----------------------------------+
              |
              | (VM bridge)
              v
+----------------------------------+
|  Windows test VMs                |
|  - <vm-name> with OpenSSH server |
|  - SSH key auth, no passwords    |
|  - Sysmon installed              |
+----------------------------------+
```

The developer SSHes directly to each Windows VM by IP/name resolved via the local config file. The Proxmox host itself is only touched for VM lifecycle (start/stop/snapshot), not for routine test runs.

---

## 4. Why SSH and Not WinRM

WinRM is the Windows-native remoting story but has friction for cross-platform automation:

| Concern | WinRM | OpenSSH on Windows |
|---------|-------|--------------------|
| Cross-platform client | Limited (PowerShell Core, pwsh-omi) | Standard OpenSSH client, works everywhere |
| Auth | NTLM/Kerberos/Cert (complex) | SSH key-based, simple |
| Firewall | TCP 5985/5986, often blocked | TCP 22, conventional |
| Scripting | `Invoke-Command` with sessions | Plain `ssh <host> "command"` |
| Idle complexity | Trusted hosts, listener config, SPN | None |

OpenSSH Server is now a built-in Windows optional feature (Server 2019+, Windows 10 1809+) and is fully supported by Microsoft. For dev/test work, key-based SSH is the simpler path.

WinRM is documented as an alternative in Section 9 but is not the recommended default.

---

## 5. Proxmox VE Host Setup

Assumptions: Proxmox VE 8.x already installed on `<lab-host>`. Network bridge `vmbr0` exists and routes to `<lab-network>`.

### 5.1 Storage layout

Create a dedicated storage pool for test VM images and snapshots so they can be deleted/rebuilt without affecting other VMs. Recommended:

- ZFS pool or LVM-thin volume of at least 200 GB for VM disks
- Separate ISO storage for Windows install media and VirtIO drivers

### 5.2 Required ISOs

Download and store on the Proxmox host's ISO storage:

- Windows Server 2019 Evaluation ISO (Microsoft Evaluation Center)
- Windows Server 2022 Evaluation ISO
- Windows 10 Enterprise Evaluation ISO
- Windows 11 Enterprise Evaluation ISO
- VirtIO drivers ISO (`virtio-win.iso` from Fedora project)
- Sysmon (latest from Sysinternals; can be uploaded to each VM at install time)

Evaluation editions are time-limited but suffice for ephemeral test VMs that get rebuilt frequently.

### 5.3 VM template

Create a single Windows base template per OS version, then clone it for each test scenario. Template settings:

| Setting | Value |
|---------|-------|
| BIOS | OVMF (UEFI) |
| Machine | q35 |
| CPU | 2 cores, host type |
| RAM | 4096 MB minimum |
| Disk | 60 GB, VirtIO SCSI, discard on |
| Network | VirtIO, bridge vmbr0 |
| QEMU agent | Enabled |
| SCSI controller | VirtIO SCSI single |

After Windows install in the template:

1. Install VirtIO drivers from the mounted virtio-win.iso
2. Install QEMU guest agent
3. Apply latest Windows updates (one round)
4. Disable Windows Defender real-time protection (test VMs only — they are isolated)
5. Install OpenSSH Server (Section 6)
6. Install Sysmon with a baseline ICS Watch Dog config
7. Sysprep with `/generalize /oobe /shutdown` so clones get unique SIDs
8. Snapshot as `template-clean`

### 5.4 Cloning a test VM

```
qm clone <template-vmid> <new-vmid> --name <vm-name> --full
qm start <new-vmid>
```

The cloned VM picks up a new MAC, gets a new DHCP lease, and on first boot completes OOBE.

---

## 6. Windows VM Setup: OpenSSH Server with Key Auth

Run inside each test VM (as Administrator):

### 6.1 Install OpenSSH Server

```powershell
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' `
    -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
```

### 6.2 Disable password auth, enable key auth

Edit `C:\ProgramData\ssh\sshd_config`:

```
PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin no
```

For an administrator account, the authorized keys file must live at `C:\ProgramData\ssh\administrators_authorized_keys` with these ACLs (Microsoft's documented requirement):

```powershell
$acl = Get-Acl C:\ProgramData\ssh\administrators_authorized_keys
$acl.SetAccessRuleProtection($true, $false)
$rules = @(
    New-Object System.Security.AccessControl.FileSystemAccessRule('Administrators','FullControl','Allow'),
    New-Object System.Security.AccessControl.FileSystemAccessRule('SYSTEM','FullControl','Allow')
)
foreach ($r in $rules) { $acl.AddAccessRule($r) }
Set-Acl C:\ProgramData\ssh\administrators_authorized_keys $acl

Restart-Service sshd
```

For a non-admin test user, the key goes in `C:\Users\<lab-user>\.ssh\authorized_keys` with that user as owner.

### 6.3 Default shell

To make remote command execution feel natural, set PowerShell as the default shell:

```powershell
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell `
    -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
```

### 6.4 Test from the developer workstation

```
ssh -i ~/.ssh/icswd_dev_ed25519 <lab-user>@<vm-name> "Get-Host | Select-Object Version"
```

Should return the PowerShell version with no password prompt.

---

## 7. Local Configuration File (Never Committed)

Real hostnames, IPs, and key paths live in a single local file that is git-ignored.

### 7.1 Template (committed)

`claude-dev/remote-testing.example.conf`:

```
# Copy this file to remote-testing.local.conf and fill in real values.
# remote-testing.local.conf is gitignored and MUST NEVER be committed.

# Proxmox host (only used for VM lifecycle commands, not test runs)
PROXMOX_HOST=<lab-host>
PROXMOX_USER=<proxmox-user>

# SSH key (path on developer workstation; key file itself is never committed)
SSH_KEY_PATH=~/.ssh/icswd_dev_ed25519

# Test VMs (one line per VM)
# Format: VM_<role>=<user>@<host-or-ip>
VM_WIN10_ENG=<lab-user>@<vm-name>
VM_WIN11_HMI=<lab-user>@<vm-name>
VM_SRV2019_DC=<lab-user>@<vm-name>
VM_SRV2022_HISTORIAN=<lab-user>@<vm-name>
VM_WIN10_JUMPHOST=<lab-user>@<vm-name>
```

### 7.2 .gitignore entries

Add to `.gitignore` at repo root:

```
claude-dev/remote-testing.local.conf
~/.ssh/icswd_dev_*
```

### 7.3 Loading the config

Test orchestration scripts (none committed yet — to be written when the test runner lands) source this file and substitute placeholders. Nothing the script reads from the local config ever gets written to a log file or committed artifact.

---

## 8. Test Run Pattern

Once a VM is reachable via SSH, a typical test session looks like:

```
# From the developer workstation, sourcing the local config:
source claude-dev/remote-testing.local.conf

# Copy the tool to the VM
scp -i $SSH_KEY_PATH tools/Get-SysmonCoverage.ps1 $VM_WIN10_ENG:C:/Temp/

# Run it remotely
ssh -i $SSH_KEY_PATH $VM_WIN10_ENG "powershell -File C:/Temp/Get-SysmonCoverage.ps1 -ConfigPath C:/Temp/sysmonconfig-baseline-ot.xml -OutputFormat JSON" > coverage-result.json

# Or run an inventory export and bring the JSON back
ssh -i $SSH_KEY_PATH $VM_WIN10_ENG "powershell -File C:/Temp/Export-SystemInventory.ps1 -OutputPath C:/Temp/inventory.json"
scp -i $SSH_KEY_PATH $VM_WIN10_ENG:C:/Temp/inventory.json ./local-inventory.json
```

The VM is treated as a black box. Tools are copied in, run, results pulled out. The VM does not need to know anything about the developer workstation.

---

## 9. WinRM Alternative (Not Recommended)

If SSH on Windows is unavailable for some reason (very old Server 2016, restrictive policy), WinRM over HTTPS with certificate auth is the fallback. Outline only — not the recommended path:

1. Generate a self-signed cert on the VM with `New-SelfSignedCertificate`
2. Configure WinRM HTTPS listener bound to that cert
3. Add the developer's client cert thumbprint as a trusted user mapping
4. From Linux, use `pwsh` with `Enter-PSSession -ConnectionUri https://...` and `-CertificateThumbprint`

The complexity is not worth it for dev/test. Use SSH unless you have a hard reason not to.

---

## 10. Snapshots and Rebuilds

Snapshot strategy for each VM:

| Snapshot name | When taken | Purpose |
|---------------|------------|---------|
| `clean` | After OS install + SSH + Sysmon, before any test runs | Roll back to a known-clean state |
| `with-vendor-software` | After installing OT vendor software (Siemens TIA, Rockwell, Ignition, etc.) | Roll back without reinstalling the multi-GB vendor packages |
| `pre-test` | Before each test run that mutates state | Cheap rollback |

```
qm snapshot <vmid> clean --description "post-install baseline"
qm rollback <vmid> clean
```

A test VM that becomes wedged should be rolled back, not debugged in place.

---

## 11. Open Items (TODO)

These are the gaps to close as remote testing matures. None are blockers for the current Phase 11d work.

- [ ] Build a small test orchestration script (`claude-dev/remote-test-runner.ps1` or `.sh`) that reads `remote-testing.local.conf`, copies tools to a target VM, runs them, retrieves results, and produces a pass/fail summary.
- [ ] Standardize VM naming and snapshot conventions across the lab.
- [ ] Decide whether OT vendor software (Siemens TIA, Rockwell Studio 5000) gets installed in dedicated VMs, given license terms.
- [ ] Determine which Windows versions are in scope for routine CI vs. occasional manual validation.
- [ ] Document the per-OS quirks discovered along the way (e.g., Server Core vs. Desktop Experience differences in registry layout for installed software).
- [ ] Investigate Proxmox API automation for non-interactive VM lifecycle from the dev workstation.

---

## 12. Threat Model for the Test Lab

Brief, because this is a dev-only lab on an isolated network:

- **Test VMs are untrusted by default.** They run experimental Sysmon configs, may have Defender disabled, and may host vendor software with known CVEs. Do not give them access to anything outside the lab network.
- **The developer SSH key is the crown jewel.** Lose it and an attacker gets root on every test VM. Keep the private key on the developer workstation only, never on a VM, never in the repo, never in the local config file.
- **Proxmox host management interface** must not be exposed to the public internet. Keep it on a management network only reachable from the dev workstation.
- **Test data is not real OT data.** Inventory JSONs captured from these VMs can be shared (after sanitization) without operational risk because nothing in them came from a real plant.
