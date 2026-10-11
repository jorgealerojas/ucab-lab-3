#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d)
cleanup() { rm -rf "$test_dir"; }
trap cleanup EXIT

export AWS_MOCK_LOG="$test_dir/aws.log"
export HOME="$test_dir/home"
export PATH="$repo_dir/tests/bin:$PATH"
mkdir -p "$HOME"

output=$(AWS_REGION=us-east-2 "$repo_dir/scripts/deploy-lab.sh")
stack_name=$(sed -n 's/^Identificador generado: //p' <<<"$output" | head -n 1)

[[ "$stack_name" =~ ^ucab-lab-3-[0-9a-f]{16}$ ]]
[[ -f "$HOME/.ucab-lab-3/$stack_name" ]]
[[ "$(<"$HOME/.ucab-lab-3/$stack_name")" == "$stack_name" ]]
grep -q '^cloudformation create-stack ' "$AWS_MOCK_LOG"
grep -q 'ParameterKey=InstanceType' "$AWS_MOCK_LOG"
grep -q 'ParameterValue=c7i-flex.large' "$AWS_MOCK_LOG"
if grep -q '^cloudformation deploy ' "$AWS_MOCK_LOG"; then
  echo "El script no debe actualizar stacks existentes con cloudformation deploy" >&2
  exit 1
fi

export AWS_MOCK_COLLIDE_ONCE="$test_dir/collision.marker"
: >"$AWS_MOCK_LOG"
collision_output=$(AWS_REGION=us-east-2 "$repo_dir/scripts/deploy-lab.sh")
collision_stack=$(sed -n 's/^Identificador generado: //p' <<<"$collision_output" | head -n 1)
[[ "$collision_stack" =~ ^ucab-lab-3-[0-9a-f]{16}$ ]]
[[ "$(grep -c '^cloudformation describe-stacks ' "$AWS_MOCK_LOG")" -eq 2 ]]
[[ "$(grep -c '^cloudformation create-stack ' "$AWS_MOCK_LOG")" -eq 1 ]]
unset AWS_MOCK_COLLIDE_ONCE

if AWS_REGION=us-east-1 "$repo_dir/scripts/deploy-lab.sh" >"$test_dir/wrong-region.out" 2>&1; then
  echo "La región incorrecta debió ser rechazada" >&2
  exit 1
fi
grep -q 'us-east-2' "$test_dir/wrong-region.out"

if INSTANCE_TYPE=m5.large "$repo_dir/scripts/deploy-lab.sh" >"$test_dir/wrong-type.out" 2>&1; then
  echo "El tipo de instancia incorrecto debió ser rechazado" >&2
  exit 1
fi
grep -q 'INSTANCE_TYPE' "$test_dir/wrong-type.out"

echo "OK: despliegue, identificador automático y validaciones comprobados"
