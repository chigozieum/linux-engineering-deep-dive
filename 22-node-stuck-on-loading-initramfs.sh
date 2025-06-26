# 🐢 Ticket #11 – Node Stuck on “Loading initramfs...”

## 🧠 Problem Summary

During PXE boot, the screen shows:

Loading vmlinuz...
Loading initramfs...

yaml
Always show details

Copy

And then hangs indefinitely.

---

## 🔍 Root Cause

This issue occurs *before* the Linux kernel executes. It's almost always caused by:

- A corrupted or too-large `initramfs` file
- Network latency or broken TFTP connection
- UEFI/BIOS PXE boot mismatch (Legacy vs UEFI)
- Incompatible initrd compression method

---

## ✅ Step-by-Step Resolution

### 1️⃣ Check File Size and Existence

```bash
ls -lh /var/lib/warewulf/images/<container_name>/vmlinuz*
ls -lh /var/lib/warewulf/images/<container_name>/initramfs*
Make sure both files exist and are not zero-byte files.

2️⃣ Rebuild the Container
bash
Always show details

Copy
wwctl container build <container_name>
This regenerates the squashfs, vmlinuz, and initramfs.

3️⃣ Check PXE Profile Assignment
bash
Always show details

Copy
wwctl node list
wwctl profile list
wwctl profile show default
Ensure each node has the correct container and overlay assigned.

4️⃣ Ensure BIOS Settings Match
If your system is set to UEFI, you need a .efi bootloader.

If it's Legacy, ensure undionly.kpxe is used.

Switch BIOS to match the iPXE boot method.

5️⃣ Validate TFTP Transfer (Debug Mode)
Enable verbose iPXE logs to catch issues:

In your DHCP pxelinux.cfg/default or boot script, add:

ini
Always show details

Copy
console=tty0 console=ttyS0,115200 debug initcall_debug loglevel=7
6️⃣ Use Journalctl After Boot
If the node eventually boots and you're debugging postmortem:

bash
Always show details

Copy
journalctl -b | grep initramfs
🧪 Optional Diagnostic Script
bash
Always show details

Copy
#!/bin/bash
# validate_initramfs.sh

CONTAINER="$1"

echo "🔍 Checking initramfs and vmlinuz for: $CONTAINER"
ls -lh /var/lib/warewulf/images/$CONTAINER/

echo "📦 Container file size sanity:"
find /var/lib/warewulf/images/$CONTAINER -type f -exec du -h {} +

echo "🧪 Rebuilding container..."
wwctl container build $CONTAINER
✅ Final Checklist
Task	Status
Checked initramfs and kernel file integrity	✅
Container rebuilt	✅
BIOS/UEFI settings matched PXE boot method	✅
PXE profile and container correctly assigned	✅
Node successfully boots past initramfs stage	✅

💡 Pro Tip: PXE hangs before kernel execution = initramfs, iPXE, or BIOS mismatch issue.
"""

Write Markdown
with open(os.path.join(base_dir, doc_filename), "w") as f:
f.write(markdown_content)

Write script
script_path = os.path.join(script_dir, "validate_initramfs.sh")
with open(script_path, "w") as f:
f.write("""#!/bin/bash
CONTAINER="$1"

echo "🔍 Checking initramfs and vmlinuz for: $CONTAINER"
ls -lh /var/lib/warewulf/images/$CONTAINER/

echo "📦 Container file size sanity:"
find /var/lib/warewulf/images/$CONTAINER -type f -exec du -h {} +

echo "🧪 Rebuilding container..."
wwctl container build $CONTAINER


# Full Documentation


#11 – Node Stuck on “Loading initramfs...”
🧠 Problem Summary
When booting via PXE, the screen shows:

nginx
Copy
Edit
Loading vmlinuz...
Loading initramfs...
…and then the system freezes or hangs indefinitely. No further boot progress is made.

🔍 Root Cause
This issue happens before the Linux kernel fully executes. It’s almost always due to:

Corrupted or missing initramfs

TFTP timeout or interrupted transfer

BIOS vs UEFI mismatch

File too large for firmware’s TFTP buffer

Incorrect PXE boot configuration (wrong pxelinux.cfg)

🛠 Step-by-Step Beginner-Friendly Resolution
✅ Step 1: Check File Size and Existence
SSH into the PXE server:

bash
Copy
Edit
ls -lh /var/lib/warewulf/images/<container_name>/initramfs*
ls -lh /var/lib/warewulf/images/<container_name>/vmlinuz*
Ensure both files exist and are not zero-byte or overly large (>100MB can be an issue for some BIOS).

✅ Step 2: Rebuild the Container
Run:

bash
Copy
Edit
wwctl container build <container_name>
This will regenerate initramfs, vmlinuz, and the squashfs overlay for that container.

✅ Step 3: Confirm Container is Assigned
Check that your node is using the correct container:

bash
Copy
Edit
wwctl node list
Then:

bash
Copy
Edit
wwctl node show <node_name>
Look under the Container: field.

✅ Step 4: Confirm BIOS Matches Boot Method
Enter the node's BIOS/UEFI and check:

If UEFI: You must use .efi bootloader (e.g. ipxe.efi)

If Legacy: You must use undionly.kpxe

Mismatches between PXE firmware and bootloader format can cause initramfs to fail silently.

✅ Step 5: Enable PXE Debugging Output
If you want more output during PXE boot:

Edit the pxelinux.cfg/default or profile boot config.

Add:

ini
Copy
Edit
console=tty0 console=ttyS0,115200 debug initcall_debug loglevel=7
This will help trace where it’s failing.

✅ Step 6: Inspect Logs After Boot (if possible)
If the node eventually boots, log in and check:

bash
Copy
Edit
journalctl -b | grep initramfs
Look for anything unusual in mounting or loading.

🧪 Diagnostic Script: Validate initramfs and Kernel
bash
Copy
Edit
#!/bin/bash
# validate_initramfs.sh

CONTAINER="$1"

echo "🔍 Checking initramfs and vmlinuz for: $CONTAINER"
ls -lh /var/lib/warewulf/images/$CONTAINER/

echo "📦 Container file size sanity:"
find /var/lib/warewulf/images/$CONTAINER -type f -exec du -h {} +

echo "🧪 Rebuilding container..."
wwctl container build $CONTAINER
Make executable:

bash
Copy
Edit
chmod +x validate_initramfs.sh
Run it like:

bash
Copy
Edit
./validate_initramfs.sh default
✅ Final Checklist
Item	Status
initramfs and vmlinuz files present	✅
Container rebuilt	✅
Boot method (UEFI vs Legacy) confirmed and matched	✅
Node container correctly assigned	✅
Node boots past “Loading initramfs...”	✅

💡 Pro Tip: PXE hangs at initramfs = low-level PXE or firmware issue, not Linux itself. Fixes often involve BIOS settings, bootloader type, or container rebuilds.


