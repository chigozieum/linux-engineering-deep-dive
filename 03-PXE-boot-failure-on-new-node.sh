# 📄 Ticket #1 – PXE Boot Failure on New Node

## 🧠 Summary

A new compute node (`rocky26`) added to the cluster failed to boot via PXE. Although the node received an IP address from the DHCP server, it did **not receive a boot filename**, leading to BIOS fallback:

No bootable device found

PXE-E53: No boot filename received

---

## ⏱️ Impact

- Node `rocky26` could not join the Warewulf-provisioned cluster.
- PXE automation and lab testing were delayed.
- Other nodes booted correctly, indicating this was an isolated issue.

---

## 🧰 Environment Details

| Component        |                  Value         |

|------------------|--------------------------------|

| PXE Stack        | Warewulf v4 + iPXE + DHCP + TFTP |

| DHCP Server      | `dhcpd` on `192.168.200.25`     |

| TFTP Root        | `/var/lib/tftpboot/`            |

| Node Config Tool | `wwctl`                         |

| Network Range    | `192.168.200.0/24`              |

---

## 🔍 Step-by-Step Investigation

### ✅ Step 1: Confirm Node Powers On & PXE Attempt Appears

Use physical access or IPMI to verify that PXE boot is triggered and displays DHCP messages.

---

### 🔍 Step 2: Verify Node Exists in Warewulf

```sh
wwctl node list | grep rocky26

# If missing, add it:


wwctl node add rocky26 --ipaddr=192.168.200.60 \

  --netdev=eth0 \

  --hwaddr=AA:BB:CC:DD:EE:60 \

  --container=rockylinux-9-lab-10Feb25 \

  --profile=default

wwctl overlay build

wwctl bootstrap build

### 🔍 Step 3: Test DHCP Server Response

tcpdump -i eth0 port 67 or port 68 -nn

Look for a DHCPDISCOVER and DHCPOFFER exchange. If not seen:

Check MAC entry in wwctl

Validate dhcpd is running and bound to correct interface

### 🔍 Step 4: Validate DHCP Configuration

vim /etc/dhcp/dhcpd.conf

Ensure subnet entry includes:


subnet 192.168.200.0 netmask 255.255.255.0 {

  range 192.168.200.50 192.168.200.99;

  option routers 192.168.200.1;

  option broadcast-address 192.168.200.255;

  next-server 192.168.200.25;

  filename "undionly.kpxe";

}

Restart and validate config:


systemctl restart dhcpd

systemctl status dhcpd

dhcpd -t -cf /etc/dhcp/dhcpd.conf

### 🔍 Step 5: Confirm TFTP Server is Running

systemctl status tftp

Ensure file exists:


ls -lh /var/lib/tftpboot/undionly.kpxe

If missing:


cp /usr/share/ipxe/undionly.kpxe /var/lib/tftpboot/

chmod 644 /var/lib/tftpboot/undionly.kpxe

Test TFTP file delivery:


tftp 192.168.200.25

tftp> get undionly.kpxe

### 🔍 Step 6: Confirm MAC Address in Warewulf

wwctl node list rocky26 -o yaml

Ensure output contains:


NetDevs:

  default:

    HWaddr: "AA:BB:CC:DD:EE:60"

If incorrect:


wwctl node set rocky26 --netdevs.default.hwaddr=AA:BB:CC:DD:EE:60

wwctl overlay build

### 🔍 Step 7: Confirm Bootstrap Was Built

wwctl bootstrap list

If not found:


wwctl bootstrap build rockylinux-9-lab-10Feb25

### 🔍 Step 8: Watch Node and Server Logs
Node should show PXE failure lines:


DHCP......

PXE-E53: No boot filename received

PXE-M0F: Exiting Intel PXE ROM

Server logs:


journalctl -u dhcpd -f

journalctl -u tftp -f

# 🧽 Fixes Applied

✅ Corrected DHCP Boot Parameters

In /etc/dhcp/dhcpd.conf:


filename "undionly.kpxe";

next-server 192.168.200.25;

Restarted DHCP:


systemctl restart dhcpd

✅ Rebuilt Container and Overlays

wwctl container import docker://rockylinux:9 rockylinux-9-lab

wwctl overlay build

wwctl bootstrap build

✅ Updated Node Information


wwctl node set rocky26 \

  --ipaddr=192.168.200.60 \

  --netdevs.default.hwaddr=AA:BB:CC:DD:EE:60 \

  --container=rockylinux-9-lab-10Feb25 \

  --profile=default

# 📊 Results

✅ Node received DHCP lease

✅ Node retrieved undionly.kpxe via TFTP

✅ iPXE boot continued

✅ Rocky Linux container loaded successfully

✅ rocky26 joined the cluster

# 🔐 Long-Term Improvements

PXE Monitoring:

Integrate PXE boot failure detection into Prometheus/Grafana or Zabbix

Dynamic MAC Discovery:

Use wwctl node add --discover for plug-and-play provisioning

PXE Alerting:

Add journalctl + fail2ban rules for:

PXE-E53

Missing TFTP boot file

# 📁 File Summary

File	Purpose

/etc/dhcp/dhcpd.conf	DHCP server config for PXE

/var/lib/tftpboot/undionly.kpxe	PXE boot binary served over TFTP

/etc/warewulf/warewulf.conf	Cluster + PXE node settings

/etc/systemd/system/tftp.service	TFTP socket and daemon configuration

### 💬 Final Thoughts
PXE booting is foundational for high-scale infrastructure. It's fragile when misconfigured but mighty when automated.

This ticket reinforced:

✅ Importance of DHCP + TFTP synergy

✅ Accuracy of MAC + IP mappings

✅ Maintaining versioned containers and overlays

You're not just fixing PXE boot errors—
You're engineering infrastructure that rebuilds itself.