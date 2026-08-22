# Lab Documentation: PrintNightmare Local Privilege Escalation (CVE-2021-1675)

## Overview
This document outlines the successful exploitation of the PrintNightmare vulnerability on a standalone Windows Server 2019 environment. The lab demonstrates a Local Privilege Escalation (LPE) vector, taking an authenticated, low-privileged local user and elevating access to full Local Administrator permissions.

## Environment Details
- **Target OS:** Windows Server 2019 (Workgroup Environment)
- **Attack Vector:** Local Privilege Escalation (LPE)
- **Vulnerability:** CVE-2021-34527 (PrintNightmare)
- **Exploit Script:** Invoke-Nightmare (Caleb Stewart)

---

## Step 1: Laboratory Setup & Vulnerability Reproduction
Because the target operating system was patched, specific registry configurations were applied via Registry Editor (`regedit`) to simulate a vulnerable enterprise misconfiguration allowing non-administrators to install print drivers.

1. Navigated to `HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint`.
2. Configured the following values to lower system defenses:
   - `RestrictDriverInstallationToAdministrators` (DWORD 32-bit) = `0`
   - `NoWarningNoElevationOnInstall` (DWORD 32-bit) = `1`
3. Confirmed the local Print Spooler service was operational using the administrative command:
   ```cmd
   net start spooler
   ```

---

## Step 2: Tool Delivery (Air-Gapped Workaround)
Due to strict network isolation and host isolation constraints, standard network download vectors (e.g., `Invoke-WebRequest`) were unavailable. 

1. The exploit payload (`Invoke-Nightmare.ps1`) was packaged into an ISO file on the host machine.
2. The ISO was mounted to the virtual optical drive of the running Windows Server 2019 VM.
3. The script was copied directly into `C:\Users\Public\nightmare.ps1` to ensure accessibility by non-administrative users.

---

## Step 3: Low-Privileged Authentication
A non-administrative testing account was created to verify the privilege boundary:
- **Username:** `labuser`
- **Password:** `Password123`

The administrator session was closed, and a standard interactive desktop session was initiated using the `labuser` credentials.

---

## Step 4: Exploitation & Execution
A standard PowerShell console was opened under the context of `labuser` and the following execution sequence was performed:

1. Bypassed the local execution policy restriction for the current process:
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process
   ```
2. Loaded the exploit script into memory:
   ```powershell
   Import-Module C:\Users\Public\nightmare.ps1
   ```
3. Fired the exploit payload to abuse the Point-and-Print driver installation flaw, forcing the spooler process (`NT AUTHORITY\SYSTEM`) to inject a new administrative user:
   ```powershell
   Invoke-Nightmare -NewUser "hacker" -NewPassword "Password123!"
   ```

---

## Step 5: Proof of Concept & Verification
To verify successful privilege escalation, the membership of the local administrators group was queried:

```powershell
net localgroup administrators
```

**Result:** The user account `hacker` was successfully injected into the Local Administrators group, confirming arbitrary code execution at the highest local privilege level.

—
## Detection & Indicators of Compromise (IoCs)
A successful exploitation attempt leaves specific artifacts within the Windows Security Event logs. Analysts can hunt for this specific PrintNightmare activity using the following Event IDs:

- **Event ID 4720 (A user account was created):** Generated the moment the Print Spooler process was forced to create the unauthorized `hacker` account.
- **Event ID 4732 (A member was added to a security-enabled local group):** Generated immediately following the account creation, logging the elevation of `hacker` into the `Administrators` group.
- **Process Creation Logs:** Security analysts should flag the `spoolsv.exe` (Print Spooler) process spawning unexpected child processes or unusual driver installations in the system paths.



## Remediation & Verification Phase

To formally remediate the environment and verify the fixes, an automated defense script (`Audit-PrintNightmare.ps1`) was utilized alongside manual cleanup steps.

### Step 1: Automated Auditing and Remediation
The defensive script was downloaded to the Administrator account's Desktop on the local VM. 

1. An Administrative PowerShell console was opened.
2. Navigated to the script location:
   ```powershell
   cd C:\Users\Administrator\Desktop
   ```
3. Executed the initial system audit to flag the active vulnerabilities:
   ```powershell
   ./Audit-PrintNightmare.ps1
   ```
4. Applied automated remediation to safely harden the server policies:
   ```powershell
   ./Audit-PrintNightmare.ps1 -Fix
   ```

### Step 2: Manual Registry and Artifact Cleanup
To restore the system to a clean state, the temporary lab configurations were manually purged.

1. Opened `regedit` and completely deleted the custom `PointAndPrint` registry keys created during the initial setup phase.
2. Deleted the adversarial payload code (`nightmare.ps1`) from the `C:\Users\Public\` directory to remove the exploitation tools entirely from the filesystem.
3. Removed the unauthorized `hacker` account from the system:
   ```cmd
   net user hacker /delete
   ```

### Step 3: Post-Remediation Verification (Exploit Failure)
To confirm the effectiveness of the remediation, a final verification test was conducted.

1. Authenticated back into the low-privileged `labuser` account.
2. Attempted to execute the PrintNightmare exploit string again.

**Result:** The exploit **failed completely**. The Print Spooler rejected the unprivileged driver installation request, proving that the mitigation script and registry cleanup successfully closed the security loophole.




