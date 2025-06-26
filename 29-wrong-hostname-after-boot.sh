# 🖥️ Ticket #18 – Wrong Hostname Set After Boot

## 🧠 Problem Summary

After provisioning multiple PXE-booted nodes using Warewulf, it was observed that **every single node booted with the same hostname**: `rocky9`.

Symptoms:
- Running `hostnamectl` on any node returned `rocky9`.
- Nodes appeared identical in network discovery tools (mDNS/Avahi, etc.)
- Cluster-wide automation tools (like Ansible) failed due to duplicate names.

---

## 🔍 Root Cause

- The container used for provisioning (Rocky Linux 9) had a static `/etc/hostname` file with `rocky9`.
- Warewulf overlays were not configured to override the default hostname dynamically.
- PXE nodes booted using the same image and overlay, hence inherited the same hostname.

---

## 🛠️ Solution: Dynamically Inject Hostname Based on Node Name

We solved this by modifying the **default profile template overlay** to set the hostname dynamically using the node name (`{{ .Name }}` variable).

---

### ✅ Step 1: Locate or Create a Hostname Script in Overlay

Navigate to the default overlay:

```bash
cd /var/lib/warewulf/overlays/default
Create a dynamic hostname script:

bash
Always show details

Copy
sudo tee ./etc/warewulf/hostname <<EOF
#!/bin/sh
echo "{{ .Name }}" > /etc/hostname
hostnamectl set-hostname "{{ .Name }}"
EOF
Set permissions:

bash
Always show details

Copy
sudo chmod +x ./etc/warewulf/hostname
✅ Step 2: Add the Hostname Script to Startup
Ensure this gets executed during the boot process. We do this by placing it in a systemd service unit.

Create a unit file in the overlay:

bash
Always show details

Copy
sudo tee ./etc/systemd/system/warewulf-hostname.service <<EOF
[Unit]
Description=Set dynamic hostname from Warewulf
After=network.target

[Service]
Type=oneshot
ExecStart=/etc/warewulf/hostname
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
Enable it in the overlay:

bash
Always show details

Copy
sudo ln -s /etc/systemd/system/warewulf-hostname.service ./etc/systemd/system/multi-user.target.wants/warewulf-hostname.service
Create the target dir if needed:

bash
Always show details

Copy
sudo mkdir -p ./etc/systemd/system/multi-user.target.wants
✅ Step 3: Rebuild the Overlay
Apply the new template:

bash
Always show details

Copy
sudo wwctl overlay build --overlay default
Or for all overlays:

bash
Always show details

Copy
sudo wwctl overlay build --all
🧪 Script: dynamic_hostname_injection.sh
bash
Always show details

Copy
#!/bin/bash

echo "📁 Creating hostname script..."
mkdir -p /var/lib/warewulf/overlays/default/etc/warewulf
cat <<EOF > /var/lib/warewulf/overlays/default/etc/warewulf/hostname
#!/bin/sh
echo "{{ .Name }}" > /etc/hostname
hostnamectl set-hostname "{{ .Name }}"
EOF
chmod +x /var/lib/warewulf/overlays/default/etc/warewulf/hostname

echo "🛠️ Creating systemd service unit..."
mkdir -p /var/lib/warewulf/overlays/default/etc/systemd/system/multi-user.target.wants
cat <<EOF > /var/lib/warewulf/overlays/default/etc/systemd/system/warewulf-hostname.service
[Unit]
Description=Set dynamic hostname from Warewulf
After=network.target

[Service]
Type=oneshot
ExecStart=/etc/warewulf/hostname
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

ln -sf /etc/systemd/system/warewulf-hostname.service \\
  /var/lib/warewulf/overlays/default/etc/systemd/system/multi-user.target.wants/warewulf-hostname.service

echo "🔄 Rebuilding overlay..."
wwctl overlay build --overlay default

echo "✅ Done. Dynamic hostname will be set on next boot."
✅ Step 4: Verify
After boot, run:

bash
Always show details

Copy
hostnamectl
Expected output:

yaml
Always show details

Copy
Static hostname: node01
Icon name: computer-vm
Chassis: vm
Also check:

bash
Always show details

Copy
cat /etc/hostname
✅ Final Checklist
Task	Status
Static /etc/hostname removed from container	✅
Hostname script added to overlay	✅
systemd unit created and linked	✅
Overlay rebuilt and deployed	✅
Hostname verified post-boot	✅

💭 Lessons Learned
Always override static hostnames in containers used for cloning nodes.

Use {{ .Name }} in Warewulf templates for dynamic configuration.

Always verify systemd units via systemctl status and journalctl -xe if custom units don’t execute.