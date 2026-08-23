@echo off
setlocal enabledelayedexpansion
cls
echo ===================================================
echo            VPN DEPLOYMENT BATCH BUILDER           
echo ===================================================
echo.

:: 1. Get the inputs
set /p "VpnName=Enter VPN Connection Name: "
set "Server=!VpnName!.ddns.net"
set /p "User=Enter Call Sign: "
set /p "Pass=Enter Password: "
echo.

:: 2. Create the custom named output batch file
set "OutputFile=deploy-!User!-!VpnName!-vpn.bat"
set "ZipFile=deploy-!User!-!VpnName!-vpn.zip"

:: 3. Build the deploy batch file cleanly
echo @echo off > "!OutputFile!"
echo :: Automatically request Administrator privileges >> "!OutputFile!"
echo openfiles ^>nul 2^>^&1 >> "!OutputFile!"
echo if %%errorlevel%% neq 0 ( >> "!OutputFile!"
echo     echo Requesting Administrator privileges... >> "!OutputFile!"
echo     powershell -Command "Start-Process -FilePath '%%0' -Verb RunAs" >> "!OutputFile!"
echo     exit /b >> "!OutputFile!"
echo ) >> "!OutputFile!"
echo. >> "!OutputFile!"

echo :: Run the deployment commands >> "!OutputFile!"
echo powershell -NoProfile -ExecutionPolicy Bypass -Command "$VpnName = '%VpnName%'; $Server = '%Server%'; $Psk = 'vpn'; $User = '%User%'; $Pass = '%Pass%'; Add-VpnConnection -Name $VpnName -ServerAddress $Server -TunnelType L2tp -L2tpPsk $Psk -EncryptionLevel Required -AuthenticationMethod MSChapv2 -RememberCredential -AllUserConnection -Force" >> "!OutputFile!"
echo powershell -NoProfile -ExecutionPolicy Bypass -Command "New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\PolicyAgent' -Name 'AssumeUDPEncapsulationContextOnSendRule' -PropertyType DWORD -Value 2 -Force" >> "!OutputFile!"
echo powershell -NoProfile -ExecutionPolicy Bypass -Command "$PbkPath = [System.IO.Path]::Combine($env:ProgramData, 'Microsoft\Network\Connections\Pbk\rasphone.pbk'); if (Test-Path $PbkPath) { (Get-Content $PbkPath) -replace 'PreviewUserPw=1', 'PreviewUserPw=0' -replace 'PreviewDomain=1', 'PreviewDomain=0' -replace 'CacheUserPw=0', 'CacheUserPw=1' | Set-Content $PbkPath }" >> "!OutputFile!"
:: NOTE: Windows' RAS/dial-up client looks up saved credentials in Credential
:: Manager under a generic credential whose target name is exactly the VPN
:: connection name (this matches what the GUI creates when you check "Save
:: this user name and password"). Using any other target name (like a made-up
:: prefix) stores a credential that RAS never finds, so it keeps prompting.
echo cmdkey /generic:"%VpnName%" /user:"%User%" /pass:"%Pass%" >> "!OutputFile!"

echo :: Create Shortcuts on the Public Desktop cleanly using clean string structures >> "!OutputFile!"
echo powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=New-Object -ComObject WScript.Shell; $k=$s.CreateShortcut('C:\Users\Public\Desktop\%VpnName% Connect.lnk'); $k.TargetPath='cmd.exe'; $k.Arguments='/c echo Connecting to %VpnName%... [and] rasdial \"%VpnName%\" \"%User%\" \"%Pass%\" [and] timeout /t 3' -replace '\[and\]','&'; $k.WindowStyle=1; $k.IconLocation='shell32.dll,135'; $k.Save()" >> "!OutputFile!"
echo powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=New-Object -ComObject WScript.Shell; $k=$s.CreateShortcut('C:\Users\Public\Desktop\%VpnName% Disconnect.lnk'); $k.TargetPath='cmd.exe'; $k.Arguments='/c echo Disconnecting from %VpnName%... [and] rasphone.exe -h \"%VpnName%\" [and] timeout /t 3' -replace '\[and\]','&'; $k.WindowStyle=1; $k.IconLocation='shell32.dll,131'; $k.Save()" >> "!OutputFile!"

echo echo. >> "!OutputFile!"
echo echo VPN Setup Complete! Please restart your computer now. >> "!OutputFile!"
echo pause >> "!OutputFile!"

:: 4. Compress the deploy batch file into a .zip archive natively
echo Compressing package into !ZipFile!...
if exist "!ZipFile!" del "!ZipFile!"
tar -a -c -f "!ZipFile!" "!OutputFile!"

echo =============================================================================
echo  SUCCESS: "!ZipFile!" created successfully!     
echo  Now upload !ZipFile! to Dropbox then copy the link
echo  to be inserted in the email template file
echo =============================================================================
pause
exit
