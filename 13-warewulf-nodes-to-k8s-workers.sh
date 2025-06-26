☸️ Task 4 – Expand into Kubernetes by Converting Warewulf Nodes into K8s Workers
Objective: Take your PXE-provisioned Warewulf nodes and elevate them into a real Kubernetes cluster — one that mimics enterprise-level orchestration in a home lab.

🧠 Why Kubernetes in a PXE Cluster?
You’ve already built a powerful PXE + Warewulf provisioning stack — nodes boot from containers, overlays are automated, and infrastructure is clean. Now, you want to scale services, run containers dynamically, and simulate microservice deployments like a real DevOps or SRE engineer.

Integrating Kubernetes means:

✅ Dynamic orchestration on top of statically provisioned hardware
✅ Scaling applications without touching bare metal
✅ Full CI/CD simulation in your lab
✅ Perfect match with monitoring tools (Prometheus, Grafana already installed)

🧰 Lab Topology
Component	Details
PXE/K8s Master	192.168.200.25, Rocky Linux, runs PXE, DHCP, TFTP, Prometheus, Grafana
Node1	rocky01, PXE-booted with Warewulf, will be k8s worker
Node2	rocky02, same as above
Overlay Setup	Each node already booted with SSH access, container base image: rockylinux-9-lab

We will:

Install kubeadm, kubelet, and kubectl

Initialize the control plane on the PXE server

Join Warewulf nodes as workers

Configure networking and visibility

🔧 Step 1: Prepare the PXE Server as Kubernetes Control Plane
🖥️ Disable swap (required by Kubernetes)
bash
Copy
Edit
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab
🔄 Load required kernel modules
bash
Copy
Edit
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system
📦 Install kubeadm, kubelet, and kubectl
bash
Copy
Edit
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
EOF

sudo dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet
☸️ Step 2: Initialize Kubernetes Master (PXE Server)
bash
Copy
Edit
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
Once done, it shows a kubeadm join command like:

bash
Copy
Edit
kubeadm join 192.168.200.25:6443 --token abcdef.0123456789abcdef \
--discovery-token-ca-cert-hash sha256:xxxxxxxx...
Save this.

⚙️ Configure kubectl for the current user
bash
Copy
Edit
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
Test it:

bash
Copy
Edit
kubectl get nodes
📡 Step 3: Install Pod Network (Flannel)
bash
Copy
Edit
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
Wait for:

bash
Copy
Edit
kubectl get pods -n kube-system
Ensure all are Running.

🧪 Step 4: Convert PXE-Provisioned Warewulf Nodes to Workers
📁 Step into container and install Kubernetes components
You must install these same tools inside your Warewulf container used for node provisioning.

bash
Copy
Edit
wwctl container exec rockylinux-9-lab -- bash -c "
yum install -y kubelet kubeadm --disableexcludes=kubernetes
systemctl enable kubelet
"
Rebuild container:

bash
Copy
Edit
wwctl container build rockylinux-9-lab
Update and reboot PXE-booted node:

bash
Copy
Edit
wwctl power cycle rocky01
🧬 Step 5: Join the Node to Kubernetes
On the booted node (rocky01):

bash
Copy
Edit
kubeadm join 192.168.200.25:6443 --token abcdef.0123456789abcdef \
--discovery-token-ca-cert-hash sha256:xxxxxxxx...
✅ Step 6: Validate in PXE Server (Control Plane)
bash
Copy
Edit
kubectl get nodes
You should see:

pgsql
Copy
Edit
NAME       STATUS   ROLES           AGE     VERSION
rocky01    Ready    <none>          1m      v1.29.x
Repeat the process for all PXE-booted nodes (e.g., rocky02, rocky03).

🧠 Bonus: Auto-Join on Boot (via Overlay)
Add the kubeadm join ... line into your runtime overlay’s startup script so PXE nodes automatically join K8s on every boot.

bash
Copy
Edit
vim overlays/generic/etc/rc.local
bash
Copy
Edit
#!/bin/bash
kubeadm join 192.168.200.25:6443 --token abcdef.0123456789abcdef \
--discovery-token-ca-cert-hash sha256:xxxxxxxx... || true
Make executable and rebuild:

bash
Copy
Edit
chmod +x overlays/generic/etc/rc.local
wwctl overlay build
📊 Monitoring Kubernetes in Grafana
You already have Prometheus + Grafana

Install Kube State Metrics for advanced K8s stats

Use pre-built Grafana dashboards:

ID: 315 – Kubernetes Cluster Monitoring

ID: 6417 – Kubelet performance

🔐 Secure Your Cluster
Use firewalld to only allow control traffic on 6443 from internal nodes

Enable PodSecurityPolicies or Gatekeeper

Enable audit logging in kube-apiserver

🧠 What You Accomplished
Task	Skill Gained
Installed kubeadm/kubelet	Core cluster building
Initialized control plane	Full Kubernetes orchestration
Converted PXE nodes to workers	Real-world hybrid infrastructure
Created reusable K8s nodes	Lab repeatability & automation
Linked K8s to Grafana	Complete observability stack


# Extra


# ☸️ Task 4 – Expand into Kubernetes by Converting Warewulf Nodes into K8s Workers

This guide explains how to convert PXE-booted Warewulf nodes into full Kubernetes workers, using kubeadm and overlays for reproducible lab environments.

...

[Full content provided in the previous assistant response]
"""

# Script to join node to Kubernetes
k8s_join_script = """#!/bin/bash
# Script to join PXE-provisioned node to Kubernetes cluster
# Replace with your actual values

K8S_MASTER_IP="192.168.200.25"
K8S_JOIN_TOKEN="abcdef.0123456789abcdef"
CA_CERT_HASH="sha256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

echo "[+] Joining Kubernetes cluster at ${K8S_MASTER_IP}..."
sudo kubeadm join ${K8S_MASTER_IP}:6443 --token ${K8S_JOIN_TOKEN} --discovery-token-ca-cert-hash ${CA_CERT_HASH}



