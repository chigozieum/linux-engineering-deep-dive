🧠 Install Prometheus + Grafana on the PXE Server for Monitoring
Length: 1000+ words | Focus: Home lab environment using Warewulf + Rocky Linux 9

🧰 Goal
You're running a PXE server to provision nodes using Warewulf. But without visibility, you're flying blind.

So, in this guide, we’ll turn your PXE server into a full-fledged monitoring node using:

🔍 Prometheus – time-series metrics collection

📊 Grafana – interactive dashboards

🧭 Node Exporter – lightweight metrics exporter for the server and Warewulf nodes

🧭 Step 1: Update and Prep the PXE Server
Before you install anything, always update:

bash
Copy
Edit
sudo dnf update -y
sudo dnf install wget curl vim tar -y
Check your hostname and IP:

bash
Copy
Edit
hostnamectl
ip a
Assume your PXE server IP is 192.168.200.25.

📦 Step 2: Install Prometheus
🔽 Download the Latest Prometheus Release
bash
Copy
Edit
cd /opt
sudo useradd --no-create-home --shell /bin/false prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.49.1/prometheus-2.49.1.linux-amd64.tar.gz
tar -xvf prometheus-2.49.1.linux-amd64.tar.gz
mv prometheus-2.49.1.linux-amd64 prometheus
🗃️ Organize the Directories
bash
Copy
Edit
sudo mkdir -p /etc/prometheus /var/lib/prometheus
sudo cp prometheus/prometheus /usr/local/bin/
sudo cp prometheus/promtool /usr/local/bin/
sudo cp -r prometheus/consoles /etc/prometheus
sudo cp -r prometheus/console_libraries /etc/prometheus
📝 Step 3: Create Prometheus Configuration
Edit config:

bash
Copy
Edit
sudo vim /etc/prometheus/prometheus.yml
Paste:

yaml
Copy
Edit
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: "node_exporter"
    static_configs:
      - targets: ["localhost:9100", "192.168.200.51:9100", "192.168.200.52:9100"]
Replace IPs with your Warewulf nodes.

🔧 Step 4: Create Prometheus Systemd Service
bash
Copy
Edit
sudo vim /etc/systemd/system/prometheus.service
Paste:

ini
Copy
Edit
[Unit]
Description=Prometheus Monitoring
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus

[Install]
WantedBy=default.target
Set ownership:

bash
Copy
Edit
sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
Enable and start:

bash
Copy
Edit
sudo systemctl daemon-reexec
sudo systemctl enable --now prometheus
sudo systemctl status prometheus
Check if it’s listening:

bash
Copy
Edit
ss -tulnp | grep 9090
📈 Step 5: Install Node Exporter
For metrics from the PXE server:

bash
Copy
Edit
cd /opt
wget https://github.com/prometheus/node_exporter/releases/download/v1.8.1/node_exporter-1.8.1.linux-amd64.tar.gz
tar -xvf node_exporter-1.8.1.linux-amd64.tar.gz
sudo cp node_exporter-1.8.1.linux-amd64/node_exporter /usr/local/bin/
Create service:

bash
Copy
Edit
sudo useradd -rs /bin/false node_exporter
sudo vim /etc/systemd/system/node_exporter.service
Paste:

ini
Copy
Edit
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=default.target
Start it:

bash
Copy
Edit
sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter
Now both:

Prometheus is running on :9090

Node Exporter is on :9100

🎨 Step 6: Install Grafana on Rocky Linux 9
Add Grafana repo:

bash
Copy
Edit
sudo tee /etc/yum.repos.d/grafana.repo<<EOF
[grafana]
name=Grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
EOF
Install:

bash
Copy
Edit
sudo dnf install grafana -y
Start and enable:

bash
Copy
Edit
sudo systemctl enable --now grafana-server
Check it:

bash
Copy
Edit
ss -tulnp | grep 3000
🌐 Step 7: Access Prometheus and Grafana via Browser
Prometheus: http://192.168.200.25:9090

Grafana: http://192.168.200.25:3000

Default Grafana credentials:

admin

admin (will prompt you to change)

📊 Step 8: Add Prometheus as a Data Source in Grafana
Login to Grafana

Go to Settings → Data Sources

Click Add Data Source

Choose Prometheus

URL: http://localhost:9090

Click Save & Test

📈 Step 9: Import a Dashboard
Go to Dashboard → Import

Use popular Node Exporter ID: 1860 or 8919

Select Prometheus as data source

View real-time CPU, RAM, disk, and network metrics!

📍 Optional: Monitor Your Warewulf Nodes
You can install Node Exporter on each provisioned node by:

Embedding the binary in your Warewulf container image

Adding it to an overlay (like /usr/local/bin)

Creating a systemd unit in the runtime overlay

Once each node is listening on :9100, Prometheus will auto-pull metrics from them.

🔐 Security Tip: Protect Grafana with a Reverse Proxy + HTTPS
If this will be used outside your LAN, use:

Nginx + Let’s Encrypt for HTTPS termination

Fail2Ban to block brute-force Grafana attempts

Firewalld to restrict Grafana and Prometheus access

(Detailed in the next guide.)

🧪 Verify End-to-End
Tool	URL	Test
Prometheus	http://<ip>:9090/targets	All targets = UP
Node Exp.	http://<ip>:9100/metrics	See metrics page
Grafana	http://<ip>:3000	Dashboard loads

🧠 Summary
With Prometheus + Grafana running on your PXE server, you've unlocked a full observability stack:

📈 Real-time metrics

📊 Custom dashboards

🔍 Drill-down into node CPU, memory, disk I/O

📦 Optional alerting (via Alertmanager later)

You’ve just transformed your home lab from a black box into a data-rich observability platform.