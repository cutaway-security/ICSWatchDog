# Phase 8a Tagging Worksheet

## Purpose

This worksheet inventories every rule pattern across the 8 curated Sysmon configs and proposes the ATT&CK-tagged `name` attribute value for each. It is the deliverable of Phase 8a and the input to Phase 8b (Apply Tags). No config edits have been performed in Phase 8a -- this document is for review before any rule editing.

## Convention Recap

The full convention is defined in `claude-dev/SYSMON_CODING_STANDARD.md` section 6 (Rule Naming Convention). Quick reference:

**Include rules**: `name="technique_id=<ID>[|<ID2>],technique=<ATT&CK Name>[,detection=<Site Context>]"`

**Exclude rules**: `name="exclude=<Site-Specific Context>"`

**Composite rules**: parent `<Rule>` only, inner field conditions stay untagged.

**Multiple techniques**: pipe-delimited (`|`) in `technique_id`.

**Field constraints**: 250-char hard limit, 80-180 char target, no commas or pipes in field values (technique_id may use pipe as multi-technique separator).

**XML comment block**: above each tagged include rule (or logically grouped set), documenting the ATT&CK reference and investigation guidance.

## Inventory Summary

| Config | RuleGroups | Composite Rules | Field Conditions | Currently Named |
|---|---|---|---|---|
| baseline-it-workstation | 20 | 0 | 120 | 59 |
| baseline-it-server | 20 | 0 | 116 | 62 |
| server-ad | 22 | 0 | 160 | 89 |
| server-services | 22 | 0 | 192 | 117 |
| baseline-ot | 20 | 0 | 146 | 88 |
| enhanced-ot | 21 | 0 | 186 | 128 |
| advanced-ot | 24 | 0 | 202 | 144 |
| jumphost | 21 | 0 | 102 | 60 |
| **TOTAL** | **170** | **0** | **1224** | **747** |

**Composite `<Rule>` elements: ZERO across all configs.** All rules are simple field conditions (`<Image>`, `<CommandLine>`, `<TargetFilename>`, etc.). This simplifies Phase 8b -- no parent-only tagging logic required.

**Currently named rules** already have descriptive names (e.g., `name="DC: ntdsutil execution"`, `name="Ransomware: shadow copy deletion"`). These will be migrated into the `detection` field of the new convention. Currently unnamed rules will get full new names.

**ATT&CK techniques referenced across all configs**:
T1003, T1003.001, T1003.003, T1003.006, T1005, T1021, T1021.001, T1027, T1036, T1055, T1055.012, T1059, T1059.001, T1059.003, T1070, T1070.004, T1070.006, T1071, T1071.001, T1087.002, T1115, T1190, T1204, T1218, T1485, T1486, T1490, T1505.001, T1505.003, T1505.004, T1543.003, T1546.003, T1547, T1547.001, T1547.004, T1547.005, T1556, T1562.001, T1564.004, T1565, T1569.002, T1572

---

## SECTION 1: Common Include Rule Patterns (in multiple configs)

These patterns appear in 2 or more curated configs. Tagging them once here gives Phase 8b a single source of truth.

### 1.1 Ransomware Indicators (ProcessCreate)

**Configs**: workstation, it-server, server-ad, server-services, baseline-ot, enhanced-ot, advanced-ot, jumphost (8 configs)

**RuleGroup**: `ProcessCreate-RansomwareIndicators`

| Current name | Proposed tagged name |
|---|---|
| `Ransomware: shadow copy deletion` | `technique_id=T1490,technique=Inhibit System Recovery,detection=Ransomware shadow copy deletion via vssadmin` |
| `Ransomware: shadow copy deletion via WMI` | `technique_id=T1490,technique=Inhibit System Recovery,detection=Ransomware shadow copy deletion via WMI` |
| `Ransomware: recovery disabled` | `technique_id=T1490,technique=Inhibit System Recovery,detection=Ransomware Windows recovery disabled via bcdedit` |
| `Ransomware: boot status policy` | `technique_id=T1490,technique=Inhibit System Recovery,detection=Ransomware boot status policy bypass via bcdedit` |
| `Ransomware: backup catalog deletion` | `technique_id=T1490,technique=Inhibit System Recovery,detection=Ransomware Windows backup catalog deletion via wbadmin` |
| `Ransomware: safe mode boot` | `technique_id=T1490,technique=Inhibit System Recovery,detection=Ransomware safe mode boot configuration` |
| `Ransomware: Defender realtime disabled` | `technique_id=T1562.001,technique=Disable or Modify Tools,detection=Ransomware Defender realtime monitoring disabled` |
| `Ransomware: Defender drive exclusion` | `technique_id=T1562.001,technique=Disable or Modify Tools,detection=Ransomware Defender path exclusion added` |

### 1.2 Named Pipe C2 and Lateral Movement Detection (PipeEvent)

**Configs**: workstation, it-server, server-ad, server-services, baseline-ot, enhanced-ot, advanced-ot (7 configs; jumphost uses log-all)

**RuleGroup**: `PipeCreated-C2Detection`

| Current name | Proposed tagged name |
|---|---|
| `C2: Cobalt Strike` | `technique_id=T1572\|T1071,technique=Protocol Tunneling,detection=Cobalt Strike default named pipe (MSSE-)` |
| `C2: Cobalt Strike postex` | `technique_id=T1572\|T1071,technique=Protocol Tunneling,detection=Cobalt Strike post-exploitation pipe (postex_)` |
| `C2: Cobalt Strike status` | `technique_id=T1572\|T1071,technique=Protocol Tunneling,detection=Cobalt Strike status pipe` |
| `C2: Cobalt Strike msagent` | `technique_id=T1572\|T1071,technique=Protocol Tunneling,detection=Cobalt Strike msagent pipe` |
| `Lateral: PsExec` | `technique_id=T1021.002\|T1570,technique=SMB Admin Shares,detection=PsExec service pipe (PSEXESVC)` |
| `Lateral: paexec` | `technique_id=T1021.002\|T1570,technique=SMB Admin Shares,detection=PAExec lateral movement pipe` |
| `Lateral: remcom` | `technique_id=T1021.002\|T1570,technique=SMB Admin Shares,detection=RemCom lateral movement pipe` |
| `Lateral: csexec` | `technique_id=T1021.002\|T1570,technique=SMB Admin Shares,detection=CSExec lateral movement pipe` |
| `Cred: lsadump` | `technique_id=T1003.001,technique=LSASS Memory,detection=Mimikatz lsadump named pipe` |
| `Cred: cachedump` | `technique_id=T1003.005,technique=Cached Domain Credentials,detection=Cachedump named pipe` |
| `Cred: wceservicepipe` | `technique_id=T1003.001,technique=LSASS Memory,detection=Windows Credential Editor service pipe` |

