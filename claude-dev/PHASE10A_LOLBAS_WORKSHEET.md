# Phase 10a LOLBAS Tagging Worksheet

## Purpose

This worksheet defines every LOLBAS detection rule that Phase 10 will add to the ICS Watch Dog curated configurations and module library. It is the deliverable of Phase 10a and the input to Phase 10b (Tier 1 rules), Phase 10c (Tier 2 rules), and Phase 10d (Tier 3 modules). No config or module edits have been performed in Phase 10a.

This worksheet must be reviewed and approved before Phase 10b begins.

## Convention Recap

The full convention is defined in `claude-dev/SYSMON_CODING_STANDARD.md`. Quick reference:

- **Composite rules** (Section 5.3): use `<Rule groupRelation="and">` for binary + command-line pattern detection. Tag the parent `<Rule>` element only; inner conditions stay untagged. Schema 4.50 (Sysmon v13+) supports this.
- **ATT&CK tagging** (Section 6): `name="technique_id=<ID>[|<ID2>],technique=<Name>[,detection=<Site Context>]"`. Pipe-delimited multi-technique. No commas or pipes in values. 250-char hard limit, 80-180 char target.
- **LOLBAS three-tier strategy** (Section 6.6): Tier 1 inline in all 8 configs, Tier 2 inline in 5 advanced configs, Tier 3 in `modules/lolbas/`.

## Source Material

- LOLBAS Project: https://lolbas-project.github.io
- MITRE ATT&CK Enterprise: https://attack.mitre.org/matrices/enterprise/
- SwiftOnSecurity sysmon-config v74 (in `sysmon-configs/reference/`)
- olafhartong/sysmon-modular `1_process_creation/include_living_off_the_land.xml`
- Sigma rules: https://github.com/SigmaHQ/sigma/tree/master/rules/windows/process_creation

---

## TIER 1: Core LOLBAS Rules (in all 8 curated configs)

12 detections with composite `<Rule groupRelation="and">` logic. Each rule scoped by binary + command-line pattern to minimize false positives. Each rule must satisfy: high signal, low FP, rare or never legitimate in OT environments.

These rules go in a new `ProcessCreate-LOLBAS-Core` RuleGroup added to all 8 curated configs identically. The RuleGroup uses `groupRelation="or"` (the parent), and each composite `<Rule>` inside uses `groupRelation="and"`.

### RuleGroup Structure

```xml
<!--
================================================================
LOLBAS-CORE: Core Living off the Land Binaries and Scripts detection.

Tier 1 of the three-tier LOLBAS strategy. Each rule is scoped by binary +
command-line pattern via composite Rule logic to minimize false positives.
These detections should rarely or never fire in stable OT environments;
every match warrants investigation.

See https://icswatchdog.com/lolbas-detection/ for the full strategy and
tuning guidance, and SYSMON_CODING_STANDARD.md section 6.6.

References:
  https://lolbas-project.github.io
  https://attack.mitre.org/matrices/enterprise/
================================================================
-->
<RuleGroup name="ProcessCreate-LOLBAS-Core" groupRelation="or">
  <ProcessCreate onmatch="include">
    <!-- 12 composite Rules below -->
  </ProcessCreate>
</RuleGroup>
```

### Tier 1 Rules

#### Rule 1: certutil -urlcache (Download)

```xml
<!--
  T1105 Ingress Tool Transfer + T1140 Deobfuscate Decode Files
  certutil's -urlcache argument downloads files from a URL. There is no
  legitimate administrative use case in OT environments. Any match indicates
  either malicious download staging or admin testing tools (investigate user).
  Reference: https://lolbas-project.github.io/lolbas/Binaries/Certutil/
-->
<Rule name="technique_id=T1105|T1140,technique=Ingress Tool Transfer,detection=certutil download via urlcache argument" groupRelation="and">
  <Image condition="end with">\certutil.exe</Image>
  <CommandLine condition="contains">urlcache</CommandLine>
</Rule>
```

**OT tuning notes**: No known legitimate OT use. If a vendor maintenance script uses certutil for certificate operations, it should use `-addstore` or `-importpfx`, not `-urlcache`.

#### Rule 2: certutil -decode (Base64 decode)

```xml
<!--
  T1140 Deobfuscate Decode Files
  certutil's -decode argument decodes base64-encoded files. Threat actors
  commonly use this to decode dropped payloads after staging encoded blobs
  to disk to evade content inspection.
  Reference: https://lolbas-project.github.io/lolbas/Binaries/Certutil/
-->
<Rule name="technique_id=T1140,technique=Deobfuscate Decode Files,detection=certutil base64 decode of staged payload" groupRelation="and">
  <Image condition="end with">\certutil.exe</Image>
  <CommandLine condition="contains">-decode</CommandLine>
</Rule>
```

**OT tuning notes**: No known legitimate OT use. If your environment uses certutil for certificate operations, those use `-addstore`, `-importpfx`, `-store`, etc., not `-decode`.

#### Rule 3: mshta with HTTP URL (Remote HTA Execution)

```xml
<!--
  T1218.005 Mshta + T1105 Ingress Tool Transfer
  mshta.exe executing an HTML application from an HTTP/HTTPS URL is the
  classic mshta abuse pattern. There is no legitimate use case for mshta
  loading remote content in OT environments. Investigate every match.
  Reference: https://lolbas-project.github.io/lolbas/Binaries/Mshta/
-->
<Rule name="technique_id=T1218.005|T1105,technique=Mshta,detection=Mshta loading remote HTA over HTTP/HTTPS" groupRelation="and">
  <Image condition="end with">\mshta.exe</Image>
  <CommandLine condition="contains">http</CommandLine>
</Rule>
```

**OT tuning notes**: No known legitimate OT use. Some legacy enterprise apps used mshta for local HTA wrapping, but those reference local file paths, not HTTP URLs.

#### Rule 4: regsvr32 Squiblydoo (Remote Scriptlet)

