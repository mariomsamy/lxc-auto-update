#!/usr/bin/env bash
# Author: Mario Magdy Samy
# Company: Recipe Codes
# License: MIT
#
# Proxmox VE LXC Auto Update (running-only)
# Designed for Proxmox VE Helper-Scripts containers (often updated via `update`)

set -euo pipefail

CONFIG_FILE="/etc/lxc-auto-update.conf"
[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

LOG_DIR="${LOG_DIR:-/var/log/lxc-auto-update}"
LOG_FILE="${LOG_FILE:-${LOG_DIR}/daily.log}"
PER_CT_TIMEOUT="${PER_CT_TIMEOUT:-1800}"
INSTALL_EXPECT="${INSTALL_EXPECT:-yes}"
EXCLUDE_CTIDS="${EXCLUDE_CTIDS:-}"
TERM_DUMB="${TERM_DUMB:-yes}"

mkdir -p "$LOG_DIR"

ts() { date '+%Y-%m-%d %H:%M:%S'; }
log() { echo "[${ts}] $*" | tee -a "$LOG_FILE"; }

is_excluded() { for x in $EXCLUDE_CTIDS; do [[ "$x" == "$1" ]] && return 0; done; return 1; }
get_running_cts() { pct list | awk '$2=="running"{print $1}'; }
run_in_ct() { timeout "${PER_CT_TIMEOUT}s" pct exec "$1" -- sh -c "$2"; }

detect_pkg_mgr() {
  for m in apk apt-get dnf yum zypper pacman; do
    pct exec "$1" -- sh -c "command -v ${m%%-*} >/dev/null 2>&1" && {
      [[ "$m" == "apt-get" ]] && echo apt || echo "$m"
      return
    }
  done
  echo unknown
}

ensure_expect() {
  [[ "$INSTALL_EXPECT" != "yes" ]] && return
  pct exec "$1" -- sh -c 'command -v expect >/dev/null 2>&1' && return
  case "$2" in
    apk) run_in_ct "$1" 'apk add --no-cache expect' ;;
    apt) run_in_ct "$1" 'apt-get update -y && apt-get install -y expect' ;;
    dnf|yum) run_in_ct "$1" "$2 -y install expect" ;;
    zypper) run_in_ct "$1" 'zypper --non-interactive install -y expect' ;;
    pacman) run_in_ct "$1" 'pacman -Sy --noconfirm expect' ;;
  esac
}

update_ct() {
  case "$2" in
    apk) run_in_ct "$1" 'apk update && apk upgrade --available' ;;
    apt) run_in_ct "$1" 'apt-get update -y && apt-get upgrade -y && apt-get autoremove -y' ;;
    dnf|yum) run_in_ct "$1" "$2 -y upgrade" ;;
    zypper) run_in_ct "$1" 'zypper --non-interactive update -y' ;;
    pacman) run_in_ct "$1" 'pacman -Syu --noconfirm' ;;
  esac
}

log "=== LXC AUTO UPDATE START ==="
for ctid in $(get_running_cts); do
  is_excluded "$ctid" && continue
  pkg="$(detect_pkg_mgr "$ctid")"
  ensure_expect "$ctid" "$pkg"
  update_ct "$ctid" "$pkg"
done
log "=== LXC AUTO UPDATE END ==="
