#!/usr/bin/env bash
set -euo pipefail

REPO="Recipe-Codes/lxc-auto-update"
BRANCH="main"
RAW="https://raw.githubusercontent.com/${REPO}/${BRANCH}"

curl -fsSL "${RAW}/lxc-auto-update.sh" -o /usr/local/sbin/lxc-auto-update.sh
chmod +x /usr/local/sbin/lxc-auto-update.sh

# Install config only if not existing (preserve user edits on upgrades)
if [[ ! -f /etc/lxc-auto-update.conf ]]; then
  curl -fsSL "${RAW}/config/lxc-auto-update.conf" -o /etc/lxc-auto-update.conf
fi

curl -fsSL "${RAW}/systemd/lxc-auto-update.service" -o /etc/systemd/system/lxc-auto-update.service
curl -fsSL "${RAW}/systemd/lxc-auto-update.timer" -o /etc/systemd/system/lxc-auto-update.timer

mkdir -p /var/log/lxc-auto-update
chmod 755 /var/log/lxc-auto-update

systemctl daemon-reload
systemctl enable --now lxc-auto-update.timer

echo "Installed: /usr/local/sbin/lxc-auto-update.sh"
echo "Config:    /etc/lxc-auto-update.conf"
echo "Timer:     lxc-auto-update.timer (daily 06:30)"
echo "Log:       /var/log/lxc-auto-update/daily.log"
echo
systemctl list-timers --all | grep lxc-auto-update || true
