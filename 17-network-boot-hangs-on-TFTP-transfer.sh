#7 – Network Boot Hangs on TFTP Transfer
Issue:
When PXE booting, a node hangs indefinitely while trying to download its kernel or initrd via TFTP. Sometimes you see “TFTP open timeout,” or the screen stalls after Trying to load pxelinux.0....

🧠 Summary
This issue typically arises when:

The TFTP server isn’t running or bound to the right interface

Firewall rules block UDP port 69 (TFTP)

PXE boot files are missing or wrongly placed

The node has mismatched architecture or MAC config

This guide walks you through diagnosing and fixing it end-to-end.

🧰 Lab Environment Context
Component	Value
PXE Master	192.168.200.25
Node MAC	52:54:00:aa:bb:cc
TFTP Server	/var/lib/tftpboot/
PXE Binary	pxelinux.0, vmlinuz, initrd.img
OS	Rocky Linux 9 PXE Head Node

🧪 Step 1: Verify TFTP Server is Running
bash
Copy
Edit
systemctl status tftp
Or if you're using xinetd:

bash
Copy
Edit
grep tftp /etc/xinetd.d/tftp
Expected result:

bash
Copy
Edit
server_args = -s /var/lib/tftpboot
If it’s not running:

bash
Copy
Edit
systemctl enable --now tftp.socket
Or:

bash
Copy
Edit
systemctl restart xinetd
🔎 Step 2: Check TFTP Port Accessibility
Use ss to verify port 69:

bash
Copy
Edit
ss -lun | grep 69
If blank, restart the TFTP service.

Also test locally:

bash
Copy
Edit
tftp localhost
tftp> get pxelinux.0
🔥 Step 3: Open Firewall Port
Ensure Firewalld allows TFTP:

bash
Copy
Edit
firewall-cmd --add-service=tftp --permanent
firewall-cmd --reload
For explicit rules:

bash
Copy
Edit
firewall-cmd --add-port=69/udp --permanent
firewall-cmd --reload
Verify:

bash
Copy
Edit
firewall-cmd --list-all
📁 Step 4: Validate PXE Boot Files
Ensure required files are in /var/lib/tftpboot/:

bash
Copy
Edit
ls -lh /var/lib/tftpboot/
You should see:

txt
Copy
Edit
-rw-r--r--  pxelinux.0
-rw-r--r--  vmlinuz
-rw-r--r--  initrd.img
If missing, copy them from your container build:

