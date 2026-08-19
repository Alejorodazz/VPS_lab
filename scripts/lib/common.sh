#!/usr/bin/env bash

set -euo pipefail

log() {
  printf '[INFO] %s\n' "$*"
}

warn() {
  printf '[WARN] %s\n' "$*" >&2
}

error() {
  printf '[ERROR] %s\n' "$*" >&2
}

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    error "Este script debe ejecutarse como root o con sudo."
    exit 1
  fi
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

ensure_ubuntu_lts() {
  if [[ ! -r /etc/os-release ]]; then
    error "No se pudo leer /etc/os-release para validar la distribucion."
    exit 1
  fi

  # shellcheck disable=SC1091
  source /etc/os-release

  if [[ "${ID:-}" != "ubuntu" ]]; then
    error "Estos scripts solo soportan Ubuntu LTS. Sistema detectado: ${PRETTY_NAME:-desconocido}."
    exit 1
  fi

  if [[ "${VERSION:-}" != *"LTS"* && "${PRETTY_NAME:-}" != *"LTS"* ]]; then
    error "Se requiere una version Ubuntu LTS. Sistema detectado: ${PRETTY_NAME:-desconocido}."
    exit 1
  fi
}

apt_update_once() {
  if [[ "${APT_UPDATED:-0}" -eq 0 ]]; then
    log "Actualizando indices de paquetes..."
    apt-get update
    APT_UPDATED=1
    export APT_UPDATED
  fi
}

ensure_apt() {
  if ! command_exists apt-get; then
    error "No se encontro apt-get. Estos scripts requieren Ubuntu LTS."
    exit 1
  fi
}

apt_install() {
  DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
}
