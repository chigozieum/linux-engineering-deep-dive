# 📡 Ticket #9 – TFTP Boot File Not Found

## 🧠 Problem Summary

PXE boot halts with:

PXE-E23: Client received TFTP error from server
PXE-M0F: Exiting PXE ROM

nginx
Always show details

Copy

or

File not found

yaml
Always show details

Copy

---

## 🔎 Root Cause

The PXE client is requesting a boot file like `undionly.kpxe`, but:
- The file is missing
- Permissions are incorrect
- The symlink is broken
- TFTP root path (`tftproot`) is misconfigured

---

## ✅ Solution Overview

1. Validate the `tftproot` directory
2. Ensure correct ownership and permissions
3. Re-create the missing PXE boot file or symbolic link
4. Restart the TFTP service

---

## 🔧 Step-by-Step Resolution

### 📂 Step 1: Locate the tftproot Directory

Typical default location:

```bash
ls -l /var/lib/tftpboot
Expected contents:

ruby
Always show details

Copy
undionly.kpxe -> /usr/share/ipxe/undionly.kpxe
pxelinux.0
bootloader/
🔍 Step 2: Check File or Symlink Existence
bash
Always show details

Copy
ls -l /var/lib/tftpboot/undionly.kpxe
If missing or broken:

bash
Always show details

Copy
file /var/lib/tftpboot/undionly.kpxe
🔗 Step 3: Recreate Symbolic Link
bash
Always show details

Copy
sudo ln -sf /usr/share/ipxe/undionly.kpxe /var/lib/tftpboot/undionly.kpxe
🔐 Step 4: Fix Permissions
bash
Always show details

Copy
sudo chown -R nobody:nobody /var/lib/tftpboot
sudo chmod -R 755 /var/lib/tftpboot
🔁 Step 5: Restart TFTP Service
bash
Always show details

Copy
sudo systemctl restart tftp
Check logs:

bash
Always show details

Copy
journalctl -u tftp -f
🧪 Step 6: Reboot Node and Watch
Use your IPMI console or wwctl power cycle node01 and observe PXE screen.

🧪 Optional Script: TFTP PXE File Validator
Create:

bash
Always show details

Copy
#!/bin/bash
# File: check_tftp_symlink.sh

PXE_FILE="/var/lib/tftpboot/undionly.kpxe"
TARGET="/usr/share/ipxe/undionly.kpxe"

if [[ ! -e "$PXE_FILE" ]]; then
  echo "[-] PXE boot file missing."
  echo "[+] Recreating symlink..."
  sudo ln -sf "$TARGET" "$PXE_FILE"
  echo "[✓] Symlink created."
else
  echo "[✓] PXE boot file exists."
  file "$PXE_FILE"
fi
✅ Final Checklist
Task	Done
TFTP root verified	✅
File exists and linked	✅
Ownership and perms fixed	✅
TFTP service restarted	✅
PXE node boot successful	✅

💡 TFTP is extremely sensitive to permissions. Always double-check.
"""

Write Markdown
with open(os.path.join(base_dir, doc_filename), "w") as f:
f.write(markdown_content)

Write script
script_path = os.path.join(script_dir, "check_tftp_symlink.sh")
with open(script_path, "w") as f:
f.write("""#!/bin/bash
PXE_FILE="/var/lib/tftpboot/undionly.kpxe"
TARGET="/usr/share/ipxe/undionly.kpxe"

if [[ ! -e "$PXE_FILE" ]]; then
echo "[-] PXE boot file missing."
echo "[+] Recreating symlink..."
sudo ln -sf "$TARGET" "$PXE_FILE"
echo "[✓] Symlink created."
else
echo "[✓] PXE boot file exists."
file "$PXE_FILE"
fi




# Step by step process 


#9 – TFTP Boot File Not Found
🧠 Issue Summary
When a PXE boot attempt fails, you may see messages like:

makefile
Copy
Edit
PXE-E23: Client received TFTP error from server
PXE-M0F: Exiting PXE ROM
Or a direct:

arduino
Copy
Edit
File not found
This halts the PXE boot and prevents the node from proceeding with Warewulf provisioning.

🔍 Root Cause
The node uses TFTP to download its bootloader. If the TFTP server cannot find the requested file (undionly.kpxe, pxelinux.0, etc.), the boot fails.

The most common reasons are:

The TFTP root directory (/var/lib/tftpboot) does not contain the expected file.

File permissions are incorrect.

A symbolic link is broken or missing.

TFTP server is running but cannot serve files due to security policies.

🛠 Step-by-Step Beginner-Friendly Fix
📂 Step 1: Locate the TFTP Root
bash
Copy
Edit
ls -l /var/lib/tftpboot
You should see something like:

ruby
Copy
Edit
lrwxrwxrwx 1 root root       27 Jun 23 12:00 undionly.kpxe -> /usr/share/ipxe/undionly.kpxe
-rw-r--r-- 1 root root  264660 Jun 23 11:45 pxelinux.0
drwxr-xr-x 2 root root     4096 Jun 23 12:00 bootloader
If the file is missing or the symlink is broken, the node won't boot.

🔍 Step 2: Check if the File is There
bash
Copy
Edit
file /var/lib/tftpboot/undionly.kpxe
You might see:

bash
Copy
Edit
undionly.kpxe: broken symbolic link to /usr/share/ipxe/undionly.kpxe
🔗 Step 3: Recreate the Symlink
bash
Copy
Edit
sudo ln -sf /usr/share/ipxe/undionly.kpxe /var/lib/tftpboot/undionly.kpxe
🔐 Step 4: Fix Ownership and Permissions
bash
Copy
Edit
sudo chown -R nobody:nobody /var/lib/tftpboot
sudo chmod -R 755 /var/lib/tftpboot
Why? TFTP servers like tftp-hpa run as the nobody user by default. Incorrect ownership blocks access.

🔁 Step 5: Restart the TFTP Server
bash
Copy
Edit
sudo systemctl restart tftp
If your system uses tftp.socket:

bash
Copy
Edit
sudo systemctl restart tftp.socket
🧪 Step 6: Reboot the Node
Reboot your node to see if it boots:

bash
Copy
Edit
wwctl power cycle node01
Watch the PXE screen and confirm that the boot file is now found and loaded.

🧪 Optional: Automated Script to Fix Symlink
You can use this script to validate and repair the PXE file link:

bash
Copy
Edit
#!/bin/bash
# File: check_tftp_symlink.sh

PXE_FILE="/var/lib/tftpboot/undionly.kpxe"
TARGET="/usr/share/ipxe/undionly.kpxe"

if [[ ! -e "$PXE_FILE" ]]; then
  echo "[-] PXE boot file missing."
  echo "[+] Recreating symlink..."
  sudo ln -sf "$TARGET" "$PXE_FILE"
  echo "[✓] Symlink created."
else
  echo "[✓] PXE boot file exists."
  file "$PXE_FILE"
fi
Make it executable:

bash
Copy
Edit
chmod +x check_tftp_symlink.sh
Run it any time a boot file goes missing.

✅ Final Checklist
Task	Completed
TFTP root exists and is correct	✅
PXE boot file present or symlinked	✅
Ownership is nobody:nobody	✅
Permissions are 755	✅
TFTP service restarted	✅
Node successfully boots	✅


