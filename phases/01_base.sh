#!/bin/bash
set -Eeuo pipefail
source lib/common.sh
source ./config.env

info "Starting Base phase"

info "Updating system"
run "apt update"
run "apt full-upgrade -y"

info "Installing base packages"
run "apt install -y vim curl htop rsync smartmontools ufw fail2ban unattended-upgrades"

info "Setting timezone"
run "timedatectl set-timezone $TIMEZONE"

info "Creating general directory structure"
run "mkdir -p /srv/samba/shared"
run "mkdir -p /srv/immich/{library,postgres,cache}"
run "mkdir -p /opt/containers"

info "Setting ownership to primary user"
run "chown -R $PRIMARY_USER:$PRIMARY_USER /srv /opt/containers"

info "Base phase complete"
