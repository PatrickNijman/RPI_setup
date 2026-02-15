#!/bin/bash
set -Eeuo pipefail

# Complete uninstall script: removes all Docker containers, volumes, packages, and files
# created during the RPI setup installation. Permissions remain unchanged.

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$SCRIPT_DIR"

source lib/common.sh
source ./config.env

require_root

info "=== RPI Setup Uninstall Script ==="
info "This will remove:"
echo "  - All Docker containers and images"
echo "  - All Docker volumes (pihole_data, dnsmasq_data, immich_*)"
echo "  - Docker package (docker.io, docker-ce)"
echo "  - Samba package and configuration"
echo "  - Directories: /srv/samba, /opt/containers, backup mount ($BACKUP_MOUNT)"
echo "  - Backup disk mount entry from /etc/fstab"
echo ""

DRY_RUN="${DRY_RUN:-false}"
if [ "$DRY_RUN" = "true" ]; then
    info "DRY_RUN enabled — showing what would be removed without making changes"
fi

read -r -p "Proceed with uninstall? [y/N]: " RESP
case "$RESP" in
    [yY]|[yY][eE][sS])
        ;;
    *)
        info "Uninstall cancelled"
        exit 0
        ;;
esac

# ---
# Docker cleanup
# ---

if command_exists docker; then
    info "Stopping all Docker containers"
    CONTAINER_COUNT=$(docker ps -a -q | wc -l || true)
    if [ "$CONTAINER_COUNT" -gt 0 ]; then
        run "docker stop \$(docker ps -a -q) || true" || true
        info "Stopped $CONTAINER_COUNT container(s)"
    fi

    info "Removing all Docker containers"
    run "docker rm \$(docker ps -a -q) || true" || true

    info "Removing Docker images"
    run "docker rmi \$(docker images -q) || true" || true

    info "Removing Docker volumes"
    for VOL in pihole_data dnsmasq_data immich_library immich_postgres immich_cache; do
        if docker volume ls --format '{{.Name}}' 2>/dev/null | grep -q "^$VOL$"; then
            run "docker volume rm $VOL || true" || true
            info "Removed Docker volume: $VOL"
        fi
    done

    info "Removing Docker network bridges and configs"
    run "docker system prune -a -f --volumes" || true
fi

# Uninstall Docker packages
info "Uninstalling Docker packages"
run "apt remove -y docker.io docker-ce docker-ce-cli containerd.io docker-compose-plugin" || true
run "apt autoremove -y" || true

# ---
# Samba cleanup
# ---

info "Stopping Samba services"
run "systemctl stop smbd nmbd" || true
run "systemctl disable smbd nmbd" || true

info "Uninstalling Samba package"
run "apt remove -y samba" || true

# Remove Samba configuration backup (optional: user may want to keep it)
if [ -f /etc/samba/smb.conf.bak ]; then
    info "Found backup of smb.conf"
    read -r -p "Remove /etc/samba/smb.conf.bak? [y/N]: " RESP_SMB
    case "$RESP_SMB" in
        [yY]|[yY][eE][sS])
            run "rm /etc/samba/smb.conf.bak" || true
            ;;
        *)
            ;;
    esac
fi

# ---
# Directory cleanup
# ---

info "Removing installation directories"
for DIR in /srv/samba /opt/containers; do
    if [ -d "$DIR" ]; then
        info "Removing directory: $DIR"
        run "rm -rf $DIR || true" || true
    fi
done

# ---
# Backup mount cleanup
# ---

info "Removing backup mount configuration"
if [ -n "${BACKUP_MOUNT}" ] && mountpoint -q "$BACKUP_MOUNT" 2>/dev/null; then
    info "Unmounting $BACKUP_MOUNT"
    run "umount $BACKUP_MOUNT || true" || true
fi

if [ -n "${BACKUP_MOUNT}" ] && [ -d "$BACKUP_MOUNT" ]; then
    info "Removing backup mount directory: $BACKUP_MOUNT"
    run "rmdir $BACKUP_MOUNT || true" || true
fi

# Remove fstab entry for backup disk
if grep -q "$BACKUP_MOUNT" /etc/fstab 2>/dev/null; then
    info "Removing backup mount from /etc/fstab"
    # Create a temporary backup of fstab
    run "cp /etc/fstab /etc/fstab.bak-uninstall"
    # Remove the matching line (non-destructive: only removes the backup mount line)
    run "sed -i \"\\|$BACKUP_MOUNT|d\" /etc/fstab"
fi

# ---
# Service cleanup
# ---

info "Removing systemd timers and services"
run "systemctl stop backup-mirror.timer backup-mirror.service" || true
run "systemctl disable backup-mirror.timer backup-mirror.service" || true

for SERVICE in backup-mirror docker; do
    if [ -f "/etc/systemd/system/${SERVICE}.service" ] || [ -f "/etc/systemd/system/${SERVICE}.timer" ]; then
        run "rm -f /etc/systemd/system/${SERVICE}.service /etc/systemd/system/${SERVICE}.timer"
        info "Removed systemd unit: $SERVICE"
    fi
done

run "systemctl daemon-reload" || true

# ---
# Summary
# ---

info "=== Uninstall Complete ==="
info "Remaining items (not removed):"
echo "  - User permissions and groups"
echo "  - System packages (apt): vim, curl, htop, rsync, smartmontools, ufw, fail2ban, unattended-upgrades"
echo "  - Log file: /var/log/pi-setup.log (can be removed manually)"
echo "  - Backup of /etc/fstab: /etc/fstab.bak-uninstall (for safety)"
echo ""
echo "To complete cleanup, optionally run:"
echo "  sudo rm /var/log/pi-setup.log"
echo "  sudo rm /etc/fstab.bak-uninstall"
echo ""
info "Ready to reinstall. Run './install.sh all' when ready."
