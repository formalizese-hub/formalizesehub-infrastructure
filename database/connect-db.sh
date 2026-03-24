#!/bin/bash

# =====================================================
# Script para conectarse a la base de datos PostgreSQL
# FormalizeSE Hub - Infraestructura consolidada
# =====================================================

set -e

STACK_NAME="formalizese-hub"
AWS_PROFILE="${AWS_PROFILE:-personal}"
AWS_REGION="${AWS_REGION:-sa-east-1}"

echo "📡 Obteniendo información de conexión..."
echo "   Stack: $STACK_NAME | Profile: $AWS_PROFILE | Region: $AWS_REGION"

DB_ENDPOINT=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --query 'Stacks[0].Outputs[?OutputKey==`DatabaseEndpoint`].OutputValue' \
    --output text \
    --profile $AWS_PROFILE \
    --region $AWS_REGION 2>/dev/null)

DB_PORT="5432"
DB_NAME="formalizese"

if [ -z "$DB_ENDPOINT" ]; then
    echo "❌ No se pudo obtener la información del stack '$STACK_NAME'"
    exit 1
fi

echo "✅ Conectando a: $DB_ENDPOINT:$DB_PORT/$DB_NAME"
echo ""

read -p "Usuario (default: postgres): " DB_USER
DB_USER=${DB_USER:-postgres}

read -sp "Contraseña: " DB_PASSWORD
echo ""
echo ""

export PGPASSWORD="$DB_PASSWORD"
psql -h "$DB_ENDPOINT" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME"
unset PGPASSWORD
