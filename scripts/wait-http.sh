#!/usr/bin/env bash
set -euo pipefail

url="${1:?uso: wait-http.sh URL [SEGUNDOS]}"
timeout_seconds="${2:-30}"
deadline=$((SECONDS + timeout_seconds))

while (( SECONDS < deadline )); do
  if curl --fail --silent --show-error --max-time 2 "$url" >/dev/null 2>&1; then
    exit 0
  fi
  sleep 1
done

echo "ERROR: $url no respondió correctamente en ${timeout_seconds}s" >&2
exit 1
