# 🌊 Ticket #15 – Log Flood from `systemd-resolved`

## 🧠 Problem Summary

System administrators observed that `/var/log/messages` and `journalctl` logs were growing rapidly, consuming disk space at a rate of several megabytes per hour. 

Upon inspection, the dominant log entries were from `systemd-resolved`, often showing errors such as:

systemd-resolved[347]: DNSSEC validation failed for question lab.local IN A: failed-auxiliary
systemd-resolved[347]: Using degraded mode due to timeout or failed DNS resolution

yaml
Always show details

Copy

This flood not only filled logs but also caused confusion during real debugging sessions.

---

## 🔍 Root Cause

- `systemd-resolved` was enabled on the Warewulf PXE server and PXE nodes.
- Misconfigured DNS (e.g. missing entries in `dnsmasq`) led to failed queries.
- DNSSEC was enabled by default.
- `systemd-journald` verbosity level was high (default "info"), leading to noise in logs.

---

## 🛠️ Step-by-Step Resolution

This section explains how to disable `systemd-resolved`, apply a static DNS configuration, and suppress unnecessary journald logs.

---

### ✅ Step 1: Disable systemd-resolved

Stop and disable the service:

```bash
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
Mask it to prevent accidental restarts:

bash
Always show details

Copy
sudo systemctl mask systemd-resolved
✅ Step 2: Replace /etc/resolv.conf
Since systemd-resolved creates a symlink here:

bash
Always show details

Copy
ls -l /etc/resolv.conf
Output:

swift
Always show details

Copy
/etc/resolv.conf -> /run/systemd/resolve/stub-resolv.conf
We need to remove it and create a static file:

bash
Always show details

Copy
sudo rm -f /etc/resolv.conf
echo "nameserver 192.168.1.1" | sudo tee /etc/resolv.conf
Optionally add fallback DNS:

bash
Always show details

Copy
echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf
✅ Step 3: Verify DNS Resolution
Test DNS resolution manually:

bash
Always show details

Copy
ping -c 2 lab.local
dig lab.local
Ensure /etc/nsswitch.conf is properly configured:

bash
Always show details

Copy
grep hosts /etc/nsswitch.conf
Expected:

makefile
Always show details

Copy
hosts: files dns
✅ Step 4: Suppress Journald Verbosity (Optional but Helpful)
To reduce log noise:

bash
Always show details

Copy
sudo mkdir -p /etc/systemd/journald.conf.d
Create a config override:

bash
Always show details

Copy
sudo tee /etc/systemd/journald.conf.d/custom.conf <<EOF
[Journal]
MaxLevelStore=warning
EOF
Reload the configuration:

bash
Always show details

Copy
sudo systemctl restart systemd-journald
🧪 Sanity Check Script: disable_resolved.sh
bash
Always show details

Copy
#!/bin/bash
echo "🔧 Disabling systemd-resolved..."
systemctl stop systemd-resolved
systemctl disable systemd-resolved
systemctl mask systemd-resolved

echo "📄 Replacing /etc/resolv.conf..."
rm -f /etc/resolv.conf
echo 'nameserver 192.168.1.1' > /etc/resolv.conf
echo 'nameserver 1.1.1.1' >> /etc/resolv.conf

echo "📉 Lowering journald verbosity..."
mkdir -p /etc/systemd/journald.conf.d
echo -e "[Journal]\\nMaxLevelStore=warning" > /etc/systemd/journald.conf.d/custom.conf
systemctl restart systemd-journald

echo "✅ Done. Test DNS with: ping -c 2 lab.local"
Make executable:

bash
Always show details

Copy
chmod +x disable_resolved.sh
🧪 Post-Implementation Monitoring
Check the log again:

bash
Always show details

Copy
sudo tail -f /var/log/messages
Make sure spam entries from systemd-resolved are gone.

You may also clean old logs:

bash
Always show details

Copy
sudo journalctl --vacuum-size=100M
✅ Final Checklist
Task	Status
Disabled systemd-resolved	✅
Static /etc/resolv.conf configured	✅
DNS resolution verified	✅
Journald verbosity lowered	✅
Log flood eliminated	✅

💭 Lessons Learned
Avoid enabling systemd-resolved unless you need DNSSEC or split-DNS.

For clusters using dnsmasq, static resolv.conf is faster and more predictable.

Always audit journald levels in production or embedded systems.
