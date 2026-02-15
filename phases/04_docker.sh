#!/bin/bash
set -Eeuo pipefail
source lib/common.sh
source ./config.env

info "Starting Docker phase"

OS=$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
ARCH=$(dpkg --print-architecture)
info "Detected OS: $OS, ARCH: $ARCH"

if ! command_exists docker; then
    if [[ "$OS" == "raspbian" ]] || grep -qi "raspberry" /etc/os-release; then
        info "Installing Docker from OS repo"
        run "apt update"
        run "apt install -y docker.io docker-compose-plugin"
    else
        info "Installing official Docker CE"
        run "apt update"
        run "apt install -y ca-certificates curl gnupg lsb-release"
        run "install -m 0755 -d /etc/apt/keyrings"
        run "curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc"
        run "chmod a+r /etc/apt/keyrings/docker.asc"
        run "echo \"deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(lsb_release -cs) stable\" > /etc/apt/sources.list.d/docker.list"
        run "apt update"
        run "apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin"
    fi
fi

info "Enabling Docker service"
run "systemctl enable --now docker"

info "Docker phase complete"