bash
Copy
Edit
cp /var/lib/warewulf/containers/rockylinux-9-lab/boot/* /var/lib/tftpboot/
🧼 Step 5: Reset Permissions
bash
Copy
Edit
chown -R nobody:nobody /var/lib/tftpboot/
chmod -R 755 /var/lib/tftpboot/
restorecon -Rv /var/lib/tftpboot/
🧬 Step 6: Confirm Node Is Listed in wwctl
bash
Copy
Edit
wwctl node list
Check for correct MAC and container. To update:

bash
Copy
Edit
wwctl node set rocky01 --netdev eth0 --hwaddr 52:54:00:aa:bb:cc
wwctl node set rocky01 --ipaddr 192.168.200.51
wwctl node set rocky01 --container rockylinux-9-lab
wwctl configure --all
🧪 Step 7: Test PXE Boot Again
Power cycle the node:

bash
Copy
Edit
wwctl power cycle rocky01
Monitor logs:

bash
Copy
Edit
journalctl -u tftp -f
You should see lines like:

text
Copy
Edit
RRQ from 192.168.200.51 filename pxelinux.0
If the file successfully transfers, the hang is resolved.

🧠 Bonus: Install and Use tftpd-hpa (Optional Replacement)
bash
Copy
Edit
yum install tftp-server
systemctl enable --now tftp
Set config in /etc/xinetd.d/tftp:

ini
Copy
Edit
service tftp
{
    socket_type     = dgram
    protocol        = udp
    wait            = yes
    user            = root
    server          = /usr/sbin/in.tftpd
    server_args     = -s /var/lib/tftpboot
    disable         = no
}
Then:

bash
Copy
Edit
systemctl restart xinetd
✅ Final Checklist
Task	Status
TFTP service running	✅
Firewall port open	✅
Boot files available	✅
Permissions corrected	✅
Node assigned correctly	✅


# Extra 


# 🗂️ Ticket #7 – NFS Write Errors on Mounted Home Directory

## 🧠 Problem Summary

You're managing a PXE-based lab where all nodes mount `/home` from a central PXE server using NFS (Network File System).  
Users start reporting this frustrating error:

```bash
Permission denied: cannot write to /home/<username>
You confirmed the /home directory exists and is mounted. But still, no one can write.

This guide will walk you step-by-step through diagnosing and resolving NFS write issues caused by root squashing and UID/GID mismatches.

🛠️ Root Cause
By default, NFS tries to protect the server from client root users by converting their UID to a limited nobody user. This is called root squashing.

So even if your user is root on a PXE-booted node, they may not have write access to the /home directory on the server — unless you configure the NFS server to trust root on specific clients.

✅ Step-by-Step Fix
🔍 Step 1: Verify Mount is Working
Run on a PXE-booted node:

bash
Always show details

Copy
mount | grep /home
Output should look like:

bash
Always show details

Copy
192.168.200.25:/home on /home type nfs ...
If not mounted:

bash
Always show details

Copy
mount -t nfs 192.168.200.25:/home /home
🧪 Step 2: Check Permissions and UID/GID
Run:

bash
Always show details

Copy
ls -l /home
Check if user folders exist and if ls -n shows numeric UID/GID mismatches:

bash
Always show details

Copy
ls -ln /home
If UID/GID on the server (e.g., 1001) doesn’t match the one on the client (e.g., 1003), users will be denied access.

🔧 Step 3: Update /etc/exports on the NFS Server
Edit the NFS export config:

bash
Always show details

Copy
sudo nano /etc/exports
Change:

bash
Always show details

Copy
/home 192.168.200.0/24(rw,sync,no_subtree_check)
To:

bash
Always show details

Copy
/home 192.168.200.0/24(rw,sync,no_root_squash,no_subtree_check)
Then re-export:

bash
Always show details

Copy
exportfs -ra
Verify:

bash
Always show details

Copy
exportfs -v
🔄 Step 4: Restart NFS Services
bash
Always show details

Copy
systemctl restart nfs-server
🚀 Step 5: Ensure UID/GID Match
Compare /etc/passwd and /etc/group on server and client.

Example (server):

bash
Always show details

Copy
id student
# uid=1001(student) gid=1001(student)
Client must match:

bash
Always show details

Copy
useradd -u 1001 -g 1001 student
🔁 Step 6: Reboot and Test
On the node:

bash
Always show details

Copy
reboot
Login again and try writing:

bash
Always show details

Copy
touch /home/student/testfile
✅ If the file is created, the issue is resolved!

💡 Bonus Tips
Use no_root_squash only in trusted lab environments.

For production, consider using maproot with safer options.

To avoid manual UID/GID mismatches, configure LDAP or NIS authentication across all nodes.

✅ Summary Checklist
Task	Done?
Export updated	✅
UID/GID match verified	✅
no_root_squash enabled	✅
Mount point checked	✅
Write test passed	✅


## NFS preflight validation script

#!/bin/bash

Check NFS /home write permissions from client
FILE="/home/testfile.$(date +%s)"

echo "[+] Checking NFS mount status..."
mount | grep '/home' || { echo "[-] /home not mounted"; exit 1; }

echo "[+] Trying to create file: $FILE"
touch "$FILE" && echo "[✓] Write successful" || echo "[-] Write failed"

echo "[+] Cleaning up test file"
rm -f "$FILE"