### 1.3 ProcessAccess: LSASS Monitoring

**Configs**: all 8

| Current name | Proposed tagged name |
|---|---|
| (none) | `technique_id=T1003.001,technique=LSASS Memory,detection=Process accessing lsass.exe` |

### 1.4 FileCreate: Persistence and Script File Types

**Configs**: all 8 (jumphost has additional paths)

| Current name | Proposed tagged name |
|---|---|
| `Startup folder` (Start Menu) | `technique_id=T1547.001,technique=Registry Run Keys / Startup Folder,detection=File created in Start Menu` |
| `Startup folder` (Startup) | `technique_id=T1547.001,technique=Registry Run Keys / Startup Folder,detection=File created in Startup folder` |
| `Scheduled tasks` | `technique_id=T1053.005,technique=Scheduled Task,detection=Scheduled task XML created in Tasks directory` |
| `Executable` | `technique_id=T1204.002,technique=Malicious File,detection=Executable file created` |
| `DLL` | `technique_id=T1574.002,technique=DLL Side-Loading,detection=DLL file created` |
| `System driver` | `technique_id=T1543.003\|T1014,technique=Windows Service,detection=System driver (.sys) file created` |
| `Batch script` | `technique_id=T1059.003,technique=Windows Command Shell,detection=Batch script created` |
| `Command script` | `technique_id=T1059.003,technique=Windows Command Shell,detection=Command script created` |
| `PowerShell script` | `technique_id=T1059.001,technique=PowerShell,detection=PowerShell script created` |
| `VBScript` | `technique_id=T1059.005,technique=Visual Basic,detection=VBScript file created` |
| `JavaScript` | `technique_id=T1059.007,technique=JavaScript,detection=JavaScript file created` |
| `WSF script` | `technique_id=T1059.005,technique=Visual Basic,detection=Windows Script File created` |
| `HTA application` | `technique_id=T1218.005,technique=Mshta,detection=HTML Application file created` |
| `SCR screensaver` | `technique_id=T1546.002,technique=Screensaver,detection=Screensaver executable created` |
| `MSI installer` | `technique_id=T1218.007,technique=Msiexec,detection=MSI installer file created` |
| `Downloads folder` | `technique_id=T1105,technique=Ingress Tool Transfer,detection=File created in user Downloads folder` |
| `Temp folder` | `technique_id=T1105,technique=Ingress Tool Transfer,detection=File created in user AppData Temp folder` |
| `ProgramData` | `technique_id=T1105,technique=Ingress Tool Transfer,detection=File created in ProgramData folder` |
| `Recycle Bin` | `technique_id=T1564.001,technique=Hidden Files and Directories,detection=File staged in Recycle Bin` |
| `Group Policy` | `technique_id=T1484.001,technique=Group Policy Modification,detection=Group Policy file modified` |
| `Windows Temp` | `technique_id=T1105,technique=Ingress Tool Transfer,detection=File created in Windows Temp folder` |

### 1.5 RegistryEvent: Autostart and Persistence Keys

**Configs**: all 8

| Current name | Proposed tagged name |
|---|---|
| `Run key` | `technique_id=T1547.001,technique=Registry Run Keys / Startup Folder,detection=Registry Run key modified` |
| `RunOnce key` | `technique_id=T1547.001,technique=Registry Run Keys / Startup Folder,detection=Registry RunOnce key modified` |
| `RunServices` | `technique_id=T1547.001,technique=Registry Run Keys / Startup Folder,detection=RunServices key modified` |
| `Explorer Run` | `technique_id=T1547.001,technique=Registry Run Keys / Startup Folder,detection=Explorer Policies Run key modified` |
| `Services` | `technique_id=T1543.003,technique=Windows Service,detection=Windows service registry key modified` |
| `Task Cache` | `technique_id=T1053.005,technique=Scheduled Task,detection=Scheduled task cache modified` |
| `AppInit DLLs` | `technique_id=T1546.010,technique=AppInit DLLs,detection=AppInit_DLLs registry value modified` |
| `IFEO` | `technique_id=T1546.012,technique=Image File Execution Options Injection,detection=IFEO registry key modified` |
| `Winlogon Shell` | `technique_id=T1547.004,technique=Winlogon Helper DLL,detection=Winlogon Shell value modified` |
| `Winlogon Userinit` | `technique_id=T1547.004,technique=Winlogon Helper DLL,detection=Winlogon Userinit value modified` |
| `AppLocker policy` | `technique_id=T1562.001,technique=Disable or Modify Tools,detection=AppLocker policy modified` |
| `Ransomware: SafeBoot config` | `technique_id=T1490,technique=Inhibit System Recovery,detection=SafeBoot configuration modified` |
| `Ransomware: WDigest credential caching` | `technique_id=T1112\|T1003.001,technique=Modify Registry,detection=WDigest credential caching enabled` |
| `Ransomware: Defender policy` | `technique_id=T1562.001,technique=Disable or Modify Tools,detection=Windows Defender policy modified` |
| `Ransomware: Sysmon Autologger` | `technique_id=T1562.001,technique=Disable or Modify Tools,detection=Sysmon Autologger registry tampering` |

### 1.6 FileCreateStreamHash (Mark of the Web)

**Configs**: all 8

These rules currently have NO `name` attribute. They are extension-based filters that all map to T1564.004 (NTFS File Attributes / Alternate Data Streams) and T1553.005 (Mark of the Web Bypass).

| File extension | Proposed tagged name |
|---|---|
| `.exe` | `technique_id=T1564.004\|T1553.005,technique=NTFS File Attributes,detection=Executable Mark of the Web stream created` |
| `.dll` | `technique_id=T1564.004\|T1553.005,technique=NTFS File Attributes,detection=DLL Mark of the Web stream created` |
| `.bat` | `technique_id=T1564.004\|T1553.005,technique=NTFS File Attributes,detection=Batch script Mark of the Web stream created` |
| `.cmd` | `technique_id=T1564.004\|T1553.005,technique=NTFS File Attributes,detection=Command script Mark of the Web stream created` |
| `.ps1` | `technique_id=T1564.004\|T1553.005,technique=NTFS File Attributes,detection=PowerShell script Mark of the Web stream created` |
| `.vbs` | `technique_id=T1564.004\|T1553.005,technique=NTFS File Attributes,detection=VBScript Mark of the Web stream created` |
| `.js` | `technique_id=T1564.004\|T1553.005,technique=NTFS File Attributes,detection=JavaScript Mark of the Web stream created` |
| `.hta` | `technique_id=T1564.004\|T1553.005,technique=NTFS File Attributes,detection=HTA Mark of the Web stream created` |

