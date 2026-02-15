#!/bin/bash
set -Eeuo pipefail

# Lightweight validator for Docker and Pi-hole readiness
# Exits 0 when critical checks pass, non-zero otherwise

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$SCRIPT_DIR"

source lib/common.sh
source ./config.env

info "Running Docker + Pi-hole validation"

ok=0
fail=0

# Docker service
if systemctl is-active --quiet docker; then
    info "Docker service: active"
    ok=$((ok+1))
else
    error "Docker service is not active"
fi

# Basic docker command
if command_exists docker; then
    info "Docker CLI: available"
else
    error "Docker CLI not found"
fi

# Check key volumes (best-effort list)
expected_vols=(pihole_data dnsmasq_data immich_library immich_postgres immich_cache)
missing=()
for v in "${expected_vols[@]}"; do
    if docker volume ls --format '{{.Name}}' | grep -q "^$v$"; then
        info "Docker volume exists: $v"
        ok=$((ok+1))
    else
        warn "Docker volume missing: $v"
        missing+=("$v")
        fail=$((fail+1))
    fi
done

# Check Pi-hole container status
if docker ps --format '{{.Names}}' | grep -q '^pihole$'; then
    info "Pi-hole container: running"
    ok=$((ok+1))
else
    warn "Pi-hole container not running"
    fail=$((fail+1))
fi

# Check port 53 is listening (UDP or TCP)
if ss -lupn | grep -q ':53' || ss -ltnp | grep -q ':53'; then
    info "Port 53: listening"
    ok=$((ok+1))
else
    warn "Port 53: not listening"
    fail=$((fail+1))
fi

# Final decision
info "Validation summary: $ok OK, $fail failed checks"
if [ $fail -gt 0 ]; then
    error "Validation failed: $fail checks did not pass"
else
    info "Validation successful"
    exit 0
fi
