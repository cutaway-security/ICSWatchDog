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
| **Total** | **35** |

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
