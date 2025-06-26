Ticket #3 – DHCP IP Range Conflict, using the same detailed, beginner-friendly 1000+ word style.

⚠️ Ticket #3 – DHCP IP Range Conflict: Two Nodes, One IP
Issue: Two Warewulf nodes in a PXE-boot cluster were assigned the same IP address, resulting in:

❌ Network collisions
❌ Boot loops or dropped packets
❌ Failed PXE chainloading
❌ Inconsistent node visibility

🧠 Summary
In a cluster, every node must have a unique IP address, especially when provisioning via DHCP.

This ticket describes how to:

Diagnose duplicate IP issues

Fix overlapping DHCP ranges

Enforce MAC uniqueness

Harden your Warewulf config against recurrence

You’ll learn how PXE + DHCP + static IP management work together in Warewulf and how to debug collisions like a pro.

🧰 Environment Overview
Component	Example Value
PXE Server IP	192.168.200.25
DHCP Subnet	192.168.200.0/24
Node1 IP	192.168.200.60
Node2 IP	192.168.200.60 (conflict)
DHCP Range	192.168.200.50–99

🔍 Symptoms of IP Conflict
Booting both nodes may result in:

Node A boots fine, Node B fails with:

text
Copy
Edit
PXE-E51: No DHCP or proxyDHCP offers were received
Random disconnection after PXE boot

“This IP is already in use” errors

Container mount failure or infinite reboot loops

📡 Step 1: Verify the Problem with ARP Scan
From the PXE server:

bash
Copy
Edit
sudo arp-scan --interface=eth0 --localnet
You'll see:

text
Copy
Edit
192.168.200.60 AA:BB:CC:DD:EE:01
192.168.200.60 AA:BB:CC:DD:EE:02
This confirms a MAC address collision or double assignment to the same IP.

🛠️ Step 2: Audit the Warewulf Node IP Assignments
List all nodes:

bash
Copy
Edit
wwctl node list -o yaml | grep -E 'NodeName:|IPAddr:|HWaddr:'
Sample output:

yaml
Copy
Edit
NodeName: rocky01
  IPAddr: 192.168.200.60
  HWaddr: AA:BB:CC:DD:EE:01
NodeName: rocky02
  IPAddr: 192.168.200.60
  HWaddr: AA:BB:CC:DD:EE:02
Boom — two different MACs, same IP. This is the root of the problem.

🧼 Step 3: Assign Unique IPs to Each Node
Update Node 2:

bash
Copy
Edit
wwctl node set rocky02 --ipaddr 192.168.200.61
Confirm:

bash
Copy
Edit
wwctl node list rocky02 -o yaml
Output:

yaml
Copy
Edit
IPAddr: 192.168.200.61
Apply changes:

bash
Copy
Edit
wwctl overlay build
wwctl bootstrap build
🧾 Step 4: Adjust DHCP Range in Warewulf Config
Edit the main config:

bash
Copy
Edit
sudo vim /etc/warewulf/warewulf.conf
Locate the DHCP block:

yaml
Copy
Edit
dhcp:
  enabled: true
  rangeStart: 192.168.200.50
  rangeEnd: 192.168.200.99
  systemdName: dhcpd
If you’re manually assigning IPs (preferred), reduce the dynamic range:

yaml
Copy
Edit
rangeStart: 192.168.200.80
rangeEnd: 192.168.200.99
This preserves 192.168.200.50–79 for static PXE node assignments.

🔄 Step 5: Restart DHCP + Reboot Nodes
Apply config:

bash
Copy
Edit
sudo systemctl restart dhcpd
Then reboot both nodes:

bash
Copy
Edit
wwctl power cycle rocky01
wwctl power cycle rocky02
(Or manually power cycle the physical machines.)

🧪 Step 6: Verify Fix
Scan again:

bash
Copy
Edit
sudo arp-scan --interface=eth0 --localnet
You should now see:

text
Copy
Edit
192.168.200.60 AA:BB:CC:DD:EE:01
192.168.200.61 AA:BB:CC:DD:EE:02
✅ No more collision
✅ Both nodes get different IPs
✅ PXE + container mounting proceeds smoothly

⚔️ Step 7: Enforce MAC Uniqueness in Future
Add a check script:

bash
Copy
Edit
#!/bin/bash
echo "[+] Checking MAC uniqueness..."
wwctl node list -o yaml | grep HWaddr | sort | uniq -d
This will print duplicate MACs — your early warning system.

Add it to scripts/check_mac_duplicates.sh.

🧩 Bonus: Warewulf Auto IP Assignment Best Practice
You can use this strategy:

Reserve .50–.79 for statically assigned PXE nodes

Allow .80–.99 as dynamic fallback

Use descriptive hostnames (rocky01, rocky02, etc.)

Document MAC/IP pairs in /etc/hosts or NetBox

📁 Example Warewulf Node Config
yaml
Copy
Edit
NodeName: rocky03
  IPAddr: 192.168.200.62
  HWaddr: AA:BB:CC:DD:EE:03
  ContainerName: rockylinux-9-lab
  RuntimeOverlay: generic
  SystemOverlay: default
  NetDevs:
    eth0:
      IPv4: 192.168.200.62
      HWaddr: AA:BB:CC:DD:EE:03
🧠 What You Learned
Concept	Skill
ARP Scanning	Troubleshooting duplicate IPs
Warewulf YAML	Node configuration management
DHCP Tuning	Range partitioning for static + dynamic
MAC/IP Mapping	Manual integrity enforcement
Boot Error Diagnosis	Real-world PXE debugging

🔐 Security Note
To prevent rogue nodes from taking IPs:

Consider MAC-based static leases in /etc/dhcp/dhcpd.conf

Use firewalld to block unknown MACs (advanced)

Monitor DHCP logs for collisions:

bash
Copy
Edit
journalctl -u dhcpd -f
✅ Final Result
Your PXE cluster now:

Has unique IPs for each node

Is protected from network collisions

Has a defined IP structure (static vs. dynamic)

Is easier to maintain and expand


# Extra 



# Markdown documentation content for the DHCP IP Conflict ticket
markdown_content = """# ⚠️ Ticket #3 – DHCP IP Range Conflict: Two Nodes, One IP

**Issue:** Two Warewulf nodes received the same IP address, resulting in network collisions and PXE boot issues.

...

[Full guide content was written in the previous message; shortened here for brevity]
"""

# Shell script to check for duplicate MAC addresses
mac_check_script = """#!/bin/bash
# Detect duplicate MAC addresses in Warewulf node definitions

echo "[+] Scanning for duplicate MAC addresses..."
wwctl node list -o yaml | grep HWaddr | sort | uniq -d

if [ $? -ne 0 ]; then
  echo "[✓] No duplicate MACs detected."
else
  echo "[!] Duplicate MACs found. Please fix them using: wwctl node set"
fi
"""
