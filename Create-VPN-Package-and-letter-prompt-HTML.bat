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
:: Anchor everything (deploy .bat + letters) to the folder this script
:: was launched from, not the current working directory (which can
:: change under UAC).
set "ScriptDir=%~dp0"
set "OutputFile=!ScriptDir!deploy-!User!-!VpnName!-vpn.bat"

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

echo =============================================================================
echo  SUCCESS: "!OutputFile!" created successfully!
echo  Now upload !OutputFile! to Dropbox then copy the link
echo  to be inserted in the email template file
echo =============================================================================
pause

cls
echo ===================================================
echo            VPN EMAIL INSTRUCTIONS BUILDER
echo ===================================================
echo.

:: 5. Prompt for the web link and create three HTML letters:
::    Letter 1: Automated / unattended install (uses the deploy .bat + Dropbox link)
::    Letter 2: macOS manual / attended setup
::    Letter 3: Windows manual / attended setup
:: HTML carries a real hyperlink; .txt does not.
set /p "DownloadUrl=Enter your Dropbox Download Link URL for the .bat file: "
set "EmailFile1=!ScriptDir!!User!-unattended-!VpnName!-Email-Template.html"
set "EmailFile2=!ScriptDir!!User!-MacOS-attended-!VpnName!-Email-Template.html"
set "EmailFile3=!ScriptDir!!User!-Windows-attended-!VpnName!-Email-Template.html"

:: Use PowerShell only to encode the entered values safely for HTML.
:: NOTE: temporarily disable delayed expansion here because the HTML text below
:: contains literal "!" characters (<!doctype ...> and "Complete!"). With
:: delayed expansion ON, cmd treats any two "!" on a line as a variable
:: expansion pair and silently deletes everything between them, which is
:: what caused the "Missing closing ')' in subexpression" PowerShell error.
setlocal disabledelayedexpansion

:: ---------------------------------------------------------------------
:: Letter 1: Automated / Unattended install (unchanged content, new name)
:: ---------------------------------------------------------------------
powershell -NoProfile -ExecutionPolicy Bypass -Command "$vpn=[System.Net.WebUtility]::HtmlEncode($env:VpnName); $user=[System.Net.WebUtility]::HtmlEncode($env:User); $url=[System.Net.WebUtility]::HtmlEncode($env:DownloadUrl); $bat=[System.Net.WebUtility]::HtmlEncode(('deploy-{0}-{1}-vpn.bat' -f $env:User,$env:VpnName)); $html=@('<!doctype html>','<html><head><meta charset=utf-8><title>VPN Setup Instructions</title></head><body style=font-family:Arial,sans-serif;line-height:1.5>',('<p><strong>Subject:</strong> Setup Instructions for your {0} Connection (Automated / Unattended Setup)</p>' -f $vpn),'<p>Hello,</p>',('<p>To access the {0} securely from your remote location, we have automated the configuration process. Please follow these step-by-step instructions to set up the connection on your Windows 11 computer.</p>' -f $vpn),'<h3>Step 1: Download the Setup File from the Server Link</h3>',('<ol><li>Click this secure download link to retrieve your connection file: <a href={0}>Download the VPN setup file</a></li><li>Save the file ({1}) somewhere easy to find, such as Desktop, Downloads, or Documents.</li><li>A copy of the User Guide can be downloaded from <a href=https://github.com/mboroff/nsrc-scheduler-documentation/blob/main/NSRC-Flex-Cadre_Manual.docx>NSRC Flex Cadre Manual</a>.</li></ol>' -f $url,$bat),'<h3>Step 2: Install the VPN Configuration</h3>',('<ol><li>Right-click {0} and choose &quot;Run as administrator&quot;.</li><li>If Windows SmartScreen appears, click &quot;More info&quot; then &quot;Run anyway&quot;.</li><li>If User Account Control asks for permission, click &quot;Yes&quot;.</li><li>When the window reports &quot;VPN Setup Complete!&quot;, press any key to close it.</li></ol>' -f $bat),'<p><strong>Critical required action:</strong> Restart your computer immediately after running the file. The connection profile and security changes cannot take effect until a complete reboot.</p>','<h3>Step 3: How to Connect and Disconnect</h3>',('<p>After restarting, two shortcuts will appear on the desktop:</p><ul><li><strong>To Connect:</strong> Double-click &quot;{0} Connect&quot;.</li><li><strong>To Disconnect:</strong> Double-click &quot;{0} Disconnect&quot;.</li></ul>' -f $vpn,$vpn),'<h3>Step 4: Manual Connection Verification</h3>','<p>To confirm that you are connected, go to Settings &gt; Network &amp; internet &gt; VPN. The office profile will show <strong>Connected</strong>.</p>','<h3>Step 5: Access the Scheduler</h3>','<p>Once connected to the VPN, open your web browser and go to <a href=http://10.0.0.209/>http://10.0.0.209/</a> to access the scheduler.</p>','<p>Please contact me if you encounter any authentication errors or blockages during deployment.</p>','<p>Thanks,<br>Marty WD9GYM</p>','</body></html>'); Set-Content -LiteralPath $env:EmailFile1 -Value $html -Encoding UTF8"

