#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

usage() {
  cat <<'EOF'
Uso:
  sudo bash scripts/03_create_sudo_user.sh <usuario> [clave]

Ejemplos:
  sudo bash scripts/03_create_sudo_user.sh devops
  sudo bash scripts/03_create_sudo_user.sh devops 'ClaveTemporal123'

Notas:
  - Si se omite la clave, el usuario se crea sin password y debera configurarse luego con `passwd`.
  - El usuario se agrega al grupo `sudo`.
EOF
}

require_root
ensure_ubuntu_lts

USERNAME="${1:-}"
PASSWORD="${2:-}"

if [[ -z "$USERNAME" ]]; then
  usage
  exit 1
fi

if id "$USERNAME" >/dev/null 2>&1; then
  warn "El usuario '$USERNAME' ya existe. Se verificara su pertenencia al grupo sudo."
else
  log "Creando usuario '$USERNAME'..."
  adduser --disabled-password --gecos "" "$USERNAME"
fi

log "Agregando usuario '$USERNAME' al grupo sudo..."
usermod -aG sudo "$USERNAME"

if [[ -n "$PASSWORD" ]]; then
  log "Configurando password para '$USERNAME'..."
  printf '%s:%s\n' "$USERNAME" "$PASSWORD" | chpasswd
else
  warn "No se proporciono password. Configure una manualmente con: passwd $USERNAME"
fi

log "Usuario '$USERNAME' listo con privilegios sudo."
