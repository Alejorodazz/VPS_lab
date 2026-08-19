#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_root
ensure_apt
ensure_ubuntu_lts
apt_update_once

log "Instalando dependencias base sobre Ubuntu LTS..."
apt_install \
  ca-certificates \
  curl \
  wget \
  gnupg \
  lsb-release \
  software-properties-common \
  unzip \
  zip \
  tar \
  rsync \
  htop \
  net-tools \
  build-essential \
  ufw

log "Dependencias base instaladas correctamente."
