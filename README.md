# PrintNightmare-Technical-Analysis-Mitigation
Technical Analysis: The PrintNightmare Vulnerability 
An Investigation into CVE-2021-1675 and CVE-2021-34527 
Ethical Disclaimer: This repository is created strictly for educational purposes, college academic portfolios, and defensive engineering. It contains no weaponized exploits and focuses entirely on post-patch root cause analysis and mitigation deployment.

## Scope & Variant Exclusions
* **In-Scope:** CVE-2021-34527 & CVE-2021-1675 (Core PrintNightmare RCE/LPE via `RpcAddPrinterDriverEx`).
* **Out-of-Scope:** CVE-2021-34481.
  * *Justification:* CVE-2021-34481 involves a separate Local Privilege Escalation mechanism disclosed in July 2021 and patched in August 2021. This repository focuses strictly on the SMB/RPC remote driver loading vectors of CVE-2021-34527.

## 1. Executive Summary

## 2. History & CVE Duality

## 3. Technical Root Cause Analysis

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