### 1.7 FileDeleteDetected (extension-based)

**Configs**: all 8

Plain extension rules currently have NO names. Ransomware-specific deletions ARE named.

| Current name | Proposed tagged name |
|---|---|
| (none) `.exe` | `technique_id=T1070.004,technique=File Deletion,detection=Executable file deleted` |
| (none) `.dll` | `technique_id=T1070.004,technique=File Deletion,detection=DLL file deleted` |
| (none) `.sys` | `technique_id=T1070.004,technique=File Deletion,detection=System driver deleted` |
| (none) `.ps1` | `technique_id=T1070.004,technique=File Deletion,detection=PowerShell script deleted` |
| (none) `.bat` | `technique_id=T1070.004,technique=File Deletion,detection=Batch script deleted` |
| (none) `.cmd` | `technique_id=T1070.004,technique=File Deletion,detection=Command script deleted` |
| `Ransomware: backup deletion` | `technique_id=T1490\|T1485,technique=Inhibit System Recovery,detection=Backup file (.bak) deletion` |
| `Ransomware: VHD deletion` | `technique_id=T1490\|T1485,technique=Inhibit System Recovery,detection=Virtual hard disk (.vhd) deletion` |
| `Ransomware: VHDX deletion` | `technique_id=T1490\|T1485,technique=Inhibit System Recovery,detection=Virtual hard disk (.vhdx) deletion` |
| `Ransomware: SQL data deletion` | `technique_id=T1490\|T1485,technique=Inhibit System Recovery,detection=SQL Server data file (.mdf) deletion` |
| `Ransomware: SQL log deletion` | `technique_id=T1490\|T1485,technique=Inhibit System Recovery,detection=SQL Server log file (.ldf) deletion` |

---

## SECTION 2: Config-Specific Include Rules

### 2.1 sysmonconfig-server-ad.xml (DC-specific)

**RuleGroup `ProcessCreate-DC-Detection`** (9 rules)

| Current name | Proposed tagged name |
|---|---|
| `DC: ntdsutil execution` | `technique_id=T1003.003,technique=NTDS,detection=DC ntdsutil execution` |
| `DC: vssadmin execution` | `technique_id=T1003.003,technique=NTDS,detection=DC vssadmin execution (shadow copy NTDS extraction vector)` |
| `DC: esentutl execution` | `technique_id=T1003.003,technique=NTDS,detection=DC esentutl execution (NTDS database manipulation)` |
| `DC: diskshadow execution` | `technique_id=T1003.003,technique=NTDS,detection=DC diskshadow execution (shadow copy NTDS extraction vector)` |
| `DC: wmic shadowcopy` | `technique_id=T1003.003,technique=NTDS,detection=DC WMI shadow copy creation (NTDS extraction vector)` |
| `DC: csvde data export` | `technique_id=T1087.002,technique=Domain Account,detection=DC csvde AD data export` |
| `DC: ldifde data export` | `technique_id=T1087.002,technique=Domain Account,detection=DC ldifde AD data export` |
| `DC: mimikatz lsadump` | `technique_id=T1003.006,technique=DCSync,detection=DC Mimikatz lsadump command line` |
| `DC: secretsdump` | `technique_id=T1003.006,technique=DCSync,detection=DC secretsdump command line (impacket)` |

**FileCreate DC additions** (NTDS, SYSVOL, hives)

| Current name | Proposed tagged name |
|---|---|
| `DC: NTDS directory` | `technique_id=T1003.003,technique=NTDS,detection=File created in NTDS directory` |
| `DC: NTDS.dit copy` | `technique_id=T1003.003,technique=NTDS,detection=NTDS.dit file copy created` |
| `DC: Registry hive export` | `technique_id=T1003.002,technique=Security Account Manager,detection=Registry hive (.hive) export created` |
| `DC: System config` (SAM) | `technique_id=T1003.002,technique=Security Account Manager,detection=SAM hive copy from System32 config` |
| `DC: System config` (SYSTEM) | `technique_id=T1003.002,technique=Security Account Manager,detection=SYSTEM hive copy from System32 config` |
| `DC: System config` (SECURITY) | `technique_id=T1003.004,technique=LSA Secrets,detection=SECURITY hive copy from System32 config` |
| `DC: SYSVOL` | `technique_id=T1484.001,technique=Group Policy Modification,detection=File created in SYSVOL` |
| `DC: GPO ScheduledTasks` | `technique_id=T1484.001\|T1053.005,technique=Group Policy Modification,detection=GPO ScheduledTasks XML modified` |
| `DC: GPO security template` | `technique_id=T1484.001,technique=Group Policy Modification,detection=GPO GptTmpl.inf modified` |
| `DC: GPO registry.pol` | `technique_id=T1484.001,technique=Group Policy Modification,detection=GPO registry.pol modified` |

**RegistryEvent DC additions**

| Current name | Proposed tagged name |
|---|---|
| `LSA config` | `technique_id=T1556,technique=Modify Authentication Process,detection=LSA configuration modified` |
| `Security providers` | `technique_id=T1556,technique=Modify Authentication Process,detection=Security providers registry modified` |
| `LanmanServer` | `technique_id=T1543.003,technique=Windows Service,detection=LanmanServer service configuration modified` |
| `DC: NTDS service` | `technique_id=T1003.003,technique=NTDS,detection=NTDS service configuration modified` |
| `DC: Netlogon service` | `technique_id=T1556,technique=Modify Authentication Process,detection=Netlogon service configuration modified` |
| `DC: DNS service` | `technique_id=T1543.003,technique=Windows Service,detection=DNS service configuration modified on DC` |
| `DC: DFSR service` | `technique_id=T1543.003,technique=Windows Service,detection=DFSR service configuration modified` |
| `DC: NTFRS service` | `technique_id=T1543.003,technique=Windows Service,detection=NTFRS service configuration modified` |
| `DC: Kerberos config` | `technique_id=T1556,technique=Modify Authentication Process,detection=Kerberos configuration modified` |

**FileDeleteDetected DC additions**

