@echo off
cls
setlocal enabledelayedexpansion
mkdir "%tmp%\SW" >nul 2>&1


:: Check if ran as Admin
net session >nul 2>&1 || (echo. & echo Run Script As Admin & echo. & pause & exit)


:# General Power
echo.
echo 1/4 - General Power
:: Set the 'Power Management' to High performance
for /f "tokens=4,*" %%a in ('powercfg /l ^| find /i "High performance"') do powercfg /s %%a >nul 2>&1




:# Network Interfaces
echo 2/4 - Network Interfaces
set "RegPath=HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"
for /F "tokens=1*" %%A in ('reg query "%RegPath%" ^| findstr "000"') do (

:: Disable - Power Saving
reg add %%A /t REG_SZ /v "*EEE" /d 0 /f >nul 2>&1
reg add %%A /t REG_SZ /v AdvancedEEE /d 0 /f >nul 2>&1
reg add %%A /t REG_SZ /v AutoPowerSaveModeEnabled /d 0 /f >nul 2>&1
reg add %%A /t REG_SZ /v EnableEDT /d 0 /f >nul 2>&1
reg add %%A /t REG_SZ /v EnableGreenEthernet /d 0 /f >nul 2>&1
reg add %%A /t REG_SZ /v EEELinkAdvertisement /d 0 /f >nul 2>&1
reg add %%A /t REG_SZ /v ENPWMode /d 0 /f >nul 2>&1
reg add %%A /t REG_SZ /v GPPSW /d 0 /f >nul 2>&1
reg add %%A /t REG_SZ /v PowerSavingMode /d 0 /f >nul 2>&1
reg add %%A /t REG_SZ /v ULPMode /d 0 /f >nul 2>&1

:: Disable - Reduce network speed to 10/100
reg add %%A /t REG_SZ /v GigaLite /d 0 /f >nul 2>&1

:: Disable - Allow the computer to turn off this device to save power  *Does not apear to work
reg add %%A /t REG_DWORD /v PnPCapabilities /d 118 /f >nul 2>&1

:: Disable - Logging of Adapter State
reg add %%A /t REG_SZ /v LogDisconnectEvent /d 0 /f >nul 2>&1
reg add %%A /t REG_SZ /v LogLinkStateEvent /d 16 /f >nul 2>&1
)

:: Stop logging when the network cable is disconnected
reg add "HKLM\SYSTEM\CurrentControlSet\services\Tcpip\Parameters" /v DisableMediaSenseEventLog /t REG_DWORD /d 1 /f >nul 2>&1



:# USB Devices
echo 3/4 - USB Devices
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB" /s /f DeviceSelectiveSuspended > "%tmp%\SW\usb.txt"
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB" /s /f EnableSelectiveSuspend >> "%tmp%\SW\usb.txt"
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB" /s /f IdleInWorkingState >> "%tmp%\SW\usb.txt"
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB" /s /f SelectiveSuspendEnabled >> "%tmp%\SW\usb.txt"
for /f "tokens=*" %%i in ('type "%tmp%\SW\usb.txt" ^| findstr "HKEY_LOCAL_MACHINE"') do (
 reg add "%%i" /v DeviceSelectiveSuspended /t REG_DWORD /d 0 /f >nul 2>&1
 reg add "%%i" /v EnableSelectiveSuspend /t REG_DWORD /d 0 /f >nul 2>&1
 reg add "%%i" /v IdleInWorkingState /t REG_DWORD /d 0 /f >nul 2>&1
 reg add "%%i" /v SelectiveSuspendEnabled /t REG_DWORD /d 0 /f >nul 2>&1
)


:# NICs - Allow the computer to turn off this device to save power  ** Could not make this work in batch
echo 4/4 - Allow the computer to turn off this device to save power
setlocal
set "filePath=%tmp%\SW\power.ps1"
echo $adapters = Get-WmiObject Win32_NetworkAdapter ^| Where-Object { $_.NetEnabled -eq $true } > "%filePath%"
echo foreach ($adapter in $adapters) { >> "%filePath%"
echo     $pnpInstanceId = $adapter.PNPDeviceID >> "%filePath%"
echo     $powerMgtObj = Get-WmiObject -Namespace root\wmi -Class MSPower_DeviceEnable ^| Where-Object { $_.InstanceName -like "*$pnpInstanceId*" } 2^> $null >> "%filePath%"
echo     if ($powerMgtObj) { >> "%filePath%"
echo         $powerMgtObj.Enable = $False >> "%filePath%"
echo         $powerMgtObj.Put() ^> ^$null 2^>^&1 >> "%filePath%"
echo     } >> "%filePath%"
echo } >> "%filePath%"
PowerShell -ExecutionPolicy Bypass -File "%TMP%\SW\power.ps1"
endlocal



echo.
echo Finished
echo.
pause
