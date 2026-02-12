#!/bin/bash
source lib/common.sh

mkdir -p /opt/containers/immich
cd /opt/containers/immich

cat > docker-compose.yml <<EOF
services:
  immich-server:
    image: ghcr.io/immich-app/immich-server:release
    ports:
      - "$IMMICH_PORT:2283"
    volumes:
      - /srv/immich/library:/usr/src/app/upload
    restart: unless-stopped

  immich-db:
    image: postgres:14
    environment:
      POSTGRES_PASSWORD: $IMMICH_DB_PASSWORD
    volumes:
      - /srv/immich/postgres:/var/lib/postgresql/data
    restart: unless-stopped

  immich-redis:
    image: redis:6
    volumes:
      - /srv/immich/cache:/data
    restart: unless-stopped
EOF

run "docker compose up -d"

info "Immich phase complete"
