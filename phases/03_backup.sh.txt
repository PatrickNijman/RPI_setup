#!/bin/bash
source lib/common.sh

validate_mount

info "Installing backup script"

cat > /usr/local/bin/backup-mirror.sh <<EOF
#!/bin/bash
set -Eeuo pipefail
docker ps -q | xargs -r docker stop
rsync -aAX --delete \
--exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","$BACKUP_MOUNT/*","/lost+found"} \
/ $BACKUP_MOUNT/ssd-mirror
docker ps -aq | xargs -r docker start
EOF

chmod +x /usr/local/bin/backup-mirror.sh

cat > /etc/systemd/system/backup-mirror.timer <<EOF
[Unit]
Description=Nightly Backup

[Timer]
OnCalendar=$BACKUP_TIME
Persistent=true

[Install]
WantedBy=timers.target
EOF

cat > /etc/systemd/system/backup-mirror.service <<EOF
[Unit]
Description=SSD Mirror Backup

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup-mirror.sh
EOF

run "systemctl daemon-reload"
run "systemctl enable --now backup-mirror.timer"

info "Backup phase complete"
