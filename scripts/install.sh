#!/usr/bin/env bash
set -e
REPO="Recipe-Codes/lxc-auto-update"
RAW="https://raw.githubusercontent.com/${REPO}/main"

curl -fsSL "$RAW/lxc-auto-update.sh" -o /usr/local/sbin/lxc-auto-update.sh
chmod +x /usr/local/sbin/lxc-auto-update.sh

[ ! -f /etc/lxc-auto-update.conf ] && curl -fsSL "$RAW/config/lxc-auto-update.conf" -o /etc/lxc-auto-update.conf

curl -fsSL "$RAW/systemd/lxc-auto-update.service" -o /etc/systemd/system/lxc-auto-update.service
curl -fsSL "$RAW/systemd/lxc-auto-update.timer" -o /etc/systemd/system/lxc-auto-update.timer

systemctl daemon-reload
systemctl enable --now lxc-auto-update.timer
