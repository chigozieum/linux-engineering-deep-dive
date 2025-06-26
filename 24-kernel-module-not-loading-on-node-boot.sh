⚙️ Ticket #13 – Kernel Module Not Loading on Node Boot
🧠 Problem Summary
A PXE-booted node fails to load a required kernel module (e.g., ixgbe, vfio, overlay) at boot time. This causes errors like:

vbnet
Copy
Edit
modprobe: FATAL: Module overlay not found in directory /lib/modules/...
Or:

vbnet
Copy
Edit
docker: Error response from daemon: error creating overlay mount...
🔍 Root Causes
The module is missing from the kernel build in the container

Incorrect kernel version mismatch between node and container

modprobe cannot locate the module due to path or version issues

modules.dep not rebuilt after module installation

Module was excluded during image build (--no-kmod or --minimal options)

🛠️ Step-by-Step Resolution (Beginner-Friendly)
✅ Step 1: Identify the Failing Module
On the PXE node:

bash
Copy
Edit
dmesg | grep -i fail
Or:

bash
Copy
Edit
journalctl -b | grep modprobe
Common errors:

modprobe: FATAL: Module not found

overlayfs not supported

✅ Step 2: Confirm Kernel Version
On the node:

bash
Copy
Edit
uname -r
On the PXE server:

bash
Copy
Edit
ls /var/lib/warewulf/images/<container_name>/lib/modules/
Kernel versions must match. If they don’t, the node won't find the right modules.

✅ Step 3: Check for Module Presence in Container
bash
Copy
Edit
find /var/lib/warewulf/images/<container_name>/lib/modules -name overlay.ko*
If missing, rebuild with the correct kernel:

bash
Copy
Edit
wwctl container build <container_name>
✅ Step 4: Install Missing Modules (Advanced)
If module is missing entirely:

bash
Copy
Edit
yum install -y kernel-modules-extra
Then:

bash
Copy
Edit
depmod -a
Then rebuild container:

bash
Copy
Edit
wwctl container build <container_name>
✅ Step 5: Force Load Module on Boot
Edit overlay or profile to include:

bash
Copy
Edit
echo overlay >> /etc/modules-load.d/custom.conf
Then:

bash
Copy
Edit
wwctl overlay build default
wwctl configure --all
🧪 Diagnostic Script
bash
Copy
Edit
#!/bin/bash
# check_kernel_module.sh

NODE="node01"
MODULE="overlay"

echo "🔍 Checking module $MODULE on node $NODE"

echo "🧠 Kernel version on PXE node:"
ssh $NODE uname -r

echo "📦 Module file check:"
ssh $NODE modinfo $MODULE 2>/dev/null || echo "❌ Module not found"

echo "🧪 Loading module manually:"
ssh $NODE sudo modprobe $MODULE || echo "❌ Could not load $MODULE"

echo "🧩 Overlay rebuild if needed:"
wwctl overlay build default
wwctl configure --all
✅ Final Checklist
Task	Status
Confirmed kernel version matches module dir	✅
Verified module exists in /lib/modules	✅
Module included in container build	✅
Overlay rebuilt with boot-time modprobe config	✅
Node loads module successfully	✅

💡 Pro Tip: Every PXE node shares kernel from the container — if the module isn’t there, it won’t load. Always verify versions.

