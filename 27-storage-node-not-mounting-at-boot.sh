# 🗃️ Ticket #16 – Storage Node Not Mounting at Boot

## 🧠 Problem Summary

In our Warewulf PXE cluster, `/mnt/data` was mounted from an NFS storage server to each compute node. However, after rebooting the nodes, we observed the following issues:

- `/mnt/data` was missing
- `df -h` did not show the mount point
- Manual `mount -a` worked fine after boot

This pointed to a timing issue where the NFS share was being attempted **before the network was fully online**.

---

## 🔍 Root Cause

- The mount operation was listed in `/etc/fstab`, but the network stack (especially in PXE-booted nodes) was not ready when `mount` commands ran.
- NFS mounts fail silently or are deferred during early boot stages.
- System boot logs (`journalctl`) confirmed:
mount.nfs: Connection timed out

yaml
Always show details

Copy

---

## 🛠️ Solution: Create a Custom `systemd` Mount Unit

The fix involved **creating a custom systemd unit file** for the NFS mount and tying it to the `network-online.target`.

---

### ✅ Step 1: Disable fstab-Based Mount

Remove or comment the entry in `/etc/fstab`:

```bash
sudo sed -i '/mnt\\/data/d' /etc/fstab
Or manually comment:

bash
Always show details

Copy
# 192.168.1.100:/export/data /mnt/data nfs defaults 0 0
✅ Step 2: Create a systemd Mount Unit
Create a new file: /etc/systemd/system/mnt-data.mount

ini
Always show details

Copy
[Unit]
Description=Mount /mnt/data NFS Share
After=network-online.target
Wants=network-online.target

[Mount]
What=192.168.1.100:/export/data
Where=/mnt/data
Type=nfs
Options=defaults

[Install]
WantedBy=multi-user.target
Save and exit.

✅ Step 3: Enable and Start the Mount
bash
Always show details

Copy
sudo mkdir -p /mnt/data
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable mnt-data.mount
sudo systemctl start mnt-data.mount
Check status:

bash
Always show details

Copy
systemctl status mnt-data.mount
🧪 Script: Create and Enable NFS Mount Unit
You can automate this using:

bash
Always show details

Copy
#!/bin/bash

echo "🧰 Creating mount point..."
mkdir -p /mnt/data

echo "📝 Writing systemd unit file..."
cat <<EOF > /etc/systemd/system/mnt-data.mount
[Unit]
Description=Mount /mnt/data NFS Share
After=network-online.target
Wants=network-online.target

[Mount]
What=192.168.1.100:/export/data
Where=/mnt/data
Type=nfs
Options=defaults

[Install]
WantedBy=multi-user.target
EOF

echo "🔄 Reloading systemd..."
systemctl daemon-reexec
systemctl daemon-reload

echo "📌 Enabling and starting mount..."
systemctl enable mnt-data.mount
systemctl start mnt-data.mount

echo "✅ Done."
Save as mount_data.sh and run:

bash
Always show details

Copy
chmod +x mount_data.sh
./mount_data.sh
✅ Validation
Run:

bash
Always show details

Copy
mount | grep mnt
Expected output:

ruby
Always show details

Copy
192.168.1.100:/export/data on /mnt/data type nfs (rw,relatime)
Ensure persistence across reboots:

bash
Always show details

Copy
reboot
# then after login
mount | grep mnt
✅ Final Checklist
Task	Status
fstab entry removed	✅
Custom systemd unit created	✅
Mount tied to network-online.target	✅
Mount verified post-boot	✅
Fully automated script tested	✅

💭 Lessons Learned
NFS mounts during early boot are fragile without a proper After=network-online.target dependency.

systemd mount units offer more flexibility than /etc/fstab in clustered, PXE, or headless environments.

Use journalctl -xe to investigate failed mounts in multi-user.target.