:: ---------------------------------------------------------------------
:: Letter 2: macOS manual / attended setup
:: ---------------------------------------------------------------------
powershell -NoProfile -ExecutionPolicy Bypass -Command "$vpn=[System.Net.WebUtility]::HtmlEncode($env:VpnName); $user=[System.Net.WebUtility]::HtmlEncode($env:User); $pass=[System.Net.WebUtility]::HtmlEncode($env:Pass); $server=[System.Net.WebUtility]::HtmlEncode(('{0}.ddns.net' -f $env:VpnName)); $html=@('<!doctype html>','<html><head><meta charset=utf-8><title>VPN Setup Instructions (macOS)</title></head><body style=font-family:Arial,sans-serif;line-height:1.5>',('<p><strong>Subject:</strong> Setup Instructions for your {0} Connection (macOS Manual Setup)</p>' -f $vpn),'<p>Hello,</p>',('<p>To access the {0} securely from your Mac, please follow these step-by-step instructions to manually create the connection in System Settings.</p>' -f $vpn),'<h3>Step 1: Create the VPN Connection</h3>',('<ol><li>Open <strong>System Settings</strong>.</li><li>Select <strong>VPN</strong>.</li><li>Click on <strong>+</strong>.</li><li>Select <strong>L2TP over IPsec&#8230;</strong>.</li><li>Change <strong>Display Name</strong> to <strong>{0}</strong>.</li><li><strong>Server Address</strong> = <strong>{1}</strong>.</li><li><strong>Account Name</strong> = <strong>{2}</strong>.</li><li><strong>Password</strong> = <strong>{3}</strong>.</li><li><strong>Shared Secret</strong> = <strong>vpn</strong>.</li><li>Click on <strong>Create</strong>.</li></ol>' -f $vpn,$server,$user,$pass),'<h3>Step 2: How to Connect and Disconnect</h3>','<p>To make a connection, click the toggle on.</p><p>To disconnect, toggle the connection off.</p>','<h3>Step 3: Access the Scheduler</h3>','<p>Once connected to the VPN, open your web browser and go to <a href=http://10.0.0.209/>http://10.0.0.209/</a> to access the scheduler.</p>','<p>A copy of the User Guide can be downloaded from <a href=https://github.com/mboroff/nsrc-scheduler-documentation/blob/main/NSRC-Flex-Cadre_Manual.docx>NSRC Flex Cadre Manual</a>.</p>','<p>Please contact me if you encounter any authentication errors or blockages during setup.</p>','<p>Thanks,<br>Marty WD9GYM</p>','</body></html>'); Set-Content -LiteralPath $env:EmailFile2 -Value $html -Encoding UTF8"

