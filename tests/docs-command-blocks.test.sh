#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

awk '
  FNR == 1 { inside = 0 }
  /^```bash$/ {
    inside = 1
    command_lines = 0
    block_start = FNR
    next
  }
  inside && /^```$/ {
    if (command_lines != 1) {
      printf "ERROR: %s:%d contiene %d líneas ejecutables; se esperaba una.\n", FILENAME, block_start, command_lines > "/dev/stderr"
      failures++
    }
    inside = 0
    next
  }
  inside && NF { command_lines++ }
  END { exit failures }
' "$repo_dir/LAB_GUIDE.md" "$repo_dir/README.md"

echo "OK: cada bloque bash de la documentación contiene una sola acción"
