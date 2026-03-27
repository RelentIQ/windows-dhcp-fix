@echo off
setlocal EnableDelayedExpansion
title DHCP Fix Tool - Revive My Device

:: ============================================================
:: DHCP Fix Script - Auto Static IP Workaround
:: Created by Revive My Device | 020 8050 9779
:: For use when Windows update breaks automatic IP assignment
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
echo   DHCP Fix Tool - Revive My Device
echo   Automatically fixes internet connection broken
echo   by a Windows update (February 2026 / KB5077181)
echo  =====================================================
echo.

:: -------------------------------------------------------
:: STEP 1: Try to detect gateway from routing table
:: -------------------------------------------------------
echo [1/5] Checking for existing gateway in routing table...

set "GATEWAY="

for /f "tokens=3" %%G in ('route print 0.0.0.0 2^>nul ^| findstr /R "0\.0\.0\.0.*0\.0\.0\.0"') do (
    if not defined GATEWAY (
        if not "%%G"=="0.0.0.0" (
            if not "%%G"=="255.255.255.0" (
                set "GATEWAY=%%G"
            )
        )
    )
)

if defined GATEWAY (
    echo     Gateway found in routing table: !GATEWAY!
    goto :GATEWAY_FOUND
)

echo     No gateway in routing table. Scanning common router addresses...
echo.

:: -------------------------------------------------------
:: STEP 2: Ping common gateway addresses
:: -------------------------------------------------------
echo [2/5] Scanning common router addresses...

set COMMON_GW=192.168.1.1 192.168.0.1 192.168.1.254 192.168.0.254 192.168.1.253 192.168.2.1 192.168.3.1 192.168.4.1 192.168.8.1 192.168.10.1 192.168.11.1 192.168.20.1 192.168.50.1 192.168.68.1 192.168.100.1 192.168.178.1 10.0.0.1 10.0.0.2 10.0.0.138 10.1.1.1 172.16.0.1

for %%G in (%COMMON_GW%) do (
    if not defined GATEWAY (
        ping -n 1 -w 500 %%G >nul 2>&1
        if !errorLevel! EQU 0 (
            set "GATEWAY=%%G"
            echo     Router found at: %%G
        )
    )
)

if defined GATEWAY goto :GATEWAY_FOUND

:: -------------------------------------------------------
:: STEP 3: No gateway found - ask user to input manually
:: -------------------------------------------------------
echo.
echo  -------------------------------------------------------
echo   Could not detect your router automatically.
echo.
echo   Please check the label on the back or bottom of your
echo   router. Look for "Gateway" or "Default IP Address".
echo   It usually looks like: 192.168.x.x or 10.0.0.x
echo  -------------------------------------------------------
echo.

:ASK_GATEWAY
set /p GATEWAY= Enter your router IP address (e.g. 192.168.1.1): 

set "DOT_CHECK=%GATEWAY:.=%"
if "%GATEWAY%"=="%DOT_CHECK%" (
    echo     Invalid format. Please enter a valid IP (e.g. 192.168.1.1)
    goto :ASK_GATEWAY
)

for /f "delims=. tokens=1,2,3,4" %%A in ("%GATEWAY%") do (
    if "%%A"=="" goto :BAD_IP
    if "%%B"=="" goto :BAD_IP
    if "%%C"=="" goto :BAD_IP
    if "%%D"=="" goto :BAD_IP
    goto :IP_OK
)
:BAD_IP
echo     Invalid IP address. Please try again.
goto :ASK_GATEWAY

:IP_OK
echo.
echo     Checking if %GATEWAY% responds...
ping -n 1 -w 1000 %GATEWAY% >nul 2>&1
if %errorLevel% NEQ 0 (
    echo.
    echo  WARNING: No response from %GATEWAY%.
    echo  It may still be correct if the router blocks pings.
    echo.
    set /p CONTINUE= Continue anyway? (Y/N): 
    if /i "!CONTINUE!" NEQ "Y" goto :ASK_GATEWAY
)

:GATEWAY_FOUND
echo.

:: -------------------------------------------------------
:: STEP 4: Detect active network adapter - multiple methods
:: -------------------------------------------------------
echo [3/5] Detecting active network adapter...

set "ADAPTER="
set "SUBNET=255.255.255.0"
set "CURRENT_IF="