| Current name | Proposed tagged name |
|---|---|
| `DC: NTDS.dit deletion` | `technique_id=T1070.004\|T1485,technique=File Deletion,detection=NTDS.dit deletion (forensic evidence destruction)` |
| `DC: Hive file deletion` | `technique_id=T1070.004\|T1485,technique=File Deletion,detection=Registry hive file deletion (forensic evidence destruction)` |

### 2.2 sysmonconfig-server-services.xml (Database/Web)

**RuleGroup `ProcessCreate-ServiceDetection`** (database engines spawning shells)

| Current name | Proposed tagged name |
|---|---|
| `DB: SQL Server spawned process` | `technique_id=T1059\|T1505.001,technique=Command and Scripting Interpreter,detection=SQL Server (sqlservr.exe) spawned child process` |
| `DB: SQL Agent spawned process` | `technique_id=T1059\|T1505.001,technique=Command and Scripting Interpreter,detection=SQL Server Agent spawned child process` |
| `DB: PostgreSQL spawned process` | `technique_id=T1059\|T1505.001,technique=Command and Scripting Interpreter,detection=PostgreSQL spawned child process` |
| `DB: MySQL spawned process` | `technique_id=T1059\|T1505.001,technique=Command and Scripting Interpreter,detection=MySQL spawned child process` |
| `DB: MariaDB spawned process` | `technique_id=T1059\|T1505.001,technique=Command and Scripting Interpreter,detection=MariaDB spawned child process` |
| `DB: Oracle spawned process` | `technique_id=T1059\|T1505.001,technique=Command and Scripting Interpreter,detection=Oracle Database spawned child process` |
| `DB: Oracle extjob spawned process` | `technique_id=T1059\|T1505.001,technique=Command and Scripting Interpreter,detection=Oracle external job spawned child process` |
| `DB: Oracle extproc spawned process` | `technique_id=T1059\|T1505.001,technique=Command and Scripting Interpreter,detection=Oracle external procedure spawned child process` |
| `DB: MongoDB spawned process` | `technique_id=T1059\|T1505.001,technique=Command and Scripting Interpreter,detection=MongoDB spawned child process` |
| `DB: InfluxDB spawned process` | `technique_id=T1059\|T1505.001,technique=Command and Scripting Interpreter,detection=InfluxDB spawned child process` |

**Web servers spawning shells**

| Current name | Proposed tagged name |
|---|---|
| `Web: IIS worker spawned process` | `technique_id=T1505.003\|T1059,technique=Server Software Component: Web Shell,detection=IIS worker (w3wp.exe) spawned child process` |
| `Web: Apache spawned process` | `technique_id=T1505.003\|T1059,technique=Server Software Component: Web Shell,detection=Apache (httpd.exe) spawned child process` |
| `Web: Nginx spawned process` | `technique_id=T1505.003\|T1059,technique=Server Software Component: Web Shell,detection=Nginx spawned child process` |
| `Web: Tomcat spawned process` (tomcat9) | `technique_id=T1505.003\|T1059,technique=Server Software Component: Web Shell,detection=Apache Tomcat 9 spawned child process` |
| `Web: Tomcat spawned process` (tomcat10) | `technique_id=T1505.003\|T1059,technique=Server Software Component: Web Shell,detection=Apache Tomcat 10 spawned child process` |
| `Web: PHP spawned process` (php-cgi) | `technique_id=T1505.003\|T1059,technique=Server Software Component: Web Shell,detection=PHP-CGI spawned child process` |
| `Web: PHP spawned process` (php) | `technique_id=T1505.003\|T1059,technique=Server Software Component: Web Shell,detection=PHP interpreter spawned child process` |
| `Web: Node.js spawned process` | `technique_id=T1505.003\|T1059,technique=Server Software Component: Web Shell,detection=Node.js spawned child process` |
| `Web: IIS appcmd execution` | `technique_id=T1505.004,technique=IIS Components,detection=IIS appcmd.exe execution (module installation)` |

**ImageLoad (web workers)**

| Current name | Proposed tagged name |
|---|---|
| `Web: IIS DLL load` | `technique_id=T1505.004,technique=IIS Components,detection=DLL loaded into IIS worker (w3wp.exe)` |
| `Web: Apache DLL load` | `technique_id=T1505.004,technique=IIS Components,detection=DLL loaded into Apache (httpd.exe)` |

**FileCreate database files**

| Current name | Proposed tagged name |
|---|---|
| `DB: SQL Server backup` | `technique_id=T1005\|T1213,technique=Data from Local System,detection=SQL Server backup (.bak) created` |
| `DB: SQL Server data` | `technique_id=T1005\|T1213,technique=Data from Local System,detection=SQL Server data file (.mdf) created` |
| `DB: SQL Server log` | `technique_id=T1005\|T1213,technique=Data from Local System,detection=SQL Server log file (.ldf) created` |
| `DB: SQL Server secondary` | `technique_id=T1005\|T1213,technique=Data from Local System,detection=SQL Server secondary data file (.ndf) created` |
| `DB: SQL Server bacpac` | `technique_id=T1005\|T1213,technique=Data from Local System,detection=SQL Server bacpac export created` |
| `DB: SQL Server dacpac` | `technique_id=T1005\|T1213,technique=Data from Local System,detection=SQL Server dacpac export created` |
| `DB: Transaction log backup` | `technique_id=T1005\|T1213,technique=Data from Local System,detection=SQL Server transaction log backup (.trn) created` |
| `DB: PostgreSQL dump` | `technique_id=T1005\|T1213,technique=Data from Local System,detection=PostgreSQL dump file created` |
| `DB: Oracle data file` | `technique_id=T1005\|T1213,technique=Data from Local System,detection=Oracle data file (.dbf) created` |
| `DB: Oracle Data Pump` | `technique_id=T1005\|T1213,technique=Data from Local System,detection=Oracle Data Pump export (.dmp) created` |
| `DB: SQL dump` | `technique_id=T1005\|T1213,technique=Data from Local System,detection=Generic SQL dump file created` |

**FileCreate web shell extensions**

