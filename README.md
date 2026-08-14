# PrintNightmare-Technical-Analysis-Mitigation
Technical Analysis: The PrintNightmare Vulnerability 
An Investigation into CVE-2021-1675 and CVE-2021-34527 
Ethical Disclaimer: This repository is created strictly for educational purposes, college academic portfolios, and defensive engineering. It contains no weaponized exploits and focuses entirely on post-patch root cause analysis and mitigation deployment.
## Scope & Variant Exclusions

* **In-Scope:** CVE-2021-34527 & CVE-2021-1675 (Core PrintNightmare RCE/LPE via `RpcAddPrinterDriverEx`).
* **Out-of-Scope:** CVE-2021-34481.
  * *Justification:* CVE-2021-34481 involves a separate Local Privilege Escalation mechanism disclosed in July 2021 and patched in August 2021. This repository focuses strictly on the SMB/RPC remote driver loading vectors of CVE-2021-34527.