:: Method 1: Find adapter that has our gateway via netsh ip show config
for /f "tokens=*" %%L in ('netsh interface ip show config 2^>nul') do (
    set "LINE=%%L"
    echo !LINE! | findstr /I "Configuration for interface" >nul 2>&1
    if !errorLevel! EQU 0 set "CURRENT_IF=!LINE!"
    echo !LINE! | findstr "%GATEWAY%" >nul 2>&1
    if !errorLevel! EQU 0 (
        if not defined ADAPTER (
            for /f "tokens=4*" %%A in ("!CURRENT_IF!") do (
                set "ADAPTER=%%A"
                set "ADAPTER=!ADAPTER:"=!"
            )
        )
    )
)

:: Method 2: netsh interface show interface - look for Dedicated+Connected
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

:: Get subnet mask from ipconfig
for /f "tokens=2 delims=:" %%S in ('ipconfig 2^>nul ^| findstr /C:"Subnet Mask"') do (
    if not defined SUBNET_SET (
        set "SUBNET=%%S"
        set "SUBNET=!SUBNET: =!"
        set "SUBNET_SET=1"
    )
)

:: -------------------------------------------------------
:: STEP 5: Build static IP from gateway prefix + .200
:: -------------------------------------------------------
echo [4/5] Calculating safe static IP address...

for /f "tokens=1,2,3 delims=." %%A in ("%GATEWAY%") do (
    set "NET_PREFIX=%%A.%%B.%%C"
)

set "STATIC_IP=%NET_PREFIX%.200"
set "DNS1=8.8.8.8"
set "DNS2=1.1.1.1"

echo.
echo  -------------------------------------------------------
echo   Configuration to be applied:
echo.
echo     Adapter    : %ADAPTER%
echo     IP Address : %STATIC_IP%
echo     Subnet     : %SUBNET%
echo     Gateway    : %GATEWAY%
echo     DNS        : %DNS1% / %DNS2%
echo  -------------------------------------------------------
echo.
set /p CONFIRM= Press ENTER to apply the fix, or Ctrl+C to cancel...
echo.

:: -------------------------------------------------------
:: Apply the static IP
:: -------------------------------------------------------
echo [5/5] Applying configuration...

netsh interface ip set address name="%ADAPTER%" static %STATIC_IP% %SUBNET% %GATEWAY% >nul 2>&1
set "APPLY_ERR=%errorLevel%"

if %APPLY_ERR% NEQ 0 (
    netsh interface ipv4 set address "%ADAPTER%" static %STATIC_IP% %SUBNET% %GATEWAY% >nul 2>&1
    set "APPLY_ERR=!errorLevel!"
)

netsh interface ip set dns name="%ADAPTER%" static %DNS1% >nul 2>&1
netsh interface ip add dns name="%ADAPTER%" %DNS2% index=2 >nul 2>&1

echo     Waiting for connection to establish...
timeout /t 5 /nobreak >nul

:: -------------------------------------------------------
:: Verify connectivity
:: -------------------------------------------------------
ping -n 1 -w 2000 8.8.8.8 >nul 2>&1
if %errorLevel% EQU 0 (
    echo.
    echo  =====================================================
    echo   SUCCESS! Your internet connection is restored.
    echo.
    echo   Static IP %STATIC_IP% has been assigned.
    echo.
    echo   IMPORTANT: Your IP is now set manually. Once
    echo   Microsoft releases a proper fix, you will need
    echo   to switch back to automatic. Contact us and we
    echo   will sort it remotely - free of charge.
    echo.
    echo   Revive My Device
    echo   020 8050 9779
    echo  =====================================================
) else (
    ping -n 1 -w 2000 %GATEWAY% >nul 2>&1
    if !errorLevel! EQU 0 (
        echo.
        echo  =====================================================
        echo   PARTIAL SUCCESS - Router is reachable.
        echo   Please open a browser and test your connection.
        echo.
        echo   If internet still does not work, contact us:
        echo   020 8050 9779
        echo  =====================================================
    ) else (
        echo.
        echo  =====================================================
        echo   Settings applied but connection unconfirmed.
        echo   Please open a browser and test. If not working:
        echo.
        echo   Revive My Device
        echo   020 8050 9779
        echo  =====================================================
    )
)

echo.
pause
endlocal
