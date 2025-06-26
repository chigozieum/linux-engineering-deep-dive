# 🌐 Ticket #8 – Inconsistent DNS Resolution in Cluster Nodes

## 🧠 Problem Summary
# Issue Overview
You're managing a PXE-booted cluster, and some nodes can resolve internal hostnames like node01.lab.local, while others fail with errors like:

Some PXE-booted nodes resolve internal domain names like `node01.lab.local` correctly, while others do not. This results in:
- Failed inter-node communication
- Errors when connecting to services via DNS
- Intermittent failures during `apt`, `yum`, `kubectl`, or `curl`




connection timed out; no servers could be reached
This breaks communication between services, makes Kubernetes unreliable, and causes frustrating debugging sessions.

🔎 Root Cause
The nodes do not all share a consistent DNS configuration.

Some use the PXE server as their nameserver, others default to external ones.

/etc/resolv.conf on PXE-booted nodes is generated per overlay, so if not updated centrally, nodes get out of sync.

🛠️ Solution Summary
Install and configure a central dnsmasq DNS server on the PXE head node.

Ensure all node overlays contain a unified /etc/resolv.conf.

Restart affected services and verify resolution on each node.



---

## 🧪 Diagnosis

### ✅ Step 1: Test DNS on Nodes

On a working node:

