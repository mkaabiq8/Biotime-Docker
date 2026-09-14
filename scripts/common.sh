#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-${PROJECT_ROOT}/.env}"
COMPOSE_FILE="${PROJECT_ROOT}/compose.yaml"

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

info() {
  printf '%s\n' "$*"
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

env_value() {
  local key="$1"
  awk -v wanted="${key}" '
    index($0, wanted "=") == 1 {
      sub(/^[^=]*=/, "")
      sub(/\r$/, "")
      print
      exit
    }
  ' "${ENV_FILE}"
}

require_env_file() {
  [[ -f "${ENV_FILE}" ]] || die "Missing .env. Run ./scripts/init-config.sh first."
}

compose() {
  docker compose \
    --project-directory "${PROJECT_ROOT}" \
    --env-file "${ENV_FILE}" \
    -f "${COMPOSE_FILE}" \
    "$@"
}

validate_config() {
  require_env_file

  local domain email password uuid mac
  domain="$(env_value BIOTIME_DOMAIN)"
  email="$(env_value ACME_EMAIL)"
  password="$(env_value WINDOWS_PASSWORD)"
  uuid="$(env_value WINDOWS_UUID)"
  mac="$(env_value WINDOWS_MAC)"

  [[ -n "${domain}" && "${domain}" != *example.com ]] || \
    die "Set BIOTIME_DOMAIN in .env to a real DNS name."
  [[ "${email}" == *@* && "${email}" != *example.com ]] || \
    die "Set ACME_EMAIL in .env to a real email address."
  [[ ${#password} -ge 16 && "${password}" != CHANGE_ME* ]] || \
    die "WINDOWS_PASSWORD must be a generated password of at least 16 characters."
  [[ "${uuid}" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]] || \
    die "WINDOWS_UUID is not a valid UUID. Re-run init or fix .env."
  [[ "${mac}" =~ ^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$ ]] || \
    die "WINDOWS_MAC is not a valid MAC address. Re-run init or fix .env."
}

require_docker() {
  require_command docker
  docker info >/dev/null 2>&1 || \
    die "Docker is not running or this user cannot access it."
  docker compose version >/dev/null 2>&1 || \
    die "The Docker Compose v2 plugin is required."
}

