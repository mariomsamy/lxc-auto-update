#!/usr/bin/env bash
set -e
systemctl disable --now lxc-auto-update.timer || true
rm -f /usr/local/sbin/lxc-auto-update.sh
rm -f /etc/systemd/system/lxc-auto-update.*
systemctl daemon-reload
