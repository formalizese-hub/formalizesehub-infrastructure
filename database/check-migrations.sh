#!/bin/bash

# =====================================================
# Script para ver el historial de migraciones ejecutadas
# FormalizeSE Hub - Infraestructura
# =====================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuración
AWS_PROFILE="${AWS_PROFILE:-formalizese-new}"
AWS_REGION="${AWS_REGION:-sa-east-1}"
DB_ENDPOINT="${DB_HOST:-formalizese-db-dev.crm4ysgme3wx.sa-east-1.rds.amazonaws.com}"
DB_PORT="5432"
DB_NAME="formalizese"
DB_USER="postgres"

# Funciones
print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

# Main
print_header "Historial de Migraciones - FormalizeSE Hub"

echo -e "Host: ${BLUE}$DB_ENDPOINT${NC}"
echo -e "Base de datos: ${BLUE}$DB_NAME${NC}"
echo -e "Región: ${BLUE}$AWS_REGION${NC}\n"

# Leer contraseña
read -sp "Contraseña de PostgreSQL ($DB_USER@$DB_ENDPOINT): " DB_PASSWORD
echo ""
echo ""

# Validar conexión
print_info "Validando conexión a la base de datos..."
export PGPASSWORD="$DB_PASSWORD"

if ! psql -h "$DB_ENDPOINT" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
    -c "SELECT version();" > /dev/null 2>&1; then
    unset PGPASSWORD
    print_error "No se pudo conectar a la base de datos"
    exit 1
fi

echo -e "${GREEN}✓ Conexión exitosa${NC}\n"

# Verificar si la tabla existe
TABLE_EXISTS=$(psql -h "$DB_ENDPOINT" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
    -t -c "SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'schema_version');" 2>/dev/null)

if [ "$TABLE_EXISTS" = "f" ]; then
    print_error "Tabla 'schema_version' no existe. No hay migraciones registradas."
    unset PGPASSWORD
    exit 0
fi

# Consultar migraciones
echo -e "${BLUE}Migraciones ejecutadas:${NC}\n"

psql -h "$DB_ENDPOINT" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
    -c "SELECT 
        version,
        description,
        installed_by,
        installed_on,
        success
    FROM schema_version
    ORDER BY version ASC;" 2>/dev/null

echo ""

# Contar migraciones
TOTAL=$(psql -h "$DB_ENDPOINT" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
    -t -c "SELECT COUNT(*) FROM schema_version;" 2>/dev/null)

echo -e "${GREEN}Total de migraciones ejecutadas: $TOTAL${NC}\n"

unset PGPASSWORD
