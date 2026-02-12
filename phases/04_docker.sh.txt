#!/bin/bash
source lib/common.sh

if ! command_exists docker; then
    run "curl -fsSL https://get.docker.com | sh"
fi

run "usermod -aG docker $PRIMARY_USER"

mkdir -p /etc/docker

cat > /etc/docker/daemon.json <<EOF
{
"log-driver":"json-file",
"log-opts":{"max-size":"10m","max-file":"3"}
}
EOF

run "systemctl restart docker"

info "Docker phase complete"
