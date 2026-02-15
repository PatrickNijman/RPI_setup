#!/bin/bash
set -Eeuo pipefail
source lib/common.sh
source ./config.env

info "Starting Samba phase"

# Ensure package installed
if ! command_exists smbd; then
    info "Installing Samba"
    run "apt update"
    run "apt install -y samba"
fi

# Ensure shared directory exists
SHARED_DIR="/srv/samba/shared"
if [ ! -d "$SHARED_DIR" ]; then
    info "Creating Samba shared directory"
    run "mkdir -p $SHARED_DIR"
fi

# Set ownership and permissions
run "chown -R $PRIMARY_USER:$PRIMARY_USER $SHARED_DIR"
run "chmod -R 2775 $SHARED_DIR"  # SGID ensures new files inherit group

# Add Samba user if missing
if ! pdbedit -L | grep -q "^$PRIMARY_USER:"; then
    info "Adding Samba user $PRIMARY_USER"
    (echo "$SAMBA_PASSWORD"; echo "$SAMBA_PASSWORD") | smbpasswd -a -s $PRIMARY_USER
fi

# Configure Samba share in smb.conf
if ! grep -q "^\[shared\]" /etc/samba/smb.conf; then
    info "Adding Samba share to /etc/samba/smb.conf"
    cat >> /etc/samba/smb.conf <<EOF

[shared]
   path = $SHARED_DIR
   browseable = yes
   read only = no
   writable = yes
   valid users = $PRIMARY_USER
   create mask = 0664
   directory mask = 2775
EOF
fi

info "Restarting Samba services"
run "systemctl restart smbd nmbd"

info "Samba phase complete"
