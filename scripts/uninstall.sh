#!/usr/bin/env bash
set -euo pipefail

systemctl disable --now lxc-auto-update.timer 2>/dev/null || true
systemctl disable --now lxc-auto-update.service 2>/dev/null || true

rm -f /etc/systemd/system/lxc-auto-update.timer
rm -f /etc/systemd/system/lxc-auto-update.service
rm -f /usr/local/sbin/lxc-auto-update.sh

systemctl daemon-reload

echo "Uninstalled lxc-auto-update."
echo "Note: /etc/lxc-auto-update.conf and /var/log/lxc-auto-update/ were NOT removed."