:: ---------------------------------------------------------------------
:: Letter 3: Windows manual / attended setup
:: ---------------------------------------------------------------------
powershell -NoProfile -ExecutionPolicy Bypass -Command "$vpn=[System.Net.WebUtility]::HtmlEncode($env:VpnName); $user=[System.Net.WebUtility]::HtmlEncode($env:User); $pass=[System.Net.WebUtility]::HtmlEncode($env:Pass); $server=[System.Net.WebUtility]::HtmlEncode(('{0}.ddns.net' -f $env:VpnName)); $html=@('<!doctype html>','<html><head><meta charset=utf-8><title>VPN Setup Instructions (Windows)</title></head><body style=font-family:Arial,sans-serif;line-height:1.5>',('<p><strong>Subject:</strong> Setup Instructions for your {0} Connection (Windows Manual Setup)</p>' -f $vpn),'<p>Hello,</p>',('<p>To access the {0} securely from your Windows 11 computer, please follow these step-by-step instructions to manually create the connection in Settings.</p>' -f $vpn),'<h3>Step 1: Create the VPN Connection</h3>',('<ol><li>Open <strong>Settings</strong> &gt; <strong>Network &amp; internet</strong> &gt; <strong>VPN</strong>.</li><li>Click <strong>Add VPN</strong>.</li><li><strong>VPN provider</strong> = <strong>Windows (built-in)</strong>.</li><li><strong>Connection name</strong> = <strong>{0}</strong>.</li><li><strong>Server name or address</strong> = <strong>{1}</strong>.</li><li><strong>VPN type</strong> = <strong>L2TP/IPsec with pre-shared key</strong>.</li><li><strong>Pre-shared key</strong> = <strong>vpn</strong>.</li><li><strong>Type of sign-in info</strong> = <strong>User name and password</strong>.</li><li><strong>User name</strong> = <strong>{2}</strong>.</li><li><strong>Password</strong> = <strong>{3}</strong>.</li><li>Click <strong>Save</strong>.</li></ol>' -f $vpn,$server,$user,$pass),'<h3>Step 2: How to Connect and Disconnect</h3>',('<p>To connect, click the network icon in the taskbar, click <strong>VPN</strong>, select <strong>{0}</strong>, then click <strong>Connect</strong>.</p><p>To disconnect, click the network icon, click <strong>VPN</strong>, select <strong>{0}</strong>, then click <strong>Disconnect</strong>.</p>' -f $vpn),'<h3>Step 3: Access the Scheduler</h3>','<p>Once connected to the VPN, open your web browser and go to <a href=http://10.0.0.209/>http://10.0.0.209/</a> to access the scheduler.</p>','<h3>Troubleshooting Note</h3>','<p>If the connection fails behind a router with NAT, this is commonly caused by NAT-T. An administrator may need to set the <strong>AssumeUDPEncapsulationContextOnSendRule</strong> registry value to <strong>2</strong> under <strong>HKLM\SYSTEM\CurrentControlSet\Services\PolicyAgent</strong>, then restart the computer.</p>','<p>A copy of the User Guide can be downloaded from <a href=https://github.com/mboroff/nsrc-scheduler-documentation/blob/main/NSRC-Flex-Cadre_Manual.docx>NSRC Flex Cadre Manual</a>.</p>','<p>Please contact me if you encounter any authentication errors or blockages during setup.</p>','<p>Thanks,<br>Marty WD9GYM</p>','</body></html>'); Set-Content -LiteralPath $env:EmailFile3 -Value $html -Encoding UTF8"

setlocal enabledelayedexpansion

echo ===================================================
echo  SUCCESS: The following letters were generated with clickable links/formatting:
echo    - "!EmailFile1!"  (automated / unattended, Windows)
echo    - "!EmailFile2!"  (manual / attended, macOS)
echo    - "!EmailFile3!"  (manual / attended, Windows)
echo  Open each in a web browser, then copy the message into your email.
echo ===================================================
pause
exit