| Current name | Proposed tagged name |
|---|---|
| `Web: ASPX file` | `technique_id=T1505.003,technique=Server Software Component: Web Shell,detection=ASPX file created (potential webshell)` |
| `Web: ASP file` | `technique_id=T1505.003,technique=Server Software Component: Web Shell,detection=ASP file created (potential webshell)` |
| `Web: ASHX handler` | `technique_id=T1505.003,technique=Server Software Component: Web Shell,detection=ASHX HTTP handler created (potential webshell)` |
| `Web: ASMX service` | `technique_id=T1505.003,technique=Server Software Component: Web Shell,detection=ASMX web service created (potential webshell)` |
| `Web: PHP file` | `technique_id=T1505.003,technique=Server Software Component: Web Shell,detection=PHP file created (potential webshell)` |
| `Web: JSP file` | `technique_id=T1505.003,technique=Server Software Component: Web Shell,detection=JSP file created (potential webshell)` |
| `Web: JSPX file` | `technique_id=T1505.003,technique=Server Software Component: Web Shell,detection=JSPX file created (potential webshell)` |
| `Web: WAR file` | `technique_id=T1505.003,technique=Server Software Component: Web Shell,detection=Java WAR file created (potential webshell deployment)` |
| `Web: CFM file` | `technique_id=T1505.003,technique=Server Software Component: Web Shell,detection=ColdFusion CFM file created (potential webshell)` |
| `Web: CGI script` | `technique_id=T1505.003,technique=Server Software Component: Web Shell,detection=CGI script created (potential webshell)` |
| `Web: web.config` | `technique_id=T1505.003\|T1574,technique=Server Software Component: Web Shell,detection=IIS web.config file modified` |
| `Web: .htaccess` | `technique_id=T1505.003\|T1574,technique=Server Software Component: Web Shell,detection=Apache .htaccess file modified` |
| `Web: IIS web root` | `technique_id=T1505.003,technique=Server Software Component: Web Shell,detection=File created in IIS wwwroot directory` |
| `Web: ASP.NET temp` | `technique_id=T1505.003,technique=Server Software Component: Web Shell,detection=File created in ASP.NET Temporary Files (webshell compilation artifact)` |

**RegistryEvent database/web additions**

| Current name | Proposed tagged name |
|---|---|
| `Web: IIS extensions` | `technique_id=T1505.004,technique=IIS Components,detection=IIS Extensions registry modified` |
| `Web: W3SVC service` | `technique_id=T1505.004,technique=IIS Components,detection=W3SVC service registry modified` |
| `Web: WAS service` | `technique_id=T1505.004,technique=IIS Components,detection=WAS service registry modified` |
| `DB: SQL Server config` | `technique_id=T1112,technique=Modify Registry,detection=SQL Server registry configuration modified` |

**FileDeleteDetected database/web additions**

| Current name | Proposed tagged name |
|---|---|
| `DB: Backup file deletion` | `technique_id=T1070.004\|T1485,technique=File Deletion,detection=Database backup (.bak) deletion` |
| `DB: Dump file deletion` | `technique_id=T1070.004\|T1485,technique=File Deletion,detection=Database dump (.dmp) deletion` |
| `Web: ASPX deletion` | `technique_id=T1070.004,technique=File Deletion,detection=ASPX file deletion (potential webshell cleanup)` |
| `Web: PHP deletion` | `technique_id=T1070.004,technique=File Deletion,detection=PHP file deletion (potential webshell cleanup)` |
| `Web: JSP deletion` | `technique_id=T1070.004,technique=File Deletion,detection=JSP file deletion (potential webshell cleanup)` |

### 2.3 OT Configs (baseline-ot, enhanced-ot, advanced-ot)

**FileCreate ICS file types**

| Current name | Proposed tagged name |
|---|---|
| `ICS: Siemens TIA Portal project` (.ap17/.ap18/.ap19) | `technique_id=T1565.001,technique=Stored Data Manipulation,detection=Siemens TIA Portal project file created` |
| `ICS: Siemens STEP 7 project` | `technique_id=T1565.001,technique=Stored Data Manipulation,detection=Siemens STEP 7 project file created` |
| `ICS: CODESYS project` | `technique_id=T1565.001,technique=Stored Data Manipulation,detection=CODESYS project file created` |
| `ICS: IEC 61131 structured text` | `technique_id=T1565.001,technique=Stored Data Manipulation,detection=IEC 61131 structured text source created` |
| `ICS: AVEVA InTouch app` | `technique_id=T1565.001,technique=Stored Data Manipulation,detection=AVEVA InTouch application file created` |
| `ICS: Firmware hex` | `technique_id=T0857\|T1601,technique=Modify Controller Tasking,detection=Firmware HEX file created (potential PLC firmware update)` |
| `ICS: Firmware binary` | `technique_id=T0857\|T1601,technique=Modify Controller Tasking,detection=Firmware binary file created (potential PLC firmware update)` |
| `ICS: Firmware update` | `technique_id=T0857\|T1601,technique=Modify Controller Tasking,detection=Firmware update file created` |
| `ICS: OPC config` | `technique_id=T1565.001,technique=Stored Data Manipulation,detection=OPC configuration file created` |
| `ICS: Rockwell Studio 5000 project` | `technique_id=T1565.001,technique=Stored Data Manipulation,detection=Rockwell Studio 5000 project (.ACD) created` |
| `ICS: Rockwell RSLogix project` | `technique_id=T1565.001,technique=Stored Data Manipulation,detection=Rockwell RSLogix project (.RSS) created` |
| `ICS: Rockwell RSLogix 5000 project` | `technique_id=T1565.001,technique=Stored Data Manipulation,detection=Rockwell RSLogix 5000 project (.L5K) created` |
| `ICS: Rockwell RSLogix 5000 export` | `technique_id=T1565.001,technique=Stored Data Manipulation,detection=Rockwell RSLogix 5000 export (.L5X) created` |
| `ICS: Schneider Unity Pro project` | `technique_id=T1565.001,technique=Stored Data Manipulation,detection=Schneider Unity Pro project (.stu) created` |
| `ICS: Schneider EcoStruxure project` | `technique_id=T1565.001,technique=Stored Data Manipulation,detection=Schneider EcoStruxure project (.xef) created` |
| `ICS: SEL relay settings` | `technique_id=T0836\|T1565.001,technique=Modify Parameter,detection=SEL relay settings file created` |
| `ICS: SEL event report` | `technique_id=T0852,technique=Screen Capture,detection=SEL relay event report created` |
| `ICS: GE Proficy project` | `technique_id=T1565.001,technique=Stored Data Manipulation,detection=GE Proficy project file created` |
| `ICS: OPC UA certificate` (.der) | `technique_id=T1552.004\|T1556,technique=Private Keys,detection=OPC UA certificate (.der) created` |
| `ICS: OPC UA certificate` (.pem) | `technique_id=T1552.004\|T1556,technique=Private Keys,detection=OPC UA certificate (.pem) created` |
| `ICS: Config export CSV` | `technique_id=T1005,technique=Data from Local System,detection=ICS configuration CSV export created` |
| `Archive: ZIP` | `technique_id=T1560.001,technique=Archive via Utility,detection=ZIP archive created` |
| `Archive: RAR` | `technique_id=T1560.001,technique=Archive via Utility,detection=RAR archive created` |
| `Archive: 7z` | `technique_id=T1560.001,technique=Archive via Utility,detection=7z archive created` |
| `Archive: ISO` | `technique_id=T1204.002\|T1027.006,technique=Malicious File,detection=ISO file created (common malware container)` |

