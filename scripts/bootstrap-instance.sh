#!/usr/bin/env bash
set -euo pipefail

K3S_VERSION="${K3S_VERSION:-v1.37.1+k3s1}"
LAB_USER="${LAB_USER:-student}"

exec > >(tee -a /var/log/ucab-lab-bootstrap.log) 2>&1
echo "Iniciando bootstrap de UCAB Lab 3"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends ca-certificates curl docker.io git jq make
systemctl enable --now docker
docker pull node:22-alpine

if ! id "$LAB_USER" >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash "$LAB_USER"
fi
usermod -aG docker "$LAB_USER"
cat >/etc/sudoers.d/90-ucab-lab-student <<EOF
${LAB_USER} ALL=(ALL) NOPASSWD:ALL
EOF
chmod 0440 /etc/sudoers.d/90-ucab-lab-student

if [[ ! -x /usr/local/bin/k3s ]] || [[ "$(k3s --version 2>/dev/null | head -1)" != *"${K3S_VERSION}"* ]]; then
  install_script=$(mktemp)
  curl --fail --silent --show-error --location https://get.k3s.io --output "$install_script"
  INSTALL_K3S_VERSION="$K3S_VERSION" \
    K3S_KUBECONFIG_MODE="644" \
    INSTALL_K3S_EXEC="server --disable=traefik" \
    sh "$install_script"
  rm -f "$install_script"
else
  systemctl enable --now k3s
fi

"$(dirname -- "${BASH_SOURCE[0]}")/wait-k3s-ready.sh"
systemctl stop k3s

chown -R "$LAB_USER:$LAB_USER" "/home/$LAB_USER"
mkdir -p /var/lib/ucab-lab
date --iso-8601=seconds >/var/lib/ucab-lab/ready
echo "Bootstrap completado; K3s quedó detenido para iniciar el ejercicio con Docker"
