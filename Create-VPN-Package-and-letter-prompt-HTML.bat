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

:: 3. Build the deploy batch file
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
echo cmdkey /generic:"%VpnName%" /user:"%User%" /pass:"%Pass%" >> "!OutputFile!"

echo :: Create Public Desktop shortcuts >> "!OutputFile!"
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

cls
echo ===================================================
echo            VPN EMAIL INSTRUCTIONS BUILDER
echo ===================================================
echo.

:: 5. Prompt for the web link and create an HTML email template.
:: HTML carries a real hyperlink; .txt does not.
set /p "DownloadUrl=Enter your Dropbox Download Link URL: "
set "EmailFile=!User!-!VpnName!-Email-Template.html"

:: Use PowerShell only to encode the entered values safely for HTML.
:: NOTE: temporarily disable delayed expansion here because the HTML text below
:: contains literal "!" characters (<!doctype ...> and "Complete!"). With
:: delayed expansion ON, cmd treats any two "!" on a line as a variable
:: expansion pair and silently deletes everything between them, which is
:: what caused the "Missing closing ')' in subexpression" PowerShell error.
setlocal disabledelayedexpansion
powershell -NoProfile -ExecutionPolicy Bypass -Command "$vpn=[System.Net.WebUtility]::HtmlEncode($env:VpnName); $user=[System.Net.WebUtility]::HtmlEncode($env:User); $url=[System.Net.WebUtility]::HtmlEncode($env:DownloadUrl); $bat=[System.Net.WebUtility]::HtmlEncode(('deploy-{0}-{1}-vpn.bat' -f $env:User,$env:VpnName)); $html=@('<!doctype html>','<html><head><meta charset=utf-8><title>VPN Setup Instructions</title></head><body style=font-family:Arial,sans-serif;line-height:1.5>',('<p><strong>Subject:</strong> Setup Instructions for your {0} Connection</p>' -f $vpn),'<p>Hello,</p>',('<p>To access the {0} securely from your remote location, we have automated the configuration process. Please follow these step-by-step instructions to set up the connection on your Windows 11 computer.</p>' -f $vpn),'<h3>Step 1: Download the Setup File from the Server Link</h3>',('<ol><li>Click this secure download link to retrieve your connection file: <a href={0}>Download the VPN setup file</a></li><li>Save the file ({1}) somewhere easy to find, such as Desktop, Downloads, or Documents.</li></ol>' -f $url,$bat),'<h3>Step 2: Install the VPN Configuration</h3>',('<ol><li>Right-click {0} and choose &quot;Run as administrator&quot;.</li><li>If Windows SmartScreen appears, click &quot;More info&quot; then &quot;Run anyway&quot;.</li><li>If User Account Control asks for permission, click &quot;Yes&quot;.</li><li>When the window reports &quot;VPN Setup Complete!&quot;, press any key to close it.</li></ol>' -f $bat),'<p><strong>Critical required action:</strong> Restart your computer immediately after running the file. The connection profile and security changes cannot take effect until a complete reboot.</p>','<h3>Step 3: How to Connect and Disconnect</h3>',('<p>After restarting, two shortcuts will appear on the desktop:</p><ul><li><strong>To Connect:</strong> Double-click &quot;{0} Connect&quot;.</li><li><strong>To Disconnect:</strong> Double-click &quot;{0} Disconnect&quot;.</li></ul>' -f $vpn,$vpn),'<h3>Step 4: Manual Connection Verification</h3>','<p>To confirm that you are connected, go to Settings &gt; Network &amp; internet &gt; VPN. The office profile will show <strong>Connected</strong>.</p>','<p>Please contact me if you encounter any authentication errors or blockages during deployment.</p>','<p>Thanks,<br>Marty WD9GYM</p>','</body></html>'); Set-Content -LiteralPath $env:EmailFile -Value $html -Encoding UTF8"
setlocal enabledelayedexpansion

echo ===================================================
echo  SUCCESS: "!EmailFile!" generated with a clickable link!
echo  Open it in a web browser on macOS, then copy the message into your email.
echo ===================================================
pause
exit