# 🔐 Ticket #17 – Overlays Missing SSH Keys

## 🧠 Problem Summary

After provisioning new PXE nodes using Warewulf, an issue was discovered:

- Nodes booted successfully
- However, `ssh root@nodeX` failed with:
Permission denied (publickey).

yaml
Always show details

Copy

Despite setting up SSH keys for cluster-wide access, nodes were missing `~/.ssh/authorized_keys`. Investigation showed that the overlay did not include the appropriate SSH keys.

---

## 🔍 Root Cause

- The `authorized_keys` file was **not included** in the overlay assigned to the node.
- Warewulf overlays must be rebuilt after modifying contents (SSH keys in this case).
- Node-specific SSH keys were not dynamically inserted during node creation.

---

## 🛠️ Step-by-Step Resolution

We fixed this by properly injecting the SSH public key into the node’s overlay using Warewulf’s `overlay` system and verified successful provisioning.

---

### ✅ Step 1: Generate SSH Key (if not existing)

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
Copy the public key:

bash
Always show details

Copy
cat ~/.ssh/id_rsa.pub
✅ Step 2: Create or Edit the Overlay File
Assuming the overlay is default, create a file for SSH keys:

bash
Always show details

Copy
sudo mkdir -p /var/lib/warewulf/overlays/default/root/.ssh
sudo tee /var/lib/warewulf/overlays/default/root/.ssh/authorized_keys <<EOF
ssh-rsa AAAAB3... your-public-key-here ... user@host
EOF
Set proper permissions:

bash
Always show details

Copy
sudo chmod 700 /var/lib/warewulf/overlays/default/root/.ssh
sudo chmod 600 /var/lib/warewulf/overlays/default/root/.ssh/authorized_keys
✅ Step 3: Rebuild Overlay
bash
Always show details

Copy
sudo wwctl overlay build --overlay default
If you're assigning overlays node-by-node:

bash
Always show details

Copy
sudo wwctl overlay build --all
✅ Step 4: Assign Overlay to Node (Optional)
If default is not yet assigned:

bash
Always show details

Copy
sudo wwctl node set node01 --overlay default
Confirm:

bash
Always show details

Copy
wwctl node list
✅ Step 5: Confirm Overlay Was Applied
After booting node01, log in via console or ipmitool and verify:

bash
Always show details

Copy
ls -l /root/.ssh/authorized_keys
If missing, confirm overlay content with:

bash
Always show details

Copy
sudo wwctl overlay export default | tar -tvf -
Look for:

bash
Always show details

Copy
./root/.ssh/authorized_keys
🧪 Script to Automate Overlay SSH Key Injection
bash
Always show details

Copy
#!/bin/bash

KEYFILE="$HOME/.ssh/id_rsa.pub"
OVERLAY_DIR="/var/lib/warewulf/overlays/default/root/.ssh"

if [ ! -f "$KEYFILE" ]; then
  echo "❌ SSH public key not found at $KEYFILE"
  exit 1
fi

echo "🔧 Creating SSH key directory..."
sudo mkdir -p "$OVERLAY_DIR"

echo "📄 Injecting authorized_keys..."
sudo cp "$KEYFILE" "$OVERLAY_DIR/authorized_keys"

echo "🔐 Setting permissions..."
sudo chmod 700 "$(dirname "$OVERLAY_DIR")"
sudo chmod 600 "$OVERLAY_DIR/authorized_keys"

echo "🛠️ Rebuilding overlay..."
sudo wwctl overlay build --overlay default

echo "✅ SSH key injected successfully."
Save as inject_ssh_key.sh:

bash
Always show details

Copy
chmod +x inject_ssh_key.sh
./inject_ssh_key.sh
✅ Final Validation
From your admin node:

bash
Always show details

Copy
ssh root@node01
Should now allow access without password.

✅ Final Checklist
Task	Status
SSH key generated and saved	✅
Overlay .ssh/authorized_keys created	✅
Permissions set (700/600)	✅
Overlay rebuilt	✅
SSH login confirmed	✅

💭 Lessons Learned
Overlays are static until rebuilt — changes won’t take effect without explicit rebuild.

SSH keys are a vital part of initial cluster access automation.

Use overlay export to verify what a node receives during boot.
