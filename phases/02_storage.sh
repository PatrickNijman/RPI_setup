#!/bin/bash
source lib/common.sh
source ./config.env

ROOT_DISK=$(lsblk -no PKNAME $(findmnt -n -o SOURCE /) | head -n1)
ROOT_DISK="/dev/$ROOT_DISK"

info "Root disk detected as $ROOT_DISK"

DISK=$(lsblk -dpno NAME | grep -v "$ROOT_DISK" | grep -v loop | head -n1)

[ -z "$DISK" ] && error "No suitable external disk found"

info "Backup disk candidate: $DISK"

info "Preparing disk $DISK"

if blkid "$DISK" &>/dev/null; then
    warn "Disk already has filesystem — skipping format"
else
    run "parted -s $DISK mklabel gpt"
    run "parted -s $DISK mkpart primary ext4 0% 100%"
    run "mkfs.ext4 -L $BACKUP_LABEL ${DISK}1"
fi

UUID=$(blkid -s UUID -o value ${DISK}1)

grep -q "$UUID" /etc/fstab || \
run "echo UUID=$UUID $BACKUP_MOUNT ext4 defaults,noatime 0 2 >> /etc/fstab"

run "mkdir -p $BACKUP_MOUNT"
run "mount -a"

validate_mount

run "mkdir -p $BACKUP_MOUNT/{ssd-mirror,logs}"

info "Storage phase complete"
