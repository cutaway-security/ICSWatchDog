# Module Library Index

This is the index of all available modules in the ICS Watch Dog module library. Each entry lists the module's purpose, ATT&CK references, and schema requirement.

For module format, dual-use convention, and merge tool usage, see [README.md](README.md).

## Statistics

| Category | Count |
|----------|-------|
| OT Vendor (`vendor-ot/`) | 5 |
| IT Vendor (`vendor-it/`) | 5 |
| Cloud Storage (`cloud-storage/`) | 8 |
| Sector (`sector/`) | 4 |
| Protocol (`protocol/`) | 8 |
| Remote Access (`remote-access/`) | 5 |
| LOLBAS (`lolbas/`) | 13 |
| **Total** | **48** |

This is the initial release. The library will grow over time as community contributions are accepted and additional vendors, sectors, and tools are added.

## OT Vendor Modules

Include rules for monitoring OT vendor software activity. Add these to a curated config to detect unexpected execution of engineering tools, project file activity, and vendor-specific configuration changes.

| Module | Purpose | ATT&CK | Schema |
|--------|---------|--------|--------|
| [siemens-tia-portal.xml](vendor-ot/siemens-tia-portal.xml) | Siemens TIA Portal engineering tool and project files | T1565.001 | 4.50 |
| [rockwell-studio5000.xml](vendor-ot/rockwell-studio5000.xml) | Rockwell Studio 5000 / RSLogix 500 / RSLogix 5 | T1565.001 | 4.50 |
| [schneider-ecostruxure.xml](vendor-ot/schneider-ecostruxure.xml) | Schneider Electric EcoStruxure / Unity Pro / Citect | T1565.001 | 4.50 |
| [aveva-pi-system.xml](vendor-ot/aveva-pi-system.xml) | AVEVA / OSIsoft PI System (historian) | T1005, T1213, T1565.002, T0830 | 4.50 |
| [ignition-gateway.xml](vendor-ot/ignition-gateway.xml) | Inductive Automation Ignition Gateway | T1505.003, T1565.002, T0830 | 4.50 |

## IT Vendor Modules (Noise Reduction)

Exclude rules for IT software present on OT engineering workstations. Use these to suppress event volume from approved IT applications.

**Warning**: Excluding software reduces forensic visibility. Apply only when noise volume is overwhelming and the software is fully sanctioned.

| Module | Purpose | Schema |
|--------|---------|--------|
| [exclude_google_chrome.xml](vendor-it/exclude_google_chrome.xml) | Suppress noise from sanctioned Google Chrome | 4.50 |
| [exclude_microsoft_edge.xml](vendor-it/exclude_microsoft_edge.xml) | Suppress noise from sanctioned Microsoft Edge | 4.50 |
| [exclude_mozilla_firefox.xml](vendor-it/exclude_mozilla_firefox.xml) | Suppress noise from sanctioned Mozilla Firefox | 4.50 |
| [exclude_adobe_reader.xml](vendor-it/exclude_adobe_reader.xml) | Suppress noise from sanctioned Adobe Acrobat Reader | 4.50 |
| [exclude_microsoft_office.xml](vendor-it/exclude_microsoft_office.xml) | Suppress noise from Word, Excel, PowerPoint, Outlook | 4.50 |

## Cloud Storage Modules (Dual-Use)

Cloud storage clients are dual-use: sanctioned use needs noise reduction, unsanctioned use needs detection. Pick exactly one variant per tool based on site policy.

| Module | Variant | Purpose | ATT&CK | Schema |
|--------|---------|---------|--------|--------|
| [exclude_dropbox.xml](cloud-storage/exclude_dropbox.xml) | Sanctioned | Suppress sanctioned Dropbox noise | -- | 4.50 |
| [include_dropbox.xml](cloud-storage/include_dropbox.xml) | Unsanctioned | Detect unsanctioned Dropbox usage | T1567.002, T1102 | 4.50 |
| [exclude_onedrive.xml](cloud-storage/exclude_onedrive.xml) | Sanctioned | Suppress sanctioned OneDrive noise | -- | 4.50 |
| [include_onedrive.xml](cloud-storage/include_onedrive.xml) | Unsanctioned | Detect unsanctioned OneDrive usage | T1567.002, T1102 | 4.50 |
| [include_box.xml](cloud-storage/include_box.xml) | Unsanctioned | Detect unsanctioned Box usage | T1567.002, T1102 | 4.50 |
| [include_google_drive.xml](cloud-storage/include_google_drive.xml) | Unsanctioned | Detect unsanctioned Google Drive usage | T1567.002, T1102 | 4.50 |
| [include_mega.xml](cloud-storage/include_mega.xml) | Detection only | Detect MEGA.nz client (high-confidence exfil indicator) | T1567.002, T1102 | 4.50 |
| [include_anonfile_tempsh.xml](cloud-storage/include_anonfile_tempsh.xml) | Detection only | Detect anonymous file sharing services (temp.sh, transfer.sh, file.io, etc.) | T1105, T1567 | 4.50 |

## Sector Modules