```xml
<!--
  T1218.010 Regsvr32
  regsvr32 with /i:http and scrobj.dll loads a remote COM scriptlet (the
  Squiblydoo technique published by Casey Smith / @subTee in 2017). There
  is no legitimate use case. Any match indicates malicious activity.
  Reference: https://lolbas-project.github.io/lolbas/Binaries/Regsvr32/
-->
<Rule name="technique_id=T1218.010,technique=Regsvr32,detection=Squiblydoo regsvr32 remote scriptlet load" groupRelation="and">
  <Image condition="end with">\regsvr32.exe</Image>
  <CommandLine condition="contains">/i:http</CommandLine>
</Rule>
```

**OT tuning notes**: No legitimate use. The `/i:http` pattern is the canonical Squiblydoo signature. A separate Tier 2 rule will catch `scrobj.dll` patterns more broadly.

#### Rule 5: bitsadmin /transfer (BITS Download)

```xml
<!--
  T1197 BITS Jobs + T1105 Ingress Tool Transfer
  bitsadmin /transfer creates a BITS job to download a file. While bitsadmin
  has legitimate uses for software deployment, the /transfer mode for
  downloading remote files is heavily abused and rarely used in modern admin
  workflows (replaced by PowerShell BITS module).
  Reference: https://lolbas-project.github.io/lolbas/Binaries/Bitsadmin/
-->
<Rule name="technique_id=T1197|T1105,technique=BITS Jobs,detection=bitsadmin transfer mode for file download" groupRelation="and">
  <Image condition="end with">\bitsadmin.exe</Image>
  <CommandLine condition="contains">/transfer</CommandLine>
</Rule>
```

**OT tuning notes**: Some legacy SCCM and Windows Update operations use bitsadmin internally, but they invoke it via service, not as a child of cmd/powershell. Manual `/transfer` invocations from interactive shells warrant investigation.

#### Rule 6: PowerShell Encoded Command

```xml
<!--
  T1059.001 PowerShell + T1027 Obfuscated Files or Information
  PowerShell -encodedcommand (or -enc) executes a base64-encoded script.
  Encoding is overwhelmingly used to evade command-line logging and content
  inspection. Legitimate admin scripts almost never use encoded commands.
  This rule covers both powershell.exe and pwsh.exe variants in two Rules.
  Reference: https://attack.mitre.org/techniques/T1059/001/
-->
<Rule name="technique_id=T1059.001|T1027,technique=PowerShell,detection=PowerShell encoded command (powershell.exe)" groupRelation="and">
  <Image condition="end with">\powershell.exe</Image>
  <CommandLine condition="contains">-encodedcommand</CommandLine>
</Rule>
<Rule name="technique_id=T1059.001|T1027,technique=PowerShell,detection=PowerShell short -enc encoded command (powershell.exe)" groupRelation="and">
  <Image condition="end with">\powershell.exe</Image>
  <CommandLine condition="contains">-enc </CommandLine>
</Rule>
<Rule name="technique_id=T1059.001|T1027,technique=PowerShell,detection=PowerShell encoded command (pwsh.exe)" groupRelation="and">
  <Image condition="end with">\pwsh.exe</Image>
  <CommandLine condition="contains">-encodedcommand</CommandLine>
</Rule>
```

**OT tuning notes**: Encoded PowerShell is rare in modern admin scripting. SCCM and some monitoring agents may use it for command marshaling -- if you see consistent encoded commands from a service account, identify the calling agent and exclude that specific service path. Note: this is conceptually one detection that requires three Rules to cover binary variants and parameter forms.

#### Rule 7: PowerShell DownloadString (Web Cradle)

```xml
<!--
  T1059.001 PowerShell + T1105 Ingress Tool Transfer
  System.Net.WebClient.DownloadString is the classic PowerShell stager
  pattern (commonly preceded by IEX or piped to Invoke-Expression). The
  string "DownloadString" appearing in a PowerShell command line is a
  high-confidence stager indicator.
  Reference: https://attack.mitre.org/techniques/T1059/001/
-->
<Rule name="technique_id=T1059.001|T1105,technique=PowerShell,detection=PowerShell Net.WebClient DownloadString stager" groupRelation="and">
  <Image condition="end with">\powershell.exe</Image>
  <CommandLine condition="contains">downloadstring</CommandLine>
</Rule>
<Rule name="technique_id=T1059.001|T1105,technique=PowerShell,detection=PowerShell Net.WebClient DownloadString stager (pwsh)" groupRelation="and">
  <Image condition="end with">\pwsh.exe</Image>
  <CommandLine condition="contains">downloadstring</CommandLine>
</Rule>
```

**OT tuning notes**: Almost no legitimate admin script uses DownloadString. Modern alternatives use `Invoke-WebRequest` with explicit error handling. If you have legitimate scripts that use DownloadString, they should be migrated.

#### Rule 8: PowerShell IEX with Web Call

```xml
<!--
  T1059.001 PowerShell
  Invoke-Expression (or its IEX alias) chained with web download is the
  classic PowerShell in-memory execution cradle. This rule catches the
  pattern where IEX is used with a web URL or download command in the
  same command line.
  Reference: https://attack.mitre.org/techniques/T1059/001/
-->
<Rule name="technique_id=T1059.001,technique=PowerShell,detection=PowerShell Invoke-Expression web cradle pattern" groupRelation="and">
  <Image condition="end with">\powershell.exe</Image>
  <CommandLine condition="contains">iex(new-object</CommandLine>
</Rule>
<Rule name="technique_id=T1059.001,technique=PowerShell,detection=PowerShell Invoke-Expression web cradle long form" groupRelation="and">
  <Image condition="end with">\powershell.exe</Image>
  <CommandLine condition="contains">invoke-expression(new-object</CommandLine>
</Rule>
```

**OT tuning notes**: This is the highest-confidence PowerShell stager pattern. Almost zero legitimate use. May be triggered by some red team training or pen test tools.

#### Rule 9: WMIC XSL Format (XSL Script Processing)

