Ticket #4: resolving Kernel Panic on Boot during PXE provisioning using Warewulf.

💥 Ticket #4 – Kernel Panic on Boot During PXE Provisioning
Issue: After PXE booting a node, the system loads the kernel but crashes with a kernel panic, rendering it unbootable.

🧠 Summary
A kernel panic is a full system crash — the Linux kernel detects a critical error and halts. When it happens during PXE boot, it typically means the problem lies in:

🧊 A broken or incompatible container image

❌ Incorrect kernel boot parameters (e.g., crashkernel=)

🗂️ Mismatched overlays or hardware configurations

In this guide, we’ll break down how to:

Diagnose and understand the kernel panic

Revert to a working container/kernel

Properly update Kernel.Args

Validate changes and reboot safely

🧰 Lab Environment
Component	Value
PXE Server IP	192.168.200.25
Affected Node	rocky04
IP Address	192.168.200.64
Assigned Container	rockylinux-9-lab
Kernel Args	quiet crashkernel=no vga=791 net.naming-scheme=v238

🧪 Step 1: Reproduce the Issue
Reboot the affected node:

bash
Copy
Edit
wwctl power cycle rocky04
Watch boot output via console, IPMI, or serial:

vbnet
Copy
Edit
[    0.123456] Kernel panic - not syncing: Attempted to kill init!
[    0.123457] panic occurred, switching back to text console
📌 Common causes:

Kernel can’t mount root filesystem

initramfs can’t find /sbin/init

Incompatible crashkernel= flag or broken modules

📁 Step 2: Check the Container Assignment
Verify node configuration:

bash
Copy
Edit
wwctl node list rocky04 -o yaml
You should see:

yaml
Copy
Edit
ContainerName: rockylinux-9-lab
Kernel:
  Args: "quiet crashkernel=no vga=791 net.naming-scheme=v238"
Check if other nodes are using the same container and are booting fine.

If yes → your container is likely not the root cause.
If only this node fails → misconfiguration in Kernel Args or overlays likely.

📦 Step 3: Try Reverting Kernel Args
First, test with simplified kernel arguments:

bash
Copy
Edit
wwctl node set rocky04 --kernel-args "quiet net.naming-scheme=v238"
wwctl overlay build
wwctl bootstrap build
Reboot the node again:

bash
Copy
Edit
wwctl power cycle rocky04
If it boots successfully — the issue was likely with the crashkernel= argument.

❌ Understanding the crashkernel= Flag
This flag reserves memory for crash dumps. On low-memory systems or wrong configurations, it causes failure to boot.

Typical risky args:

bash
Copy
Edit
crashkernel=auto
crashkernel=256M
Safe removal:

bash
Copy
Edit
crashkernel=no
But sometimes even no causes problems depending on kernel/initramfs behavior.

🔙 Step 4: Rollback to a Previous Working Container
List containers:

bash
Copy
Edit
wwctl container list
If you see a previous working version, reassign:

bash
Copy
Edit
wwctl node set rocky04 --container rockylinux-9-lab-backup
wwctl bootstrap build
If not available, import a fresh stable version:

bash
Copy
Edit
wwctl container import docker://rockylinux:9 rockylinux-9-lab-stable
wwctl node set rocky04 --container rockylinux-9-lab-stable
wwctl overlay build
wwctl bootstrap build
🧼 Step 5: Regenerate Boot Files
Whenever you update containers or kernel args:

bash
Copy
Edit
wwctl overlay build
wwctl bootstrap build
Also, rebuild the container if it seems corrupted:

bash
Copy
Edit
wwctl container build rockylinux-9-lab
🛠️ Step 6: Monitor Boot Logs and PXE
While rebooting node:

bash
Copy
Edit
journalctl -u wwd -f
Also monitor HTTP request logs:

bash
Copy
Edit
sudo tail -f /var/log/messages | grep warewulf
You should see:

vbnet
Copy
Edit
warewulf: Sending container rockylinux-9-lab.img to 192.168.200.64
warewulf: Sending overlays
No entries = image not sent → container or assignment problem.

🧪 Step 7: Enable Serial or Debug Console for Deeper Logs
Update Kernel Args to include debug mode:

bash
Copy
Edit
wwctl node set rocky04 --kernel-args "quiet debug console=tty0"
wwctl overlay build
wwctl bootstrap build
This will output more verbose errors at boot, making it easier to trace the panic cause.

🔍 Step 8: Inspect Initramfs
Kernel panic might be due to a corrupted or incompatible initramfs.

Mount your container:

bash
Copy
Edit
sudo chroot /var/lib/warewulf/containers/rockylinux-9-lab/rootfs
ls /boot
You should see matching:

vmlinuz-*

initramfs-*

If missing, re-import or build container.

🧱 Best Practices for Kernel Stability
Practice	Why it Helps
Keep backup containers	Allows instant rollback
Avoid experimental kernel args	Especially crashkernel, efi, and kexec
Test on one node first	Prevents cascading failure
Enable serial/debug console	Captures errors early

🧩 Common Kernel Panic Fixes
Symptom	Fix
VFS: Unable to mount root fs	Missing initramfs or corrupt container
Kernel panic: no init found	Overlay failure or deleted /sbin/init
Panic after bootloader	Invalid kernel flag
Random reboots	Hardware issue or invalid memory reservation

✅ Final Checklist
 Kernel.Args cleaned and verified

 Working container reassigned

 Overlays rebuilt

 Boot successful on rocky04

 All logs checked and clean

🧠 What You Learned
Skill	Benefit
Diagnosing kernel panic	Real-world datacenter experience
PXE + Warewulf recovery	High-impact Linux troubleshooting
Kernel Args handling	Boot customization with precision
Overlay + container debugging	Multi-layer config tracking







# Extra 




markdown_content = """# 💥 Ticket #4 – Kernel Panic on Boot During PXE Provisioning

This guide explains how to diagnose and resolve kernel panic issues during PXE boot using Warewulf, including container rollback and kernel argument adjustments.

...

[Truncated for brevity, full content provided above]
"""

# Script to reset kernel arguments for a node
reset_kernel_args_script = """#!/bin/bash
# Reset Kernel.Args for a Warewulf node to prevent kernel panic
NODE=$1

if [ -z "$NODE" ]; then
  echo "Usage: $0 <node-name>"
  exit 1
fi

echo "[+] Resetting Kernel.Args for node: $NODE"
wwctl node set "$NODE" --kernel-args "quiet net.naming-scheme=v238"
wwctl overlay build
wwctl bootstrap build
echo "[✓] Kernel.Args reset and build triggered. You may now reboot the node."