```bash
dig node01.lab.local
On a failing node:

bash
Always show details

Copy
dig node01.lab.local
Compare the results. Failing nodes typically show:

bash
Always show details

Copy
;; connection timed out; no servers could be reached
🔧 Step 2: Centralize DNS with dnsmasq
Install dnsmasq on your PXE server:

sudo dnf install dnsmasq -y

bash
Always show details

Copy
yum install dnsmasq -y
Edit /etc/dnsmasq.conf:

ini
Always show details

Copy
domain=lab.local
expand-hosts
interface=eth0
listen-address=127.0.0.1
bind-interfaces
bogus-priv
no-resolv
server=8.8.8.8
Ensure /etc/hosts has correct node entries:

txt
Always show details

Copy
192.168.200.51 node01.lab.local node01
192.168.200.52 node02.lab.local node02
🔁 Step 3: Restart dnsmasq
bash
Always show details

Copy
systemctl enable --now dnsmasq
Verify:

bash
Always show details

Copy
dig @127.0.0.1 node01.lab.local
🧼 Step 4: Update Node Overlay with /etc/resolv.conf
Set the overlay template for DNS:

bash
Always show details

Copy
echo "nameserver 192.168.200.25" > /etc/warewulf/overlays/dns/etc/resolv.conf
Rebuild overlays:

bash
Always show details

Copy
wwctl overlay build -H
Apply overlays:

bash
Always show details

Copy
wwctl configure --all
🚀 Step 5: Reboot Affected Nodes
bash
Always show details

Copy
wwctl power cycle node01
🧪 Step 6: Validate Fix
Run again on the previously failing node:

bash
Always show details

Copy
dig node01.lab.local
ping node02.lab.local
Expected:

bash
Always show details

Copy
64 bytes from node02.lab.local...
💡 Tips
Make sure dnsmasq is only listening on internal interfaces

Avoid conflict with systemd-resolved or other local DNS managers

Use dnsmasq --test to validate syntax

✅ Final Checklist
Task	Status
dnsmasq installed & configured	✅
/etc/hosts updated with nodes	✅
Overlay rebuilt with resolv.conf	✅
DNS tested from all nodes	✅

🧪 Script Suggestion
Add a script scripts/verify_dns_cluster.sh to test resolution from each node via SSH.

Would you like this added?"""

Script to verify DNS resolution across nodes
dns_test_script = """#!/bin/bash

Run DNS resolution check on all known PXE nodes
NODES=("node01" "node02" "node03")
DOMAIN="lab.local"
DNS_SERVER="192.168.200.25"

for NODE in "${NODES[@]}"; do
echo "[+] Checking $NODE.$DOMAIN"
ssh $NODE "dig @$DNS_SERVER $NODE.$DOMAIN +short"
done


# step by step of the above

🌐 Ticket #8 – Inconsistent DNS Resolution in Cluster Nodes
🧠 Issue Overview
You're managing a PXE-booted cluster, and some nodes can resolve internal hostnames like node01.lab.local, while others fail with errors like:


connection timed out; no servers could be reached
This breaks communication between services, makes Kubernetes unreliable, and causes frustrating debugging sessions.

🔎 Root Cause
The nodes do not all share a consistent DNS configuration.

Some use the PXE server as their nameserver, others default to external ones.

/etc/resolv.conf on PXE-booted nodes is generated per overlay, so if not updated centrally, nodes get out of sync.

🛠️ Solution Summary
Install and configure a central dnsmasq DNS server on the PXE head node.

Ensure all node overlays contain a unified /etc/resolv.conf.

Restart affected services and verify resolution on each node.

🔧 Step-by-Step Resolution
📌 1. Install dnsmasq on the PXE Server
bash
Copy
Edit
sudo dnf install dnsmasq -y
📝 2. Edit /etc/dnsmasq.conf
Use this minimal working example:

ini
Copy
Edit
domain=lab.local
expand-hosts
interface=eth0
listen-address=127.0.0.1
bind-interfaces
bogus-priv
no-resolv
server=8.8.8.8
Replace eth0 with your PXE interface if different.

🧾 3. Add Node IPs to /etc/hosts
Add your nodes:

lua
Copy
Edit
192.168.200.51 node01.lab.local node01
192.168.200.52 node02.lab.local node02
192.168.200.53 node03.lab.local node03
🔁 4. Restart and Enable dnsmasq
bash
Copy
Edit
sudo systemctl enable --now dnsmasq
Check logs:

bash
Copy
Edit
journalctl -u dnsmasq -f
🔍 5. Validate DNS Server Locally
bash
Copy
Edit
dig @127.0.0.1 node01.lab.local
Output should be:

less
Copy
Edit
;; ANSWER SECTION:
node01.lab.local. IN A 192.168.200.51
🧩 Step 6: Rebuild PXE Node Overlay with DNS Info
📂 Create DNS overlay folder if needed:
bash
Copy
Edit
mkdir -p /etc/warewulf/overlays/dns/etc
✍️ Write resolv.conf to overlay:
bash
Copy
Edit
echo "nameserver 192.168.200.25" > /etc/warewulf/overlays/dns/etc/resolv.conf
Replace with your PXE server IP.

🔨 Build overlay:
bash
Copy
Edit
wwctl overlay build -H
💡 Apply overlay to all nodes:
bash
Copy
Edit
wwctl configure --all
🚀 Step 7: Reboot the Nodes
bash
Copy
Edit
wwctl power cycle node01
wwctl power cycle node02
wwctl power cycle node03
🧪 Step 8: Validate on All Nodes
SSH into each and run:

bash
Copy
Edit
dig node02.lab.local
ping node03.lab.local
You should get valid IPs and replies.

🧪 Bonus: Script to Check DNS Resolution Cluster-Wide
Here’s a diagnostic script:

bash
Copy
Edit
#!/bin/bash
# File: verify_dns_cluster.sh

NODES=("node01" "node02" "node03")
DOMAIN="lab.local"
DNS_SERVER="192.168.200.25"

for NODE in "${NODES[@]}"; do
    echo "[+] Checking $NODE.$DOMAIN"
    ssh $NODE "dig @$DNS_SERVER $NODE.$DOMAIN +short"
done
Make it executable:

bash
Copy
Edit
chmod +x verify_dns_cluster.sh
✅ Final Checklist
Task	Done
dnsmasq installed & configured	✅
/etc/hosts populated with nodes	✅
/etc/resolv.conf in overlays	✅
Overlay rebuilt and applied	✅
All nodes rebooted	✅
Dig & ping passed on all nodes	✅