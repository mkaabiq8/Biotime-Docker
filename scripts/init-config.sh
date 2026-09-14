#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

[[ ! -e "${ENV_FILE}" ]] || die "${ENV_FILE} already exists; it was not changed."
require_command awk
require_command od

umask 077
password="$(od -An -N24 -tx1 /dev/urandom | tr -d ' \n')"

if [[ -r /proc/sys/kernel/random/uuid ]]; then
  uuid="$(tr '[:upper:]' '[:lower:]' </proc/sys/kernel/random/uuid)"
else
  require_command uuidgen
  uuid="$(uuidgen | tr '[:upper:]' '[:lower:]')"
fi

mac_hex="$(od -An -N5 -tx1 /dev/urandom | tr -d ' \n')"
mac="02:${mac_hex:0:2}:${mac_hex:2:2}:${mac_hex:4:2}:${mac_hex:6:2}:${mac_hex:8:2}"

tmp_file="$(mktemp "${PROJECT_ROOT}/.env.tmp.XXXXXX")"
trap 'rm -f "${tmp_file}"' EXIT

awk \
  -v password="${password}" \
  -v uuid="${uuid}" \
  -v mac="${mac}" '
    /^WINDOWS_PASSWORD=/ {$0 = "WINDOWS_PASSWORD=" password}
    /^WINDOWS_UUID=/     {$0 = "WINDOWS_UUID=" uuid}
    /^WINDOWS_MAC=/      {$0 = "WINDOWS_MAC=" mac}
    {print}
  ' "${PROJECT_ROOT}/.env.example" >"${tmp_file}"

mv "${tmp_file}" "${ENV_FILE}"
chmod 600 "${ENV_FILE}"
trap - EXIT

info "Created ${ENV_FILE} with a random Windows password, UUID, and MAC."
info "Now set BIOTIME_DOMAIN and ACME_EMAIL before deployment."

