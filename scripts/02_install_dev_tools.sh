#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_root
ensure_apt
ensure_ubuntu_lts
apt_update_once

log "Instalando git, neovim y neofetch sobre Ubuntu LTS..."
apt_install \
  git \
  neovim \
  neofetch

log "Herramientas de desarrollo instaladas correctamente."
