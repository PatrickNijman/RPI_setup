#!/bin/bash
set -Eeuo pipefail

ACTION=$1

case "$ACTION" in
    stop) docker ps -q | xargs -r docker stop ;;
    start) docker ps -aq | xargs -r docker start ;;
    status) docker ps -a ;;
    *) echo "Usage: $0 {stop|start|status}" ;;
esac
