#!/bin/bash
# =====================================================
# Script para hacer dump de la base de datos PostgreSQL
# FormalizeSE Hub
# =====================================================

set -e

STACK_NAME="formalizese-hub"
AWS_PROFILE="${AWS_PROFILE:-personal}"
AWS_REGION="${AWS_REGION:-sa-east-1}"
OUTPUT_DIR="${1:-.}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

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
    echo ""
    echo "Puedes especificar el endpoint manualmente:"
    echo "  DB_HOST=tu-endpoint.rds.amazonaws.com $0"
    exit 1
fi

# Permitir override manual del host
DB_HOST="${DB_HOST:-$DB_ENDPOINT}"

echo "✅ Endpoint: $DB_HOST:$DB_PORT/$DB_NAME"
echo ""

read -p "Usuario (default: postgres): " DB_USER
DB_USER=${DB_USER:-postgres}

read -sp "Contraseña: " DB_PASSWORD
echo ""

DUMP_FILE="$OUTPUT_DIR/formalizese_dump_$TIMESTAMP.sql"

echo ""
echo "📦 Generando dump en: $DUMP_FILE"
echo ""

export PGPASSWORD="$DB_PASSWORD"

pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
    --no-owner \
    --no-acl \
    --clean \
    --if-exists \
    -f "$DUMP_FILE"

unset PGPASSWORD

echo ""
echo "✅ Dump completado: $DUMP_FILE"
echo "   Tamaño: $(du -h "$DUMP_FILE" | cut -f1)"
