#!/usr/bin/env bash
set -euo pipefail

KUBECTL=(sudo k3s kubectl)
deployment=ucab-api
selector=app.kubernetes.io/name=ucab-api

echo "[1/5] Verificando Deployment y Service"
"${KUBECTL[@]}" rollout status "deployment/$deployment" --timeout=120s
"${KUBECTL[@]}" get service "$deployment" >/dev/null
./scripts/wait-http.sh http://127.0.0.1:30080/health 60

initial_ready=$("${KUBECTL[@]}" get pods -l "$selector" --field-selector=status.phase=Running --no-headers | wc -l)
if (( initial_ready < 3 )); then
  echo "ERROR: se esperaban al menos 3 Pods Running; se encontraron $initial_ready" >&2
  exit 1
fi

echo "[2/5] Verificando respuesta del Service"
response=$(curl --fail --silent --show-error http://127.0.0.1:30080/)
jq -e '.service == "ucab-lab-3-api" and (.hostname | length > 0)' <<<"$response" >/dev/null

echo "[3/5] Verificando autocuración"
old_pod=$("${KUBECTL[@]}" get pods -l "$selector" -o jsonpath='{.items[0].metadata.name}')
old_uid=$("${KUBECTL[@]}" get pod "$old_pod" -o jsonpath='{.metadata.uid}')
"${KUBECTL[@]}" delete pod "$old_pod" --wait=false >/dev/null
"${KUBECTL[@]}" wait --for=delete "pod/$old_pod" --timeout=60s
"${KUBECTL[@]}" rollout status "deployment/$deployment" --timeout=120s

if "${KUBECTL[@]}" get pods -l "$selector" -o jsonpath='{range .items[*]}{.metadata.uid}{"\n"}{end}' | grep -qx "$old_uid"; then
  echo "ERROR: el Pod eliminado no fue reemplazado" >&2
  exit 1
fi

echo "[4/5] Verificando escalado a cuatro réplicas"
"${KUBECTL[@]}" scale "deployment/$deployment" --replicas=4 >/dev/null
"${KUBECTL[@]}" rollout status "deployment/$deployment" --timeout=120s
replicas=$("${KUBECTL[@]}" get deployment "$deployment" -o jsonpath='{.status.availableReplicas}')
if [[ "$replicas" != "4" ]]; then
  echo "ERROR: se esperaban 4 réplicas disponibles; se encontraron ${replicas:-0}" >&2
  exit 1
fi

echo "[5/5] Restaurando tres réplicas"
"${KUBECTL[@]}" scale "deployment/$deployment" --replicas=3 >/dev/null
"${KUBECTL[@]}" rollout status "deployment/$deployment" --timeout=120s
echo "Verificación funcional completada correctamente"
