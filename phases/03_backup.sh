#!/bin/bash
set -Eeuo pipefail
source lib/common.sh
source ./config.env

info "Starting Backup phase"

# --- Determine backup disk if not explicitly configured ---
if [ -z "${BACKUP_DISK-}" ]; then
    info "No BACKUP_DISK set in config; attempting to auto-detect an external disk"
    # pick first non-root, non-loop, non-mmcb disk
    ROOT_SRC=$(findmnt -n -o SOURCE / 2>/dev/null || true)
    BACKUP_DISK_CANDIDATE=$(lsblk -dpno NAME | grep -v "$ROOT_SRC" | grep -v loop | grep -v mmcblk | head -n1 || true)
    if [ -z "$BACKUP_DISK_CANDIDATE" ]; then
        error "No suitable backup disk auto-detected. Set BACKUP_DISK in config.env or attach a disk."
    fi
    BACKUP_DISK="$BACKUP_DISK_CANDIDATE"
    info "Auto-detected backup disk: $BACKUP_DISK"
fi

# --- Mount backup disk if not mounted ---
if ! mountpoint -q "$BACKUP_MOUNT"; then
    info "Mounting backup disk $BACKUP_DISK to $BACKUP_MOUNT"
    run "mkdir -p $BACKUP_MOUNT"
    # Auto-format if empty filesystem (dangerous if user already has data!)
    FS_TYPE=$(blkid -o value -s TYPE "$BACKUP_DISK" || echo "")
    if [ -z "$FS_TYPE" ]; then
        info "Backup disk unformatted, creating ext4 filesystem"
        run "mkfs.ext4 -F $BACKUP_DISK"
    fi
    run "mount $BACKUP_DISK $BACKUP_MOUNT"
fi

# --- Rsync mirror SSD to backup disk ---
info "Starting incremental backup of SSD root to backup disk"
# Exclude backup disk itself, /proc, /sys, /dev, /tmp
EXCLUDES="--exclude=/proc --exclude=/sys --exclude=/dev --exclude=/tmp --exclude=$BACKUP_MOUNT"
run "rsync -aAXv $EXCLUDES / $BACKUP_MOUNT/backup"

# --- Optional: create timestamped snapshot (if space allows) ---
# run "cp -al $BACKUP_MOUNT/backup $BACKUP_MOUNT/backup_$(date +%Y%m%d%H%M)"

# --- Spin down HDD to preserve lifespan -
