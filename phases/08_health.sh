  #!/bin/bash
  set -Eeuo pipefail
  source lib/common.sh
  source ./config.env

  info "=== SYSTEM HEALTH ==="
  run "uptime"
  run "df -h"
  run "systemctl status backup-mirror.timer --no-pager" || true
  run "docker ps" || true
  # if smartctl exists, run a quick health check on first non-mmcb disk
  if command_exists smartctl; then
    DEV=$(lsblk -dpno NAME | grep -v mmcblk | head -n1 || true)
    if [ -n "$DEV" ]; then
      info "Running smartctl health check on $DEV"
      run "smartctl -H $DEV" || true
    else
      warn "No rotational disk detected for SMART check"
    fi
  fi

  info "Health phase complete"
