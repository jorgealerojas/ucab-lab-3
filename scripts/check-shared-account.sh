#!/usr/bin/env bash
set -euo pipefail

expected_students="${1:?uso: check-shared-account.sh CANTIDAD_ESTUDIANTES}"
region="${AWS_REGION:-us-east-2}"

if ! [[ "$expected_students" =~ ^[1-9][0-9]*$ ]]; then
  echo "ERROR: la cantidad debe ser un entero positivo" >&2
  exit 1
fi

if [[ "$region" != "us-east-2" ]]; then
  echo "ERROR: este laboratorio está limitado a us-east-2; región recibida: $region" >&2
  exit 1
fi

quota=$(aws service-quotas get-service-quota \
  --service-code ec2 \
  --quota-code L-1216C47A \
  --region "$region" \
  --query 'Quota.Value' \
  --output text)

active_labs=$(aws ec2 describe-instances \
  --region "$region" \
  --filters \
    Name=tag:Course,Values=INFO-02028 \
    Name=instance-state-name,Values=pending,running \
  --query 'length(Reservations[].Instances[])' \
  --output text)

required_vcpus=$((expected_students * 2))

echo "Preflight de cuenta compartida"
echo "Región:                         $region"
echo "Estudiantes simultáneos:        $expected_students"
echo "vCPU requeridas por el grupo:   $required_vcpus"
echo "Cuota EC2 Standard On-Demand:   ${quota%.*}"
echo "Instancias activas de este lab: $active_labs"

if (( required_vcpus > ${quota%.*} )); then
  echo "ERROR: la cuota no permite ejecutar todos los laboratorios simultáneamente." >&2
  echo "Solicite al menos $required_vcpus vCPU en Service Quotas antes de la clase." >&2
  exit 1
fi

echo "Cuota nominal suficiente. Revise además créditos, otras instancias y límites IAM de la cuenta."
