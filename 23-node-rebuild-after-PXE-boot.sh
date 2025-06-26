# 🔁 Ticket #12 – Node Reboots Immediately After PXE Boot

## 🧠 Problem Summary

After loading the PXE configuration and downloading the kernel, the node **reboots immediately** before showing any meaningful boot output.

---

## 🔍 Root Causes

- PXE bootloader is incompatible (wrong architecture)
- `initrd` or `vmlinuz` is corrupt or too large
- Incorrect kernel parameters (missing `root=`, `ip=`, or overlay directives)
- UEFI vs Legacy mismatch
- Memory or firmware limitation (old BIOS or BMC)

---

## 🛠 Step-by-Step Resolution

### ✅ Step 1: Confirm PXE File Matches Node Architecture

Run:

```bash
file /var/lib/tftpboot/undionly.kpxe
If the node is UEFI, you should be using something like:

bash
Always show details

Copy
file /var/lib/tftpboot/ipxe.efi
Mismatch here = instant reboot.

✅ Step 2: Test Smaller initramfs (if >100MB)
bash
Always show details

Copy
ls -lh /var/lib/warewulf/images/<container>/initramfs*
If it’s too large, enable gzip compression:

Edit container definition or apply:

bash
Always show details

Copy
wwctl container build <container> --compress gzip
✅ Step 3: Validate Kernel Args
bash
Always show details

Copy
wwctl node show <nodename> | grep Args
Ensure it includes:

ini
Always show details

Copy
root=/dev/nfs ip=dhcp overlay=yes
Reapply config:

bash
Always show details

Copy
wwctl configure --all
✅ Step 4: Enable PXE Boot Debugging
Edit PXE template or DHCP:

nginx
Always show details

Copy
APPEND debug earlyprintk=ttyS0 loglevel=7
This will display output before reboot.

✅ Step 5: Verify Power Profile or Watchdog
If the server has a BMC or watchdog timer, disable it in BIOS.

🧪 Diagnostic Script
bash
Always show details

Copy
#!/bin/bash
# check_pxe_reboot.sh

PXE_FILE="/var/lib/tftpboot/undionly.kpxe"
echo "🧠 PXE bootloader check:"
file "$PXE_FILE"

echo "🧪 Kernel file size check:"
ls -lh /var/lib/warewulf/images/default/initramfs*

echo "⚙️  Kernel arguments:"
wwctl node show node01 | grep Args

echo "📦 Rebuilding container..."
wwctl container build default
✅ Final Checklist
Task	Status
PXE file matches system architecture	✅
initramfs size < 100MB or gzip enabled	✅
Kernel arguments present and correct	✅
PXE shows debug before reboot	✅
Node boots and does not reboot early	✅

💡 Instant reboot = firmware fails to hand control to Linux. Fix = correct PXE arch, kernel args, or compression method.
"""

Save markdown
md_path = "/mnt/data/pxe-lab-docs/" + doc_filename
with open(md_path, "w") as f:
f.write(markdown_doc)

Save script
script = """#!/bin/bash

check_pxe_reboot.sh
PXE_FILE="/var/lib/tftpboot/undionly.kpxe"
echo "🧠 PXE bootloader check:"
file "$PXE_FILE"

echo "🧪 Kernel file size check:"
ls -lh /var/lib/warewulf/images/default/initramfs*

echo "⚙️ Kernel arguments:"
wwctl node show node01 | grep Args

echo "📦 Rebuilding container..."
wwctl container build default