#!/bin/bash
# =====================================================
# FormalizeSE Hub — Test automatizado de endpoints
# Uso: export API_BASE_URL=https://xxxxx.execute-api.sa-east-1.amazonaws.com/dev
#      ./test-endpoints.sh
# =====================================================

BASE="${API_BASE_URL:-}"

if [ -z "$BASE" ]; then
    echo "❌ API_BASE_URL no configurada"
    echo "   export API_BASE_URL=https://xxxxx.execute-api.sa-east-1.amazonaws.com/dev"
    exit 1
fi

PASS=0
FAIL=0

green='\033[0;32m'
red='\033[0;31m'
yellow='\033[1;33m'
nc='\033[0m'

check() {
  local label="$1"
  local status="$2"
  local body="$3"
  local expected_status="$4"

  if [ "$status" -eq "$expected_status" ]; then
    echo -e "${green}✅ $label${nc} ($status)"
    PASS=$((PASS + 1))
  else
    echo -e "${red}❌ $label${nc} (esperado $expected_status, recibido $status)"
    echo "   Body: $body"
    FAIL=$((FAIL + 1))
  fi
}

echo ""
echo "=================================================="
echo " FormalizeSE Hub — Test de endpoints"
echo "=================================================="

# ─────────────────────────────────────────────────────
# CLIENTES
# ─────────────────────────────────────────────────────
echo ""
echo -e "${yellow}── CLIENTES ──${nc}"

RESP=$(curl -s -o /tmp/body.json -w "%{http_code}" "$BASE/clientes")
check "GET /clientes" "$RESP" "$(cat /tmp/body.json)" 200

# Crear (NIT dinámico para evitar duplicados)
TS=$(date +%s)
RESP=$(curl -s -o /tmp/body.json -w "%{http_code}" -X POST "$BASE/clientes" \
  -H "Content-Type: application/json" \
  -d "{\"nombre\":\"Test Cliente\",\"nit\":\"999-${TS}\",\"direccion\":\"Calle Test 1\",\"telefono\":\"+57 300 0000001\",\"email\":\"test${TS}@cliente.com\",\"contacto_principal\":\"Test User\",\"activo\":true,\"prefijo_facturas\":[\"TEST\"]}")
check "POST /clientes" "$RESP" "$(cat /tmp/body.json)" 201
CLIENTE_ID=$(cat /tmp/body.json | python3 -c "import sys,json; print(json.load(sys.stdin).get('data',{}).get('id',''))" 2>/dev/null)

if [ -n "$CLIENTE_ID" ]; then
  RESP=$(curl -s -o /tmp/body.json -w "%{http_code}" "$BASE/clientes/$CLIENTE_ID")
  check "GET /clientes/$CLIENTE_ID" "$RESP" "$(cat /tmp/body.json)" 200

  RESP=$(curl -s -o /tmp/body.json -w "%{http_code}" -X PUT "$BASE/clientes/$CLIENTE_ID" \
    -H "Content-Type: application/json" \
    -d '{"nombre":"Test Cliente Actualizado"}')
  check "PUT /clientes/$CLIENTE_ID" "$RESP" "$(cat /tmp/body.json)" 200

  RESP=$(curl -s -o /tmp/body.json -w "%{http_code}" -X DELETE "$BASE/clientes/$CLIENTE_ID")
  check "DELETE /clientes/$CLIENTE_ID" "$RESP" "$(cat /tmp/body.json)" 204
fi


# ─────────────────────────────────────────────────────
# PROVEEDORES
# ─────────────────────────────────────────────────────
echo ""
echo -e "${yellow}── PROVEEDORES ──${nc}"

RESP=$(curl -s -o /tmp/body.json -w "%{http_code}" "$BASE/proveedores")
check "GET /proveedores" "$RESP" "$(cat /tmp/body.json)" 200

RESP=$(curl -s -o /tmp/body.json -w "%{http_code}" -X POST "$BASE/proveedores" \
  -H "Content-Type: application/json" \
  -d "{\"nombre\":\"Test Proveedor\",\"nit\":\"111-${TS}\",\"direccion\":\"Av Test 2\",\"telefono\":\"+57 311 0000002\",\"email\":\"prov${TS}@test.com\",\"contacto_principal\":\"Test Proveedor User\",\"activo\":true}")
check "POST /proveedores" "$RESP" "$(cat /tmp/body.json)" 201
PROVEEDOR_ID=$(cat /tmp/body.json | python3 -c "import sys,json; print(json.load(sys.stdin).get('data',{}).get('id',''))" 2>/dev/null)

if [ -n "$PROVEEDOR_ID" ]; then
  RESP=$(curl -s -o /tmp/body.json -w "%{http_code}" "$BASE/proveedores/$PROVEEDOR_ID")
  check "GET /proveedores/$PROVEEDOR_ID" "$RESP" "$(cat /tmp/body.json)" 200

  RESP=$(curl -s -o /tmp/body.json -w "%{http_code}" -X PUT "$BASE/proveedores/$PROVEEDOR_ID" \
    -H "Content-Type: application/json" \
    -d '{"nombre":"Test Proveedor Actualizado"}')
  check "PUT /proveedores/$PROVEEDOR_ID" "$RESP" "$(cat /tmp/body.json)" 200

  RESP=$(curl -s -o /tmp/body.json -w "%{http_code}" -X DELETE "$BASE/proveedores/$PROVEEDOR_ID")
  check "DELETE /proveedores/$PROVEEDOR_ID" "$RESP" "$(cat /tmp/body.json)" 200
fi


# ─────────────────────────────────────────────────────
# CUENTAS CONTABLES
# ─────────────────────────────────────────────────────
echo ""
echo -e "${yellow}── CUENTAS CONTABLES ──${nc}"

RESP=$(curl -s -o /tmp/body.json -w "%{http_code}" "$BASE/cuentas-contables")
check "GET /cuentas-contables" "$RESP" "$(cat /tmp/body.json)" 200


# ─────────────────────────────────────────────────────
# PARAMETRIZACIÓN
# ─────────────────────────────────────────────────────
echo ""
echo -e "${yellow}── PARAMETRIZACIÓN ──${nc}"

RESP=$(curl -s -o /tmp/body.json -w "%{http_code}" "$BASE/proveedores-por-cuentas")
check "GET /proveedores-por-cuentas" "$RESP" "$(cat /tmp/body.json)" 200


# ─────────────────────────────────────────────────────
# DESCARGAS
# ─────────────────────────────────────────────────────
echo ""
echo -e "${yellow}── DESCARGAS ──${nc}"

RESP=$(curl -s -o /tmp/body.json -w "%{http_code}" "$BASE/descargas")
check "GET /descargas" "$RESP" "$(cat /tmp/body.json)" 200


# ─────────────────────────────────────────────────────
# RESUMEN
# ─────────────────────────────────────────────────────
echo ""
echo "=================================================="
echo -e " ${green}✅ Pasaron: $PASS${nc}  |  ${red}❌ Fallaron: $FAIL${nc}"
echo "=================================================="
echo ""
