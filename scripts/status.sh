#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

require_env_file
require_docker
require_command curl

compose --profile public ps

backend_port="$(env_value BIOTIME_BACKEND_PORT)"
if curl --silent --location --output /dev/null --connect-timeout 5 "http://127.0.0.1:${backend_port}/"; then
  info "OK: BioTime is reachable from the VPS on ${backend_port}."
else
  info "NOT READY: BioTime is not reachable from the VPS on ${backend_port}."
fi

domain="$(env_value BIOTIME_DOMAIN)"
if curl --fail --silent --show-error --location --output /dev/null \
  --connect-timeout 8 "https://${domain}/"; then
  info "OK: public GUI is reachable at https://${domain}."
else
  info "NOT READY: public GUI or TLS is not reachable at https://${domain}."
fi