**ICS vendor installation directories** (FileCreate)

| Current name | Proposed tagged name |
|---|---|
| `ICS: Siemens directory` | `technique_id=T1565.002,technique=Transmitted Data Manipulation,detection=File created in Siemens installation directory` |
| `ICS: Rockwell directory` | `technique_id=T1565.002,technique=Transmitted Data Manipulation,detection=File created in Rockwell Software directory` |
| `ICS: Rockwell FactoryTalk` | `technique_id=T1565.002,technique=Transmitted Data Manipulation,detection=File created in FactoryTalk directory` |
| `ICS: Schneider directory` | `technique_id=T1565.002,technique=Transmitted Data Manipulation,detection=File created in Schneider Electric directory` |
| `ICS: Wonderware directory` | `technique_id=T1565.002,technique=Transmitted Data Manipulation,detection=File created in Wonderware directory` |
| `ICS: ArchestrA directory` | `technique_id=T1565.002,technique=Transmitted Data Manipulation,detection=File created in ArchestrA directory` |
| `ICS: OSIsoft PI directory` | `technique_id=T1565.002,technique=Transmitted Data Manipulation,detection=File created in OSIsoft PI directory` |
| `ICS: Ignition directory` | `technique_id=T1565.002,technique=Transmitted Data Manipulation,detection=File created in Inductive Automation Ignition directory` |
| `ICS: Kepware directory` | `technique_id=T1565.002,technique=Transmitted Data Manipulation,detection=File created in Kepware directory` |
| `ICS: SEL directory` | `technique_id=T1565.002,technique=Transmitted Data Manipulation,detection=File created in SEL directory` |
| `ICS: CODESYS directory` | `technique_id=T1565.002,technique=Transmitted Data Manipulation,detection=File created in CODESYS directory` |
| `ICS: GE directory` | `technique_id=T1565.002,technique=Transmitted Data Manipulation,detection=File created in GE Digital directory` |
| `ICS: GE iFIX directory` | `technique_id=T1565.002,technique=Transmitted Data Manipulation,detection=File created in GE iFIX directory` |
| `ICS: Honeywell directory` | `technique_id=T1565.002,technique=Transmitted Data Manipulation,detection=File created in Honeywell directory` |
| `ICS: Emerson directory` | `technique_id=T1565.002,technique=Transmitted Data Manipulation,detection=File created in Emerson directory` |
| `ICS: ABB directory` | `technique_id=T1565.002,technique=Transmitted Data Manipulation,detection=File created in ABB directory` |
| `ICS: Yokogawa directory` | `technique_id=T1565.002,technique=Transmitted Data Manipulation,detection=File created in Yokogawa directory` |

**Ransomware ransom notes (FileCreate)**

| Current name | Proposed tagged name |
|---|---|
| `Ransomware: ransom note` (DECRYPT) | `technique_id=T1486,technique=Data Encrypted for Impact,detection=Ransom note filename containing DECRYPT` |
| `Ransomware: ransom note` (RANSOM) | `technique_id=T1486,technique=Data Encrypted for Impact,detection=Ransom note filename containing RANSOM` |
| `Ransomware: ransom note` (RECOVER) | `technique_id=T1486,technique=Data Encrypted for Impact,detection=Ransom note filename containing RECOVER` |
| `Ransomware: EKANS note` | `technique_id=T1486,technique=Data Encrypted for Impact,detection=EKANS ransomware note (Decrypt-Your-Files.txt)` |

**Industrial protocol port monitoring (NetworkConnect)** (enhanced-ot, advanced-ot)

| Current name | Proposed tagged name |
|---|---|
| `ICS: Modbus TCP` | `technique_id=T0830\|T0855,technique=Adversary-in-the-Middle,detection=Process connecting to Modbus TCP port 502` |
| `ICS: EtherNet/IP` | `technique_id=T0830\|T0855,technique=Adversary-in-the-Middle,detection=Process connecting to EtherNet/IP TCP port 44818` |
| `ICS: EtherNet/IP implicit` | `technique_id=T0830,technique=Adversary-in-the-Middle,detection=Process connecting to EtherNet/IP implicit messaging port 2222` |
| `ICS: OPC-UA` | `technique_id=T0830\|T0855,technique=Adversary-in-the-Middle,detection=Process connecting to OPC-UA port 4840` |
| `ICS: OPC DA/DCOM (RPC)` | `technique_id=T0830\|T0855,technique=Adversary-in-the-Middle,detection=Process connecting to OPC DA/DCOM RPC port 135` |
| `ICS: DNP3` | `technique_id=T0830\|T0855,technique=Adversary-in-the-Middle,detection=Process connecting to DNP3 port 20000` |
| `ICS: S7comm/ISO-TSAP` | `technique_id=T0830\|T0855,technique=Adversary-in-the-Middle,detection=Process connecting to S7comm/ISO-TSAP port 102` |
| `ICS: BACnet/IP` | `technique_id=T0830\|T0855,technique=Adversary-in-the-Middle,detection=Process connecting to BACnet/IP port 47808` |
| `ICS: IEC 104` | `technique_id=T0830\|T0855,technique=Adversary-in-the-Middle,detection=Process connecting to IEC 60870-5-104 port 2404` |
| `ICS: MQTT` | `technique_id=T0830\|T0855,technique=Adversary-in-the-Middle,detection=Process connecting to MQTT port 1883` |
| `ICS: MQTT TLS` | `technique_id=T0830\|T0855,technique=Adversary-in-the-Middle,detection=Process connecting to MQTT over TLS port 8883` |
| `ICS: Ignition Gateway HTTP` | `technique_id=T0830,technique=Adversary-in-the-Middle,detection=Process connecting to Ignition Gateway HTTP port 8088` |
| `ICS: Ignition Gateway HTTPS` | `technique_id=T0830,technique=Adversary-in-the-Middle,detection=Process connecting to Ignition Gateway HTTPS port 8043` |
| `ICS: PI Data Archive` | `technique_id=T0830,technique=Adversary-in-the-Middle,detection=Process connecting to OSIsoft PI Data Archive port 5450` |
| `ICS: GE SRTP` | `technique_id=T0830,technique=Adversary-in-the-Middle,detection=Process connecting to GE SRTP port 18245` |
| `ICS: PROFINET IO CM` | `technique_id=T0830,technique=Adversary-in-the-Middle,detection=Process connecting to PROFINET IO context management port 34962` |
| `ICS: PROFINET IO alarm` | `technique_id=T0830,technique=Adversary-in-the-Middle,detection=Process connecting to PROFINET IO alarm port 34963` |
| `ICS: PROFINET IO data` | `technique_id=T0830,technique=Adversary-in-the-Middle,detection=Process connecting to PROFINET IO data port 34964` |

