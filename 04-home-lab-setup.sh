

# 📁 Home Lab Documentation Bundle Structure

pxe-lab-docs/

├── README.md

├── 01_network_setup.md

├── 02_dhcp_config.md

├── 03_tftp_server.md

├── 04_warewulf_node_add.md

├── 05_overlay_container_build.md

├── 06_pxe_boot_troubleshooting.md

├── assets/

│   ├── pxe_flowchart.png

│   ├── tftp_config_example.png

│   └── wireshark_dhcp_offer.png

└── scripts/

    ├── check_dhcp.sh

    ├── rebuild_node.sh

    └── test_pxe_boot.sh

📄 README.md

# 🧰 PXE Boot + Warewulf Lab – Home Lab Documentation

Welcome to the PXE Boot and Cluster Provisioning Documentation Bundle. This repository documents a real-world PXE failure (and resolution) experienced in a home lab using Warewulf and Rocky Linux nodes.


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
wwctl node add rocky26 --ipaddr=192.168.200.60 --netdev=eth0 \

  --hwaddr=AA:BB:CC:DD:EE:60 --container=rockylinux-9-lab-10Feb25 --profile=default

# Rebuild overlays and bootstrap
wwctl overlay build

wwctl bootstrap build

For full step-by-step, see 03_pxe_boot_troubleshooting.md

🔗 Credits

🐺 Warewulf Project: https://warewulf.org

🐧 Maintainer: Your Name (Linux Engineer, Home Lab Advocate)





### 🗃️ Supporting File – `06_pxe_boot_troubleshooting.md`

Includes the full 1000-word doc we just wrote. Save it as a standalone reference.



### 🛠️ Example Scripts

#### `check_dhcp.sh`


#!/bin/bash

# Simple check for DHCP packets on eth0

echo "[+] Monitoring DHCP requests..."

tcpdump -i eth0 port 67 or port 68 -nn

rebuild_node.sh

- 

#!/bin/bash

NODE=$1

echo "[+] Rebuilding overlays and bootstrap for $NODE"

wwctl overlay build

wwctl bootstrap build

test_pxe_boot.sh


#!/bin/bash

tftp 192.168.200.25 <<EOF
get undionly.kpxe
EOF

# 🖼️ Assets Folder Suggestions

You can add visuals for clarity:

pxe_flowchart.png → Visual overview of DHCP + PXE + TFTP + container stages

tftp_config_example.png → Annotated screenshot of /etc/dhcp/dhcpd.conf

wireshark_dhcp_offer.png → Packet capture of successful PXE handshake