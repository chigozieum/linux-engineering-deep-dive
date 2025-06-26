🛡️ 2. Secure the Setup Using Firewalld and Fail2Ban (1000+ Words)
Applies to: Your PXE server running DHCP, TFTP, Prometheus, Grafana, and Warewulf

🧠 Why This Is Critical
Your PXE server:

Hosts containerized OS images

Provides DHCP and TFTP to boot new nodes

Exposes Grafana and Prometheus on ports 3000 and 9090

Acts as the central brain of your cluster

Without basic security hardening, it’s vulnerable to:

Unauthorized scans or attacks

Brute-force login attempts (especially on Grafana)

Exploitation of exposed ports and services

This guide locks it down using Firewalld and Fail2Ban, two beginner-friendly tools with enterprise-grade capability.

🧰 What You'll Achieve
✅ Configure Firewalld zones and rules to allow only trusted services
✅ Enable Fail2Ban to block brute-force attempts (SSH, Grafana, etc.)
✅ Log and monitor suspicious activity
✅ Apply these configs to your lab images to auto-harden all Warewulf nodes too

🔧 Step 1: Install Firewalld and Fail2Ban
Firewalld is typically preinstalled on Rocky Linux. If not:

bash
Copy
Edit
sudo dnf install firewalld -y
sudo systemctl enable --now firewalld
Check status:

bash
Copy
Edit
sudo firewall-cmd --state
Install Fail2Ban:

bash
Copy
Edit
sudo dnf install epel-release -y
sudo dnf install fail2ban -y
sudo systemctl enable --now fail2ban
🌐 Step 2: Define Firewalld Zones
Zones let you define per-interface trust levels.

Check your active interface:

bash
Copy
Edit
nmcli device status
Let’s assume eth0 is your main NIC.

🔒 Assign the Interface to the Internal Zone
bash
Copy
Edit
sudo firewall-cmd --zone=internal --change-interface=eth0 --permanent
sudo firewall-cmd --reload
🔥 Step 3: Allow Required Services Only
👨‍💻 SSH Access
bash
Copy
Edit
sudo firewall-cmd --zone=internal --add-service=ssh --permanent
📡 DHCP and TFTP (PXE Booting)
bash
Copy
Edit
sudo firewall-cmd --zone=internal --add-service=dhcp --permanent
sudo firewall-cmd --zone=internal --add-service=tftp --permanent
🌐 Grafana + Prometheus
bash
Copy
Edit
sudo firewall-cmd --zone=internal --add-port=3000/tcp --permanent
sudo firewall-cmd --zone=internal --add-port=9090/tcp --permanent
🧪 Warewulf HTTP (Container/Image Server)
bash
Copy
Edit
sudo firewall-cmd --zone=internal --add-port=9873/tcp --permanent
Apply changes:

bash
Copy
Edit
sudo firewall-cmd --reload
🔎 Step 4: Verify Firewall Rules
bash
Copy
Edit
sudo firewall-cmd --zone=internal --list-all
You should see:

text
Copy
Edit
services: ssh dhcp tftp
ports: 3000/tcp 9090/tcp 9873/tcp
Test connectivity using:

bash
Copy
Edit
nmap -p 22,69,3000,9090,9873 <pxe-server-ip>
🧃 Step 5: Harden SSH (Optional but Recommended)
Edit /etc/ssh/sshd_config:

conf
Copy
Edit
PermitRootLogin no
PasswordAuthentication no
AllowUsers yourusername
Restart SSH:

bash
Copy
Edit
sudo systemctl restart sshd
⛔ Step 6: Configure Fail2Ban
Create a local config:

bash
Copy
Edit
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
Edit /etc/fail2ban/jail.local and configure at least:

ini
Copy
Edit
[sshd]
enabled = true
port = ssh
logpath = /var/log/secure
maxretry = 5
bantime = 3600
findtime = 600
Add protection for Grafana login:

Create a jail config:

bash
Copy
Edit
sudo tee /etc/fail2ban/filter.d/grafana.conf > /dev/null <<EOF
[Definition]
failregex = .*Invalid username or password.*
ignoreregex =
EOF
And the jail itself:

ini
Copy
Edit
[grafana]
enabled = true
port = 3000
filter = grafana
logpath = /var/log/grafana/grafana.log
maxretry = 5
bantime = 600
findtime = 300
Restart Fail2Ban:

bash
Copy
Edit
sudo systemctl restart fail2ban
Check jails:

bash
Copy
Edit
sudo fail2ban-client status
You should see both sshd and grafana listed.

📊 Step 7: Monitor Ban Events
See real-time bans:

bash
Copy
Edit
sudo fail2ban-client status sshd
sudo fail2ban-client status grafana
Or tail logs:

bash
Copy
Edit
sudo tail -f /var/log/fail2ban.log
🪄 Step 8: Test the Security
✅ SSH Test
Try logging in with the wrong SSH key or password several times. After 5 attempts, your IP should be banned.

✅ Grafana Test
Try logging into Grafana 5 times with the wrong password. You should get banned from accessing port 3000.

♻️ Optional: Auto-Sync to Warewulf Nodes
To ensure every new node inherits the same protection:

Install firewalld + fail2ban inside your Warewulf container:

bash
Copy
Edit
dnf install firewalld fail2ban -y
systemctl enable firewalld
systemctl enable fail2ban
Add /etc/firewalld/ and /etc/fail2ban/ to your overlay

Add startup scripts in your overlay’s systemd units

Now every booted node has hardened defaults.

🔐 Summary: What You Just Did
Task	Outcome
Firewalld Zones	Allowed only critical services
Port Filtering	Blocked unused or dangerous ports
Fail2Ban Rules	Banned bad SSH and Grafana login attempts
Node Template	Prepared hardened boot images for future nodes

🧠 Why This Matters
You’re not just building a lab — you’re modeling enterprise-grade, real-world infrastructure:

🔒 Least privilege

🚫 Brute force protection

🔍 Audit-ready logging

♻️ Hardened templates

And you did it with beginner-friendly tools that you can now apply to servers, cloud VMs, and production environments.



# Extra 


# Markdown content for the guide
markdown_content = """# 🛡️ Ticket 3 – Secure the PXE Server Using Firewalld and Fail2Ban

This guide provides a 1000+ word step-by-step security hardening walkthrough for your PXE boot server using Firewalld and Fail2Ban.

...

[Full content truncated for brevity — will be written to file]
"""

# Script to test SSH brute-force ban
ssh_test_script = """#!/bin/bash
# Simulate SSH brute-force to test Fail2Ban (run from another machine or container)
echo "[*] Testing brute-force on SSH... (you may get banned)"
for i in {1..6}; do
  ssh invaliduser@<pxe-server-ip> exit
done
"""