```xml
<!--
  T1220 XSL Script Processing
  wmic with /format: pointing to an XSL stylesheet executes the stylesheet
  as code. This is the canonical T1220 abuse pattern, used to bypass
  application allowlisting. There is no legitimate admin use case.
  Reference: https://lolbas-project.github.io/lolbas/Binaries/Wmic/
-->
<Rule name="technique_id=T1220,technique=XSL Script Processing,detection=WMIC XSL stylesheet format processing" groupRelation="and">
  <Image condition="end with">\wmic.exe</Image>
  <CommandLine condition="contains">format:"http</CommandLine>
</Rule>
<Rule name="technique_id=T1220,technique=XSL Script Processing,detection=WMIC XSL stylesheet from URL" groupRelation="and">
  <Image condition="end with">\wmic.exe</Image>
  <CommandLine condition="contains">/format:http</CommandLine>
</Rule>
```

**OT tuning notes**: No legitimate use. WMIC `/format:` with local XSL files is rare; with HTTP URLs it is always investigative. Note that wmic.exe is being deprecated in newer Windows versions.

#### Rule 10: WMIC Remote Process Creation (Lateral Movement)

```xml
<!--
  T1047 Windows Management Instrumentation + T1021.003 Distributed Component Object Model
  wmic /node: process call create is the classic WMIC lateral movement pattern.
  An attacker uses WMIC to spawn a process on a remote system. There is no
  legitimate interactive admin use case in OT environments.
  Reference: https://lolbas-project.github.io/lolbas/Binaries/Wmic/
-->
<Rule name="technique_id=T1047|T1021.003,technique=Windows Management Instrumentation,detection=WMIC remote process creation via /node:" groupRelation="and">
  <Image condition="end with">\wmic.exe</Image>
  <CommandLine condition="contains">/node:</CommandLine>
</Rule>
<Rule name="technique_id=T1047,technique=Windows Management Instrumentation,detection=WMIC process call create command" groupRelation="and">
  <Image condition="end with">\wmic.exe</Image>
  <CommandLine condition="contains">process call create</CommandLine>
</Rule>
```

**OT tuning notes**: SCCM, monitoring agents, and inventory tools may use WMIC, but typically without `/node:` or `process call create`. If you have legitimate management tools that use these patterns, identify the parent process and exclude by parent.

#### Rule 11: rundll32 JavaScript (Script Execution)

```xml
<!--
  T1218.011 Rundll32 + T1059.007 JavaScript
  rundll32 with javascript: in the command line executes JavaScript via
  the rundll32 proxy mechanism. There is no legitimate use case. Always
  investigate.
  Reference: https://lolbas-project.github.io/lolbas/Binaries/Rundll32/
-->
<Rule name="technique_id=T1218.011|T1059.007,technique=Rundll32,detection=Rundll32 JavaScript execution" groupRelation="and">
  <Image condition="end with">\rundll32.exe</Image>
  <CommandLine condition="contains">javascript:</CommandLine>
</Rule>
```

**OT tuning notes**: No legitimate use. The pattern `rundll32 javascript:"\..\mshtml,RunHTMLApplication ..."` is the canonical signature.

#### Rule 12: msdt.exe Follina Pattern (CVE-2022-30190)

```xml
<!--
  T1218 System Binary Proxy Execution
  Microsoft Diagnostic Tool (msdt.exe) was abused in CVE-2022-30190 (Follina)
  to execute arbitrary code via crafted ms-msdt: URIs in Office documents.
  Patched in 2022, but the binary remains a high-confidence detection target.
  Reference: https://msrc.microsoft.com/update-guide/vulnerability/CVE-2022-30190
-->
<Rule name="technique_id=T1218,technique=System Binary Proxy Execution,detection=Follina msdt PCWDiagnostic exploit pattern" groupRelation="and">
  <Image condition="end with">\msdt.exe</Image>
  <CommandLine condition="contains">PCWDiagnostic</CommandLine>
</Rule>
<Rule name="technique_id=T1218,technique=System Binary Proxy Execution,detection=Follina ms-msdt URI scheme pattern" groupRelation="and">
  <Image condition="end with">\msdt.exe</Image>
  <CommandLine condition="contains">ms-msdt:</CommandLine>
</Rule>
```

**OT tuning notes**: msdt.exe is used by Windows troubleshooters. Legitimate launches do not contain PCWDiagnostic with crafted parameters. If your environment uses msdt for troubleshooting, those launches will not match these patterns.

### Tier 1 Summary

| # | Detection | XML Rules | Composite | ATT&CK |
|---|---|---|---|---|
| 1 | certutil -urlcache | 1 | Yes | T1105\|T1140 |
| 2 | certutil -decode | 1 | Yes | T1140 |
| 3 | mshta http | 1 | Yes | T1218.005\|T1105 |
| 4 | regsvr32 Squiblydoo | 1 | Yes | T1218.010 |
| 5 | bitsadmin /transfer | 1 | Yes | T1197\|T1105 |
| 6 | PowerShell encoded | 3 (binary variants) | Yes | T1059.001\|T1027 |
| 7 | PowerShell DownloadString | 2 (binary variants) | Yes | T1059.001\|T1105 |
| 8 | PowerShell IEX cradle | 2 (pattern variants) | Yes | T1059.001 |
| 9 | WMIC XSL processing | 2 (pattern variants) | Yes | T1220 |
| 10 | WMIC remote process create | 2 (pattern variants) | Yes | T1047\|T1021.003 |
| 11 | rundll32 javascript | 1 | Yes | T1218.011\|T1059.007 |
| 12 | msdt Follina | 2 (pattern variants) | Yes | T1218 |
| **Total** | **12 detections** | **19 XML Rules** | **All composite** | -- |

19 XML `<Rule>` elements implementing 12 conceptual detections. Each goes in `ProcessCreate-LOLBAS-Core` RuleGroup in all 8 configs.

---

## TIER 2: Advanced LOLBAS Rules (in 5 advanced configs)

