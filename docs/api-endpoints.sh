#!/bin/bash
# =====================================================
# FormalizeSE Hub — Pruebas de endpoints API
# =====================================================

# Set your API Gateway URL here or export API_BASE_URL before running
BASE="${API_BASE_URL:-https://YOUR_API_GATEWAY_ID.execute-api.sa-east-1.amazonaws.com/dev}"

if [[ "$BASE" == *"YOUR_API_GATEWAY_ID"* ]]; then
    echo "⚠️  Configure API_BASE_URL antes de ejecutar:"
    echo "   export API_BASE_URL=https://xxxxx.execute-api.sa-east-1.amazonaws.com/dev"
    exit 1
fi

# ─────────────────────────────────────────────────────
# CLIENTES
# ─────────────────────────────────────────────────────

# Listar todos los clientes
curl "$BASE/clientes"

# Obtener cliente por ID
curl "$BASE/clientes/{id}"

# Crear cliente
curl -X POST "$BASE/clientes" \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "Acme S.A.S.",
    "nit": "901234567-1",
    "direccion": "Cra 7 #32-10, Bogotá",
    "telefono": "+57 310 1234567",
    "email": "admin@acme.com",
    "contacto_principal": "Pedro López",
    "activo": true,
    "prefijo_facturas": ["ACME", "FV"]
  }'

# Actualizar cliente
curl -X PUT "$BASE/clientes/{id}" \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "Acme Colombia S.A.S.",
    "telefono": "+57 320 9876543"
  }'

# Eliminar cliente (soft delete)
curl -X DELETE "$BASE/clientes/{id}"


# ─────────────────────────────────────────────────────
# PROVEEDORES
# ─────────────────────────────────────────────────────

# Listar todos los proveedores
curl "$BASE/proveedores"

# Obtener proveedor por ID
curl "$BASE/proveedores/{id}"

# Crear proveedor
curl -X POST "$BASE/proveedores" \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "Servicios Técnicos Ltda.",
    "nit": "800111222-5",
    "direccion": "Av. El Dorado #68-50, Bogotá",
    "telefono": "+57 315 5556666",
    "email": "contacto@servicios.com",
    "contacto_principal": "Ana Martínez",
    "activo": true
  }'

# Actualizar proveedor
curl -X PUT "$BASE/proveedores/{id}" \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "Servicios Técnicos Colombia Ltda.",
    "telefono": "+57 315 9998888"
  }'

# Eliminar proveedor (soft delete)
curl -X DELETE "$BASE/proveedores/{id}"


# ─────────────────────────────────────────────────────
# CUENTAS CONTABLES
# ─────────────────────────────────────────────────────

# Listar todas las cuentas contables
curl "$BASE/cuentas-contables"

# Obtener cuenta contable por ID
curl "$BASE/cuentas-contables/{id}"

# Crear cuenta contable
# tipo_cuenta: ACTIVO | PASIVO | PATRIMONIO | INGRESO | GASTO | COSTO
# naturaleza_cuenta: DEBITO | CREDITO
# nivel_cuenta: 1=Clase, 2=Grupo, 3=Cuenta, 4=Subcuenta, 5=Auxiliar
curl -X POST "$BASE/cuentas-contables" \
  -H "Content-Type: application/json" \
  -d '{
    "cliente_id": "cliente-001",
    "codigo_cuenta": "6205",
    "nombre_cuenta": "HORAS EXTRAS Y RECARGOS",
    "tipo_cuenta": "GASTO",
    "nivel_cuenta": 3,
    "cuenta_padre_id": "cuenta-003",
    "naturaleza_cuenta": "DEBITO",
    "acepta_movimientos": false,
    "activa": true,
    "descripcion": "Horas extras y recargos laborales"
  }'

# Actualizar cuenta contable
curl -X PUT "$BASE/cuentas-contables/{id}" \
  -H "Content-Type: application/json" \
  -d '{
    "nombre_cuenta": "HORAS EXTRAS, RECARGOS Y DOMINICALES",
    "descripcion": "Horas extras, recargos nocturnos y dominicales"
  }'

# Eliminar cuenta contable (soft delete)
curl -X DELETE "$BASE/cuentas-contables/{id}"

# Carga masiva de cuentas contables (desde archivo Excel/CSV)
curl -X POST "$BASE/cuentas-contables/cargar-masiva" \
  -H "Content-Type: application/json" \
  -d '{
    "cliente_id": "cliente-001",
    "cuentas": [
      {
        "codigo_cuenta": "1105",
        "nombre_cuenta": "CAJA",
        "tipo_cuenta": "ACTIVO",
        "nivel_cuenta": 3,
        "naturaleza_cuenta": "DEBITO"
      }
    ]
  }'


# ─────────────────────────────────────────────────────
# PARAMETRIZACIÓN — Proveedor por Cuenta Contable
# ─────────────────────────────────────────────────────

# Listar todas las parametrizaciones
curl "$BASE/proveedores-por-cuentas"

# Obtener parametrización por ID
curl "$BASE/proveedores-por-cuentas/{id}"

# Crear parametrización (asociar proveedor a cuenta contable)
curl -X POST "$BASE/proveedores-por-cuentas" \
  -H "Content-Type: application/json" \
  -d '{
    "cuenta_contable_id": "cuenta-012",
    "proveedor_id": "proveedor-001",
    "prioridad": 1,
    "activo": true,
    "notas": "Cuenta principal para honorarios"
  }'

# Actualizar parametrización
curl -X PUT "$BASE/proveedores-por-cuentas/{id}" \
  -H "Content-Type: application/json" \
  -d '{
    "prioridad": 2,
    "notas": "Cuenta secundaria para honorarios"
  }'

# Eliminar parametrización
curl -X DELETE "$BASE/proveedores-por-cuentas/{id}"


# ─────────────────────────────────────────────────────
# DESCARGAS DIAN
# ─────────────────────────────────────────────────────

# Listar todas las descargas
curl "$BASE/descargas"

# Obtener descarga por ID
curl "$BASE/descargas/{id}"

# Iniciar descarga de facturas desde DIAN
curl -X POST "$BASE/dian/download" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "cliente-001",
    "fechaInicio": "2026-01-01",
    "fechaFin": "2026-01-31",
    "dianCookies": "cookie_string_from_browser"
  }'


# ─────────────────────────────────────────────────────
# FACTURAS
# ─────────────────────────────────────────────────────

# Obtener factura por ID
curl "$BASE/facturas/{id}"