**RegistryEvent OT additions** (enhanced-ot, advanced-ot)

| Current name | Proposed tagged name |
|---|---|
| `ICS: DCOM config` | `technique_id=T1559.001,technique=Component Object Model,detection=DCOM Ole configuration modified` |
| `ICS: OPC server registration` | `technique_id=T1559.001,technique=Component Object Model,detection=OPC server registration modified` |
| `Firewall rules` | `technique_id=T1562.004,technique=Disable or Modify System Firewall,detection=Windows Firewall rules modified` |

**FileBlockExecutable** (advanced-ot only)

All FileBlockExecutable rules in vendor directories share the same technique mapping. Pattern:

| Current name | Proposed tagged name |
|---|---|
| `ICS: Executable in Siemens dir` | `technique_id=T1204.002\|T1036.005,technique=Match Legitimate Name or Location,detection=Executable created in Siemens directory` |
| `ICS: Executable in Rockwell dir` | `technique_id=T1204.002\|T1036.005,technique=Match Legitimate Name or Location,detection=Executable created in Rockwell Software directory` |
| `ICS: Executable in FactoryTalk dir` | `technique_id=T1204.002\|T1036.005,technique=Match Legitimate Name or Location,detection=Executable created in FactoryTalk directory` |
| `ICS: Executable in Schneider dir` | (same pattern, Schneider Electric) |
| `ICS: Executable in Wonderware dir` | (same pattern, Wonderware) |
| `ICS: Executable in ArchestrA dir` | (same pattern, ArchestrA) |
| `ICS: Executable in PI dir` | (same pattern, OSIsoft PI) |
| `ICS: Executable in Ignition dir` | (same pattern, Ignition) |
| `ICS: Executable in Kepware dir` | (same pattern, Kepware) |
| `ICS: Executable in CODESYS dir` | (same pattern, CODESYS) |
| `ICS: Executable in GE dir` | (same pattern, GE Digital) |
| `ICS: Executable in Honeywell dir` | (same pattern, Honeywell) |
| `ICS: Executable in ABB dir` | (same pattern, ABB) |
| `Executable in Startup` | `technique_id=T1547.001,technique=Registry Run Keys / Startup Folder,detection=Executable created in Startup folder` |
| `Executable in Tasks` | `technique_id=T1053.005,technique=Scheduled Task,detection=Executable created in Windows Tasks directory` |
| `Executable in Recycle Bin` | `technique_id=T1564.001,technique=Hidden Files and Directories,detection=Executable created in Recycle Bin (staging/hiding)` |

### 2.4 sysmonconfig-jumphost.xml

**RegistryEvent jumphost additions**

| Current name | Proposed tagged name |
|---|---|
| `RDP config` | `technique_id=T1021.001,technique=Remote Desktop Protocol,detection=Terminal Services configuration modified` |
| `RDP authentication` | `technique_id=T1021.001,technique=Remote Desktop Protocol,detection=Terminal Server WinStations modified` |

**FileCreate jumphost additions**

| Current name | Proposed tagged name |
|---|---|
| `User Desktop` | `technique_id=T1105\|T1074,technique=Ingress Tool Transfer,detection=File created on user Desktop on jump host` |
| `User Documents` | `technique_id=T1105\|T1074,technique=Ingress Tool Transfer,detection=File created in user Documents on jump host` |

---

## SECTION 3: Exclude Rule Convention

Exclude rules are noise reduction, not detection. They get a simple `name="exclude=<context>"` rather than ATT&CK tagging.

**Currently unnamed exclude rules** (e.g., `<Image condition="is">C:\Windows\System32\svchost.exe</Image>`) will receive a name during Phase 8b. Examples:

| Current rule | Proposed name |
|---|---|
| `<Image condition="is">C:\Windows\System32\svchost.exe</Image>` (in NetworkConnect) | `exclude=svchost.exe network noise` |
| `<Image condition="is">C:\Program Files\Windows Defender\MsMpEng.exe</Image>` | `exclude=Windows Defender MsMpEng` |
| `<SourceImage condition="is">C:\Windows\System32\csrss.exe</SourceImage>` (in CreateRemoteThread) | `exclude=csrss legitimate remote thread` |
| `<PipeName condition="is">\lsass</PipeName>` (in PipeEvent) | `exclude=lsass system pipe` |
| `<QueryName condition="end with">.microsoft.com</QueryName>` | `exclude=Microsoft DNS query` |
| `<Signature condition="contains">Microsoft</Signature>` (in DriverLoad) | `exclude=Microsoft-signed driver` |

**Note**: Exclude rules using `is` against a full path will get the same name across multiple configs (e.g., `svchost.exe` exclusion). Names should be descriptive enough to distinguish purpose without being overly long.

---

## SECTION 4: Multi-Technique Rules

These rules use pipe-delimited `technique_id` because they map cleanly to multiple ATT&CK techniques:

| Pattern | Techniques | Reasoning |
|---|---|---|
| C2 named pipes (Cobalt Strike) | T1572 \| T1071 | Protocol Tunneling + Application Layer Protocol -- C2 uses both |
| Lateral movement pipes (PsExec, etc.) | T1021.002 \| T1570 | SMB Admin Shares + Lateral Tool Transfer -- both apply |
| Database engine spawning shell | T1059 \| T1505.001 | Command Interpreter + SQL Stored Procedures abuse |
| Web server spawning shell | T1505.003 \| T1059 | Web Shell + Command Interpreter |
| WDigest credential caching enabled | T1112 \| T1003.001 | Modify Registry + LSASS Memory (enables LSASS plaintext caching) |
| Backup file deletion (.bak) | T1490 \| T1485 | Inhibit System Recovery + Data Destruction |
| NTDS.dit deletion | T1070.004 \| T1485 | File Deletion + Data Destruction |
| Industrial port connections (Modbus, EtherNet/IP, OPC-UA, DNP3, S7comm, BACnet, IEC104, MQTT) | T0830 \| T0855 | ICS ATT&CK: Adversary-in-the-Middle + Unauthorized Command Message |
| Firmware files (.hex, .bin, .fw) | T0857 \| T1601 | ICS ATT&CK: Modify Controller Tasking + System Firmware |
| FileBlockExecutable in vendor dirs | T1204.002 \| T1036.005 | Malicious File + Match Legitimate Name or Location |
| OPC UA certificates | T1552.004 \| T1556 | Private Keys + Modify Authentication Process |
| ISO file creation | T1204.002 \| T1027.006 | Malicious File + HTML Smuggling (ISO container abuse) |
| FileCreateStreamHash all extensions | T1564.004 \| T1553.005 | NTFS File Attributes + Mark of the Web Bypass |

