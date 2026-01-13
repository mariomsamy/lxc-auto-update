# LXC Auto Update for Proxmox VE

Automated updates for **Proxmox VE LXC containers**, designed specifically to work with  
**Proxmox VE Helper-Scripts** containers that are commonly updated using the `update` command.

This tool updates **only running LXC containers** and safely ignores stopped ones.

---

## 📌 What is this for?

Many **Proxmox VE Helper-Scripts** containers include an interactive updater:

```bash
update
````

That command is not suitable for automation.

This project provides a **safe, non-interactive, automation-friendly solution** that:

* Runs on the **Proxmox VE host**
* Updates **running LXC containers only**
* Works with Helper-Scripts containers
* Uses the container’s native package manager (apt, apk, dnf, yum, etc.)
* Runs automatically on a schedule using `systemd`

---

## ✨ Features

* ✅ **Proxmox VE only**
* ✅ **LXC containers only**
* ✅ **Running containers only** (never starts stopped CTs)
* ✅ Designed for **Proxmox VE Helper-Scripts**
* ✅ Compatible with containers normally updated using `update`
* ✅ Sequential updates (one container at a time)
* ✅ Fully non-interactive
* ✅ systemd timer based scheduling
* ✅ Optional automatic install of `expect` inside containers
* ✅ Multi-distribution support:

Supported Linux distributions inside LXCs:

* Debian / Ubuntu (apt)
* Alpine (apk)
* CentOS / Rocky / AlmaLinux / RHEL (dnf / yum)
* Fedora
* openSUSE (zypper)
* Arch Linux (pacman)

---

## 🚀 Installation

Run this **on the Proxmox VE host** as `root`:

```bash
curl -fsSL https://raw.githubusercontent.com/mariomsamy/Proxmox-VE-LXC-Update-Scripts-Automation/main/scripts/install.sh | bash
```

### What the installer does

* Installs the updater to `/usr/local/sbin/lxc-auto-update.sh`
* Creates config file at `/etc/lxc-auto-update.conf`
* Installs systemd service & timer
* Enables automatic daily updates
* Creates log directory at `/var/log/lxc-auto-update/`

---

## ▶ Run manually (any time)

To run updates immediately:

```bash
systemctl start lxc-auto-update.service
```

---

## ⏰ Change update time / schedule

Default schedule:

```
Every day at 06:30 AM (server local time)
```

### Change the schedule

Edit the systemd timer:

```bash
nano /etc/systemd/system/lxc-auto-update.timer
```

### Examples

**Daily at 03:00**

```ini
OnCalendar=*-*-* 03:00:00
```

**Every 12 hours**

```ini
OnCalendar=*-*-* 00,12:00:00
```

**Weekly (Sunday at 05:00)**

```ini
OnCalendar=Sun *-*-* 05:00:00
```

Apply changes:

```bash
systemctl daemon-reload
systemctl restart lxc-auto-update.timer
systemctl list-timers | grep lxc-auto-update
```

---

## ⚙ Configuration Options

Edit the configuration file:

```bash
nano /etc/lxc-auto-update.conf
```

### Available options

#### 🔹 Exclude specific containers

```bash
EXCLUDE_CTIDS="101 115 120"
```

#### 🔹 Disable installing `expect` inside containers

```bash
INSTALL_EXPECT=no
```

#### 🔹 Change per-container timeout (seconds)

```bash
PER_CT_TIMEOUT=3600
```

#### 🔹 Change log location

```bash
LOG_DIR="/var/log/lxc-auto-update"
LOG_FILE="/var/log/lxc-auto-update/daily.log"
```

#### 🔹 Reduce terminal formatting / banners

```bash
TERM_DUMB=yes
```

> Changes take effect automatically on the next run.

---

## 📄 Logs

### Script log

```bash
tail -f /var/log/lxc-auto-update/daily.log
```

### systemd log

```bash
journalctl -u lxc-auto-update.service --no-pager -n 200
```

---

## 🛑 Uninstall

To completely remove the updater:

```bash
curl -fsSL https://raw.githubusercontent.com/mariomsamy/Proxmox-VE-LXC-Update-Scripts-Automation/main/scripts/uninstall.sh | bash
```

### What uninstall does

* Disables and removes systemd service & timer
* Removes updater script

### What is kept

* `/etc/lxc-auto-update.conf`
* `/var/log/lxc-auto-update/`

This allows easy reinstall without losing settings.

---

## ⚠ Important Notes

* ❌ Does **not** start stopped containers
* ❌ Does **not** reboot containers
* ❌ Does **not** update the Proxmox host
* ✔ Safe for production Proxmox environments
* ✔ Designed for automation and cron-like execution

---

## 👤 Author & Company

**Mario Magdy Samy**

**Recipe Codes**
