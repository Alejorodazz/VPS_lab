#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<EOF
Uso:
  sudo bash scripts/bootstrap_vps.sh <usuario> [clave] [puerto_ssh]

Ejemplos:
  sudo bash scripts/bootstrap_vps.sh devops
  sudo bash scripts/bootstrap_vps.sh devops 'ClaveTemporal123'
  sudo bash scripts/bootstrap_vps.sh devops 'ClaveTemporal123' 2222

Secuencia:
  1. Instala dependencias base
  2. Instala git, neovim y neofetch
  3. Crea un usuario con sudo
  4. Configura UFW para SSH
EOF
}

USERNAME="${1:-}"
PASSWORD="${2:-}"
SSH_PORT="${3:-22}"

if [[ -z "$USERNAME" ]]; then
  usage
  exit 1
fi

bash "$SCRIPT_DIR/01_install_dependencies.sh"
bash "$SCRIPT_DIR/02_install_dev_tools.sh"
bash "$SCRIPT_DIR/03_create_sudo_user.sh" "$USERNAME" "$PASSWORD"
bash "$SCRIPT_DIR/04_configure_firewall.sh" "$SSH_PORT"

printf '\nBootstrap completado para el usuario %s con SSH en el puerto %s.\n' "$USERNAME" "$SSH_PORT"