20 additional rules added to: `enhanced-ot.xml`, `advanced-ot.xml`, `server-ad.xml`, `server-services.xml`, `jumphost.xml`. These configs assume mature tuning programs and accept moderate false positive risk.

The Tier 2 rules go in a new `ProcessCreate-LOLBAS-Advanced` RuleGroup. Some rules use composite logic; others use simple `<Image>` matches.

### Tier 2 Rules

#### Rule 13: certutil -encode (Encode for Exfil)

```xml
<!--
  T1132 Data Encoding + T1027 Obfuscated Files or Information
  certutil -encode encodes a file as base64. Often used by attackers to
  prepare data for exfiltration over channels that don't tolerate binary.
-->
<Rule name="technique_id=T1132|T1027,technique=Data Encoding,detection=certutil base64 encode of file (potential exfil staging)" groupRelation="and">
  <Image condition="end with">\certutil.exe</Image>
  <CommandLine condition="contains">-encode</CommandLine>
</Rule>
```

#### Rules 14-15: mshta Inline Scripting

```xml
<!--
  T1218.005 Mshta + T1059.005 Visual Basic / T1059.007 JavaScript
  Mshta executing inline VBScript or JavaScript without a remote URL.
  Less common abuse pattern but still high-signal.
-->
<Rule name="technique_id=T1218.005|T1059.005,technique=Mshta,detection=Mshta inline VBScript execution" groupRelation="and">
  <Image condition="end with">\mshta.exe</Image>
  <CommandLine condition="contains">vbscript:</CommandLine>
</Rule>
<Rule name="technique_id=T1218.005|T1059.007,technique=Mshta,detection=Mshta inline JavaScript execution" groupRelation="and">
  <Image condition="end with">\mshta.exe</Image>
  <CommandLine condition="contains">javascript:</CommandLine>
</Rule>
```

#### Rule 16: Generic mshta Execution

```xml
<!--
  T1218.005 Mshta
  Any execution of mshta.exe. Catches less common abuse patterns and renamed
  HTA files. Higher false positive risk; some legacy apps may bundle HTAs.
-->
<Image name="technique_id=T1218.005,technique=Mshta,detection=Generic mshta.exe execution (binary-only detection)" condition="end with">\mshta.exe</Image>
```

#### Rule 17: Generic bitsadmin Execution

```xml
<!--
  T1197 BITS Jobs
  Any execution of bitsadmin.exe. Catches abuse modes other than /transfer.
-->
<Image name="technique_id=T1197,technique=BITS Jobs,detection=Generic bitsadmin.exe execution" condition="end with">\bitsadmin.exe</Image>
```

#### Rule 18: PowerShell Hidden + No Profile + Bypass Combo

```xml
<!--
  T1059.001 PowerShell + T1564.003 Hidden Window
  PowerShell with -w hidden, -nop, and -ep bypass simultaneously is the
  classic offensive PowerShell launcher pattern. Almost no legitimate
  admin script needs all three.
-->
<Rule name="technique_id=T1059.001|T1564.003,technique=PowerShell,detection=PowerShell hidden window with no profile flag" groupRelation="and">
  <Image condition="end with">\powershell.exe</Image>
  <CommandLine condition="contains">-w hidden -nop</CommandLine>
</Rule>
```

#### Rule 19: PowerShell Execution Policy Bypass

```xml
<!--
  T1059.001 PowerShell + T1562.001 Disable or Modify Tools
  PowerShell -ep bypass disables the execution policy for the current session.
  Legitimate but rarely used by sanctioned admin scripts.
-->
<Rule name="technique_id=T1059.001|T1562.001,technique=PowerShell,detection=PowerShell execution policy bypass" groupRelation="and">
  <Image condition="end with">\powershell.exe</Image>
  <CommandLine condition="contains">-ep bypass</CommandLine>
</Rule>
```

#### Rule 20: PowerShell from User Temp Directory

```xml
<!--
  T1059.001 PowerShell + T1564.001 Hidden Files and Directories
  PowerShell.exe whose parent process is in the user temp directory or
  Recycle Bin indicates a stager pattern. The Image condition matches
  PowerShell launched from temp paths (some malware copies powershell.exe
  there to evade simple AV).
-->
<Rule name="technique_id=T1059.001|T1564.001,technique=PowerShell,detection=PowerShell launched from AppData Temp directory" groupRelation="and">
  <Image condition="contains">\AppData\Local\Temp\</Image>
  <Image condition="end with">powershell.exe</Image>
</Rule>
```

#### Rule 21: InstallUtil Squiblytwo

```xml
<!--
  T1218.004 InstallUtil
  InstallUtil with /U or /AppPath arguments executes uninstall code or
  loads from non-standard paths. Squiblytwo abuse pattern.
-->
<Rule name="technique_id=T1218.004,technique=InstallUtil,detection=InstallUtil uninstall mode (Squiblytwo abuse)" groupRelation="and">
  <Image condition="end with">\InstallUtil.exe</Image>
  <CommandLine condition="contains">/U</CommandLine>
</Rule>
```

#### Rules 22-23: Generic regasm.exe / regsvcs.exe

```xml
<!--
  T1218.009 Regsvcs Regasm
  Regasm and regsvcs are .NET utilities that can execute managed code
  and bypass application allowlisting.
-->
<Image name="technique_id=T1218.009,technique=Regsvcs Regasm,detection=Generic regasm.exe execution" condition="end with">\RegAsm.exe</Image>
<Image name="technique_id=T1218.009,technique=Regsvcs Regasm,detection=Generic regsvcs.exe execution" condition="end with">\RegSvcs.exe</Image>
```

#### Rule 24: msxsl.exe Execution

```xml
<!--
  T1220 XSL Script Processing
  msxsl.exe is a standalone XSL transformation utility. Used to bypass
  AppLocker. Not a default Windows binary; presence indicates intentional
  install (admin or attacker).
-->
<Image name="technique_id=T1220,technique=XSL Script Processing,detection=Generic msxsl.exe execution" condition="end with">\msxsl.exe</Image>
```

