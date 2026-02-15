#!/bin/bash
set -Eeuo pipefail
source lib/common.sh
source ./config.env

info "Starting Backup phase"

# --- Validate backup disk ---
if [ ! -b "$BACKUP_DISK" ]; then
    error "Backup disk $BACKUP_DISK not found. Attach it before running this phase."
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
