#!/bin/bash
source lib/common.sh

mkdir -p /opt/containers/pihole
cd /opt/containers/pihole

cat > docker-compose.yml <<EOF
services:
  pihole:
    image: pihole/pihole:latest
    network_mode: host
    restart: unless-stopped
    volumes:
      - /srv/pihole:/etc/pihole
    environment:
      TZ: $PIHOLE_TZ
EOF

run "docker compose up -d"

info "Pi-hole phase complete"
