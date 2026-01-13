# LXC Auto Update for Proxmox VE

Automated updates for **Proxmox VE LXC containers** created using **Proxmox VE Helper-Scripts**.
Works only on **running containers** and safely ignores stopped ones.

## Install
```bash
curl -fsSL https://raw.githubusercontent.com/Recipe-Codes/lxc-auto-update/main/scripts/install.sh | bash
```

## Uninstall
```bash
curl -fsSL https://raw.githubusercontent.com/Recipe-Codes/lxc-auto-update/main/scripts/uninstall.sh | bash
```

## Schedule
Default: daily at 06:30 (systemd timer)
