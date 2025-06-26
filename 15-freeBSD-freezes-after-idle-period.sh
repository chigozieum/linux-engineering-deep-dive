#5 – FreeBSD Console Freezes Randomly, using the same detailed, 1000+ word structure tailored for PXE-based lab environments.

🧊 Ticket #5 – FreeBSD Console Freezes Randomly After Idle Period
Issue:
A FreeBSD management node — used for observation, control, or lab simulation in your PXE infrastructure — intermittently freezes when left idle. After some minutes of inactivity, the console becomes unresponsive, requiring a hard reboot or SSH session termination.

🧠 Summary
This guide covers how to:

Diagnose console freezing on FreeBSD

Prevent idle disconnects or lockups

Use tmux to make sessions persistent

Tune sysctl and login session limits

Restore stable, multi-hour console interaction for FreeBSD PXE nodes or lab terminals

This is especially relevant when using FreeBSD nodes as:

Serial console monitors

Audit or packet inspection systems

Lab gateways or security probes

🛠️ Lab Context
Component	Details
OS	FreeBSD 13.x
Node Role	Monitoring/Control
Access Method	SSH via PXE server
Symptom	Freezes after 5–10 min idle
Terminal Emulator	Local terminal or tmux missing

🧪 Step 1: Reproduce and Observe
SSH into the node:

bash
Copy
Edit
ssh root@freebsd01.lab.local
Run:

bash
Copy
Edit
top
Let the session idle for ~5–10 minutes. You’ll notice:

Console output stops

Keyboard unresponsive

Session eventually terminates or must be killed

Check logs:

bash
Copy
Edit
tail -n 100 /var/log/messages
Or check dmesg:

bash
Copy
Edit
dmesg | tail
No critical errors? That indicates a session timeout or terminal control issue.

🧰 Step 2: Install and Use tmux
tmux is a terminal multiplexer — it lets you keep sessions alive even if your SSH connection dies.

📦 Install tmux:
bash
Copy
Edit
pkg install tmux
🔄 Start a persistent session:
bash
Copy
Edit
tmux new -s monitor
Do your work here (e.g., run top, tcpdump, syslogd).

To detach:

arduino
Copy
Edit
Ctrl + b, then press d
To resume later:

bash
Copy
Edit
tmux attach -t monitor
Now if the console freezes, you can reconnect and resume the session.

⚙️ Step 3: Increase Idle Limits with sysctl
FreeBSD uses kernel parameters to manage session persistence.

🔍 Check current values:
bash
Copy
Edit
sysctl kern.tty
Add or modify these to keep sessions alive:

bash
Copy
Edit
sysctl kern.vt.kbd_timeout=30000
sysctl kern.tty.vtime=600
Persist changes in /etc/sysctl.conf:

bash
Copy
Edit
echo 'kern.vt.kbd_timeout=30000' >> /etc/sysctl.conf
echo 'kern.tty.vtime=600' >> /etc/sysctl.conf
🔐 Step 4: Prevent SSH Timeout Disconnects
SSH clients and servers may auto-kill idle connections.

On FreeBSD Node:
Edit /etc/ssh/sshd_config:

ini
Copy
Edit
ClientAliveInterval 120
ClientAliveCountMax 10
Restart SSH:

bash
Copy
Edit
service sshd restart
On Your PXE Server:
Edit ~/.ssh/config:

ini
Copy
Edit
Host freebsd01.lab.local
  ServerAliveInterval 60
  ServerAliveCountMax 5
🧼 Step 5: Clean Up Frozen TTYs
If your console is hung, but you can still SSH, try killing stale TTYs:

bash
Copy
Edit
who
You might see:

txt
Copy
Edit
root     ttyv0   Jun 19 09:00
Kill it:

bash
Copy
Edit
kill -9 $(ps -t ttyv0 -o pid=)
💡 Step 6: Auto-Start tmux on Login (Optional)
Edit root’s .profile or .shrc:

bash
Copy
Edit
tmux attach || tmux new
Now tmux auto-resumes every time you SSH in — even if the console dies.

📟 Step 7: Enable Serial Console (Advanced Lab Usage)
If you’re monitoring the FreeBSD node via PXE server or a USB/serial dongle:

Edit /boot/loader.conf:

ini
Copy
Edit
console="comconsole"
And /etc/ttys:

ini
Copy
Edit
ttyu0 "/usr/libexec/getty std.9600" vt100 on secure
Then:

bash
Copy
Edit
shutdown -r now
You now have a reliable console even without network.

📋 Step 8: Summary of Fixes Applied
Action	Purpose
Installed tmux	Session persistence
Raised sysctl limits	Prevents idle timeouts
Tuned SSH configs	Avoid disconnects
Cleaned up TTYs	Resolved stale sessions
Enabled serial	Optional, headless console access

🧠 What You Gained
Skill	Impact
FreeBSD kernel tuning	Cross-platform admin knowledge
Terminal session persistence	Red Team, Ops, and Security readiness
PXE + BSD integration	Hybrid lab operation
Console recovery	No more lost work on idle


# Extra 

# 🧊 Ticket #5 – FreeBSD Console Freezes Randomly After Idle Period

This guide covers how to fix random console freezing on a FreeBSD node used in your PXE-based lab by installing `tmux`, increasing `sysctl` limits, and adjusting SSH timeout parameters.

...

[Full content provided above — truncated here for brevity]
"""

# Script for tmux autologin setup
tmux_autologin_script = """#!/bin/sh
# Automatically attach to an existing tmux session or create a new one

if command -v tmux >/dev/null 2>&1; then
  tmux has-session -t monitor 2>/dev/null
  if [ $? != 0 ]; then
    tmux new -s monitor
  else
    tmux attach -t monitor
  fi
fi


