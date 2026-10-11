#!/usr/bin/env bash
set -euo pipefail

attempts="${K3S_DISCOVERY_ATTEMPTS:-90}"
interval_seconds="${K3S_DISCOVERY_INTERVAL_SECONDS:-2}"
ready_timeout="${K3S_READY_TIMEOUT:-180s}"

if ! [[ "$attempts" =~ ^[1-9][0-9]*$ ]]; then
  echo "ERROR: K3S_DISCOVERY_ATTEMPTS debe ser un entero positivo." >&2
  exit 2
fi

echo "Esperando que K3s registre el nodo..."
node_found=false
for ((attempt = 1; attempt <= attempts; attempt++)); do
  if k3s kubectl get nodes -o name 2>/dev/null | grep -q '^node/'; then
    node_found=true
    break
  fi
  sleep "$interval_seconds"
done

if [[ "$node_found" != true ]]; then
  echo "ERROR: K3s no registró ningún nodo después de $attempts intentos." >&2
  systemctl status k3s --no-pager >&2 || true
  journalctl -u k3s -n 100 --no-pager >&2 || true
  exit 1
fi

echo "Nodo registrado; esperando la condición Ready..."
k3s kubectl wait --for=condition=Ready node --all --timeout="$ready_timeout"
k3s kubectl get nodes -o wide