#### Rule 25: cmstp.exe with Auto Update / Silent Mode

```xml
<!--
  T1218.003 CMSTP
  cmstp.exe with /au (auto update) or /s (silent) is used to install
  malicious connection manager profiles that execute code.
-->
<Rule name="technique_id=T1218.003,technique=CMSTP,detection=CMSTP installation with auto-update or silent mode" groupRelation="and">
  <Image condition="end with">\cmstp.exe</Image>
  <CommandLine condition="contains">/au</CommandLine>
</Rule>
<Rule name="technique_id=T1218.003,technique=CMSTP,detection=CMSTP silent install mode" groupRelation="and">
  <Image condition="end with">\cmstp.exe</Image>
  <CommandLine condition="contains">/s</CommandLine>
</Rule>
```

#### Rule 26: wuauclt DLL Sideload

```xml
<!--
  T1218 System Binary Proxy Execution
  wuauclt with /UpdateDeploymentProvider loads an arbitrary DLL via the
  Windows Update client. Used as a stealthy sideload technique.
-->
<Rule name="technique_id=T1218,technique=System Binary Proxy Execution,detection=wuauclt UpdateDeploymentProvider DLL sideload" groupRelation="and">
  <Image condition="end with">\wuauclt.exe</Image>
  <CommandLine condition="contains">/UpdateDeploymentProvider</CommandLine>
</Rule>
```

#### Rule 27: msbuild.exe from Non-VS Path

```xml
<!--
  T1127.001 MSBuild
  msbuild.exe execution from a path outside Visual Studio installation may
  indicate inline task abuse. This rule catches msbuild from any path; tune
  by excluding your specific Visual Studio install path if developers use
  the engineering workstation.
-->
<Image name="technique_id=T1127.001,technique=MSBuild,detection=Generic msbuild.exe execution (tune for VS install paths)" condition="end with">\MSBuild.exe</Image>
```

#### Rule 28: csc.exe Parented by Shell

```xml
<!--
  T1027.004 Compile After Delivery
  C# compiler csc.exe spawned by powershell.exe or cmd.exe indicates
  inline compilation, a common compile-after-delivery pattern.
-->
<Rule name="technique_id=T1027.004,technique=Compile After Delivery,detection=csc.exe spawned by PowerShell parent" groupRelation="and">
  <Image condition="end with">\csc.exe</Image>
  <ParentImage condition="end with">\powershell.exe</ParentImage>
</Rule>
<Rule name="technique_id=T1027.004,technique=Compile After Delivery,detection=csc.exe spawned by cmd.exe parent" groupRelation="and">
  <Image condition="end with">\csc.exe</Image>
  <ParentImage condition="end with">\cmd.exe</ParentImage>
</Rule>
```

#### Rules 29-30: Mavinject and Pcalua

```xml
<!--
  T1055.001 Process Injection: Dynamic-link Library Injection
  mavinject.exe is a Microsoft App-V utility that can inject DLLs into
  arbitrary processes. Heavily abused for code injection.
-->
<Image name="technique_id=T1055.001,technique=DLL Injection,detection=mavinject.exe DLL injection utility execution" condition="end with">\mavinject.exe</Image>

<!--
  T1218 System Binary Proxy Execution
  pcalua.exe (Program Compatibility Assistant) can be used to launch
  arbitrary executables and bypass application allowlisting.
-->
<Image name="technique_id=T1218,technique=System Binary Proxy Execution,detection=pcalua.exe Program Compatibility Assistant execution" condition="end with">\pcalua.exe</Image>
```

#### Rule 31: forfiles.exe Spawning Shell

```xml
<!--
  T1059.003 Windows Command Shell + T1218 System Binary Proxy Execution
  forfiles.exe with /c containing cmd.exe or powershell is a process
  execution proxy pattern. forfiles can iterate files and execute
  arbitrary commands per match.
-->
<Rule name="technique_id=T1059.003|T1218,technique=Windows Command Shell,detection=forfiles invoking cmd.exe via /c argument" groupRelation="and">
  <Image condition="end with">\forfiles.exe</Image>
  <CommandLine condition="contains">cmd</CommandLine>
</Rule>
```

#### Rule 32: finger.exe Execution

```xml
<!--
  T1105 Ingress Tool Transfer
  finger.exe is a legacy Unix protocol client included in Windows but
  rarely used legitimately. Has been abused as an exfiltration / download
  channel via the finger protocol.
-->
<Image name="technique_id=T1105,technique=Ingress Tool Transfer,detection=finger.exe execution (rare legacy binary)" condition="end with">\finger.exe</Image>
```

### Tier 2 Summary

| # | Detection | XML Rules | Composite | ATT&CK |
|---|---|---|---|---|
| 13 | certutil -encode | 1 | Yes | T1132\|T1027 |
| 14 | mshta vbscript: | 1 | Yes | T1218.005\|T1059.005 |
| 15 | mshta javascript: | 1 | Yes | T1218.005\|T1059.007 |
| 16 | Generic mshta | 1 | No (Image only) | T1218.005 |
| 17 | Generic bitsadmin | 1 | No (Image only) | T1197 |
| 18 | PowerShell hidden + nop | 1 | Yes | T1059.001\|T1564.003 |
| 19 | PowerShell -ep bypass | 1 | Yes | T1059.001\|T1562.001 |
| 20 | PowerShell from temp | 1 | Yes (path + binary) | T1059.001\|T1564.001 |
| 21 | InstallUtil /U | 1 | Yes | T1218.004 |
| 22 | regasm.exe | 1 | No (Image only) | T1218.009 |
| 23 | regsvcs.exe | 1 | No (Image only) | T1218.009 |
| 24 | msxsl.exe | 1 | No (Image only) | T1220 |
| 25 | cmstp /au or /s | 2 | Yes | T1218.003 |
| 26 | wuauclt UpdateDeploymentProvider | 1 | Yes | T1218 |
| 27 | msbuild.exe generic | 1 | No (Image only) | T1127.001 |
| 28 | csc.exe parented by shell | 2 | Yes | T1027.004 |
| 29 | mavinject.exe | 1 | No (Image only) | T1055.001 |
| 30 | pcalua.exe | 1 | No (Image only) | T1218 |
| 31 | forfiles spawning cmd | 1 | Yes | T1059.003\|T1218 |
| 32 | finger.exe | 1 | No (Image only) | T1105 |
| **Total** | **20 detections** | **22 XML Rules** | 14 composite, 8 Image-only | -- |

