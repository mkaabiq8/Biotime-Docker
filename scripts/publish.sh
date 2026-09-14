#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

validate_config
require_docker
require_command curl

[[ "$(env_value BIOTIME_SECURITY_PATCH_CONFIRMED)" == "yes" ]] || \
  die "Refusing public exposure. Install build 8.5.5.2944 or a vendor-confirmed newer fixed build, then set BIOTIME_SECURITY_PATCH_CONFIRMED=yes."

backend_port="$(env_value BIOTIME_BACKEND_PORT)"
if ! curl --silent --show-error --location --output /dev/null \
  --connect-timeout 5 "http://127.0.0.1:${backend_port}/"; then
  die "BioTime is not reachable on VPS loopback port ${backend_port}. Check the Windows service and port 8090."
fi

compose --profile public pull caddy
compose --profile public up -d

domain="$(env_value BIOTIME_DOMAIN)"
device_port="$(env_value DEVICE_HTTP_PORT)"
info "Publishing enabled. GUI: https://${domain}"
info "Device ADMS endpoint: http://${domain}:${device_port} (only /iclock paths are accepted)"
info "Open TCP 80, 443, and ${device_port} in both UFW and the VPS provider firewall."

