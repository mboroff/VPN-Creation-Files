@echo off 
:: Automatically request Administrator privileges 
openfiles >nul 2>&1 
if %errorlevel% neq 0 ( 
    echo Requesting Administrator privileges... 
    powershell -Command "Start-Process -FilePath '%0' -Verb RunAs" 
    exit /b 
) 
 
:: Run the deployment commands 
powershell -NoProfile -ExecutionPolicy Bypass -Command "$VpnName = 'NorthbrookVPN'; $Server = 'NorthbrookVPN.ddns.net'; $Psk = 'vpn'; $User = 'wd9gym'; $Pass = 'Wd9gym95xy'; Add-VpnConnection -Name $VpnName -ServerAddress $Server -TunnelType L2tp -L2tpPsk $Psk -EncryptionLevel Required -AuthenticationMethod MSChapv2 -RememberCredential -AllUserConnection -Force" 
powershell -NoProfile -ExecutionPolicy Bypass -Command "New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\PolicyAgent' -Name 'AssumeUDPEncapsulationContextOnSendRule' -PropertyType DWORD -Value 2 -Force" 
powershell -NoProfile -ExecutionPolicy Bypass -Command "$PbkPath = [System.IO.Path]::Combine($env:ProgramData, 'Microsoft\Network\Connections\Pbk\rasphone.pbk'); if (Test-Path $PbkPath) { (Get-Content $PbkPath) -replace 'PreviewUserPw=1', 'PreviewUserPw=0' -replace 'PreviewDomain=1', 'PreviewDomain=0' -replace 'CacheUserPw=0', 'CacheUserPw=1' | Set-Content $PbkPath }" 
cmdkey /generic:"NorthbrookVPN" /user:"wd9gym" /pass:"Wd9gym95xy" 
:: Create Public Desktop shortcuts 
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=New-Object -ComObject WScript.Shell; $k=$s.CreateShortcut('C:\Users\Public\Desktop\NorthbrookVPN Connect.lnk'); $k.TargetPath='cmd.exe'; $k.Arguments='/c echo Connecting to NorthbrookVPN... [and] rasdial \"NorthbrookVPN\" \"wd9gym\" \"Wd9gym95xy\" [and] timeout /t 3' -replace '\[and\]','&'; $k.WindowStyle=1; $k.IconLocation='shell32.dll,135'; $k.Save()" 
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=New-Object -ComObject WScript.Shell; $k=$s.CreateShortcut('C:\Users\Public\Desktop\NorthbrookVPN Disconnect.lnk'); $k.TargetPath='cmd.exe'; $k.Arguments='/c echo Disconnecting from NorthbrookVPN... [and] rasphone.exe -h \"NorthbrookVPN\" [and] timeout /t 3' -replace '\[and\]','&'; $k.WindowStyle=1; $k.IconLocation='shell32.dll,131'; $k.Save()" 
echo. 
echo VPN Setup Complete Please restart your computer now. 
pause 