Sector-specific monitoring patterns. Each module bundles industrial protocols, vendor tools, and file types relevant to a specific sector.

| Module | Purpose | ATT&CK | Schema |
|--------|---------|--------|--------|
| [electric-utility.xml](sector/electric-utility.xml) | NERC CIP / IEC 61850 environments (SEL, ABB, IEC 61850 SCL files) | T0830, T0855, T0836, T0852, T1565.001 | 4.50 |
| [water-wastewater.xml](sector/water-wastewater.xml) | Water and wastewater treatment / distribution SCADA | T0830, T0855, T1219 | 4.50 |
| [oil-gas-pipeline.xml](sector/oil-gas-pipeline.xml) | Oil and gas pipeline operations (TSA SD relevant) | T0830, T0855 | 4.50 |
| [manufacturing.xml](sector/manufacturing.xml) | Discrete and process manufacturing | T0830, T0855 | 4.50 |

## Protocol Modules

Industrial protocol port monitoring. Each module is a focused single-protocol detector. Use these when you want fine-grained control over which protocols to monitor.

| Module | Protocol | Default Ports | ATT&CK | Schema |
|--------|----------|---------------|--------|--------|
| [modbus-tcp.xml](protocol/modbus-tcp.xml) | Modbus TCP | 502 | T0830, T0855 | 4.50 |
| [opc-ua.xml](protocol/opc-ua.xml) | OPC UA | 4840 | T0830, T0855 | 4.50 |
| [ethernet-ip.xml](protocol/ethernet-ip.xml) | EtherNet/IP (Allen-Bradley) | 44818, 2222 | T0830, T0855 | 4.50 |
| [dnp3.xml](protocol/dnp3.xml) | DNP3 | 20000 | T0830, T0855 | 4.50 |
| [s7comm.xml](protocol/s7comm.xml) | Siemens S7comm / ISO-TSAP | 102 | T0830, T0855 | 4.50 |
| [bacnet.xml](protocol/bacnet.xml) | BACnet/IP (building automation) | 47808 | T0830, T0855 | 4.50 |
| [iec-60870-5-104.xml](protocol/iec-60870-5-104.xml) | IEC 60870-5-104 (telecontrol) | 2404 | T0830, T0855 | 4.50 |
| [mqtt.xml](protocol/mqtt.xml) | MQTT (IIoT messaging) | 1883, 8883 | T0830, T0855 | 4.50 |

## Remote Access Modules (Dual-Use)

Granular per-tool RMM detection. Pick exactly one variant per tool based on site policy. The curated configs already include some RMM tool detection inline; these modules provide finer per-tool control.

| Module | Variant | Purpose | ATT&CK | Schema |
|--------|---------|---------|--------|--------|
| [exclude_teamviewer.xml](remote-access/exclude_teamviewer.xml) | Sanctioned | Suppress sanctioned TeamViewer noise | -- | 4.50 |
| [include_teamviewer.xml](remote-access/include_teamviewer.xml) | Unsanctioned | Detect TeamViewer (Oldsmar 2021 incident) | T1219, T1133 | 4.50 |
| [include_anydesk.xml](remote-access/include_anydesk.xml) | Unsanctioned | Detect AnyDesk (CISA AA23-025A) | T1219, T1133 | 4.50 |
| [include_screenconnect.xml](remote-access/include_screenconnect.xml) | Unsanctioned | Detect ConnectWise ScreenConnect (CVE-2024-1709) | T1219, T1133 | 4.50 |
| [include_rustdesk.xml](remote-access/include_rustdesk.xml) | Unsanctioned | Detect RustDesk (open source self-hostable) | T1219, T1133 | 4.50 |

## LOLBAS Modules (Tier 3 Comprehensive)

Comprehensive Living off the Land Binaries and Scripts detection organized by ATT&CK technique family. Provides Sigma-level coverage for advanced users with mature tuning programs. Tier 3 of the three-tier LOLBAS strategy (Tier 1 and Tier 2 are inline in curated configs).

The modules use composite `<Rule groupRelation="and">` logic where binary + command-line scoping is appropriate, and flat `<Image>` rules where binary execution alone is the detection. All include rules use the ATT&CK structured tagging convention.

See https://icswatchdog.com/lolbas-detection/ for the three-tier strategy and OT tuning guidance.

