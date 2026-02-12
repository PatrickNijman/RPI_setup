#!/bin/bash

set -Eeuo pipefail

LOG_FILE="/var/log/pi-setup.log"
DRY_RUN="${DRY_RUN:-false}"

log() {
    echo "$(date '+%F %T') [$1] $2" | tee -a "$LOG_FILE"
}

info() { log INFO "$1"; }
warn() { log WARN "$1"; }
error() { log ERROR "$1"; exit 1; }

require_root() {
    [ "$EUID" -eq 0 ] || error "Run as root"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

run() {
    if [ "$DRY_RUN" = "true" ]; then
        echo "[DRY-RUN] $*"
    else
        eval "$@"
    fi
}

validate_mount() {
    mountpoint -q "$BACKUP_MOUNT" || error "Backup mount not mounted"
}

validate_config() {
    [ -f config.env ] || error "Missing config.env"
}
