🌐 Task 3 – Deploy an Internal DNS Using dnsmasq (1000+ Words)
Objective:
Transform your PXE server into a lightweight DNS/DHCP provider for your lab, using dnsmasq. This ensures consistent hostname resolution across your nodes, improves PXE reliability, and centralizes control in your provisioning environment.

🧠 Why dnsmasq?
dnsmasq is a fast, lightweight, and easy-to-configure DNS forwarder + DHCP server. It works perfectly in home lab setups to:

✅ Serve DNS for Warewulf-managed nodes
✅ Resolve hostnames like rocky01.lab.local without Internet DNS
✅ Avoid hardcoding /etc/hosts across machines
✅ Act as backup DHCP or PXE chainloader

🛠️ Step 1: Install dnsmasq
On your PXE/Warewulf server (Rocky Linux 9):

bash
Copy
Edit
sudo dnf install dnsmasq -y
Stop and disable any conflicting DHCP server:

bash
Copy
Edit
sudo systemctl disable --now dhcpd
Ensure dnsmasq isn’t already running:

bash
Copy
Edit
sudo systemctl stop dnsmasq
📁 Step 2: Create the Main Config
Backup default config:

bash
Copy
Edit
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.backup
Create a fresh one:

bash
Copy
Edit
sudo vim /etc/dnsmasq.conf
Paste the following:

ini
Copy
Edit
# Core DNS Settings
domain-needed
bogus-priv
domain=lab.local
expand-hosts
local=/lab.local/

# DHCP Range (Match PXE Subnet)
interface=eth0
dhcp-range=192.168.200.50,192.168.200.99,12h
dhcp-option=3,192.168.200.1
dhcp-option=6,192.168.200.25

# PXE Boot (Optional - PXE fallback)
dhcp-boot=undionly.kpxe
enable-tftp
tftp-root=/var/lib/tftpboot

# Log to syslog
log-queries
log-dhcp
📜 Step 3: Define Static Hostnames
Edit /etc/hosts and add each node:

bash
Copy
Edit
sudo vim /etc/hosts
ini
Copy
Edit
192.168.200.50 rocky01.lab.local rocky01
192.168.200.51 rocky02.lab.local rocky02
192.168.200.52 rocky03.lab.local rocky03
Because expand-hosts is enabled in dnsmasq.conf, it will map all these to .lab.local.

You can also define them via dnsmasq.hosts file:

bash
Copy
Edit
sudo mkdir -p /etc/dnsmasq.d
sudo vim /etc/dnsmasq.d/lab-hosts.conf
ini
Copy
Edit
address=/rocky01.lab.local/192.168.200.50
address=/rocky02.lab.local/192.168.200.51
🚀 Step 4: Start and Enable dnsmasq
bash
Copy
Edit
sudo systemctl enable --now dnsmasq
sudo systemctl status dnsmasq
Check logs:

bash
Copy
Edit
journalctl -u dnsmasq -f
You should see:

txt
Copy
Edit
dnsmasq[xxxxx]: DHCP, IP range 192.168.200.50 -- 192.168.200.99
dnsmasq[xxxxx]: reading /etc/hosts
🌐 Step 5: Test Local DNS Resolution
🔄 From PXE Server
bash
Copy
Edit
ping rocky01.lab.local
Expected:

txt
Copy
Edit
PING rocky01.lab.local (192.168.200.50) 56(84) bytes of data...
🔄 From Any PXE-booted Node
Ensure Warewulf overlays are injecting correct /etc/resolv.conf:

bash
Copy
Edit
nameserver 192.168.200.25
search lab.local
To verify:

bash
Copy
Edit
grep nameserver /etc/resolv.conf
ping rocky02.lab.local
🧪 Step 6: Integrate with Warewulf
Update your Warewulf runtime overlay to auto-configure DNS for every node.

Add to overlay:

bash
Copy
Edit
vim overlays/generic/etc/resolv.conf
ini
Copy
Edit
nameserver 192.168.200.25
search lab.local
Rebuild the overlay:

bash
Copy
Edit
wwctl overlay build
Now all new nodes will use your internal dnsmasq DNS on boot.

🔥 Step 7: Use dnsmasq for PXE TFTP Routing
If you're not using dhcpd, let dnsmasq handle PXE chainloading:

ini
Copy
Edit
# Inside dnsmasq.conf
dhcp-boot=undionly.kpxe
enable-tftp
tftp-root=/var/lib/tftpboot
Restart the service:

bash
Copy
Edit
sudo systemctl restart dnsmasq
🧱 Optional: Forward External DNS
Let your lab use Google or Cloudflare as fallback:

ini
Copy
Edit
server=8.8.8.8
server=1.1.1.1
Now even booted nodes can reach the internet.

🔐 Bonus: Add Firewalld Rule for DNS
Allow DNS and DHCP ports:

bash
Copy
Edit
sudo firewall-cmd --permanent --add-service=dns
sudo firewall-cmd --permanent --add-service=dhcp
sudo firewall-cmd --reload
🧠 What You’ve Built
Feature	Result
Internal DNS	All nodes resolve each other by hostname
PXE DHCP	IPs automatically assigned from 50–99
Overlay Integration	/etc/resolv.conf preconfigured
Lightweight DNS	Uses < 5MB RAM and ~1s boot time
LAN-Only Setup	Fully internal resolution of .lab.local

🧪 Troubleshooting Tips
1. DNS not working?

bash
Copy
Edit
dig rocky01.lab.local @192.168.200.25
2. Boot failure after switch from dhcpd to dnsmasq?

Check PXE boot message for:

txt
Copy
Edit
PXE-E53: No boot filename received
If so, fix:

ini
Copy
Edit
dhcp-boot=undionly.kpxe
Ensure undionly.kpxe is in /var/lib/tftpboot/.

3. dnsmasq won’t start?

Check for port conflicts:

bash
Copy
Edit
ss -tulnp | grep :53
🧩 Real-World Use Cases
🎓 Teaching labs where students access machines by hostname

☁️ Simulated datacenter with hostnames like node01.lab.local

🛡️ Red Team labs where you simulate DNS hijacking or tunneling

🔁 Faster PXE deployments by local DNS caching

✅ Summary
With dnsmasq deployed, your PXE lab now has:

📡 Stable internal DNS

🧠 Human-readable hostnames

🔄 Integrated DHCP fallback

🔐 Full overlay compatibility for booted nodes

This transforms your PXE server from just a boot point into a fully autonomous lab infrastructure controller.


# Extra 



# Markdown documentation content for DNSMasq Internal DNS
markdown_content = """# 🌐 Task 3 – Deploy an Internal DNS Using `dnsmasq`

Transform your PXE server into a DNS and DHCP provider for your Warewulf cluster using dnsmasq. This guide walks through installation, configuration, integration, and testing steps.

...

[Truncated for brevity, full content was given in previous message]
"""

# Test script for DNS resolution
dns_test_script = """#!/bin/bash
# Test internal DNS resolution using dnsmasq

NODES=("rocky01.lab.local" "rocky02.lab.local" "rocky03.lab.local")
DNS_SERVER="192.168.200.25"

echo "[+] Testing internal DNS resolution against ${DNS_SERVER}"
for node in "${NODES[@]}"; do
  echo -n " - ${node}: "
  dig +short "$node" @"$DNS_SERVER"
done
"""