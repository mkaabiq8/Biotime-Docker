#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

[[ ${EUID} -eq 0 ]] || die "Run this script with sudo."
require_env_file
require_command ufw
require_command sshd

ssh_port="$(sshd -T 2>/dev/null | awk '$1 == "port" {print $2; exit}')"
ssh_port="${ssh_port:-22}"
device_port="$(env_value DEVICE_HTTP_PORT)"

info "This will allow SSH (${ssh_port}/tcp), HTTPS certificate traffic (80/443),"
info "and BioTime device push traffic (${device_port}/tcp), set deny-by-default"
info "for inbound traffic, then enable UFW. Existing public services may be blocked."
read -r -p "Continue? [y/N] " answer
[[ "${answer}" =~ ^[Yy]$ ]] || die "Cancelled; no firewall rules were changed."

ufw allow "${ssh_port}/tcp" comment 'SSH'
ufw allow 80/tcp comment 'Caddy ACME HTTP'
ufw allow 443/tcp comment 'BioTime HTTPS GUI'
ufw allow "${device_port}/tcp" comment 'BioTime ADMS device push'
ufw default deny incoming
ufw default allow outgoing
ufw --force enable
ufw status verbose

info "Also apply the same inbound rules in your VPS provider's network firewall."
