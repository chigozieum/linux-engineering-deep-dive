# 🛠️ Real-World Linux Engineering Tickets from the Field

These are real-world Linux engineering tickets I’ve encountered (or that someone in a similar role would face) during a career focused on:

- 🔁 Automation  

- 🧱 Infrastructure as Code  

- 🌐 PXE Booting & Network Provisioning  

- 📦 Container Deployment (Warewulf)  

- 📡 DHCP/TFTP  

- 🗃️ NFS File Sharing  

- 🧮 FreeBSD Systems  

- 🧠 System Observability  

particularly in environments using Warewulf, Rocky Linux RHEL.

🛠️ 18+ Linux Engineering Tickets from the Field

### 1. PXE Boot Failure on New Node

**Description:**

Node fails to boot via PXE; screen stuck on **“No bootable device found.”**

**Resolution:**  
- Verified DHCP configuration (`dhcpd.conf`)  
- Fixed typo in `next-server` entry  
- Confirmed TFTP server was active (`systemctl status tftp`)  
- Regenerated PXE boot menu with `wwctl configure`


### 2. Warewulf Container Not Mounting
**Description:**  
Node boots but fails to mount the **root overlay**.

**Resolution:**  
- Checked overlay logs in `/var/log/warewulf/`  
- Discovered missing container image  
- Rebuilt with `wwctl container build rockylinux-9-lab`


### 3. DHCP IP Range Conflict
**Description:**  
Two nodes receive the **same IP**, causing collisions.

**Resolution:**  
- Updated DHCP range in `/etc/warewulf/warewulf.conf`  
- Ensured unique MAC addresses across node configs


### 4. Kernel Panic on Boot
**Description:**  
Node enters **kernel panic** during PXE boot.

**Resolution:**  
- Rolled back to working kernel in container  
- Removed invalid `crashkernel` flag from `Kernel.Args`


### 5. FreeBSD Console Freezes Randomly
**Description:**  
FreeBSD management node freezes after being idle.

**Resolution:**  
- Installed `tmux` to manage terminal sessions  
- Increased idle timeout via `sysctl.conf`

### 6. Warewulf Daemon Crash After Container Update
**Description:**  
`wwd` daemon crashes during overlay rebuild.

**Resolution:**  
- Traced issue to misconfigured path in `warewulf.conf`  
- Applied GitHub patch  
- Restarted `wwd` daemon


### 7. NFS Write Errors on Mounted Home Directory
**Description:**  
Users get **Permission denied** on `/home`.

**Resolution:**  
- Updated NFS export to use `no_root_squash`  
- Verified UID/GID consistency between NFS server and nodes

### 8. Inconsistent DNS Resolution in Cluster Nodes
**Description:**  
Some nodes resolve `*.lab.local`, others do not.

**Resolution:**  
- Deployed `dnsmasq` on a central node  
- Rebuilt overlays with correct `/etc/resolv.conf`

### 9. TFTP Boot File Not Found
**Description:**  
PXE boot reports: **“file not found”**.

**Resolution:**  
- Verified contents of `/var/lib/tftpboot`  
- Corrected file permissions  
- Re-symlinked `undionly.kpxe`

### 10. Slow Overlay Deployment
**Description:**  
Node takes **4+ minutes** to apply overlays.

**Resolution:**  
- Optimized overlay files  
- Cleaned `.old` containers  
- Enabled parallel builds with `wwctl overlay build --parallel`

### 11. Log Flood from systemd-resolved
**Description:**  
`/var/log/messages` grows rapidly with **DNS errors**.

**Resolution:**  
- Disabled `systemd-resolved`  
- Set static `/etc/resolv.conf`  
- Reduced `journald` verbosity

### 12. Storage Node Not Mounting at Boot
**Description:**  
NFS mount `/mnt/data` fails during boot.

**Resolution:**  
- Created a custom `systemd` unit for NFS  
- Ensured dependency on `network-online.target`

### 13. Overlays Missing SSH Keys
**Description:**  
Node boots but **SSH access is denied**.

**Resolution:**  
- Injected `authorized_keys` via overlay  
- Rebuilt runtime overlay  
- Verified SSH public key propagation

### 14. Wrong Hostname Set After Boot
**Description:**  
All nodes set hostname to `rocky9`.

**Resolution:**  
- Edited overlay or profile template  
- Enabled dynamic hostname injection using node name

### 15. Load Balancer Dropping Node Health
**Description:**  
Newly deployed node is **removed from pool**.

**Resolution:**  
- Identified incorrect SSH port in container  
- Updated `sshd_config`  
- Rebuilt and redeployed container

### 16. Users Cannot Login Due to PAM Misconfig
**Description:**  
Authentication fails with **PAM module error**.

**Resolution:**  
- Added missing `/etc/pam.d/common-auth` to overlay  
- Rebuilt overlay and applied to nodes

### 17. TFTP Port Blocked by Firewall
**Description:**  
PXE boot doesn’t work from a **remote subnet**.

**Resolution:**  

- firewall-cmd --add-port=69/udp --permanent

- firewall-cmd --reload

### 18. Cluster Time Drift
**Description:**
NTP not syncing properly on multiple nodes, Multiple nodes show inconsistent system clocks.

**Resolution:** 
- Replaced ntpd with chrony

- Configured chrony.conf and enabled service

- Verified sync using chronyc tracking 

- Confirmed ntpd conflict resolved.

- Configured chrony.conf.

- Added chrony to base image.



## ➕ And More...

- Auto-registering MACs with dnsmasq

- Automating container rebuilds with Git hooks

- Overlay-based GPG provisioning for secure boot nodes

- Visual dashboard for overlay status monitoring

- CI/CD pipelines for node image updates