# PrintNightmare-Technical-Analysis-Mitigation
Technical Analysis: The PrintNightmare Vulnerability 
An Investigation into CVE-2021-1675 and CVE-2021-34527 
Ethical Disclaimer: This repository is created strictly for educational purposes, college academic portfolios, and defensive engineering. It contains no weaponized exploits and focuses entirely on post-patch root cause analysis and mitigation deployment.

## Scope & Variant Exclusions
* **In-Scope:** CVE-2021-34527 & CVE-2021-1675 (Core PrintNightmare RCE/LPE via `RpcAddPrinterDriverEx`).
* **Out-of-Scope:** CVE-2021-34481.
  * *Justification:* CVE-2021-34481 involves a separate Local Privilege Escalation mechanism disclosed in July 2021 and patched in August 2021. This repository focuses strictly on the SMB/RPC remote driver loading vectors of CVE-2021-34527&CVE-2021-1675.

## 1. Executive Summary
The PrintNightmare(CVE-2021-34527 & CVE-2021-1675) is a critical vulnerability within the spoolsv.exe dealing with improper authorization and access control validation which are exploited through RPC functions.

### Vulnerability Matrix
|Metric|CVE-2021-1675|CVE-2021-34527|
| :---| :---| :---|
| **Common Name** | PrintNightmare(Local Variant) | PrintNightmare(Remote Variant) |
| **NVD CVSS v3.x Score**| 7.8 HIGH | 8.8 HIGH |
| **Primary Vector** | Local Privilege Escalation (LPE) | Remote Code Execution (RCE) |
| **Weakness Type** | CWE-269 (Improper Privilege Management) -A flaw in the RpcAddPrinterDriverEx() function allowed low-privilege users to bypass authentication and execute code.| CWE-287 (Improper Authentication)-A logic flaw where the Spooler service failed to validate the authorization level or path of a printer driver during remote execution. |
| **Initial Patch Date** | June 8, 2021 | July 1, 2021 (Out-of-Band Emergency) |

## 2. History & CVE Duality


## 3. Technical Root Cause Analysis
Both vulnerabilities exploit a structural error inside spoolsv.exe, specifically how the service handles permissions when installing print drivers(instructions for printer to talk to computers)
### Windows API weaknesses
* **Lack of Privilege Verification:** The functions used to add printer drivers, locally `RpcAddPrinterDriverEx()`, and remotely `RpcAsyncAddPrinterDriver()`, both failed to verify that the user installing the drivers had `SeLoadDriverPrivilege`(Admin Rights).
* **Parameter Manipulation:** If the dwFileCopyFlags parameter contained specific flags (like APD_COPY_ALL_FILES), the code assumed the files were already verified, allowing a standard user to execute high privilege commands.
* **Directory Junction Exploitation:**  The internal driver management code failed to properly sanitize folder paths, allowing strings containing subdirectories like \3\old\ to misdirect the file parser. This bug forces the Spooler to look inside the wrong folder directory, bypass verification checks, and actively run the malicious file.
* **Full Privileged Context:** Because spoolsv.exe runs natively under the NT AUTHORITY\SYSTEM context, any code it was tricked into loading inherited full, unrestricted access to the OS kernel.

### Built-in Windows Feature Flaws
* **Point and Print:** Designed to let regular users install printer drivers automatically from a print server without IT intervention. This feature inherently trusted remote driver sources.
* **RPC over SMB:** Windows enables remote printer management by default over SMB (IPC$ share and \pipe\spoolss named pipe), leaving the service exposed to the local network. This allows anyone on network to share files to this open file via RPC.


## 4. Defense Mitigations
PrintNightmare can be completely neutralized by basic network hardening techniques for small businesses and enterprise networks.
### Remediation Path 1: Windows Patches
Make sure all security updates released after July 2021 are installed. Modern Windows updates alter the bug `RpcAddPrinterDriverEx` to require admin privileges to install any printer drivers using point to print config.

### Remediation Path 2: Hardening Registry
Even with Windows Patches installed, malicious actors can exploit legacy code logic or misconfigured registries to bypass Windows updates entirely. Thus, explicit configuration is required via the Windows Registry or Group Policy Objects (GPO).
The following registry parameters must be verified and hardened:
* **Path:** `HKLM\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint`
* **Key:** `RestrictDriverInstallationToAdministrators` $\rightarrow$ Must be set to `1` (Enforced)
* **Key:** `NoWarningNoElevationOnInstall` $\rightarrow$ Must be set to `0` (Disabled)

### Remediation Path 3: Disabling Spooler Service
For servers that don't use physical printers that managed by GPO, it is best to disable Print Spooler service entirely. This can be done in Powershell(admin) or services.msc.
#### Powershell
1. Press the Windows Key, type powershell, right-click on the application, and select Run as administrator.

2. Copy and paste this command directly into Powershell(admin)
```powershell
# Stop and completely disable the Windows Print Spooler service
Stop-Service -Name Spooler -Force
Set-Service -Name Spooler -StartupType Disabled
```
#### Services.msc
1. Open the Run Dialog: Press the Windows Key + R on your keyboard to open the Run box.
2. Launch Services: Type services.msc into the box and press Enter (or click OK).
3. Locate the Service: Scroll down the alphabetical list of services until you find Print Spooler.
4. Open Properties: Right-click on Print Spooler and select Properties (or simply double-click the service name).
5. Stop the Service: Click the Stop button under the "Service status" section. Wait for the progress bar to finish.
6. Disable the Startup: Locate the Startup type dropdown menu and change it from Automatic or Manual to Disabled.
7. Save and Close: Click Apply, and then click OK to close the properties window

## 5. Conclusion


## 6. Resources



