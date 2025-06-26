# 🔐 Ticket #20 – Users Cannot Login Due to PAM Misconfig

## 🧠 Problem Summary

Newly provisioned PXE nodes would not allow users to log in via SSH or local console. The error observed was:

Authentication failed
PAM: Authentication failure

yaml
Always show details

Copy

This rendered the nodes unusable post-boot.

---

## 🔍 Root Cause

- The container used to build the Warewulf nodes was **missing** the file `/etc/pam.d/common-auth`.
- This file is essential in PAM-based authentication stacks (especially in Debian/Ubuntu).
- Without it, PAM fails to validate credentials, leading to login denial.

---

## 🛠️ Solution: Add `common-auth` to Base Container and Rebuild Overlays

We fixed this issue by editing the container, adding the necessary PAM config, and rebuilding the overlays for PXE nodes.

---

### ✅ Step 1: Check Container for PAM Configs

Enter the container shell:

```bash
sudo wwctl container shell rocky9
Inspect the /etc/pam.d/ directory:

bash
Always show details

Copy
ls -la /etc/pam.d/
Check if common-auth exists:

bash
Always show details

Copy
cat /etc/pam.d/common-auth
If missing or empty, continue to next step.

✅ Step 2: Add common-auth File
Still within the container shell:

bash
Always show details

Copy
cat <<EOF > /etc/pam.d/common-auth
auth    required    pam_unix.so nullok_secure
EOF
Also confirm other PAM files exist like common-session, common-password, and common-account.

If needed, copy them from a known good system:

bash
Always show details

Copy
scp /etc/pam.d/common-* root@admin-node:/var/tmp/
Then inject them into container:

bash
Always show details

Copy
cp /var/tmp/common-* /etc/pam.d/
✅ Step 3: Rebuild the Container
Exit the container shell:

bash
Always show details

Copy
exit
Commit the changes:

bash
Always show details

Copy
sudo wwctl container build rocky9
✅ Step 4: Rebuild All Overlays
bash
Always show details

Copy
sudo wwctl overlay build --all
If you use node-specific overlays:

bash
Always show details

Copy
sudo wwctl overlay build --overlay node01
🧪 Script: patch_pam_auth.sh
bash
Always show details

Copy
#!/bin/bash

CONTAINER="rocky9"
TMP_PAM_FILE="/tmp/common-auth"

echo "📄 Creating PAM auth file..."
echo 'auth required pam_unix.so nullok_secure' > "$TMP_PAM_FILE"

echo "🔧 Injecting into container..."
sudo wwctl container shell $CONTAINER <<EOF
cp $TMP_PAM_FILE /etc/pam.d/common-auth
EOF

echo "🛠️ Rebuilding container..."
sudo wwctl container build $CONTAINER

echo "♻️ Rebuilding overlays..."
sudo wwctl overlay build --all

echo "✅ PAM config patched and system updated."
Make executable and run:

bash
Always show details

Copy
chmod +x patch_pam_auth.sh
./patch_pam_auth.sh
✅ Step 5: Validate
Reboot a node and test login:

bash
Always show details

Copy
ssh root@node01
Check auth logs:

bash
Always show details

Copy
journalctl -u sshd
Also check PAM validation:

bash
Always show details

Copy
grep pam /var/log/secure
✅ Final Checklist
Task	Status
PAM error verified on node	✅
common-auth added to container	✅
Container rebuilt	✅
Overlays rebuilt	✅
Logins successful post-reboot	✅

💭 Lessons Learned
Authentication systems on Linux often rely on PAM stacks, and missing config files can block all access.

Overlay-based PXE nodes must include all essential /etc/pam.d/* files or use dynamic sync.

Always inspect and log into containers interactively during image preparation to validate base config.