---

## SECTION 5: XML Comment Block Templates

Each tagged include rule (or logically grouped set) gets a maintainer comment block above it. Templates:

### Template A: Single rule with single technique

```xml
<!--
  T<ID> <Technique Name>
  <Brief description of what this rule detects and why it matters>
  <Investigation guidance: what to do when this fires>
  Reference: https://attack.mitre.org/techniques/T<ID>/
-->
<Image name="..." condition="...">...</Image>
```

### Template B: Grouped set of related rules

```xml
<!--
  T<ID> <Technique Name>
  <Brief description of the group's purpose>
  <Investigation guidance>
  Reference: https://attack.mitre.org/techniques/T<ID>/
-->
<Image name="..." condition="...">...</Image>
<Image name="..." condition="...">...</Image>
<Image name="..." condition="...">...</Image>
```

### Template C: Multi-technique rule

```xml
<!--
  T<ID1> <Primary Technique Name> + T<ID2> <Secondary Technique Name>
  <Why this rule maps to multiple techniques>
  <Investigation guidance>
  References:
    https://attack.mitre.org/techniques/T<ID1>/
    https://attack.mitre.org/techniques/T<ID2>/
-->
<CommandLine name="..." condition="...">...</CommandLine>
```

### Template D: ICS ATT&CK rule

```xml
<!--
  T0830 Adversary-in-the-Middle (ICS)
  <Industrial protocol context>
  <What an unexpected match indicates>
  Reference: https://attack.mitre.org/techniques/T0830/
-->
<DestinationPort name="..." condition="is">...</DestinationPort>
```

### Existing Comment Block Examples in Configs

Many configs already have RuleGroup-level comments with ATT&CK references in headers. Phase 8b will:
- Preserve existing RuleGroup-level comments
- Add new per-rule (or per-grouped-set) comment blocks for individual technique tagging
- Avoid duplicating header information; per-rule comments focus on the specific rule's purpose

---

## SECTION 6: Rules Excluded From ATT&CK Tagging

The following are noise-reduction or operational rules and will NOT receive ATT&CK tags:

- All exclude rules across all configs (use `exclude=<context>` convention instead)
- `<DriverLoad onmatch="exclude">` Microsoft/Windows signature filters
- Pipe `<PipeName>` exclusions (lsass, wkssvc, srvsvc, winreg, spoolss)
- DNS QueryName Microsoft/Windows update domain exclusions
- ProcessAccess DC LSASS exclusions (legitimate AD processes)
- ImageLoad system DLL path exclusions
- Server-services NetworkConnect database/web noise exclusions

---

## SECTION 7: Phase 8b Execution Workflow (per config)

For each config, the Phase 8b workflow will be:

1. Read current config in full
2. Apply tagged names to all include rules using this worksheet
3. Apply `exclude=` names to all currently-unnamed exclude rules
4. Insert XML comment blocks above tagged include rules
5. Validate well-formed XML (`xmllint --noout <config>`)
6. Diff against original to verify ONLY `name=` attributes and XML comments changed
7. Verify no rule logic regressions: all `condition=`, `groupRelation=`, and rule values unchanged
8. Move to next config

After all 8 configs:
- Run xmllint on all configs as final check
- Spot-check that ATT&CK technique IDs are valid (no typos)
- Verify multi-technique rules use pipe delimiter consistently
- Confirm zero composite `<Rule>` elements were touched (none exist, but verify)

---

## SECTION 8: Open Issues -- RESOLVED

All 6 open issues have been resolved by user decision (2026-04-06):

1. **ICS ATT&CK techniques (T0xxx)**: APPROVED. ICS ATT&CK matrix is used for industrial protocol and firmware rules (T0830, T0855, T0836, T0852, T0857, T1601). Encoded in SYSMON_CODING_STANDARD.md section 6.4.

2. **`technique_name` short form**: APPROVED. Worksheet uses canonical short form (e.g., `NTDS`, `Web Shell`, `Adversary-in-the-Middle`). Encoded in SYSMON_CODING_STANDARD.md section 6.4.

3. **Web shell detection on .htaccess and web.config**: APPROVED with pipe-delimited multi-technique. Tagged as `T1505.003|T1574` for Web Shell + Hijack Execution Flow. Worksheet already uses this format.

4. **Rule deduplication during tagging**: CONFIRMED. One canonical tagged name per pattern; Phase 8b applies the same name across all configs that contain the rule. No actual rule deduplication -- rules remain in each config.

5. **Detection field length and SIEM compatibility**: RESOLVED with explicit constraints. Field rules:
   - **Hard limit: 250 chars** per `name` value (under Elasticsearch default `keyword` field `ignore_above: 256`)
   - **Target: 80-180 chars**
   - **Forbidden in field values**: comma (`,` is field separator), pipe (`|` is multi-technique separator)
   - All worksheet entries verified compliant: longest is 152 chars, none contain commas/pipes in values
   - Phase 8b validation will scan all tagged names for length and forbidden characters
   - Encoded in SYSMON_CODING_STANDARD.md section 6.3.

6. **Exclude rule naming consistency**: CONFIRMED. Phase 8b applies the `exclude=<context>` pattern across all currently-unnamed exclude rules with descriptive context. Examples in section 3 above.

---

## Status

- **Phase 8a**: COMPLETE
- **Phase 8b**: READY TO BEGIN. All conventions encoded in SYSMON_CODING_STANDARD.md. Worksheet provides per-rule tagged names. Awaiting user approval to start config edits.

Phase 8b begins per-config tagging following Section 7's workflow, validated against the constraints in SYSMON_CODING_STANDARD.md sections 6.3 and 9.
