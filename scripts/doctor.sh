#!/usr/bin/env bash
set -euo pipefail

failures=0

check_command() {
  local command_name="$1"
  if command -v "$command_name" >/dev/null 2>&1; then
    printf 'OK    %-12s %s\n' "$command_name" "$(command -v "$command_name")"
  else
    printf 'FALTA %-12s no está instalado\n' "$command_name"
    failures=$((failures + 1))
  fi
}

echo "Diagnóstico de UCAB Lab 3"
if [[ -r /etc/ucab-lab-id ]]; then
  echo "INFO  LabId       $(</etc/ucab-lab-id)"
fi
for command_name in git make curl jq docker k3s; do
  check_command "$command_name"
done

if docker info >/dev/null 2>&1; then
  echo "OK    Docker      daemon accesible"
else
  echo "FALTA Docker      daemon no accesible; cierre la sesión y vuelva a entrar"
  failures=$((failures + 1))
fi

if [[ -f /var/lib/ucab-lab/ready ]]; then
  echo "OK    Bootstrap   completado"
else
  echo "FALTA Bootstrap   consulte /var/log/ucab-lab-bootstrap.log"
  failures=$((failures + 1))
fi

memory_mb=$(awk '/MemTotal/ {print int($2 / 1024)}' /proc/meminfo)
if (( memory_mb >= 3500 )); then
  echo "OK    Memoria     ${memory_mb} MiB"
else
  echo "AVISO Memoria     ${memory_mb} MiB; se recomiendan al menos 4 GiB"
fi

if (( failures > 0 )); then
  echo "Diagnóstico fallido: ${failures} requisito(s) pendiente(s)." >&2
  exit 1
fi

echo "Entorno listo. K3s puede estar detenido hasta ejecutar: make k8s-start"