---

## TIER 3: Comprehensive Module Library (`modules/lolbas/`)

13 modules organized by ATT&CK technique family. Approximately 150 rules total. Each module is a focused detector that advanced users can opt into.

Modules go in `sysmon-configs/modules/lolbas/`. All modules are detection-only (include rules); no exclude or dual-use variants.

### Module 1: include_signed_binary_proxy.xml

**Focus**: T1218 family (Signed Binary Proxy Execution) comprehensive coverage
**Approx rules**: 25
**Key detections**:
- Comprehensive cmstp variants (`/au`, `/s`, `/ni`, `/u`)
- Control panel applet abuse (`control.exe` with .cpl from non-standard path)
- `dfsvc.exe` ClickOnce abuse
- `gpscript.exe` Group Policy script execution
- `ie4uinit.exe` user init abuse
- `Microsoft.Workflow.Compiler.exe` execution
- `mmc.exe` with .msc from non-standard path
- `msconfig.exe` with custom INI
- `msiexec /i http://`
- `odbcconf.exe` with REGSVR or RECONFIG
- `pcwrun.exe`
- `presentationhost.exe` with HTTP URL
- `rasautou.exe -d ... -p ... -a ... -e ...`
- `runonce.exe /AlternateShellStartup`
- `scriptrunner.exe`
- `verclsid.exe /S /C`
- All known T1218 sub-techniques (T1218.001 through T1218.014)

### Module 2: include_powershell_offensive.xml

**Focus**: T1059.001 PowerShell detailed offensive patterns
**Approx rules**: 15
**Key detections**:
- AMSI bypass patterns: `amsiInitFailed`, `AmsiUtils`, `amsiContext`
- Reflective load patterns: `[Reflection.Assembly]::Load`, `LoadFile`, `Reflection.Emit`
- Empire / Cobalt Strike PowerShell stager signatures
- Invoke-Mimikatz, Invoke-Kerberoast, Invoke-Bloodhound names
- `IEX(IEX(` double-IEX patterns
- `New-Object Net.Sockets.TCPClient` reverse shell pattern
- `[Convert]::FromBase64String` inline base64 decoding
- `iwr` (Invoke-WebRequest alias) with stager pattern
- `Start-BitsTransfer` PowerShell BITS download
- `Set-MpPreference -DisableRealtimeMonitoring`
- Suspicious string concatenation evasion: `'in'+'voke'`
- Get-Content piped to IEX

### Module 3: include_wmic_abuse.xml

**Focus**: T1047 Windows Management Instrumentation abuse patterns
**Approx rules**: 10
**Key detections**:
- WMIC `process call create`
- WMIC `/node:` for remote execution
- WMIC `xsl:` and `/format:` XSL processing
- WMIC `qfe` for patch enumeration (recon)
- WMIC `computersystem` recon
- WMIC `useraccount` enumeration
- WMIC `group` enumeration
- WMIC `service` listing
- WMIC startup enumeration
- WMIC environment variable extraction

### Module 4: include_certutil_abuse.xml

**Focus**: All certutil abuse modes
**Approx rules**: 8
**Key detections**:
- `-urlcache` (download)
- `-decode` (base64 decode)
- `-encode` (base64 encode for exfil)
- `-decodehex` (hex decode)
- `-encodehex` (hex encode)
- `-ping` (network reachability)
- `-verifyctl` (CTL verification used for proxy)
- `-addstore` from non-standard path

### Module 5: include_bitsadmin_abuse.xml

**Focus**: BITS abuse patterns
**Approx rules**: 6
**Key detections**:
- `bitsadmin /transfer`
- `bitsadmin /addfile`
- `bitsadmin /setnotifycmdline` (BITS persistence)
- `bitsadmin /setminretrydelay` 
- `bitsadmin /create`
- `bitsadmin /resume` chained with `/complete`

### Module 6: include_script_host_abuse.xml

**Focus**: cscript, wscript, jscript abuse
**Approx rules**: 10
**Key detections**:
- `cscript` with .vbs from $Recycle.Bin or AppData\Local\Temp
- `wscript` with .vbs from temp
- `cscript` with .js from temp
- `wscript` with .js from temp
- `cscript` with HTTP URL
- `wscript` parented by office processes (DOC macro pattern)
- `jscript.exe` execution
- Old Windows .wsh script execution
- ScriptShell.Application COM abuse via CL pattern

### Module 7: include_trusted_developer_utilities.xml

