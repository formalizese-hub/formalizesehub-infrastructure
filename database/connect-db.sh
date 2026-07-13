#!/bin/bash

# =====================================================
# Script para conectarse a la base de datos PostgreSQL
# FormalizeSE Hub
# =====================================================

set -e

AWS_PROFILE="${AWS_PROFILE:-formalizese-new}"
AWS_REGION="${AWS_REGION:-sa-east-1}"

DB_HOST="formalizese-db-dev.crm4ysgme3wx.sa-east-1.rds.amazonaws.com"
DB_PORT="5432"
DB_NAME="formalizese"
DB_USER="postgres"

# Intentar obtener password desde SSM
echo "🔑 Obteniendo contraseña desde SSM..."
DB_PASSWORD=$(aws ssm get-parameter \
    --name "/formalizese/dev/db-password" \
    --with-decryption \
    --query 'Parameter.Value' \
    --output text \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" 2>/dev/null)

if [ -z "$DB_PASSWORD" ]; then
    echo "⚠️  No se pudo obtener la contraseña de SSM. Ingresándola manualmente..."
    read -sp "Contraseña: " DB_PASSWORD
    echo ""
fi

echo "✅ Conectando a: $DB_HOST:$DB_PORT/$DB_NAME (user: $DB_USER)"
echo ""

PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME"
