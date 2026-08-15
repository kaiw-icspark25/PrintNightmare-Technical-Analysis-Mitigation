<#
.SYNOPSIS
    Audits and hardens Windows Print Spooler and Point-and-Print registry settings against PrintNightmare (CVE-2021-34527 / CVE-2021-1675).

.DESCRIPTION
    By default, this script runs in AUDIT mode to inspect configuration settings without making changes.
    Using the -Fix parameter will enforce administrative hardening policies.

.PARAMETER Fix
    Enforces secure settings by stopping/disabling the Spooler service on non-print servers and setting restrictive Point-and-Print registry keys.

.EXAMPLE
    .\Audit-PrintNightmare.ps1
    Runs the audit and outputs current risk status.

.EXAMPLE
    .\Audit-PrintNightmare.ps1 -Fix
    Applies recommended security hardening policies.
#>

[CmdletBinding()]
param (
    [Switch]$Fix
)

# Function to check Administrator privileges
function Test-IsAdmin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Ensure script is run with elevated privileges
if (-not (Test-IsAdmin)) {
    Write-Warning "This script requires Administrator privileges to audit/modify system registry and service states."
    Write-Warning "Please relaunch PowerShell as Administrator."
    exit
}

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "      Print Spooler & Point-and-Print Security Audit" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------
# 1. AUDIT: Check Spooler Service Status
# ---------------------------------------------------------
Write-Host "[1/3] Checking Print Spooler Service Status..." -ForegroundColor Cyan
$spoolerService = Get-Service -Name "Spooler" -ErrorAction SilentlyContinue

if ($null -eq $spoolerService) {
    Write-Host "  [-] Print Spooler service not found." -ForegroundColor Yellow
} else {
    $spoolerState = $spoolerService.Status
    $spoolerStartType = $spoolerService.StartType
    
    Write-Host "  * Service Status : $spoolerState"
    Write-Host "  * Startup Type   : $spoolerStartType"

    if ($spoolerState -eq "Running") {
        Write-Host "  [!] WARNING: Spooler service is running. On Domain Controllers or non-print servers, this increases attack surface." -ForegroundColor Yellow
    } else {
        Write-Host "  [+] PASS: Spooler service is not running." -ForegroundColor Green
    }
}

Write-Host ""

# ---------------------------------------------------------
# 2. AUDIT: Check Point-and-Print Registry Keys
# ---------------------------------------------------------
Write-Host "[2/3] Checking Point-and-Print Registry Configurations..." -ForegroundColor Cyan

$pnpPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"

# Key 1: RestrictDriverInstallationToAdministrators
$restrictAdminVal = Get-ItemPropertyValue -Path $pnpPath -Name "RestrictDriverInstallationToAdministrators" -ErrorAction SilentlyContinue

# Key 2 & 3: NoWarningNoElevationOnInstall / NoWarningNoElevationOnUpdate
$noWarnInstallVal = Get-ItemPropertyValue -Path $pnpPath -Name "NoWarningNoElevationOnInstall" -ErrorAction SilentlyContinue
$noWarnUpdateVal  = Get-ItemPropertyValue -Path $pnpPath -Name "NoWarningNoElevationOnUpdate" -ErrorAction SilentlyContinue

# Audit Check: RestrictDriverInstallationToAdministrators
if ($restrictAdminVal -eq 1) {
    Write-Host "  [+] PASS: RestrictDriverInstallationToAdministrators is set to 1 (Restricted to Admins)." -ForegroundColor Green
} else {
    Write-Host "  [!] FAIL: RestrictDriverInstallationToAdministrators is missing or not set to 1." -ForegroundColor Red
}

# Audit Check: Elevation Prompt Requirements
if ($noWarnInstallVal -eq 0 -and $noWarnUpdateVal -eq 0) {
    Write-Host "  [+] PASS: Elevation warnings/prompts are strictly enforced for installation and updates." -ForegroundColor Green
} else {
    Write-Host "  [!] FAIL: Warning/Elevation prompts may be suppressed for non-admins." -ForegroundColor Red
}

Write-Host ""

# ---------------------------------------------------------
# 3. REMEDIATION (-Fix Switch Execution)
# ---------------------------------------------------------
if ($Fix) {
    Write-Host "----------------------------------------------------" -ForegroundColor Yellow
    Write-Host "[3/3] Executing Hardening Procedures (-Fix Mode Enabled)..." -ForegroundColor Yellow
    Write-Host "----------------------------------------------------" -ForegroundColor Yellow

    # Ensure registry path exists
    if (-not (Test-Path $pnpPath)) {
        New-Item -Path $pnpPath -Force | Out-Null
        Write-Host "  [+] Created PointAndPrint registry key path." -ForegroundColor Green
    }

    # Enforce RestrictDriverInstallationToAdministrators = 1
    Set-ItemProperty -Path $pnpPath -Name "RestrictDriverInstallationToAdministrators" -Value 1 -Type DWord -Force
    Write-Host "  [+] Configured RestrictDriverInstallationToAdministrators = 1" -ForegroundColor Green

    # Enforce Elevation Prompts (Set both to 0)
    Set-ItemProperty -Path $pnpPath -Name "NoWarningNoElevationOnInstall" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $pnpPath -Name "NoWarningNoElevationOnUpdate" -Value 0 -Type DWord -Force
    Write-Host "  [+] Configured NoWarningNoElevationOnInstall = 0 and NoWarningNoElevationOnUpdate = 0" -ForegroundColor Green

    # Optional: Prompt to stop/disable Spooler if running
    if ($spoolerService.Status -eq "Running") {
        $confirmation = Read-Host "  [?] Do you want to STOP and DISABLE the Print Spooler service on this host? (Y/N)"
        if ($confirmation -eq 'Y' -or $confirmation -eq 'y') {
            Stop-Service -Name "Spooler" -Force
            Set-Service -Name "Spooler" -StartupType Disabled
            Write-Host "  [+] Print Spooler service stopped and startup set to Disabled." -ForegroundColor Green
        } else {
            Write-Host "  [-] Skipped disabling the Print Spooler service." -ForegroundColor Yellow
        }
    }

    Write-Host ""
    Write-Host "[+] Hardening complete. Rerun script without -Fix to verify updated audit status." -ForegroundColor Green
} else {
    Write-Host "----------------------------------------------------" -ForegroundColor Gray
    Write-Host "Audit complete. To enforce security settings, rerun this script with the -Fix switch:" -ForegroundColor Gray
    Write-Host "  .\Audit-PrintNightmare.ps1 -Fix" -ForegroundColor White
    Write-Host "----------------------------------------------------" -ForegroundColor Gray
}