| Module | Rules | ATT&CK Focus | Schema |
|--------|-------|--------------|--------|
| [include_signed_binary_proxy.xml](lolbas/include_signed_binary_proxy.xml) | 25 | T1218 family (mshta, regsvr32, rundll32, cmstp, msiexec, odbcconf, control, dfsvc, gpscript, ie4uinit, mmc, msconfig, pcwrun, presentationhost, rasautou, runonce, verclsid, xwizard) | 4.50 |
| [include_powershell_offensive.xml](lolbas/include_powershell_offensive.xml) | 15 | T1059.001 PowerShell offensive patterns (-nop -w hidden -ep bypass combo, FromBase64String, Reflection.Assembly Load, TCPClient reverse shell, Invoke-Mimikatz/Kerberoast/BloodHound, IEX(IEX(, Set-MpPreference, Invoke-WebRequest stager, Start-BitsTransfer, Get-Content piped to IEX) | 4.50 |
| [include_wmic_abuse.xml](lolbas/include_wmic_abuse.xml) | 10 | T1047 WMI / T1021.003 DCOM (process call create, /node:, XSL processing, qfe, computersystem, useraccount, group, service, startup) | 4.50 |
| [include_certutil_abuse.xml](lolbas/include_certutil_abuse.xml) | 8 | T1140/T1105/T1132 (urlcache, decode, encode, decodehex, encodehex, ping, verifyctl, addstore root) | 4.50 |
| [include_bitsadmin_abuse.xml](lolbas/include_bitsadmin_abuse.xml) | 6 | T1197 BITS Jobs (transfer, addfile, setnotifycmdline, setminretrydelay, create, resume) | 4.50 |
| [include_script_host_abuse.xml](lolbas/include_script_host_abuse.xml) | 10 | T1059.005 VBScript / T1059.007 JavaScript (cscript/wscript with .vbs/.js from temp, with HTTP, parented by Office processes, jscript.exe) | 4.50 |
| [include_trusted_developer_utilities.xml](lolbas/include_trusted_developer_utilities.xml) | 12 | T1127 (msbuild generic, msbuild from temp, csc, vbc, jsc, ilasm, tracker /d, dnx, rcsi, csi, ngen from shell parent) | 4.50 |
| [include_xsl_script_processing.xml](lolbas/include_xsl_script_processing.xml) | 6 | T1220 XSL Script Processing (WMIC format URL/local, msxsl HTTP/local/generic) | 4.50 |
| [include_persistence_via_lolbas.xml](lolbas/include_persistence_via_lolbas.xml) | 10 | T1547.001 / T1053.005 / T1543.003 / T1546.012 (at, schtasks variants, sc create binPath, reg add Run keys, reg add IFEO) | 4.50 |
| [include_discovery_recon.xml](lolbas/include_discovery_recon.xml) | 15 | T1033/T1069/T1087/T1018/T1057/T1082/T1016 (whoami /all/priv/groups, net group, nltest, quser, qwinsta, tasklist /svc, systeminfo, route print, arp -a) | 4.50 |
| [include_amsi_bypass_patterns.xml](lolbas/include_amsi_bypass_patterns.xml) | 8 | T1562.001 AMSI bypass patterns (amsiInitFailed, AmsiScanBuffer, AmsiContext, AmsiUtils, amsi.dll, Reflection field SetValue, Marshal.WriteByte, amsi-bypass) | 4.50 |
| [include_dotnet_unmanaged_abuse.xml](lolbas/include_dotnet_unmanaged_abuse.xml) | 8 | T1218 / T1127 .NET unmanaged execution (csi, Microsoft.Workflow.Compiler, jsc, dotnet from temp/Public, InstallUtil/RegSvcs/RegAsm from AppData) | 4.50 |
| [include_uncommon_lolbas.xml](lolbas/include_uncommon_lolbas.xml) | 20 | T1218 long-tail rare LOLBAS (replace, runscripthelper, AgentExecutor, AppInstaller, ConfigSecurityPolicy, dnscmd /serverlevelplugindll, gpscript, hh http, ie4uinit, ieexec http, ttdinject, wuauclt /UpdateDeploymentProvider, OfflineScannerShell, MSDeploy, Squirrel, Update.exe, WorkFolders, **wsl.exe execution patterns**) | 4.50 |
| **Total LOLBAS rules** | **153** | -- | -- |

### LOLBAS Module Notes

- All LOLBAS modules are detection-only (include rules); no exclude or dual-use variants
- AMSI bypass patterns are based on known techniques; advanced threat actors may rotate strings or use unpublished bypass techniques
- The discovery/recon module covers commands with routine admin uses; pair with SIEM correlation for high-volume burst detection
- The trusted developer utilities module may have higher false positive rates on systems with Visual Studio installed; tune by excluding the VS install path
- WSL detection in `include_uncommon_lolbas.xml` is desired for OT environments where WSL should not be present

## Module File Format Reference

```xml
<!--
  ICS Watch Dog Module: <Module Name>
  Category:     <vendor-ot|vendor-it|cloud-storage|sector|protocol|remote-access>
  Version:      vX.Y
  Schema:       4.50 (default) or 4.90 (with explicit reason)
  Dependencies: <other modules required, if any>
  ATT&CK:       <technique IDs covered>

  PURPOSE:
    <what this module monitors>

  WHEN TO USE:
    <conditions under which this module is appropriate>

  WHEN NOT TO USE:
    <conditions under which this module should be omitted>

  REFERENCES:
    <URLs to relevant external documentation>
-->
<RuleGroup name="..." groupRelation="or">
  <!-- rules -->
</RuleGroup>

<!-- additional RuleGroups as needed -->
```

A module is a partial XML fragment containing one or more `<RuleGroup>` elements. It must NOT contain `<Sysmon>`, `<HashAlgorithms>`, `<CheckRevocation>`, or `<EventFiltering>` elements.

## Contributing

See [README.md](README.md#contributing-modules) for module contribution guidelines.
