# Windows 11 L2TP/IPSec VPN Automation Suite

This project lets an administrator hand a remote Windows 11 user a single file to set up
a VPN connection. The end user does nothing but **run one `.bat` file as Administrator** —
no manual network settings, no typed server addresses, no credential prompts to fill in.

The suite has two parts:

1. A builder script the administrator runs once per user, which produces the user's
   personal deployment `.bat` file (zipped for easy transfer).
2. An email-instructions generator that produces a ready-to-send **HTML email template**
   containing the download link and every step the user needs, so the administrator can
   just paste it into an email client and hit send.

---

## 🛠️ How It Works

### Step 1 — Build the user's deployment package
Running **`Create-VPN-Package-and-letter-prompt-HTML.bat`** asks the administrator for:

* **VPN Connection Name** – used as the profile name and to build the server address
  as `[ConnectionName].ddns.net`
* **Call Sign** – the username for the connection
* **Password** – the password for the connection

From these answers the script generates:

* **`deploy-[CallSign]-[ConnectionName]-vpn.bat`** — the single file the end user will run.
* **`deploy-[CallSign]-[ConnectionName]-vpn.zip`** — the same file compressed with the
  built-in Windows `tar` utility, to sidestep email filters that block `.bat` attachments.

### Step 2 — What the user's deployment file does
When the remote user runs `deploy-[CallSign]-[ConnectionName]-vpn.bat` as Administrator,
it silently:

* **Self-elevates** — relaunches itself with admin rights via UAC if it wasn't already
  started as Administrator.
* **Creates the VPN profile** — runs `Add-VpnConnection` with the server address, L2TP
  tunnel type, the pre-shared key (`vpn` by default), and MSChapv2 authentication, set up
  as an all-users connection.
* **Fixes NAT-T for home routers** — sets
  `AssumeUDPEncapsulationContextOnSendRule = 2` under
  `HKLM\SYSTEM\CurrentControlSet\Services\PolicyAgent` so the tunnel works behind typical
  consumer NAT routers.
* **Fixes the post-reboot credential prompt** — edits the system phonebook
  (`rasphone.pbk`) so Windows doesn't ask for a password every time.
* **Stores the credentials** — saves the username/password with `cmdkey` so the
  connection can dial without a prompt.
* **Adds one-click desktop shortcuts** — two shortcuts on the **Public Desktop** (visible
  to any user on the machine):
  * **`[ConnectionName] Connect`** — dials the VPN with `rasdial`.
  * **`[ConnectionName] Disconnect`** — drops the VPN with `rasphone -h`.
* Tells the user to **restart the computer** once setup finishes, since the registry and
  phonebook changes need a reboot to take effect.

### Step 3 — Build the onboarding email
After the `.zip` is uploaded somewhere the user can download it from (e.g. Dropbox), the
same builder script prompts the administrator for that **download link** and generates:

* **`[CallSign]-[ConnectionName]-Email-Template.html`** — a complete onboarding email as
  an HTML file, with a real clickable hyperlink (a plain `.txt` file can't do that).

The generated email walks the end user through:
1. Clicking the link and downloading the `.bat` file.
2. Right-clicking it and choosing **Run as administrator**.
3. Restarting the computer.
4. Using the new **Connect** / **Disconnect** desktop shortcuts.
5. Confirming the connection under **Settings > Network & internet > VPN**.

The administrator opens the generated `.html` file in a browser, copies the rendered
message, and pastes it into their email client along with the download link.

---

## 📋 Administrator Workflow Guide

1. Double-click **`Create-VPN-Package-and-letter-prompt-HTML.bat`**.
2. Enter the VPN Connection Name, Call Sign, and Password when prompted.
3. Find the generated **`deploy-[CallSign]-[ConnectionName]-vpn.zip`** in the same folder
   and upload it to Dropbox (or similar), then copy the sharable download link.
4. When prompted, paste that download link back into the script.
5. The script generates **`[CallSign]-[ConnectionName]-Email-Template.html`**. Open it in
   a browser, copy the message, and paste it into a new email to the end user.
6. The end user downloads the `.bat` file from the link, runs it as Administrator,
   restarts their computer, and uses the desktop shortcuts to connect.

---

## 🔍 Automated Verification & Diagnostic Steps
To confirm a user's deployment applied correctly without dialing the connection,
run these checks in an elevated PowerShell prompt **on the user's machine**:

### A. Registry Configuration Audit
Verifies the NAT-T fix is in place for routers behind a NAT firewall:
```powershell
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\PolicyAgent" -Name "AssumeUDPEncapsulationContextOnSendRule"
```
*Expected value:* `2`

### B. VPN Phonebook Settings Audit
Confirms Windows will save the password and skip the credential prompt. Because the
connection is created as an all-users profile, the phonebook lives under `ProgramData`,
not the current user's `AppData`:
```powershell
$PbkPath = Join-Path $env:ProgramData 'Microsoft\Network\Connections\Pbk\rasphone.pbk'
Select-String -Path $PbkPath -Pattern "PreviewUserPw", "CacheUserPw", "PreviewDomain"
```
*Expected values:* `PreviewUserPw=0`, `CacheUserPw=1`, `PreviewDomain=0`

---

## 🔑 Updating the Pre-Shared Key (PSK)
The pre-shared key is currently hardcoded to `vpn` inside
**`Create-VPN-Package-and-letter-prompt-HTML.bat`**. If your firewall or gateway policy
requires a different PSK, find the line that sets `$Psk = 'vpn'` inside the script and
change the value there, then rebuild any deployment packages you haven't sent out yet.

---

## 🗑️ Rollback & Decommission Command
To remove the VPN profile and both desktop shortcuts from a workstation, run this in an
elevated PowerShell prompt on that machine (replace `YourConnectionName` with the actual
profile name):
```powershell
Remove-VpnConnection -Name "YourConnectionName" -Force
Remove-Item "C:\Users\Public\Desktop\YourConnectionName*.lnk" -Force
```

---

**Project Lead:** Marty WD9GYM
**Target Platform:** Windows 11 Enterprise / Pro
**Protocol Focus:** L2TP over IPSec with Pre-Shared Key Authentication