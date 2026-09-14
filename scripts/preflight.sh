#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

validate_config
require_docker

[[ "$(uname -s)" == "Linux" ]] || die "This stack requires a Linux Docker host with KVM."
case "$(uname -m)" in
  x86_64|amd64) ;;
  *) die "BioTime's Windows x86 runtime requires an x86-64 VPS." ;;
esac

[[ -c /dev/kvm ]] || die "/dev/kvm is missing. Enable nested virtualization or choose a KVM-capable VPS."
[[ -r /dev/kvm && -w /dev/kvm ]] || \
  die "The current user cannot access /dev/kvm. Check the kvm group/device permissions."
[[ -c /dev/net/tun ]] || die "/dev/net/tun is missing. Load/enable the TUN device on the VPS."

if ! grep -Eqm1 '(vmx|svm)' /proc/cpuinfo; then
  die "The VPS CPU does not expose Intel VT-x or AMD-V virtualization flags."
fi

memory_kib="$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)"
minimum_memory_kib=$((10 * 1024 * 1024))
(( memory_kib >= minimum_memory_kib )) || \
  die "At least 10 GiB host RAM is recommended (8 GiB is assigned to Windows)."

available_kib="$(df -Pk "${PROJECT_ROOT}" | awk 'NR == 2 {print $4}')"
minimum_disk_kib=$((120 * 1024 * 1024))
(( available_kib >= minimum_disk_kib )) || \
  die "At least 120 GiB of free disk is required for Windows, BioTime, and backups."

compose --profile public config --quiet

if command -v ss >/dev/null 2>&1; then
  for port in 80 443 "$(env_value DEVICE_HTTP_PORT)" "$(env_value SETUP_WEB_PORT)" "$(env_value RDP_PORT)" "$(env_value BIOTIME_BACKEND_PORT)"; do
    if ss -H -lnt "sport = :${port}" 2>/dev/null | grep -q .; then
      info "WARNING: TCP port ${port} is already listening; check for a conflict before deployment."
    fi
  done
fi

info "Preflight passed: Docker, Compose, KVM, TUN, memory, disk, and configuration are ready."
