#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

usage() {
  cat <<'EOF'
Uso:
  sudo bash scripts/04_configure_firewall.sh [puerto_ssh]

Ejemplos:
  sudo bash scripts/04_configure_firewall.sh
  sudo bash scripts/04_configure_firewall.sh 2222

Comportamiento:
  - Deniega trafico entrante por defecto
  - Permite trafico saliente por defecto
  - Habilita OpenSSH o el puerto SSH indicado
EOF
}

require_root
ensure_apt
ensure_ubuntu_lts
apt_update_once

if ! command_exists ufw; then
  log "UFW no esta instalado. Instalando..."
  apt_install ufw
fi

SSH_PORT="${1:-22}"

if [[ "${SSH_PORT}" == "-h" || "${SSH_PORT}" == "--help" ]]; then
  usage
  exit 0
fi

if ! [[ "$SSH_PORT" =~ ^[0-9]+$ ]] || (( SSH_PORT < 1 || SSH_PORT > 65535 )); then
  error "El puerto SSH debe ser un entero entre 1 y 65535."
  exit 1
fi

log "Configurando politicas por defecto del firewall..."
ufw default deny incoming
ufw default allow outgoing

if [[ "$SSH_PORT" -eq 22 ]]; then
  log "Habilitando perfil OpenSSH en UFW..."
  ufw allow OpenSSH
else
  log "Habilitando puerto SSH personalizado: $SSH_PORT/tcp"
  ufw allow "${SSH_PORT}/tcp"
fi

log "Habilitando UFW..."
ufw --force enable

log "Estado actual del firewall:"
ufw status verbose
