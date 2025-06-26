# 🔥 Ticket #21 – TFTP Port Blocked by Firewall

## 🧠 Problem Summary

PXE booting across a remote subnet failed. Client machines were stuck at:

TFTP open timeout
PXE-E32: TFTP open timeout

yaml
Always show details

Copy

Upon investigation, it was discovered that:
- PXE clients were not receiving the TFTP boot file from the PXE server.
- Communication on UDP port 69 was silently dropped.
- Only nodes on the same subnet could PXE boot.

---

## 🔍 Root Cause

The firewall (`firewalld`) on the PXE boot server was **blocking incoming TFTP traffic (UDP port 69)**. This prevented the initial iPXE/undionly.kpxe file from transferring across subnets.

---

## 🛠️ Solution: Allow and Persist TFTP (UDP 69) Through Firewalld

We applied a firewall rule to allow TFTP traffic over UDP, made it permanent, and reloaded `firewalld`.

---

### ✅ Step 1: Confirm Firewalld is Running

```bash
sudo systemctl status firewalld
If inactive, start and enable:

bash
Always show details

Copy
sudo systemctl enable --now firewalld
✅ Step 2: Check Existing Rules
List current firewall rules:

bash
Always show details

Copy
sudo firewall-cmd --list-all
Expected output before change:

makefile
Always show details

Copy
services: ssh dhcp
ports: 
✅ Step 3: Temporarily Allow UDP Port 69
bash
Always show details

Copy
sudo firewall-cmd --add-port=69/udp
Confirm:

bash
Always show details

Copy
sudo firewall-cmd --list-ports
✅ Step 4: Make the Rule Permanent
bash
Always show details

Copy
sudo firewall-cmd --permanent --add-port=69/udp
sudo firewall-cmd --reload
Then check:

bash
Always show details

Copy
sudo firewall-cmd --list-all
Now you should see:

bash
Always show details

Copy
ports: 69/udp
✅ Step 5: Open PXE Ports as a Group
If you want to open all relevant PXE boot ports:

bash
Always show details

Copy
# DHCP (PXE base)
sudo firewall-cmd --permanent --add-service=dhcp

# TFTP
sudo firewall-cmd --permanent --add-service=tftp

# HTTP (used by some iPXE configs)
sudo firewall-cmd --permanent --add-service=http

# NFS if overlays are mounted via network
sudo firewall-cmd --permanent --add-service=nfs

# Reload changes
sudo firewall-cmd --reload
🧪 Script: enable_tftp_firewall.sh
bash
Always show details

Copy
#!/bin/bash

echo "🔒 Checking firewalld..."
sudo systemctl enable --now firewalld

echo "🛠️ Allowing PXE services..."
sudo firewall-cmd --permanent --add-port=69/udp
sudo firewall-cmd --permanent --add-service=dhcp
sudo firewall-cmd --permanent --add-service=tftp
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=nfs

echo "♻️ Reloading firewalld..."
sudo firewall-cmd --reload

echo "✅ Firewall updated for PXE booting."
Make executable:

bash
Always show details

Copy
chmod +x enable_tftp_firewall.sh
./enable_tftp_firewall.sh
✅ Step 6: Test TFTP Port from Remote Client
On remote PXE client or tester VM:

bash
Always show details

Copy
tftp <PXE_SERVER_IP>
tftp> get undionly.kpxe
tftp> quit
You should see the file transfer succeed.

Or test with nmap:

bash
Always show details

Copy
nmap -sU -p 69 <PXE_SERVER_IP>
Expected:

arduino
Always show details

Copy
69/udp open  tftp
✅ Final Checklist
Task	Status
firewalld active and running	✅
UDP port 69 open (temp + permanent)	✅
TFTP tested via tftp client and nmap	✅
Scripted PXE rule automation implemented	✅
Boot tested from both local and remote subnet	✅

💭 Lessons Learned
PXE boot depends on multiple services: DHCP, TFTP, HTTP, and optionally NFS.

UDP port 69 is non-negotiable for legacy PXE unless you're fully using HTTP-based iPXE.

Always test port exposure from the client’s perspective, especially across subnet routers/firewalls.

Automate PXE provisioning firewall rules using scripts for repeatable setups.
