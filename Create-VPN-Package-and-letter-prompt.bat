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

cls
echo ===================================================
echo            VPN EMAIL INSTRUCTIONS BUILDER           
echo ===================================================
echo.

:: 1. Use the connection name from Part 1 above, prompt only for the web link
set /p "DownloadUrl=Enter your Dropbox Download Link URL: "
echo.

:: 2. Set the output file name
set "OutputFile=!User!-!VpnName!-Email-Template.txt"

:: 3. Generate the Email Template text file line by line
echo Subject: Setup Instructions for your !VpnName! Connection> "!OutputFile!"
echo.>> "!OutputFile!"
echo Hello,>> "!OutputFile!"
echo.>> "!OutputFile!"
echo To access the !VpnName! securely from your remote location, we have automated the configuration process. Please follow these step-by-step instructions to set up the connection on your Windows 11 computer.>> "!OutputFile!"
echo.>> "!OutputFile!"
echo ### 📦 Step 1: Download the Zip File from the Server Link>> "!OutputFile!"
echo 1. Click the following secure download link to retrieve your connection file: !DownloadUrl!>> "!OutputFile!"
echo 2. Save the file (deploy-!User!-!VpnName!-vpn.zip) to a location where you can easily find it on your computer, such as your Desktop, Downloads, or Documents folder.>> "!OutputFile!"
echo 3. Right-click the saved zipped folder, select "Extract All...", and then click the "Extract" confirmation button.>> "!OutputFile!"
echo 4. A new, uncompressed folder window will open automatically containing a single installation script file named deploy-!User!-!VpnName!-vpn.bat.>> "!OutputFile!"
echo.>> "!OutputFile!"
echo ### 🚀 Step 2: Install the VPN Configuration>> "!OutputFile!"
echo 1. Right-click the deploy-!User!-!VpnName!-vpn.bat file and choose "Run as administrator" from the context menu.>> "!OutputFile!"
echo 2. If a blue Windows warning screen (SmartScreen) appears saying "Windows protected your PC", click the "More info" text link, then click the "Run anyway" button.>> "!OutputFile!"
echo 3. If a User Account Control prompt pops up asking if you want to allow this app to make changes to your device, click "Yes".>> "!OutputFile!"
echo 4. A black command window will open and complete the background security setup automatically. When you see the final verification message stating "VPN Setup Complete!", press any key on your keyboard to close the window.>> "!OutputFile!"
echo.>> "!OutputFile!"
echo ⚠️ CRITICAL REQUIRED ACTION:>> "!OutputFile!"
echo You must restart your computer immediately after running the file. Your new connection profiles and security changes cannot bind successfully or lock into place until after a complete system reboot.>> "!OutputFile!"
echo.>> "!OutputFile!"
echo ### 📶 Step 3: How to Connect and Disconnect>> "!OutputFile!"
echo Once your computer finishes restarting and loads back up, you will see two new customized shortcut icons placed directly onto your Desktop workspace:>> "!OutputFile!"
echo.>> "!OutputFile!"
echo * To Connect: Double-click the "!VpnName! Connect" shortcut icon (indicated by a blue network connector symbol). A brief text prompt window will pop open stating "Connecting to !VpnName!...", verify your secure password profile, and automatically close itself after exactly 3 seconds.>> "!OutputFile!"
echo * To Disconnect: Double-click the "!VpnName! Disconnect" shortcut icon (indicated by a gray disconnected symbol). A window will instantly pop open confirming your request stating "Disconnecting from !VpnName!...", terminate the secure remote line cleanly, and automatically close itself in 3 seconds.>> "!OutputFile!"
echo.>> "!OutputFile!"
echo ### 🔍 Step 4: Manual Connection Verification>> "!OutputFile!"
echo If you ever miss the quick 3-second visual status alert boxes and want to confirm you are actively connected to your workspace, navigate to Settings ^> Network ^& internet ^> VPN on your computer. Your active office profile will display an explicit "Connected" status tag directly next to its name string.>> "!OutputFile!"
echo.>> "!OutputFile!"
echo Please contact me immediately if you encounter any unexpected network authentication errors or blockages during your deployment workflow.>> "!OutputFile!"
echo.>> "!OutputFile!"
echo Thanks,>> "!OutputFile!"
echo Marty WD9GYM>> "!OutputFile!"

echo ===================================================
echo  SUCCESS: "!OutputFile!" generated cleanly!     
echo ===================================================
pause
exit
