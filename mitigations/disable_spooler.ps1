<#
.SYNOPSIS
    Mitigates PrintNightmare (CVE-2021-34527) by disabling the Windows Print Spooler.
.DESCRIPTION
    This script checks for administrative privileges, stops the Spooler service, 
    and sets its startup type to Disabled to completely close the attack vector.
.NOTES
    Author: Open-Source Security Researcher (GitHub Portfolio Project)
#>

# Ensure the script is running with administrative privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Warning "This script must be executed as an Administrator. Please relaunch PowerShell as Admin."
    Exit
}

Write-Host "[*] Initiating PrintNightmare Mitigation Protocol..." -ForegroundColor Cyan

try {
    # Stop the active service
    Write-Host "[+] Stopping Windows Print Spooler service..." -ForegroundColor Yellow
    Stop-Service -Name Spooler -Force -ErrorAction Stop
    
    # Disable the service from starting automatically
    Write-Host "[+] Disabling Spooler service startup type..." -ForegroundColor Yellow
    Set-Service -Name Spooler -StartupType Disabled -ErrorAction Stop
    
    Write-Host "[SUCCESS] Windows Print Spooler has been successfully deactivated and disabled." -ForegroundColor Green
}
catch {
    Write-Error "[-] Critical Failure during mitigation: $_"
}