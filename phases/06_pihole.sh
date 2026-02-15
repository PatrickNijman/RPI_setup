#!/bin/bash
set -Eeuo pipefail
source lib/common.sh
source ./config.env

info "Starting Pi-hole phase"

# Validate Docker
if ! command_exists docker; then
    error "Docker binary not found. Run Docker phase first."
fi

# Start Docker service if needed
if ! systemctl is-active --quiet docker; then
    info "Starting Docker service"
    run "systemctl enable --now docker"
fi

# Docker named volumes
PIHOLE_VOLUME="pihole_data"
DNSMASQ_VOLUME="dnsmasq_data"

# Create volumes if missing
for VOL in $PIHOLE_VOLUME $DNSMASQ_VOLUME; do
    if ! docker volume ls --format '{{.Name}}' | grep -q "^$VOL$"; then
        info "Creating Docker volume: $VOL"
        run "docker volume create $VOL"
    fi
    # ensure the volume is writable by container processes (set permissive perms)
    info "Ensuring permissions for Docker volume: $VOL"
    run "docker run --rm -v $VOL:/data alpine sh -c 'chmod -R 0775 /data || true'"
done

# Pull latest Pi-hole image
info "Pulling latest Pi-hole image"
run "docker pull pihole/pihole:latest"

# Remove stopped container if exists
if docker ps -a --format '{{.Names}}' | grep -q '^pihole$'; then
    STATUS=$(docker inspect -f '{{.State.Status}}' pihole)
    if [ "$STATUS" != "running" ]; then
        info "Removing stopped Pi-hole container"
        run "docker rm pihole"
    else
        info "Pi-hole container already running"
    fi
fi

# Start container if missing
if ! docker ps -a --format '{{.Names}}' | grep -q '^pihole$'; then
    info "Starting Pi-hole container"
    # ensure port 53 is available (stop common host services that bind it)
    if systemctl is-active --quiet systemd-resolved; then
        warn "systemd-resolved is active and may bind port 53; disabling it"
        run "systemctl disable --now systemd-resolved.service"
    fi
    if systemctl is-active --quiet dnsmasq; then
        warn "dnsmasq service is active and may bind port 53; disabling it"
        run "systemctl disable --now dnsmasq.service"
    fi



    run "docker run -d \
        --name pihole \
        --restart unless-stopped \
        -p 53:53/tcp \
        -p 53:53/udp \
        -p 80:80/tcp \
        -p 443:443/tcp \
        -v $PIHOLE_VOLUME:/etc/pihole \
        -v $DNSMASQ_VOLUME:/etc/dnsmasq.d \
        -e TZ="$TIMEZONE" \
        -e FTLCONF_webserver_api_password="$PIHOLE_WEBPASSWORD" \
        pihole/pihole:latest"
fi

info "Pi-hole phase complete"

# Run validation to confirm Docker + Pi-hole readiness
run "bash scripts/validate-docker-pihole.sh"
