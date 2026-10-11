#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d)
cleanup() { rm -rf "$test_dir"; }
trap cleanup EXIT

export PATH="$repo_dir/tests/bin:$PATH"
export K3S_MOCK_STATE="$test_dir/state"
export K3S_MOCK_LOG="$test_dir/k3s.log"

K3S_DISCOVERY_ATTEMPTS=5 \
K3S_DISCOVERY_INTERVAL_SECONDS=0 \
  "$repo_dir/scripts/wait-k3s-ready.sh" >"$test_dir/success.out"

[[ "$(<"$K3S_MOCK_STATE")" -eq 3 ]]
grep -q '^kubectl wait --for=condition=Ready node --all --timeout=180s$' "$K3S_MOCK_LOG"
grep -q 'Nodo registrado' "$test_dir/success.out"

: >"$K3S_MOCK_LOG"
rm -f "$K3S_MOCK_STATE"
if K3S_MOCK_NEVER_READY=true \
  K3S_DISCOVERY_ATTEMPTS=2 \
  K3S_DISCOVERY_INTERVAL_SECONDS=0 \
  "$repo_dir/scripts/wait-k3s-ready.sh" >"$test_dir/failure.out" 2>&1; then
  echo "La ausencia de nodos debió producir un error." >&2
  exit 1
fi

[[ "$(<"$K3S_MOCK_STATE")" -eq 2 ]]
grep -q 'no registró ningún nodo' "$test_dir/failure.out"

echo "OK: espera de registro y condición Ready de K3s comprobadas"
