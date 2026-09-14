$ErrorActionPreference = "Continue"

# Kuwait, Saudi Arabia, Bahrain, Qatar and Yemen use this Windows time-zone ID.
try {
    Set-TimeZone -Id "Arab Standard Time"
} catch {
    Write-Warning "Could not set the Windows time zone: $($_.Exception.Message)"
}

# A server VM must not suspend while terminals are posting attendance events.
powercfg.exe /change standby-timeout-ac 0
powercfg.exe /change hibernate-timeout-ac 0

$ruleName = "BioTime Web and ADMS (TCP 8090)"
if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule `
        -DisplayName $ruleName `
        -Direction Inbound `
        -Action Allow `
        -Protocol TCP `
        -LocalPort 8090 `
        -Profile Any | Out-Null
}

$desktop = [Environment]::GetFolderPath("Desktop")
$instructions = @"
BioTime installation checklist
===============================

1. Open the Shared folder (Z:) and run your licensed BioTime setup.exe.
2. Accept the vendor license only after reviewing it.
3. Set the BioTime server port to 8090.
4. Select the bundled/default PostgreSQL database unless you operate a supported
   external database yourself.
5. Finish setup, open BioTime Server Controller, create database tables if the
   installer did not do so, then start every BioTime service.
6. Install the vendor security update and confirm build 8.5.5.2944 or newer.
7. Confirm http://localhost:8090 opens inside Windows.

Do not change this VM's UUID or MAC address after activating BioTime.
"@

$instructions | Set-Content -Path (Join-Path $desktop "BIOTIME-FIRST-STEPS.txt") -Encoding UTF8

