# 🛡️ Linux Cluster Security Stack – AIDE + LDAP + Rsyslog

## 🧩 Overview

This real-world implementation hardens a Linux PXE-booted cluster with three open-source security tools:

- **AIDE (Advanced Intrusion Detection Environment):** Monitors file system integrity
- **OpenLDAP:** Centralized user authentication and access control
- **Rsyslog:** Centralized logging from all nodes to a secure log aggregation server

All tools are installed and configured in the base container for Warewulf-managed PXE nodes, then deployed cluster-wide.

---

## 🔐 Part 1: AIDE – Host-Based Intrusion Detection

### ✅ Step 1: Install AIDE in Container

```bash
sudo wwctl container shell rocky9
dnf install -y aide
✅ Step 2: Initialize AIDE DB
bash
Always show details

Copy
aide --init
cp /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
✅ Step 3: Create Daily AIDE Check Cron Job
bash
Always show details

Copy
echo '0 3 * * * root /usr/sbin/aide --check | mail -s "AIDE Daily Report" root' > /etc/cron.d/aide-check
✅ Step 4: Add Exclusions in /etc/aide.conf
bash
Always show details

Copy
echo "!/var/log" >> /etc/aide.conf
echo "!/proc" >> /etc/aide.conf
echo "!/dev" >> /etc/aide.conf
Exit and rebuild:

bash
Always show details

Copy
exit
sudo wwctl container build rocky9
sudo wwctl overlay build --all
👥 Part 2: OpenLDAP – Centralized Authentication
✅ Step 1: Install LDAP Client on Container
bash
Always show details

Copy
sudo wwctl container shell rocky9
dnf install -y openldap openldap-clients nss-pam-ldapd
✅ Step 2: Configure /etc/nslcd.conf
bash
Always show details

Copy
cat <<EOF > /etc/nslcd.conf
uid nslcd
gid nslcd
uri ldap://192.168.1.1/
base dc=example,dc=com
binddn cn=admin,dc=example,dc=com
bindpw secretpassword
EOF
✅ Step 3: Enable LDAP Login
bash
Always show details

Copy
authselect select sssd with-mkhomedir --force
systemctl enable --now nslcd
✅ Step 4: Test LDAP Users
bash
Always show details

Copy
getent passwd
id ldapuser01
Exit and rebuild:

bash
Always show details

Copy
exit
sudo wwctl container build rocky9
sudo wwctl overlay build --all
🪵 Part 3: Rsyslog – Centralized Logging
✅ Step 1: Setup Rsyslog on Admin Node (Log Server)
bash
Always show details

Copy
dnf install -y rsyslog
vi /etc/rsyslog.conf
Uncomment and set:

conf
Always show details

Copy
module(load="imudp")
input(type="imudp" port="514")
$AllowedSender UDP, 192.168.0.0/16
Enable:

bash
Always show details

Copy
systemctl enable --now rsyslog
firewall-cmd --permanent --add-port=514/udp
firewall-cmd --reload
✅ Step 2: Configure Clients in PXE Container
bash
Always show details

Copy
sudo wwctl container shell rocky9
echo "*.* @192.168.1.1:514" >> /etc/rsyslog.conf
systemctl enable rsyslog
exit
sudo wwctl container build rocky9
sudo wwctl overlay build --all
✅ Step 3: Reboot and Validate
bash
Always show details

Copy
ssh root@node01
logger "This is a test log from node01"
On log server:

bash
Always show details

Copy
tail -f /var/log/messages
🔁 Script Automation Example: secure_cluster_stack.sh
bash
Always show details

Copy
#!/bin/bash

echo "🔒 Installing security tools in container..."

sudo wwctl container shell rocky9 <<EOF
dnf install -y aide openldap-clients nss-pam-ldapd rsyslog

# AIDE Init
aide --init
cp /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz

# AIDE Cron
echo '0 3 * * * root /usr/sbin/aide --check' > /etc/cron.d/aide-check

# LDAP Config
cat <<EOC > /etc/nslcd.conf
uid nslcd
gid nslcd
uri ldap://192.168.1.1/
base dc=example,dc=com
binddn cn=admin,dc=example,dc=com
bindpw secretpassword
EOC
systemctl enable nslcd
authselect select sssd with-mkhomedir --force

# Rsyslog Forwarding
echo '*.* @192.168.1.1:514' >> /etc/rsyslog.conf
systemctl enable rsyslog
EOF

echo "🛠️ Rebuilding container and overlays..."
sudo wwctl container build rocky9
sudo wwctl overlay build --all
✅ Final Checklist
Component	Configured	Validated
AIDE	✅	✅
OpenLDAP	✅	✅
Rsyslog	✅	✅

🧠 Lessons Learned
AIDE helps detect rootkits, unauthorized edits, and binary changes on each node.

OpenLDAP streamlines user and group management across large clusters.

Rsyslog enables centralized forensics and monitoring—critical for compliance.

These services must be in the container before PXE provisioning; overlay rebuilds help deploy changes instantly.