**Focus**: T1127 Trusted Developer Utilities Proxy Execution
**Approx rules**: 12
**Key detections**:
- `msbuild.exe` with .csproj from non-VS path
- `msbuild.exe` with .xml from temp
- `csc.exe` from non-VS path
- `vbc.exe` execution
- `jsc.exe` execution
- `ilasm.exe` execution
- `tracker.exe` with `/d` argument
- `dnx.exe` execution
- `rcsi.exe` execution (C# REPL)
- `csi.exe` execution (Roslyn C# Interactive)
- `ngen.exe` with non-NET caller
- `msdeploy.exe` with abuse arguments

### Module 8: include_xsl_script_processing.xml

**Focus**: T1220 XSL Script Processing
**Approx rules**: 6
**Key detections**:
- `wmic format:` with local XSL file
- `wmic format:` with HTTP URL
- `wmic xsl:` with file
- `msxsl.exe` with HTTP URL
- `msxsl.exe` with local XSL
- Generic msxsl.exe

### Module 9: include_persistence_via_lolbas.xml

**Focus**: T1547, T1053, T1543 persistence command lines
**Approx rules**: 10
**Key detections**:
- `at.exe` execution
- `schtasks /create /sc onstart`
- `schtasks /create /sc onlogon`
- `schtasks /create /tn` from non-admin parent
- `schtasks /create /ru SYSTEM`
- `sc.exe create` with binPath
- `sc.exe config` with binPath
- `reg add ... \Run` from cmd or powershell
- `reg add ... \RunOnce` from cmd or powershell
- `reg add ... \Image File Execution Options`

### Module 10: include_discovery_recon.xml

**Focus**: T1033, T1069, T1087, T1018, T1057, T1082 discovery commands
**Approx rules**: 15
**Key detections**:
- `whoami /all`
- `whoami /priv`
- `whoami /groups`
- `net group "Domain Admins"`
- `net group "Enterprise Admins"`
- `net localgroup administrators`
- `nltest /dclist:`
- `nltest /domain_trusts`
- `nltest /dsgetdc:`
- `quser`
- `qwinsta`
- `query session`
- `tasklist /svc`
- `systeminfo`
- `route print` followed by `arp -a`

### Module 11: include_amsi_bypass_patterns.xml

**Focus**: T1562.001 AMSI bypass via PowerShell command-line strings
**Approx rules**: 8
**Key detections**:
- PowerShell command line containing `amsiInitFailed`
- PowerShell command line containing `AmsiScanBuffer`
- PowerShell command line containing `AmsiContext`
- PowerShell command line containing `[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils')`
- PowerShell with `Set-ItemProperty` targeting AMSI registry keys
- PowerShell with `[System.Runtime.InteropServices.Marshal]::WriteByte` AMSI patches
- `amsi.dll` referenced in command line
- AMSI bypass GitHub repo names in command line

### Module 12: include_dotnet_unmanaged_abuse.xml

**Focus**: .NET unmanaged execution abuse
**Approx rules**: 8
**Key detections**:
- `csi.exe` (C# Interactive REPL)
- `Microsoft.Workflow.Compiler.exe` execution
- `jsc.exe` (JScript compiler)
- `dotnet.exe` with unusual arguments
- `dotnet.exe` running .dll from temp
- `installutil.exe` with unusual paths
- `regsvcs.exe` from non-standard path
- `regasm.exe` from non-standard path

### Module 13: include_uncommon_lolbas.xml

**Focus**: Long-tail rare LOLBAS techniques
**Approx rules**: 20
**Key detections**:
- `replace.exe` with /A /S /U
- `runscripthelper.exe`
- `AgentExecutor.exe` (Intune)
- `AppInstaller.exe`
- `ConfigSecurityPolicy.exe`
- `dnscmd.exe /config /serverlevelplugindll` (DNSAdmin abuse)
- `gpscript.exe`
- `hh.exe` with HTTP URL
- `ie4uinit.exe`
- `ieexec.exe` with HTTP URL
- `ttdinject.exe`
- `wuauclt.exe /UpdateDeploymentProvider`
- `Microsoft.NodejsTools.PressAnyKey.exe`
- `OfflineScannerShell.exe`
- `MSDeploy.exe`
- `Squirrel.exe` (Update.exe sideload)
- `Update.exe` (Squirrel framework)
- `WorkFolders.exe`
- `wsl.exe` with execution arguments
- `wsl.exe -e bash`

### Tier 3 Summary

| Module | Approx Rules | ATT&CK Focus |
|---|---|---|
| `include_signed_binary_proxy.xml` | 25 | T1218 family |
| `include_powershell_offensive.xml` | 15 | T1059.001 |
| `include_wmic_abuse.xml` | 10 | T1047 |
| `include_certutil_abuse.xml` | 8 | T1140, T1105, T1132 |
| `include_bitsadmin_abuse.xml` | 6 | T1197, T1105 |
| `include_script_host_abuse.xml` | 10 | T1059.005, T1059.007 |
| `include_trusted_developer_utilities.xml` | 12 | T1127, T1218 |
| `include_xsl_script_processing.xml` | 6 | T1220 |
| `include_persistence_via_lolbas.xml` | 10 | T1547, T1053, T1543 |
| `include_discovery_recon.xml` | 15 | T1033, T1069, T1087, T1018, T1057, T1082 |
| `include_amsi_bypass_patterns.xml` | 8 | T1562.001 |
| `include_dotnet_unmanaged_abuse.xml` | 8 | T1218 |
| `include_uncommon_lolbas.xml` | 20 | T1218 family long tail |
| **Total** | **~153** | -- |

---

## Implementation Plan for Phase 10b/c/d

### Phase 10b Workflow (Tier 1 in all 8 configs)

For each of the 8 curated configs:

1. Read current config
2. Locate the `ProcessCreate-RansomwareIndicators` RuleGroup (which all configs have)
3. Insert a new `ProcessCreate-LOLBAS-Core` RuleGroup immediately after it
4. Add the 19 XML Rules from Tier 1 Section above
5. Add maintainer XML comment block before each rule (or grouped sets)
6. Update the config header `MITRE ATT&CK Coverage` section to add new techniques: T1027, T1047, T1059.007, T1105, T1132, T1140, T1197, T1218, T1218.005, T1218.010, T1218.011, T1220, T1021.003
7. Bump config version (e.g., v2.1 to v3.0)
8. Validate XML well-formedness with xmllint
9. Diff-check against original: only the new RuleGroup, header version bump, and ATT&CK Coverage additions changed
10. Verify no other rule logic changed

Since the 19 XML Rules are identical across all 8 configs, this is a copy-paste operation per config. The maintainer comments should explain that these rules use composite Rule logic (first use in ICS Watch Dog).

### Phase 10c Workflow (Tier 2 in 5 configs)

For each of the 5 advanced configs (`enhanced-ot`, `advanced-ot`, `server-ad`, `server-services`, `jumphost`):

1. Add `ProcessCreate-LOLBAS-Advanced` RuleGroup immediately after `ProcessCreate-LOLBAS-Core`
2. Add the 22 XML Rules from Tier 2 Section above
3. Update header MITRE ATT&CK Coverage with additional techniques: T1027.004, T1055.001, T1059.005, T1059.003, T1127.001, T1218.003, T1218.004, T1218.009, T1564.001, T1564.003
4. Validate XML, diff-check, verify no other changes

### Phase 10d Workflow (Tier 3 modules)

For each of the 13 modules:

1. Create the module file with standard module header (purpose, when to use, ATT&CK references, schema 4.50)
2. Add the rules listed in the module summary above with full ATT&CK structured tagging
3. Validate XML when wrapped in synthetic root
4. Update `sysmon-configs/modules/INDEX.md` with the new module entries and a new "LOLBAS" section
5. Update `sysmon-configs/modules/README.md` to add lolbas as the 7th category in the categories table
6. Run `tools/Test-MergeSysmonModules.ps1` to verify modules merge cleanly with curated configs

---

## Per-Config Impact Summary

### Tier 1 Only (3 configs)

| Config | Current rules | After Phase 10b | Net add |
|---|---|---|---|
| baseline-it-workstation.xml | 119 | 138 | +19 |
| baseline-it-server.xml | 115 | 134 | +19 |
| baseline-ot.xml | 145 | 164 | +19 |

### Tier 1 + Tier 2 (5 configs)

| Config | Current rules | After Phase 10b | After Phase 10c | Net add |
|---|---|---|---|---|
| enhanced-ot.xml | 185 | 204 | 226 | +41 |
| advanced-ot.xml | 201 | 220 | 242 | +41 |
| server-ad.xml | 159 | 178 | 200 | +41 |
| server-services.xml | 188 | 207 | 229 | +41 |
| jumphost.xml | 101 | 120 | 142 | +41 |

### Total Impact

- **8 configs** get Tier 1: +19 rules each = **+152 rules total across configs**
- **5 configs** also get Tier 2: +22 rules each = **+110 rules total across configs**
- **13 new modules** in modules/lolbas/: **+~153 rules**
- **Grand total new LOLBAS rules**: ~415 across the project (with duplication across configs)

---

## Composite Rule Validation

This is the first use of `<Rule groupRelation="and">` in ICS Watch Dog. To ensure correctness:

1. **Schema validation**: Tier 1 uses schema 4.50 features only. Composite Rules introduced in schema 4.20. All 8 configs are 4.50 or 4.90, so all are compatible.
2. **Sysmon version**: Composite Rules supported since Sysmon v8 (2018). All ICS Watch Dog configs require Sysmon v13+, well above the minimum.
3. **Test before propagating**: Phase 10b should start with one config (recommendation: `sysmonconfig-jumphost.xml` since it's the smallest), validate the merge tool still works, and confirm xmllint passes before propagating to the other 7.
4. **Diff-check considerations**: The Phase 8b diff-check script extracts simple `<Element condition="..." >value</Element>` tuples. Composite `<Rule>` elements wrap inner conditions, so the existing diff-check needs an update to recognize composite rules as a single tagged unit. Phase 10b should produce an updated diff-check approach that handles both simple and composite rules.

---

## Open Issues for Review

1. **Tier 1 binary variants**: Should PowerShell rules cover both `powershell.exe` and `pwsh.exe` (3 Rules per detection) or just `powershell.exe` (1 Rule, with note that PS Core users can add pwsh.exe)? Recommendation: cover both, since pwsh.exe is increasingly common.

2. **Case sensitivity**: Sysmon's `contains` operator is case-insensitive by default, so `contains "downloadstring"` matches `DownloadString`, `DOWNLOADSTRING`, etc. Confirm this is the correct assumption (it is, per Sysmon documentation).

3. **Tier 2 in `enhanced-ot.xml`**: The Phase 10 plan includes `enhanced-ot` in the Tier 2 list. Confirm: is enhanced-ot considered "advanced enough" to warrant Tier 2, or should it stay at Tier 1 only? Recommendation: include Tier 2 in enhanced-ot since enhanced-ot is meant for environments with mature OT monitoring.

4. **Module rule counts are approximate**: Each Tier 3 module lists "approximately N rules". The actual count may vary by ±20% as I implement. Acceptable, or do you want exact counts before approval?

5. **AMSI bypass patterns**: Module 11 detects strings like `amsiInitFailed` in PowerShell command lines. This is high-confidence but very specific. Threat actors may rotate strings. Consider if this should be a separate ATT&CK Coverage page noting the limitation.

6. **Discovery commands in Module 10**: Some discovery commands (whoami, net group, tasklist) are routinely run by sysadmins. Tier 3 module accepts this noise. If you want stricter filtering (only flag if parent is unusual), let me know.

7. **WSL detection**: Tier 3 Module 13 includes WSL execution. WSL is commonly used by developers but rarely by OT operators. Confirm WSL detection is desired.

8. **dnscmd.exe `/serverlevelplugindll`**: This is the DNSAdmin DLL injection technique (T1546.012 variant). Currently in Tier 3 Module 13. Could promote to Tier 2 if you consider it high-priority for AD environments. Recommendation: keep in Tier 3.

9. **Diff-check tooling update**: As noted in Composite Rule Validation, the Phase 8b diff-check approach needs adjustment for composite rules. Should this be a Phase 10b prerequisite (tool update first) or a Phase 10b deliverable (update tool inline with config edits)?

10. **Header ATT&CK Coverage section**: Adding 13 new techniques to each config's header doubles the size of the MITRE ATT&CK Coverage section. Acceptable, or should we consolidate into broader categories with sub-techniques noted in the rules only?

---

## Status

- **Phase 10a**: COMPLETE -- this worksheet is the deliverable
- **Phase 10b**: AWAITING REVIEW AND APPROVAL of this worksheet before any config edits

Once approved, Phase 10b begins with adding `ProcessCreate-LOLBAS-Core` to all 8 configs, starting with `sysmonconfig-jumphost.xml` as the validation target.
