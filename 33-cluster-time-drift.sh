# 🕒 Ticket #22 – Cluster Time Drift

## 🧠 Problem Summary

In a multi-node PXE-booted cluster, we observed time drift issues. This included:

- Nodes reporting incorrect timestamps in logs
- Authentication errors due to time differences
- Monitoring dashboards (Grafana/Prometheus) showing inconsistent metrics
- Cluster orchestration tools (like Kubernetes, Ansible) flagging drifted nodes

Logs from the affected nodes showed either no NTP service or failed synchronization attempts.

---

## 🔍 Root Cause

- PXE nodes were booted from a container that **did not include any NTP service**
- Some nodes had `ntpd`, others had nothing, and none were syncing properly
- The lack of consistent time sync caused major issues with SSH key expiry, cluster coordination, and job scheduling

---

## 🛠️ Solution: Install and Configure `chrony` on All PXE Containers

We chose `chrony` (over `ntpd`) due to:
- Faster synchronization
- Support for virtualized/cloud hardware
- Modern configuration and security

---

### ✅ Step 1: Add `chrony` to Base Container

```bash
sudo wwctl container shell rocky9
Inside the container shell:

bash
Always show details

Copy
dnf install -y chrony

# Confirm installed
chronyd -v
✅ Step 2: Configure /etc/chrony.conf
Edit or create this file in the container:

bash
Always show details

Copy
cat <<EOF > /etc/chrony.conf
pool time.google.com iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
allow 192.168.0.0/16
logdir /var/log/chrony
EOF
Key options:

makestep forces immediate adjustment for large drift

rtcsync syncs hardware clock

allow lets local subnets query the time

✅ Step 3: Mask Conflicting NTP Services
Still inside the container:

bash
Always show details

Copy
systemctl disable --now ntpd || true
systemctl mask ntpd
Make sure no other time daemons run on the node.

✅ Step 4: Enable Chrony Service
Inside the container:

bash
Always show details

Copy
systemctl enable chronyd
✅ Step 5: Exit and Rebuild Container
Exit the container shell:

bash
Always show details

Copy
exit
sudo wwctl container build rocky9
✅ Step 6: Rebuild Overlays and Reboot
bash
Always show details

Copy
sudo wwctl overlay build --all
Reboot a test node and verify:

bash
Always show details

Copy
ssh root@node01
chronyc tracking
timedatectl
Expected output:

yaml
Always show details

Copy
System clock synchronized: yes
NTP service: active
🧪 Script: fix_time_drift.sh
bash
Always show details

Copy
#!/bin/bash

CONTAINER="rocky9"

echo "🌐 Installing chrony inside container..."
sudo wwctl container shell $CONTAINER <<EOF
dnf install -y chrony
cat <<EOC > /etc/chrony.conf
pool time.google.com iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
allow 192.168.0.0/16
logdir /var/log/chrony
EOC
systemctl disable --now ntpd || true
systemctl mask ntpd
systemctl enable chronyd
EOF

echo "🔨 Rebuilding container..."
sudo wwctl container build $CONTAINER

echo "♻️ Rebuilding overlays..."
sudo wwctl overlay build --all

echo "✅ chrony installed and configured."
Run it:

bash
Always show details

Copy
chmod +x fix_time_drift.sh
./fix_time_drift.sh
✅ Step 7: Cluster-wide Time Sync Validation
Loop across all nodes:

bash
Always show details

Copy
for node in node01 node02 node03; do
  ssh root@$node "chronyc tracking && timedatectl"
done
Compare outputs for drift/offset.

Check syslog:

bash
Always show details

Copy
journalctl -u chronyd
🧠 Extra: Monitor NTP Health in Grafana
Prometheus Node Exporter exposes time metrics:

Enable ntp or chrony metrics exporter

Use time_offset_seconds dashboard in Grafana

Set alerts for offset > 2s

✅ Final Checklist
Task	Status
chrony installed on PXE container	✅
chrony.conf created with good pool	✅
ntpd disabled and masked	✅
container rebuilt and overlays refreshed	✅
nodes synced after boot	✅
Grafana dashboard tracks time health	✅

🧠 Troubleshooting Tips
If drift remains high, verify chronyd is not blocked by firewall

Try chronyc sources -v to debug remote pool reachability

Hardware clock drift on VMs can exaggerate sync issues

Avoid mixing ntpd and chrony across nodes

💭 Lessons Learned
Time drift can silently break everything from authentication to monitoring.

Use chrony instead of ntpd for modern container-based PXE environments.

Always test container time before scaling cluster.

Sync time across all layers: BIOS, OS, container, VM host.