# 🧰 PXE Boot + Warewulf Lab – Home Lab Documentation

Welcome to the PXE Boot and Cluster Provisioning Documentation Bundle. This repository documents a real-world PXE failure (and resolution) experienced in a home lab using Warewulf and Rocky Linux nodes.

---

## 📚 Contents

| File | Description |

|------|-------------|

| `01_network_setup.md` | IP subnetting, DHCP ranges, static IPs |

| `02_dhcp_config.md` | DHCP config and best practices |

| `03_tftp_server.md` | TFTP setup for PXE file delivery |

| `04_warewulf_node_add.md` | Adding new nodes via Warewulf |

| `05_overlay_container_build.md` | Containerized image creation and deployment |

| `06_pxe_boot_troubleshooting.md` | Detailed 1000-word real ticket fix |

| `scripts/` | Shell utilities to automate diagnostics |

| `assets/` | Flowcharts and screenshots |




## 🧠 Use Case

This documentation is ideal for:

- Home labbers building clusters
- Researchers deploying compute nodes
- Educators teaching PXE, DHCP, and overlay-based Linux provisioning
- Beginners who want real-world Linux automation scenarios



## ✅ Required Tools

- Warewulf v4+
- Rocky Linux 9 (or CentOS/RHEL)
- DHCP (`dhcpd`)
- TFTP (`tftp-server`)
- iPXE binaries
- NFS for `/opt`, `/home`, or `/labs` (optional)



## 💡 Recommended Hardware

- 1 Management Node (e.g., VirtualBox VM or mini PC)
- 2–10 PXE Bootable Nodes (physical or virtual)
- Switch or router with PXE-friendly config


## 🚀 Quickstart Command


# Add node to Warewulf
wwctl node add rocky26 --ipaddr=192.168.200.60 --netdev=eth0 \\
  --hwaddr=AA:BB:CC:DD:EE:60 --container=rockylinux-9-lab-10Feb25 --profile=default

# Rebuild overlays and bootstrap
wwctl overlay build
wwctl bootstrap build
For full step-by-step, see 06_pxe_boot_troubleshooting.md

# 🔗 Credits

🐺 Warewulf Project: https://warewulf.org

🐧 Maintainer: @Ugo_Neth (Linux Engineer, Home Lab Advocate)
""",

# PXE Boot Failure on New Node

## Issue New node failed PXE boot with message: “No bootable device found”.
# Environment- PXE: Warewulf + iPXE + DHCP + TFTP\n- DHCP: 192.168.200.25
TFTP root: /var/lib/tftpboot - Node: rocky26

## Troubleshooting Steps
- Verify node appears in Warewulf:\nbash\nwwctl node list | grep rocky26\n\n\n

- Check DHCP config:\nbash\nvim /etc/dhcp/dhcpd.conf\n\nEnsure:\nconf\nfilename \"undionly.kpxe\";\nnext-server 192.168.200.25;\n\nRestart service:\nbash\nsystemctl restart dhcpd\n\n\n

- Confirm TFTP:\nbash\nls -l /var/lib/tftpboot/undionly.kpxe\n\n\n

- Check MAC address mapping:\nbash\nwwctl node set rocky26 --netdevs.default.hwaddr=AA:BB:CC:DD:EE:60\n\n\n

- Rebuild overlays and bootstrap:\nbash\nwwctl overlay build\nwwctl bootstrap build.

- Reboot node and observe PXE screen.

## Resolution

Corrected DHCP, rebuilt container, node successfully booted into cluster.

## Prevention\n- 

Auto-discover MACs with wwctl node add --discover\n- Monitor TFTP and DHCP logs\n- Use version control on /etc/dhcp/dhcpd.conf\n"



## Write files to the base directory

for filename, content in files.items():

with open(os.path.join(base_dir, filename), "w") as f:

f.write(content)

##  Create sample scripts

scripts = {

"check_dhcp.sh": "#!/bin/bash\necho "[+] Monitoring DHCP requests..."\ntcpdump -i eth0 port 67 or port 68 -nn",

"rebuild_node.sh": "#!/bin/bash\nNODE=$1\necho "[+] Rebuilding overlays and bootstrap for $NODE"\nwwctl overlay build\nwwctl bootstrap build",

"test_pxe_boot.sh": "#!/bin/bash\ntftp 192.168.200.25 <<EOF\nget undionly.kpxe\nEOF"

}

for script_name, script_content in scripts.items():

script_path = os.path.join(base_dir, "scripts", script_name)

with open(script_path, "w") as f:

f.write(script_content)
os.chmod(script_path, 0o755)

import shutil

shutil.make_archive("/mnt/data/pxe-lab-docs", 'zip', base_dir)