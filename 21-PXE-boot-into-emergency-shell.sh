💥 Ticket #10 – PXE Node Boots into Emergency Shell
🧠 Problem Summary
After PXE boot and initial initrd phase, the node drops into:

sql
Copy
Edit
You are in emergency mode. After logging in, type 'journalctl -xb' to view system logs...
This indicates something critical failed early in the boot process — typically filesystem mounting or root overlay issues.

🔍 Common Causes
Root container is not correctly mounted (corrupted or missing squashfs)

Overlay is incomplete or malformed

Kernel arguments passed by PXE are invalid or missing root=

Network mounts (e.g., NFS) aren't reachable during init

🛠️ Step-by-Step Resolution
1️⃣ Identify the Node
Boot the node via IPMI or console and confirm it enters emergency mode.

It usually happens after:

PXE loads initrd

Kernel starts

Rootfs mount fails

2️⃣ Log In and Inspect the Error
At the emergency shell prompt:

bash
Copy
Edit
journalctl -xb
You’ll likely see something like:

arduino
Copy
Edit
Cannot find root filesystem. Waiting for device /dev/mapper/root...
Or:

css
Copy
Edit
Failed to mount overlay.
3️⃣ Verify the Container
On the head/PXE server, check:

bash
Copy
Edit
wwctl container list
Ensure the container for that node exists and is healthy. Then:

bash
Copy
Edit
wwctl container verify <container_name>
If broken or missing:

bash
Copy
Edit
wwctl container build <container_name>
4️⃣ Check Overlay Status
Ensure overlays are built and applied:

bash
Copy
Edit
wwctl overlay list
wwctl overlay build -H
wwctl configure --all
Look in:

bash
Copy
Edit
ls -lh /var/lib/warewulf/overlays/<nodename>/
You want to see a valid /etc/fstab, /etc/resolv.conf, and /init structure.

5️⃣ Fix Kernel Boot Args
You may need to adjust /etc/warewulf/profiles/default.ww or node-specific config:

bash
Copy
Edit
wwctl profile list
wwctl profile edit default
Ensure:

ini
Copy
Edit
KernelArgs: quiet crashkernel=auto root=/dev/nfs ip=dhcp rw overlay=yes
Remove custom flags like crashkernel=1G if unsupported.

Then reassign:

bash
Copy
Edit
wwctl configure --all
6️⃣ Reboot the Node
bash
Copy
Edit
wwctl power cycle node01
🧪 Optional Script – PXE Boot Debug Assistant
bash
Copy
Edit
#!/bin/bash
# check_pxe_emergency.sh

NODE=$1
echo "Checking PXE health for $NODE"

echo "🧩 Container status:"
wwctl container list | grep $NODE

echo "🔍 Overlay files:"
ls -l /var/lib/warewulf/overlays/$NODE/etc

echo "⚙️  Kernel args:"
wwctl node show $NODE | grep Args
✅ Final Checklist
Task	Status
Node entered emergency mode	✅
Logs reviewed with journalctl -xb	✅
Container verified and rebuilt	✅
Overlay rebuilt and deployed	✅
Kernel args updated for PXE boot	✅
Node rebooted and boots normally	✅
