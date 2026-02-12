#!/bin/bash
set -Eeuo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$BASE_DIR"

source config.env
source lib/common.sh

require_root
validate_config

PHASE="${1:-all}"
export DRY_RUN="${DRY_RUN:-false}"

run_phase() {
    local file="phases/$1"
    [ -f "$file" ] || error "Missing phase $file"
    info "Running phase: $1"
    run "bash $file"
}

case "$PHASE" in
    all)
        for f in phases/*.sh; do
            run_phase "$(basename "$f")"
        done
        ;;
    base|storage|backup|docker|samba|pihole|immich|health)
        run_phase "$(ls phases | grep "$PHASE")"
        ;;
    maintenance-on)
        run "bash scripts/docker-maintenance.sh stop"
        systemctl stop backup-mirror.timer || true
        ;;
    maintenance-off)
        run "bash scripts/docker-maintenance.sh start"
        systemctl start backup-mirror.timer || true
        ;;
    dry-run)
        export DRY_RUN=true
        "$0" all
        ;;
    *)
        echo "Usage: $0 {all|base|storage|backup|docker|samba|pihole|immich|health|maintenance-on|maintenance-off|dry-run}"
        exit 1
        ;;
esac

info "INSTALLATION COMPLETE"
