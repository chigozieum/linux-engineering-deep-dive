#6 – Warewulf Daemon Crash After Container Update, following the same detailed 1000+ word format suitable for your lab documentation.

🧨 Ticket #6 – Warewulf Daemon (wwd) Crashes After Container Update
Issue:
After rebuilding a container and triggering overlay build, the wwd service (Warewulf Daemon) crashes. The node boot process halts, and containers fail to serve to PXE clients.

🧠 Summary
You updated or rebuilt a Warewulf container. Immediately after:

The wwd service exited with a stack trace or segmentation fault

journalctl -u wwd showed panics or nil pointer errors

PXE-booted nodes failed to receive overlays or images

curl http://<pxe-ip>:9873/container/... returned 500 or failed

This guide walks through:

Diagnosing a broken warewulf.conf

Applying real fixes, including a known patch from GitHub

Restarting services safely

Preventing recurrence during future rebuilds

🧰 Lab Setup
Component	Value
PXE Master	192.168.200.25
Affected Component	wwd service
Warewulf Config File	/etc/warewulf/warewulf.conf
Container Name	rockylinux-9-lab
Overlay Directory	/var/lib/warewulf/overlays/

🧪 Step 1: Observe the Crash
Check the daemon logs:

bash
Copy
Edit
journalctl -u wwd -f
Typical output:

text
Copy
Edit
wwd: panic: runtime error: invalid memory address or nil pointer dereference
wwd: caused by malformed overlay path or container reference
Check exit status:

bash
Copy
Edit
systemctl status wwd
You’ll see:

text
Copy
Edit
Active: failed (Result: exit-code)
🧱 Step 2: Inspect Your warewulf.conf
Open it:

bash
Copy
Edit
sudo vim /etc/warewulf/warewulf.conf
Look for issues like:

yaml
Copy
Edit
root: /wrong/path
tftp:
  path: /not/found/tftpboot
container dir: /invalid/container/path
This often happens when a rebuild overwrites or resets config paths.

🧼 Step 3: Restore Correct Paths
Use this baseline config snippet:

yaml
Copy
Edit
warewulf:
  root: /var/lib/warewulf
  container dir: /var/lib/warewulf/containers
  overlays:
    system: /var/lib/warewulf/overlays/system
    runtime: /var/lib/warewulf/overlays/runtime
  tftp:
    path: /var/lib/tftpboot
    enabled: true
  dhcp:
    enabled: true
    rangeStart: 192.168.200.50
    rangeEnd: 192.168.200.99
    systemdName: dhcpd
Correct and save the file.

🔄 Step 4: Rebuild Containers and Overlays
Even if the paths are fixed, broken cache or tmp files may cause crash loops.

Clean and rebuild:

bash
Copy
Edit
wwctl container build rockylinux-9-lab
wwctl overlay build
wwctl bootstrap build
Check:

bash
Copy
Edit
ls -lh /var/lib/warewulf/containers/
ls -lh /var/lib/warewulf/overlays/
🔧 Step 5: Restart the Warewulf Daemon
bash
Copy
Edit
sudo systemctl daemon-reexec
sudo systemctl restart wwd
Check status:

bash
Copy
Edit
sudo systemctl status wwd
You should now see:

text
Copy
Edit
Active: active (running)
Also confirm HTTP port is open:

bash
Copy
Edit
ss -tuln | grep 9873
📥 Step 6: Apply GitHub Patch (Optional But Recommended)
This issue has been documented in upstream issues. Patch example:

GitHub: https://github.com/hpcng/warewulf/issues/391
Patch: https://github.com/hpcng/warewulf/pull/392

Apply manually or:

bash
Copy
Edit
cd /tmp
git clone https://github.com/hpcng/warewulf.git
cd warewulf
make
sudo make install
Then:

bash
Copy
Edit
sudo systemctl restart wwd
🔁 Step 7: Reboot a Node to Test Delivery
Choose a node (e.g., rocky05) and reboot:

bash
Copy
Edit
wwctl power cycle rocky05
Monitor:

bash
Copy
Edit
journalctl -u wwd -f
✅ You should see image and overlay delivery logs like:

text
Copy
Edit
Sent container rockylinux-9-lab.img to 192.168.200.55
Sent overlay generic
🧪 Step 8: Regression Test
Test overlay access:
bash
Copy
Edit
curl http://localhost:9873/overlay/generic.img
Test container file:
bash
Copy
Edit
curl http://localhost:9873/container/rockylinux-9-lab.img
🧠 What Causes This?
Cause	Description
Overlay path changed	Rebuild or script overwrote warewulf.conf
Wrong container ref	Node assigned invalid or deleted container
Missing overlay files	Manually deleted or corrupted during build
Overlay conflict	Manual edits inside overlay dir while wwctl overlay build was running

🔐 Bonus: Protect Against Future Crashes
Lock config file:

bash
Copy
Edit
chattr +i /etc/warewulf/warewulf.conf
To undo:

bash
Copy
Edit
chattr -i /etc/warewulf/warewulf.conf
Backup working overlays:

bash
Copy
Edit
cp -r /var/lib/warewulf/overlays /root/overlay-backup/
Version your container image builds using git or tar snapshots

✅ Final Checklist
Task	Complete?
Config corrected	✅
Overlays rebuilt	✅
Container rebuilt	✅
wwd restarted	✅
Nodes tested	✅

🧠 What You Learned
Skill	Benefit
Daemon log reading	Production-level debugging
Config file hardening	Stability through correctness
Overlay container recovery	Warewulf internals mastery
GitHub patching	OSS maintenance & patch tracking


# Extra 

# 🧨 Ticket #6 – Warewulf Daemon (`wwd`) Crashes After Container Update

This guide covers how to resolve `wwd` daemon crashes after container rebuilds, including config validation, daemon restart, and GitHub patch application.

...

[Full content provided above — truncated here for brevity]
"""

# Helper script to validate Warewulf config paths
validate_script = """#!/bin/bash
# Validate warewulf.conf for common path issues before starting wwd

CONF="/etc/warewulf/warewulf.conf"
ERROR=0

echo "[+] Validating Warewulf config: $CONF"

grep -q '/var/lib/warewulf' "$CONF" || { echo "[-] Root path misconfigured"; ERROR=1; }
grep -q 'container dir: /var/lib/warewulf/containers' "$CONF" || { echo "[-] Container dir misconfigured"; ERROR=1; }
grep -q 'tftp:' "$CONF" || { echo "[-] Missing TFTP section"; ERROR=1; }
grep -q 'overlays:' "$CONF" || { echo "[-] Missing overlays section"; ERROR=1; }

if [ "$ERROR" -eq 1 ]; then
  echo "[!] One or more config issues detected. Fix before starting wwd."
  exit 1
else
  echo "[✓] Warewulf config validated."
  exit 0
fi


