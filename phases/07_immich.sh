#!/bin/bash
set -Eeuo pipefail
source lib/common.sh
source ./config.env

info "Starting Immich phase"

# Validate Docker
if ! command_exists docker; then
    error "Docker not found. Run Docker phase first."
fi

# Start Docker service if needed
if ! systemctl is-active --quiet docker; then
    info "Starting Docker service"
    run "systemctl enable --now docker"
fi

# Define named volumes for Immich
IMMICH_LIBRARY="immich_library"
IMMICH_POSTGRES="immich_postgres"
IMMICH_CACHE="immich_cache"

for VOL in $IMMICH_LIBRARY $IMMICH_POSTGRES $IMMICH_CACHE; do
    if ! docker volume ls --format '{{.Name}}' | grep -q "^$VOL$"; then
        info "Creating Docker volume: $VOL"
        run "docker volume create $VOL"
    fi
done

# Pull required images
info "Pulling Immich server and dependencies"
run "docker pull ghcr.io/immich-app/immich-server:release"
run "docker pull postgres:14"
run "docker pull redis:6"

# Remove stopped container if exists
if docker ps -a --format '{{.Names}}' | grep -q '^immich$'; then
    STATUS=$(docker inspect -f '{{.State.Status}}' immich)
    if [ "$STATUS" != "running" ]; then
        info "Removing stopped Immich container"
        run "docker rm immich"
    else
        info "Immich container already running"
    fi
fi

# Start Immich stack (example: server + postgres + redis)
if ! docker ps --format '{{.Names}}' | grep -q '^immich$'; then
    info "Starting Immich container"
    run "docker run -d \
        --name immich \
        --restart unless-stopped \
        -p 2283:2283 \
        -v $IMMICH_LIBRARY:/app/data \
        -v $IMMICH_CACHE:/app/cache \
        -e POSTGRES_USER=$IMMICH_DB_USER \
        -e POSTGRES_PASSWORD=$IMMICH_DB_PASSWORD \
        -e POSTGRES_DB=$IMMICH_DB_NAME \
        ghcr.io/immich-app/immich-server:release"
fi

info "Immich phase complete"
