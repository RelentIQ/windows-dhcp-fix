@echo off
setlocal EnableDelayedExpansion
title Restore Automatic IP - Revive My Device

:: ============================================================
:: DHCP Restore Script - Switch back to Automatic IP
:: Created by Revive My Device | 020 8050 9779
:: Run this once Microsoft releases a fix for the Windows
:: update issue (KB5077181 / KB5079473) and your internet works normally
:: ============================================================

:: Must run as Administrator
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo.
    echo  ERROR: This script must be run as Administrator.
    echo  Right-click the script and choose "Run as administrator".
    echo.
    pause
    exit /b 1
)

echo.
echo  =====================================================
echo   Restore Automatic IP - Revive My Device
echo   This will switch your network adapter back to
echo   automatic IP (DHCP) settings.
echo  =====================================================
echo.

:: -------------------------------------------------------
:: Get current gateway from routing table (same as fix script)
:: -------------------------------------------------------
echo [1/2] Detecting network adapter...

set "GATEWAY="
set "ADAPTER="
set "CURRENT_IF="

for /f "tokens=3" %%G in ('route print 0.0.0.0 2^>nul ^| findstr /R "0\.0\.0\.0.*0\.0\.0\.0"') do (
    if not defined GATEWAY (
        if not "%%G"=="0.0.0.0" (
            if not "%%G"=="255.255.255.0" (
                set "GATEWAY=%%G"
            )
        )
    )
)

:: Method 1: Match adapter to gateway via netsh ip show config (same as fix script)
if defined GATEWAY (
    for /f "tokens=*" %%L in ('netsh interface ip show config 2^>nul') do (
        set "LINE=%%L"
        echo !LINE! | findstr /I "Configuration for interface" >nul 2>&1
        if !errorLevel! EQU 0 set "CURRENT_IF=!LINE!"
        echo !LINE! | findstr "!GATEWAY!" >nul 2>&1
        if !errorLevel! EQU 0 (
            if not defined ADAPTER (
                for /f "tokens=4*" %%A in ("!CURRENT_IF!") do (
                    set "ADAPTER=%%A"
                    set "ADAPTER=!ADAPTER:"=!"
                )
            )
        )
    )
)

:: Method 2: netsh interface show interface - look for Connected
if not defined ADAPTER (
    for /f "skip=3 tokens=1,2,3,4*" %%A in ('netsh interface show interface 2^>nul') do (
        if not defined ADAPTER (
            if /i "%%C"=="Connected" set "ADAPTER=%%E"
            if /i "%%B"=="Connected" set "ADAPTER=%%E"
        )
    )
)

:: Method 3: wmic - adapter with a gateway assigned
if not defined ADAPTER (
    for /f "skip=1 delims=" %%A in ('wmic nicconfig where "IPEnabled=True AND DefaultIPGateway IS NOT NULL" get NetConnectionID 2^>nul ^| findstr /V "^$"') do (
        if not defined ADAPTER set "ADAPTER=%%A"
    )
)

:: Method 4: wmic - any enabled adapter with a connection ID
if not defined ADAPTER (
    for /f "skip=1 delims=" %%A in ('wmic nic where "NetEnabled=True AND NetConnectionID IS NOT NULL" get NetConnectionID 2^>nul ^| findstr /V "^$"') do (
        if not defined ADAPTER set "ADAPTER=%%A"
    )
)

:: Clean trailing spaces and carriage returns
if defined ADAPTER (
    for /f "tokens=* delims= " %%A in ("!ADAPTER!") do set "ADAPTER=%%A"
)

if not defined ADAPTER (
    echo.
    echo  ERROR: Could not identify your network adapter.
    echo  Please contact Revive My Device for assistance.
    echo  020 8050 9779
    echo.
    pause
    exit /b 1
)

echo     Adapter: %ADAPTER%
echo.

set /p CONFIRM= Press ENTER to restore automatic IP, or Ctrl+C to cancel...
echo.

:: -------------------------------------------------------
:: Restore DHCP
:: -------------------------------------------------------
echo [2/2] Restoring automatic IP settings...

netsh interface ip set address name="%ADAPTER%" dhcp >nul 2>&1
netsh interface ip set dns name="%ADAPTER%" dhcp >nul 2>&1

echo     Waiting for IP to be assigned automatically...
timeout /t 5 /nobreak >nul

:: Verify
ping -n 1 -w 2000 8.8.8.8 >nul 2>&1
if %errorLevel% EQU 0 (
    echo.
    echo  =====================================================
    echo   SUCCESS! Automatic IP has been restored and
    echo   your internet connection is working normally.
    echo.
    echo   Thank you for using Revive My Device!
    echo   020 8050 9779
    echo  =====================================================
) else (
    echo.
    echo  =====================================================
    echo   Automatic IP restored but internet unconfirmed.
    echo   Please open a browser and test your connection.
    echo.
    echo   If it does not work, the Windows fix may not yet
    echo   be installed. Contact us for help:
    echo   020 8050 9779
    echo  =====================================================
)

echo.
pause
endlocal
