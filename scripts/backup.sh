#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

require_env_file
require_docker
require_command tar

backup_dir="${1:-${PROJECT_ROOT}/backups}"
mkdir -p "${backup_dir}"
backup_dir="$(CDPATH= cd -- "${backup_dir}" && pwd)"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
archive="${backup_dir}/biotime-${timestamp}.tar.gz"

windows_was_running="$(docker inspect -f '{{.State.Running}}' biotime-windows 2>/dev/null || printf 'false')"
proxy_was_running="$(docker inspect -f '{{.State.Running}}' biotime-proxy 2>/dev/null || printf 'false')"

restart_services() {
  if [[ "${windows_was_running}" == "true" ]]; then
    compose up -d windows >/dev/null
  fi
  if [[ "${proxy_was_running}" == "true" ]]; then
    compose --profile public up -d caddy >/dev/null
  fi
}
trap restart_services EXIT

if [[ "${proxy_was_running}" == "true" ]]; then
  compose --profile public stop caddy
fi
if [[ "${windows_was_running}" == "true" ]]; then
  compose stop -t 120 windows
fi

tar --sparse -C "${PROJECT_ROOT}" -czf "${archive}" data .env
chmod 600 "${archive}"

restart_services
trap - EXIT

info "Cold backup created: ${archive}"
info "It contains the Windows disk, BioTime database, TLS data, and deployment identity."
