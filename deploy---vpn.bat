@echo off 
:: Automatically request Administrator privileges 
openfiles >nul 2>&1 
if %errorlevel% neq 0 ( 
    echo Requesting Administrator privileges... 
    powershell -Command "Start-Process -FilePath '%0' -Verb RunAs" 
    exit /b 
) 
 
:: Run the deployment commands 
powershell -NoProfile -ExecutionPolicy Bypass -Command "$VpnName = ''; $Server = '.ddns.net'; $Psk = 'vpn'; $User = ''; $Pass = ''; Add-VpnConnection -Name $VpnName -ServerAddress $Server -TunnelType L2tp -L2tpPsk $Psk -EncryptionLevel Required -AuthenticationMethod MSChapv2 -RememberCredential -AllUserConnection -Force" 
powershell -NoProfile -ExecutionPolicy Bypass -Command "New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\PolicyAgent' -Name 'AssumeUDPEncapsulationContextOnSendRule' -PropertyType DWORD -Value 2 -Force" 
powershell -NoProfile -ExecutionPolicy Bypass -Command "$PbkPath = [System.IO.Path]::Combine($env:ProgramData, 'Microsoft\Network\Connections\Pbk\rasphone.pbk'); if (Test-Path $PbkPath) { (Get-Content $PbkPath) -replace 'PreviewUserPw=1', 'PreviewUserPw=0' -replace 'PreviewDomain=1', 'PreviewDomain=0' -replace 'CacheUserPw=0', 'CacheUserPw=1' | Set-Content $PbkPath }" 
cmdkey /generic:"" /user:"" /pass:"" 
:: Create Public Desktop shortcuts 
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=New-Object -ComObject WScript.Shell; $k=$s.CreateShortcut('C:\Users\Public\Desktop\ Connect.lnk'); $k.TargetPath='cmd.exe'; $k.Arguments='/c echo Connecting to ... [and] rasdial \"\" \"\" \"\" [and] timeout /t 3' -replace '\[and\]','&'; $k.WindowStyle=1; $k.IconLocation='shell32.dll,135'; $k.Save()" 
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=New-Object -ComObject WScript.Shell; $k=$s.CreateShortcut('C:\Users\Public\Desktop\ Disconnect.lnk'); $k.TargetPath='cmd.exe'; $k.Arguments='/c echo Disconnecting from ... [and] rasphone.exe -h \"\" [and] timeout /t 3' -replace '\[and\]','&'; $k.WindowStyle=1; $k.IconLocation='shell32.dll,131'; $k.Save()" 
echo. 
echo VPN Setup Complete Please restart your computer now. 
pause 
