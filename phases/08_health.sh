  GNU nano 8.4                                       phases/08_immich.sh
#!/bin/bash
source lib/common.sh
source ./config.env

echo "=== SYSTEM HEALTH ==="
uptime
df -h
systemctl status backup-mirror.timer --no-pager
docker ps
smartctl -H $(lsblk -dpno NAME | grep -v mmcblk | head -n1) || true
