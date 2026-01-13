#!/usr/bin/env bash
# Author: Mario Magdy Samy
# Company: Recipe Codes
# License: MIT
#
# Proxmox VE LXC Auto Update (running-only)
# Designed for Proxmox VE Helper-Scripts containers (often updated via `update`)

set -euo pipefail

CONFIG_FILE="/etc/lxc-auto-update.conf"
if [[ -f "$CONFIG_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi

# Defaults (override in /etc/lxc-auto-update.conf)
LOG_DIR="${LOG_DIR:-/var/log/lxc-auto-update}"
LOG_FILE="${LOG_FILE:-${LOG_DIR}/daily.log}"
PER_CT_TIMEOUT="${PER_CT_TIMEOUT:-1800}"      # seconds per CT
INSTALL_EXPECT="${INSTALL_EXPECT:-yes}"       # yes|no
EXCLUDE_CTIDS="${EXCLUDE_CTIDS:-}"            # "101 115"
TERM_DUMB="${TERM_DUMB:-yes}"                # yes|no

mkdir -p "$LOG_DIR"

ts() { date '+%Y-%m-%d %H:%M:%S'; }
log() { echo "[$(ts)] $*" | tee -a "$LOG_FILE"; }

is_excluded() {
  local ctid="$1"
  for x in $EXCLUDE_CTIDS; do
    [[ "$x" == "$ctid" ]] && return 0
  done
  return 1
}

# Only running LXCs (never starts stopped containers)
get_running_cts() {
  pct list | awk '$2 == "running" { print $1 }'
}

# Avoid login shells to prevent banners/MOTD pollution
run_in_ct() {
  local ctid="$1"
  local cmd="$2"
  timeout "${PER_CT_TIMEOUT}s" pct exec "$ctid" -- sh -c "$cmd"
}

detect_os_id() {
  local ctid="$1"
  if pct exec "$ctid" -- sh -c 'test -f /etc/os-release' >/dev/null 2>&1; then
    pct exec "$ctid" -- sh -c '
      . /etc/os-release 2>/dev/null || true
      printf "%s\n" "${ID:-unknown}"
    ' 2>/dev/null | tail -n 1 | tr -d '\r'
  elif pct exec "$ctid" -- sh -c 'test -f /etc/alpine-release' >/dev/null 2>&1; then
    echo "alpine"
  else
    echo "unknown"
  fi
}

detect_pkg_mgr() {
  local ctid="$1"

  if pct exec "$ctid" -- sh -c 'command -v apk >/dev/null 2>&1'; then echo "apk"; return; fi
  if pct exec "$ctid" -- sh -c 'command -v apt-get >/dev/null 2>&1'; then echo "apt"; return; fi
  if pct exec "$ctid" -- sh -c 'command -v dnf >/dev/null 2>&1'; then echo "dnf"; return; fi
  if pct exec "$ctid" -- sh -c 'command -v yum >/dev/null 2>&1'; then echo "yum"; return; fi
  if pct exec "$ctid" -- sh -c 'command -v zypper >/dev/null 2>&1'; then echo "zypper"; return; fi
  if pct exec "$ctid" -- sh -c 'command -v pacman >/dev/null 2>&1'; then echo "pacman"; return; fi

  echo "unknown"
}

ensure_expect_installed() {
  local ctid="$1"
  local pkg_mgr="$2"

  [[ "$INSTALL_EXPECT" != "yes" ]] && return 0

  if pct exec "$ctid" -- sh -c 'command -v expect >/dev/null 2>&1'; then
    log "CT ${ctid}: expect already installed"
    return 0
  fi

  log "CT ${ctid}: installing expect (pkg: ${pkg_mgr})"

  case "$pkg_mgr" in
    apk)
      run_in_ct "$ctid" 'apk update && apk add --no-cache expect'
      ;;
    apt)
      run_in_ct "$ctid" '
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y
        apt-get install -y expect
      '
      ;;
    dnf)
      run_in_ct "$ctid" 'dnf -y install expect || dnf -y install expect.x86_64'
      ;;
    yum)
      run_in_ct "$ctid" 'yum -y install expect'
      ;;
    zypper)
      run_in_ct "$ctid" '
        zypper --non-interactive refresh
        zypper --non-interactive install -y expect
      '
      ;;
    pacman)
      run_in_ct "$ctid" 'pacman -Sy --noconfirm expect'
      ;;
    *)
      log "CT ${ctid}: cannot install expect (unknown pkg manager)"
      ;;
  esac
}

