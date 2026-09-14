#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

validate_config
require_docker

mkdir -p \
  "${PROJECT_ROOT}/data/windows" \
  "${PROJECT_ROOT}/data/caddy-data" \
  "${PROJECT_ROOT}/data/caddy-config"

compose pull windows
compose up -d windows

setup_port="$(env_value SETUP_WEB_PORT)"
info "Windows is starting. Follow logs with: ./scripts/logs.sh"
info "From your computer, create this tunnel:"
info "  ssh -N -L ${setup_port}:127.0.0.1:${setup_port} YOUR_USER@YOUR_VPS"
info "Then open http://127.0.0.1:${setup_port} and complete docs/INSTALL-BIOTIME.md."
info "The public proxy has NOT been started."

