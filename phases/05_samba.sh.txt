#!/bin/bash
source lib/common.sh

run "apt install -y samba"

grep -q "\[Shared\]" /etc/samba/smb.conf || cat >> /etc/samba/smb.conf <<EOF

[Shared]
path = $SAMBA_SHARE
browseable = yes
read only = no
guest ok = yes
force user = $PRIMARY_USER
create mask = 0775
directory mask = 0775
min protocol = SMB3
EOF

run "systemctl restart smbd"

info "Samba phase complete"