update_apt() {
  local ctid="$1"
  log "CT ${ctid}: apt → update/upgrade"
  run_in_ct "$ctid" "
    export DEBIAN_FRONTEND=noninteractive
    $( [[ "$TERM_DUMB" == "yes" ]] && echo 'export TERM=dumb' )
    apt-get update -y
    apt-get upgrade -y
    apt-get autoremove -y
    apt-get autoclean -y
  "
}

update_apk() {
  local ctid="$1"
  log "CT ${ctid}: apk → update/upgrade"
  run_in_ct "$ctid" "
    $( [[ "$TERM_DUMB" == "yes" ]] && echo 'export TERM=dumb' )
    apk update
    apk upgrade --available
    apk cache clean
  "
}

update_dnf() {
  local ctid="$1"
  log "CT ${ctid}: dnf → update/upgrade"
  run_in_ct "$ctid" "
    $( [[ "$TERM_DUMB" == "yes" ]] && echo 'export TERM=dumb' )
    dnf -y upgrade --refresh
    dnf -y autoremove || true
    dnf -y clean all
  "
}

update_yum() {
  local ctid="$1"
  log "CT ${ctid}: yum → update/upgrade"
  run_in_ct "$ctid" "
    $( [[ "$TERM_DUMB" == "yes" ]] && echo 'export TERM=dumb' )
    yum -y update
    yum -y autoremove || true
    yum -y clean all
  "
}

update_zypper() {
  local ctid="$1"
  log "CT ${ctid}: zypper → update/upgrade"
  run_in_ct "$ctid" "
    $( [[ "$TERM_DUMB" == "yes" ]] && echo 'export TERM=dumb' )
    zypper --non-interactive refresh
    zypper --non-interactive update -y
    zypper --non-interactive clean -a
  "
}

update_pacman() {
  local ctid="$1"
  log "CT ${ctid}: pacman → update/upgrade"
  run_in_ct "$ctid" "
    $( [[ "$TERM_DUMB" == "yes" ]] && echo 'export TERM=dumb' )
    pacman -Syu --noconfirm
    pacman -Sc --noconfirm || true
  "
}

main() {
  log "=== LXC AUTO UPDATE START ==="

  local running
  running="$(get_running_cts || true)"

  if [[ -z "$running" ]]; then
    log "No running LXC containers found. Exiting."
    exit 0
  fi

  log "Running containers: $(echo "$running" | tr '\n' ' ')"
  [[ -n "$EXCLUDE_CTIDS" ]] && log "Excluded CTIDs: $EXCLUDE_CTIDS"

  local ctid os_id pkg_mgr
  for ctid in $running; do
    if is_excluded "$ctid"; then
      log "--- CT ${ctid}: SKIPPED (excluded) ---"
      continue
    fi

    log "--- CT ${ctid}: BEGIN ---"

    {
      os_id="$(detect_os_id "$ctid")"
      pkg_mgr="$(detect_pkg_mgr "$ctid")"
      log "CT ${ctid}: detected OS → ${os_id} | pkg → ${pkg_mgr}"

      ensure_expect_installed "$ctid" "$pkg_mgr"

      case "$pkg_mgr" in
        apk)    update_apk "$ctid" ;;
        apt)    update_apt "$ctid" ;;
        dnf)    update_dnf "$ctid" ;;
        yum)    update_yum "$ctid" ;;
        zypper) update_zypper "$ctid" ;;
        pacman) update_pacman "$ctid" ;;
        *)
          log "CT ${ctid}: unsupported/unknown package manager → skipped"
          ;;
      esac

      log "--- CT ${ctid}: SUCCESS ---"
    } >>"$LOG_FILE" 2>&1 || {
      rc=$?
      log "--- CT ${ctid}: FAILED (exit $rc) ---"
      continue
    }
  done

  log "=== LXC AUTO UPDATE END ==="
}

main "$@"
