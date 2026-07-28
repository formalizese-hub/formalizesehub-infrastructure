#!/bin/bash
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIGRATIONS_DIR="$SCRIPT_DIR/migrations"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-formalizese}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-}"
DB_SSLMODE="${DB_SSLMODE:-require}"
echo "Host: $DB_HOST:$DB_PORT  DB: $DB_NAME  SSL: $DB_SSLMODE"
if [ -z "$DB_PASSWORD" ]; then
    read -sp "Contrasena de PostgreSQL ($DB_USER@$DB_HOST): " DB_PASSWORD
    echo ""
fi
export PGPASSWORD="$DB_PASSWORD"
CONNSTR="host=$DB_HOST port=$DB_PORT dbname=$DB_NAME user=$DB_USER sslmode=$DB_SSLMODE"
if [ ! -d "$MIGRATIONS_DIR" ]; then
    echo "ERROR: Directorio de migraciones no encontrado: $MIGRATIONS_DIR"
    exit 1
fi
echo "-> Validando conexion..."
if ! psql "$CONNSTR" -c "SELECT 1;" > /dev/null 2>&1; then
    echo "ERROR: No se pudo conectar a la base de datos"
    unset PGPASSWORD
    exit 1
fi
echo "OK Conexion exitosa"
psql "$CONNSTR" -c "CREATE EXTENSION IF NOT EXISTS pgcrypto;" > /dev/null 2>&1
psql "$CONNSTR" << EOF > /dev/null 2>&1
CREATE TABLE IF NOT EXISTS schema_version (
    version varchar(50) PRIMARY KEY,
    description varchar(255),
    type varchar(20),
    script varchar(1000),
    installed_by varchar(100),
    installed_on timestamp,
    success boolean
);
EOF
EXECUTED_VERSIONS=$(psql "$CONNSTR" -t -c "SELECT version FROM schema_version;" 2>/dev/null || echo "")
SUCCESS_COUNT=0
ERROR_COUNT=0
SKIPPED_COUNT=0
for migration_file in $(find "$MIGRATIONS_DIR" -name "V*.sql" | sort -t'V' -k2 -n); do
    filename=$(basename "$migration_file")
    version=$(echo "$filename" | sed 's/V\([0-9]*\)__.*/\1/')
    description=$(echo "$filename" | sed 's/V[0-9]*__\(.*\)\.sql/\1/')
    if echo "$EXECUTED_VERSIONS" | sed 's/^[[:space:]]*//' | grep -qx "$version"; then
        echo "  [OMITIDA] $filename"
        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
        continue
    fi
    echo "-> Ejecutando: $filename"
    OUTPUT=$(psql "$CONNSTR" -f "$migration_file" 2>&1)
    if [ $? -eq 0 ]; then
        psql "$CONNSTR" -c "INSERT INTO schema_version (version, description, type, script, installed_by, installed_on, success) VALUES ('$version', '$description', 'SQL', '$filename', 'local-script', NOW(), true);" > /dev/null 2>&1
        echo "OK $filename"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "ERROR $filename"
        echo "$OUTPUT" | sed 's/^/    /'
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
done
unset PGPASSWORD
echo ""
echo "Resumen: Exitosas=$SUCCESS_COUNT Fallidas=$ERROR_COUNT Omitidas=$SKIPPED_COUNT"
[ "$ERROR_COUNT" -eq 0 ]
