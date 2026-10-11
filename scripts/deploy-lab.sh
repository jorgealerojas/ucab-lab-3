#!/usr/bin/env bash
set -euo pipefail

region="${AWS_REGION:-us-east-2}"
instance_type="${INSTANCE_TYPE:-c7i-flex.large}"
repository_raw_base="${REPOSITORY_RAW_BASE:-https://raw.githubusercontent.com/jorgealerojas/ucab-lab-3/main}"
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

if [[ "$region" != "us-east-2" ]]; then
  echo "ERROR: seleccione US East (Ohio), us-east-2, antes de desplegar." >&2
  exit 1
fi

if [[ "$instance_type" != "c7i-flex.large" && "$instance_type" != "t3.small" ]]; then
  echo "ERROR: INSTANCE_TYPE debe ser c7i-flex.large o t3.small." >&2
  exit 1
fi

command -v aws >/dev/null 2>&1 || {
  echo "ERROR: no se encontró AWS CLI. Ejecute este script desde AWS CloudShell." >&2
  exit 1
}

aws sts get-caller-identity --region "$region" >/dev/null

for _ in $(seq 1 10); do
  suffix=$(od -An -N8 -tx1 /dev/urandom | tr -d ' \n')
  stack_name="ucab-lab-3-$suffix"
  if ! aws cloudformation describe-stacks \
    --stack-name "$stack_name" \
    --region "$region" >/dev/null 2>&1; then
    break
  fi
  stack_name=""
done

if [[ -z "${stack_name:-}" ]]; then
  echo "ERROR: no se pudo generar un nombre de stack libre después de 10 intentos." >&2
  exit 1
fi

template_file=$(mktemp --suffix=.yaml)
cleanup() { rm -f "$template_file"; }
trap cleanup EXIT

if [[ -f "$script_dir/../infra/lab-stack.yaml" ]]; then
  cp "$script_dir/../infra/lab-stack.yaml" "$template_file"
else
  curl --fail --silent --show-error --location \
    "$repository_raw_base/infra/lab-stack.yaml" \
    --output "$template_file"
fi

echo "Identificador generado: $stack_name"
echo "Tipo de instancia:       $instance_type"
echo "Creando el laboratorio en $region (puede tardar entre 3 y 8 minutos)..."

aws cloudformation create-stack \
  --template-body "file://$template_file" \
  --stack-name "$stack_name" \
  --capabilities CAPABILITY_IAM \
  --parameters "ParameterKey=InstanceType,ParameterValue=$instance_type" \
  --region "$region" >/dev/null

if ! aws cloudformation wait stack-create-complete \
  --stack-name "$stack_name" \
  --region "$region"; then
  echo "ERROR: CloudFormation no pudo completar el laboratorio." >&2
  echo "Últimos eventos:" >&2
  aws cloudformation describe-stack-events \
    --stack-name "$stack_name" \
    --region "$region" \
    --query 'StackEvents[0:8].[Timestamp,LogicalResourceId,ResourceStatus,ResourceStatusReason]' \
    --output table >&2 || true
  echo "Consulte TROUBLESHOOTING.md antes de reintentar." >&2
  exit 1
fi

receipt_dir="$HOME/.ucab-lab-3"
mkdir -p "$receipt_dir"
printf '%s\n' "$stack_name" >"$receipt_dir/$stack_name"

cat <<EOF

LABORATORIO LISTO
Identificador y stack: $stack_name
Instancia EC2:         $stack_name

Guarde este valor en su evidencia. Para eliminar únicamente este laboratorio:
aws cloudformation delete-stack --stack-name '$stack_name' --region '$region'
aws cloudformation wait stack-delete-complete --stack-name '$stack_name' --region '$region'
EOF
