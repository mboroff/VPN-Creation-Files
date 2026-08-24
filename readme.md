# Windows 11 L2TP/IPSec VPN Automation Suite

This project lets an administrator provide a remote Windows 11 user with a single deployment file that sets up an L2TP/IPsec VPN connection with a pre-shared key (PSK).

**Important:** The admin runs **one builder `.bat`** to generate:
- A per-user **deployment `.bat`** (the file the end user runs as Administrator).
- One or more **HTML email templates** containing a real clickable download link.

The end user only downloads the deployment file and runs it.

---

## 🛠️ What the builder script does (`Create-VPN-Package-and-letter-prompt-HTML.bat`)

When you run `Create-VPN-Package-and-letter-prompt-HTML.bat`, it prompts for:

- **VPN Connection Name** → stored in `VpnName`
- **Call Sign** → stored in `User` (used as the VPN username)
- **Password** → stored in `Pass` (used for credentials and for dialing)

### Output #1: Generated deployment batch file
The script creates a file named:

- **`deploy-[CallSign]-[ConnectionName]-vpn.bat`**
  - e.g. `deploy-NG9WM-MySite-vpn.bat`

> Note: In the `.bat` content you pasted, the builder **does not create a `.zip`**. It only generates the `.bat` file and the HTML templates.

---

## ✅ What the generated deployment file does (`deploy-...-vpn.bat`)

When the end user runs `deploy-[CallSign]-[ConnectionName]-vpn.bat` **as Administrator**, it does the following:

### 1) Self-elevates (UAC)
It checks whether it’s running with admin privileges, and if not, it re-launches itself using:
- `powershell Start-Process -Verb RunAs`

### 2) Creates the VPN profile
It runs PowerShell to execute:

- `Add-VpnConnection`
  - **Name**: VPN Connection Name (`$VpnName`)
  - **ServerAddress**: `${VpnName}.ddns.net`
  - **TunnelType**: `L2tp`
  - **PSK**: hardcoded to **`vpn`**
  - **EncryptionLevel**: `Required`
  - **AuthenticationMethod**: `MSChapv2`
  - **RememberCredential**
  - **AllUserConnection**
  - **Force**

### 3) Fixes NAT-T / UDP encapsulation
It sets this DWORD value in the registry:

- Path: `HKLM\SYSTEM\CurrentControlSet\Services\PolicyAgent`
- Name: `AssumeUDPEncapsulationContextOnSendRule`
- Value: `2`

### 4) Fixes the post-reboot credential prompt (phonebook edits)
It edits the system phonebook file:

- `C:\ProgramData\Microsoft\Network\Connections\Pbk\rasphone.pbk`

If it exists, it replaces:
- `PreviewUserPw=1` → `PreviewUserPw=0`
- `PreviewDomain=1` → `PreviewDomain=0`
- `CacheUserPw=0` → `CacheUserPw=1`

### 5) Stores credentials for dialing (`cmdkey`)
It stores the VPN credentials using:

- `cmdkey /generic:"%VpnName%" /user:"%User%" /pass:"%Pass%"`

### 6) Creates desktop shortcuts (Public Desktop)
It creates **two shortcuts** on the **Public Desktop**:

- `C:\Users\Public\Desktop\%VpnName% Connect.lnk`
  - Runs: `rasdial "%VpnName%" "%User%" "%Pass%"`
  - Includes a small delay (`timeout /t 3`)
- `C:\Users\Public\Desktop\%VpnName% Disconnect.lnk`
  - Runs: `rasphone.exe -h "%VpnName%"`
  - Includes a small delay (`timeout /t 3`)

### 7) User notification
It ends with:
- “VPN Setup Complete! Please restart your computer now.”
- then pauses (`pause`)

### Required reboot
The generated deployment file instructs a **restart**, because registry/phonebook changes require it.

---

## 📨 Output #2: HTML email templates

After generating the deployment `.bat`, the builder prompts for:

- **Download URL** (Dropbox “share/download” link) for the deployment `.bat`

Then it generates **three HTML files**:

1. **`[CallSign]-unattended-[ConnectionName]-Email-Template.html`**
   - Automated/unattended instructions for the Windows end user.
2. **`[CallSign]-MacOS-attended-[ConnectionName]-Email-Template.html`**
   - Manual instructions for macOS.
3. **`[CallSign]-Windows-attended-[ConnectionName]-Email-Template.html`**
   - Manual instructions for Windows (System Settings / VPN UI).

### Link behavior
The unattended Windows template includes a hyperlink to the provided download URL and references the deployment filename as:

- `deploy-[CallSign]-[ConnectionName]-vpn.bat`

(That filename pattern is hardcoded into the template generation logic.)

---

## 📋 Administrator workflow

1. Run **`Create-VPN-Package-and-letter-prompt-HTML.bat`**
2. Enter:
   - VPN Connection Name
   - Call Sign
   - Password
3. Find the generated file:
   - `deploy-[CallSign]-[ConnectionName]-vpn.bat`
4. Upload the `.bat` somewhere the user can download it (e.g., Dropbox), and copy the share/download link.
5. Paste that link into the builder when it prompts for the download URL.
6. Open each generated HTML file in a browser, copy the rendered message, and send it to the end user(s).
7. The end user downloads the `.bat` from the link and runs it **as Administrator**, then restarts the computer.

---

## 🔍 Verification / diagnostics (run on the user machine as admin)

### A) NAT-T registry audit
```powershell
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\PolicyAgent" -Name "AssumeUDPEncapsulationContextOnSendRule"
```
Expected:
- `2`

### B) Phonebook edits audit
Phonebook path:
```powershell
$PbkPath = Join-Path $env:ProgramData 'Microsoft\Network\Connections\Pbk\rasphone.pbk'
Select-String -Path $PbkPath -Pattern "PreviewUserPw", "CacheUserPw", "PreviewDomain"
```

Expected values after replacement logic:
- `PreviewUserPw=0`
- `CacheUserPw=1`
- `PreviewDomain=0`

---

## 🔑 Updating the Pre-Shared Key (PSK)

In the generated deployment file logic, the PSK is **hardcoded** to:

- `$Psk = 'vpn'`

If you need a different PSK, update that value in `Create-VPN-Package-and-letter-prompt-HTML.bat` and regenerate the deployment `.bat` for users.

---

## 🗑️ Rollback / decommission

To remove the VPN profile and desktop shortcuts (run elevated PowerShell on the machine):

```powershell
Remove-VpnConnection -Name "YourConnectionName" -Force
Remove-Item "C:\Users\Public\Desktop\YourConnectionName*.lnk" -Force
```

---

## About your “no `.bat` upload” constraint (workarounds)

Since the deployment artifact **is a `.bat`** in your current design, sites that block `.bat` uploads force you to distribute it through a different container/type. Common approaches:

- Upload **some allowed archive type** (if allowed): `.zip`, `.7z`, or even rename-and-serve is sometimes blocked—zip is the usual safest.
- If your UI blocks only *uploads* but not *links*, use a third-party host (Dropbox/Drive) where `.bat` is permitted and share the **download link** (your template builder already supports this).
- If you truly must avoid `.bat` delivery, the code would need to be refactored to generate a different executable/script type (e.g., PowerShell-based launcher), which is a larger change.

If you tell me **what formats are allowed by your Web UI** (e.g., “zip ok, bat not ok”), I can suggest the cleanest compliant distribution method and adjust the README accordingly.  

---

**Project Lead:** Marty WD9GYM  
**Target Platform:** Windows 11 Enterprise / Pro  
**Protocol Focus:** L2TP over IPSec with Pre-Shared Key Authentication