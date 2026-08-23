@echo off
setlocal enabledelayedexpansion
cls
echo ===================================================
echo            VPN EMAIL INSTRUCTIONS BUILDER           
echo ===================================================
echo.

:: 1. Prompt Marty for the connection name and the web link only
set /p "VpnName=Enter VPN Connection Name (e.g., OfficeVPN): "
set /p "DownloadUrl=Enter your Dropbox Download Link URL: "
echo.

:: 2. Set the output file name
set "OutputFile=Email_Template.txt"

:: 3. Generate the Email Template text file line by line
echo Subject: Setup Instructions for your !VpnName! Connection> "!OutputFile!"
echo.>> "!OutputFile!"
echo Hello,>> "!OutputFile!"
echo.>> "!OutputFile!"
echo To access the !VpnName! securely from your remote location, we have automated the configuration process. Please follow these step-by-step instructions to set up the connection on your Windows 11 computer.>> "!OutputFile!"
echo.>> "!OutputFile!"
echo ### 📦 Step 1: Download the Zip File from the Server Link>> "!OutputFile!"
echo 1. Click the following secure download link to retrieve your connection file: !DownloadUrl!>> "!OutputFile!"
echo 2. Save the file (deploy-!VpnName!.zip) to a location where you can easily find it on your computer, such as your Desktop, Downloads, or Documents folder.>> "!OutputFile!"
echo 3. Right-click the saved zipped folder, select "Extract All...", and then click the "Extract" confirmation button.>> "!OutputFile!"
echo 4. A new, uncompressed folder window will open automatically containing a single installation script file named deploy-!VpnName!.bat.>> "!OutputFile!"
echo.>> "!OutputFile!"
echo ### 🚀 Step 2: Install the VPN Configuration>> "!OutputFile!"
echo 1. Right-click the deploy-!VpnName!.bat file and choose "Run as administrator" from the context menu.>> "!OutputFile!"
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
