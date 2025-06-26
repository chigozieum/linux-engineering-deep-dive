# ⚖️ Ticket #19 – Load Balancer Dropping Node Health

## 🧠 Problem Summary

In our cluster, some nodes were intermittently removed from the HAProxy load balancer health check pool immediately after PXE boot.

Symptoms included:
- HAProxy UI showing the node as DOWN
- Manual `curl` from load balancer node to the affected node returned `connection refused`
- Logs showed health check failures despite successful PXE and overlay application

---

## 🔍 Root Cause

After investigation:
- Health check was attempting to connect via `sshd` on port `22`
- The container used had a modified `sshd_config` pointing to **port 2222**
- The load balancer was unaware of the port change and marked the node unhealthy

---

## 🛠️ Solution: Standardize sshd Port via Container Update

The SSH port was reverted to the default (`22`) in the container image used for the nodes, and the `sshd` service was reloaded.

---

### ✅ Step 1: Inspect Node Container `sshd_config`

Log in to the container or mount it:

```bash
sudo wwctl container shell rocky9
Inside the container, check:

bash
Always show details

Copy
cat /etc/ssh/sshd_config | grep Port
Output:

yaml
Always show details

Copy
Port 2222
✅ Step 2: Update sshd_config to Port 22
Edit:

bash
Always show details

Copy
sed -i 's/^Port 2222/Port 22/' /etc/ssh/sshd_config
Optional: Set passwordless login or authorized key injection if needed.

✅ Step 3: Rebuild the Container
Exit the container shell and commit the changes:

bash
Always show details

Copy
exit
sudo wwctl container build rocky9
✅ Step 4: Rebuild Overlay (If Needed)
bash
Always show details

Copy
sudo wwctl overlay build --all
✅ Step 5: Restart Node and Reload SSH
Reboot the node or re-provision via PXE.

Then confirm:

bash
Always show details

Copy
ssh root@node01 -p 22
From the load balancer, test:

bash
Always show details

Copy
curl -v telnet://node01.lab.local:22
Or if using HAProxy:

bash
Always show details

Copy
sudo tail -f /var/log/haproxy.log
You should now see:

csharp
Always show details

Copy
node01 is UP
🧪 Script: fix_sshd_port.sh
bash
Always show details

Copy
#!/bin/bash

CONTAINER_NAME="rocky9"

echo "🔍 Opening container shell..."
sudo wwctl container shell $CONTAINER_NAME <<EOF
sed -i 's/^Port 2222/Port 22/' /etc/ssh/sshd_config
EOF

echo "🔨 Rebuilding container..."
sudo wwctl container build $CONTAINER_NAME

echo "♻️ Rebuilding overlays..."
sudo wwctl overlay build --all

echo "✅ SSH port corrected and containers rebuilt."
Save as fix_sshd_port.sh and execute:

bash
Always show details

Copy
chmod +x fix_sshd_port.sh
./fix_sshd_port.sh
✅ Final Checklist
Task	Status
Incorrect SSH port identified	✅
Container sshd_config fixed	✅
Container rebuilt	✅
Overlay rebuilt	✅
HAProxy health check passed	✅

💭 Lessons Learned
Always validate exposed ports in PXE containers if external systems (HAProxy, monitoring, config management) depend on them.

HAProxy health check failures are often tied to firewall or service port mismatches.

Standardize SSH ports across containers unless explicitly required otherwise.