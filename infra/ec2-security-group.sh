#!/bin/bash
# ──────────────────────────────────────────────────────────────
# Security Group Setup — Greeting Service EC2 EP3
# ──────────────────────────────────────────────────────────────
set -euo pipefail

SG_NAME="greeting-ec2-sg"
REGION="${AWS_REGION:-us-east-1}"
DESCRIPTION="Greeting Service EP3 — Frontend (80), API (8080), SSH (22)"

# Verificar si el SG ya existe
EXISTING=$(aws ec2 describe-security-groups \
  --region "$REGION" \
  --filters "Name=group-name,Values=$SG_NAME" \
  --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null || echo "")

if [ -n "$EXISTING" ] && [ "$EXISTING" != "None" ]; then
  echo "Security Group already exists: $EXISTING"
  echo "$EXISTING"
  exit 0
fi

echo "Creating Security Group: $SG_NAME"

SG_ID=$(aws ec2 create-security-group \
  --region "$REGION" \
  --group-name "$SG_NAME" \
  --description "$DESCRIPTION" \
  --query 'GroupId' --output text)

echo "Security Group created: $SG_ID"

# Etiquetar
aws ec2 create-tags \
  --region "$REGION" \
  --resources "$SG_ID" \
  --tags Key=Name,Value="$SG_NAME" Key=Project,Value=greeting-service Key=Environment,Value=EP3

# Reglas de entrada
echo "Adding inbound rules..."

aws ec2 authorize-security-group-ingress \
  --region "$REGION" \
  --group-id "$SG_ID" --protocol tcp --port 22 --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
  --region "$REGION" \
  --group-id "$SG_ID" --protocol tcp --port 80 --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
  --region "$REGION" \
  --group-id "$SG_ID" --protocol tcp --port 8080 --cidr 0.0.0.0/0

echo "Security Group ready: $SG_ID"
echo "$SG_ID"
