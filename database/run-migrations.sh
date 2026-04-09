#!/bin/bash

# =====================================================
# Script para ejecutar migraciones de base de datos
# FormalizeSE Hub - Infraestructura
# =====================================================

set -euo pipefail

# Desactivar set -e después de la fase de conexión (se reactiva solo donde es crítico)
# Para la fase de migraciones se maneja errores manualmente

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIGRATIONS_DIR="$SCRIPT_DIR/migrations"
STACK_NAME="formalizese-hub"
AWS_PROFILE="${AWS_PROFILE:-personal}"
AWS_REGION="${AWS_REGION:-sa-east-1}"
ENVIRONMENT="${1:-dev}"

# Validar ambiente
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo -e "${RED}Error: Ambiente inválido. Usa: dev, staging o prod${NC}"
    exit 1
fi

# Funciones
print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

# Main
print_header "Ejecutor de Migraciones - FormalizeSE Hub"

echo -e "Ambiente: ${BLUE}$ENVIRONMENT${NC}"
echo -e "Stack: ${BLUE}$STACK_NAME${NC}"
echo -e "Región: ${BLUE}$AWS_REGION${NC}\n"

# Validar que existe el directorio de migraciones
if [ ! -d "$MIGRATIONS_DIR" ]; then
    print_error "Directorio de migraciones no encontrado: $MIGRATIONS_DIR"
    exit 1
fi

print_info "Obteniendo información de la base de datos..."

# Obtener endpoint de la BD desde CloudFormation
DB_ENDPOINT=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --query 'Stacks[0].Outputs[?OutputKey==`DatabaseEndpoint`].OutputValue' \
    --output text \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" 2>/dev/null)

if [ -z "$DB_ENDPOINT" ]; then
    print_error "No se pudo obtener la información del stack '$STACK_NAME'"
    echo -e "${YELLOW}Asegúrate de que:${NC}"
    echo "  - El stack existe en CloudFormation"
    echo "  - Tienes credenciales configuradas (AWS_PROFILE=$AWS_PROFILE)"
    echo "  - Estás en la región correcta (AWS_REGION=$AWS_REGION)"
    exit 1
fi

DB_PORT="5432"
DB_NAME="formalizese"
DB_USER="postgres"

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

print_success "Conexión exitosa"
echo ""

# Crear tabla de control de migraciones si no existe
psql -h "$DB_ENDPOINT" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" << EOF > /dev/null 2>&1 || true
CREATE TABLE IF NOT EXISTS schema_version (
    version_rank integer,
    installed_rank integer,
    version varchar(50),
    description varchar(255),
    type varchar(20),
    script varchar(1000),
    checksum integer,
    installed_by varchar(100),
    installed_on timestamp,
    execution_time integer,
    success boolean,
    PRIMARY KEY (version)
);
EOF

print_info "Listando migraciones disponibles...\n"

# Obtener versiones ya ejecutadas
EXECUTED_VERSIONS=$(psql -h "$DB_ENDPOINT" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
    -t -c "SELECT version FROM schema_version ORDER BY installed_on DESC;" 2>/dev/null || echo "")

# Procesar migraciones
MIGRATION_COUNT=0
EXECUTED_COUNT=0
TOTAL_MIGRATIONS=$(find "$MIGRATIONS_DIR" -name "V*.sql" | wc -l)

for migration_file in $(find "$MIGRATIONS_DIR" -name "V*.sql" | sort); do
    filename=$(basename "$migration_file")
    version=$(echo "$filename" | sed 's/V\([0-9]*\)__.*/\1/')
    
    MIGRATION_COUNT=$((MIGRATION_COUNT + 1))
    
    # Verificar si ya fue ejecutada (trim espacios de psql)
    if echo "$EXECUTED_VERSIONS" | sed 's/^[[:space:]]*//' | grep -qx "$version"; then
        echo -e "  ${BLUE}[EJECUTADA]${NC} $filename"
        EXECUTED_COUNT=$((EXECUTED_COUNT + 1))
    else
        echo -e "  ${YELLOW}[PENDIENTE]${NC} $filename"
    fi
done

echo ""

# Contar migraciones pendientes
PENDING=$((TOTAL_MIGRATIONS - EXECUTED_COUNT))

if [ "$PENDING" -eq 0 ]; then
    print_success "Todas las migraciones ya han sido ejecutadas"
    unset PGPASSWORD
    exit 0
fi

echo -e "${YELLOW}Se ejecutarán $PENDING migraciones de $TOTAL_MIGRATIONS${NC}\n"

# Confirmar ejecución
read -p "¿Deseas continuar? (s/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    print_error "Operación cancelada"
    unset PGPASSWORD
    exit 1
fi

echo ""
print_info "Ejecutando migraciones...\n"

# Desactivar set -e para manejar errores de migración manualmente
set +e

# Ejecutar migraciones pendientes
ERROR_COUNT=0
SUCCESS_COUNT=0
FAILED_MIGRATIONS=""

for migration_file in $(find "$MIGRATIONS_DIR" -name "V*.sql" | sort); do
    filename=$(basename "$migration_file")
    version=$(echo "$filename" | sed 's/V\([0-9]*\)__.*/\1/')
    description=$(echo "$filename" | sed 's/V[0-9]*__\(.*\)\.sql/\1/')
    
    # Verificar si ya fue ejecutada (trim espacios de psql)
    if echo "$EXECUTED_VERSIONS" | sed 's/^[[:space:]]*//' | grep -qx "$version"; then
        continue
    fi
    
    echo -e "${YELLOW}→ Ejecutando:${NC} $filename"
    
    # Capturar salida y error de psql
    MIGRATION_OUTPUT=$(psql -h "$DB_ENDPOINT" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -f "$migration_file" 2>&1)
    MIGRATION_EXIT_CODE=$?
    
    if [ $MIGRATION_EXIT_CODE -eq 0 ]; then
        # Registrar en tabla de control
        psql -h "$DB_ENDPOINT" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
            -c "INSERT INTO schema_version (version, description, type, script, installed_by, installed_on, execution_time, success) 
                VALUES ('$version', '$description', 'SQL', '$filename', 'migration-script', NOW(), 0, true);" > /dev/null 2>&1
        
        print_success "$filename"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        print_error "$filename"
        echo -e "${RED}  Detalle del error:${NC}"
        echo "$MIGRATION_OUTPUT" | sed 's/^/    /'
        echo ""
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED_MIGRATIONS="$FAILED_MIGRATIONS\n    - $filename"
    fi
done

set -e

unset PGPASSWORD

echo ""
print_header "Resumen de la ejecución"

echo -e "  Exitosas:  ${GREEN}$SUCCESS_COUNT${NC}"
echo -e "  Fallidas:  ${RED}$ERROR_COUNT${NC}"
echo -e "  Omitidas:  ${BLUE}$EXECUTED_COUNT (ya ejecutadas)${NC}"
echo ""

if [ "$ERROR_COUNT" -eq 0 ]; then
    print_success "¡Todas las migraciones completadas exitosamente!"
    exit 0
else
    print_error "$ERROR_COUNT migraciones fallaron:"
    echo -e "$FAILED_MIGRATIONS"
    echo ""
    exit 1
fi
