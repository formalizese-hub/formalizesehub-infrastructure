-- V90: Separar configuracion_tns en tres campos independientes
--
-- homologacion_productos:
--   configuracion_tns JSONB (un solo campo mezclando conceptos TNS y cuentas contables)
--   → ambito         VARCHAR(20)  columna propia — TESORERIA | CONTABILIDAD | AMBOS
--   → conceptos_json JSONB        solo conceptos TNS: {subtotal, valor_pagar, impuestos, retenciones}
--   → cuentas_json   JSONB        solo cuentas contables: {subtotal, valor_pagar}
--
-- causacion_detalle_item:
--   configuracion_tns_snapshot JSONB
--   → conceptos_json_snapshot JSONB
--   → cuentas_json_snapshot   JSONB
--
-- Script de datos: descompone configuracion_tns existente en los tres campos nuevos.
-- El DROP de configuracion_tns va al final para poder leer los datos durante la migración.

BEGIN;

-- ─── 1. homologacion_productos — agregar columnas nuevas ─────────────────────

ALTER TABLE homologacion_productos
    ADD COLUMN IF NOT EXISTS ambito          VARCHAR(20)
        CHECK (ambito IN ('TESORERIA', 'CONTABILIDAD', 'AMBOS')),
    ADD COLUMN IF NOT EXISTS conceptos_json  JSONB,
    ADD COLUMN IF NOT EXISTS cuentas_json    JSONB;

COMMENT ON COLUMN homologacion_productos.ambito IS
    'Proceso configurado: TESORERIA (usa conceptos TNS), CONTABILIDAD (usa cuentas), AMBOS.';
COMMENT ON COLUMN homologacion_productos.conceptos_json IS
    'Configuración de conceptos TNS para tesorería.
     Estructura: { subtotal: {concepto_debito_id, concepto_credito_id},
                   valor_pagar: {concepto_debito_id, concepto_credito_id},
                   impuestos: [{codigo_impuesto_id}],
                   retenciones: [{retencion_id}] }';
COMMENT ON COLUMN homologacion_productos.cuentas_json IS
    'Configuración de cuentas contables para contabilidad.
     Estructura: { subtotal: {cuenta_debito_id, cuenta_credito_id},
                   valor_pagar: {cuenta_debito_id, cuenta_credito_id} }';

-- ─── 2. homologacion_productos — migrar datos desde configuracion_tns ────────

-- Ámbito: leer directo del JSON
UPDATE homologacion_productos
SET ambito = configuracion_tns->>'ambito'
WHERE configuracion_tns IS NOT NULL
  AND configuracion_tns->>'ambito' IS NOT NULL;

-- conceptos_json: extraer solo las claves de conceptos TNS
-- (concepto_debito_id y concepto_credito_id de subtotal y valor_pagar, más impuestos y retenciones)
UPDATE homologacion_productos
SET conceptos_json = jsonb_strip_nulls(jsonb_build_object(
    'subtotal', jsonb_strip_nulls(jsonb_build_object(
        'concepto_debito_id',  configuracion_tns->'subtotal'->>'concepto_debito_id',
        'concepto_credito_id', configuracion_tns->'subtotal'->>'concepto_credito_id'
    )),
    'valor_pagar', jsonb_strip_nulls(jsonb_build_object(
        'concepto_debito_id',  configuracion_tns->'valor_pagar'->>'concepto_debito_id',
        'concepto_credito_id', configuracion_tns->'valor_pagar'->>'concepto_credito_id'
    )),
    'impuestos',   COALESCE(configuracion_tns->'impuestos',   '[]'::jsonb),
    'retenciones', COALESCE(configuracion_tns->'retenciones', '[]'::jsonb)
))
WHERE configuracion_tns IS NOT NULL
  AND configuracion_tns->>'ambito' IN ('TESORERIA', 'AMBOS');

-- cuentas_json: extraer solo las claves de cuentas contables
UPDATE homologacion_productos
SET cuentas_json = jsonb_strip_nulls(jsonb_build_object(
    'subtotal', jsonb_strip_nulls(jsonb_build_object(
        'cuenta_debito_id',  configuracion_tns->'subtotal'->>'cuenta_debito_id',
        'cuenta_credito_id', configuracion_tns->'subtotal'->>'cuenta_credito_id'
    )),
    'valor_pagar', jsonb_strip_nulls(jsonb_build_object(
        'cuenta_debito_id',  configuracion_tns->'valor_pagar'->>'cuenta_debito_id',
        'cuenta_credito_id', configuracion_tns->'valor_pagar'->>'cuenta_credito_id'
    ))
))
WHERE configuracion_tns IS NOT NULL
  AND configuracion_tns->>'ambito' IN ('CONTABILIDAD', 'AMBOS');

-- ─── 3. homologacion_productos — eliminar campo unificado ────────────────────

ALTER TABLE homologacion_productos
    DROP COLUMN IF EXISTS configuracion_tns;

-- ─── 4. causacion_detalle_item — agregar columnas nuevas ─────────────────────

ALTER TABLE causacion_detalle_item
    ADD COLUMN IF NOT EXISTS conceptos_json_snapshot JSONB,
    ADD COLUMN IF NOT EXISTS cuentas_json_snapshot   JSONB;

COMMENT ON COLUMN causacion_detalle_item.conceptos_json_snapshot IS
    'Copia del conceptos_json de la homologación al momento de procesar. Para auditoría.';
COMMENT ON COLUMN causacion_detalle_item.cuentas_json_snapshot IS
    'Copia del cuentas_json de la homologación al momento de procesar. Para auditoría.';

-- ─── 5. causacion_detalle_item — migrar snapshot existente ───────────────────

-- conceptos_json_snapshot: extraer de configuracion_tns_snapshot
UPDATE causacion_detalle_item
SET conceptos_json_snapshot = jsonb_strip_nulls(jsonb_build_object(
    'subtotal', jsonb_strip_nulls(jsonb_build_object(
        'concepto_debito_id',  configuracion_tns_snapshot->'subtotal'->>'concepto_debito_id',
        'concepto_credito_id', configuracion_tns_snapshot->'subtotal'->>'concepto_credito_id'
    )),
    'valor_pagar', jsonb_strip_nulls(jsonb_build_object(
        'concepto_debito_id',  configuracion_tns_snapshot->'valor_pagar'->>'concepto_debito_id',
        'concepto_credito_id', configuracion_tns_snapshot->'valor_pagar'->>'concepto_credito_id'
    )),
    'impuestos',   COALESCE(configuracion_tns_snapshot->'impuestos',   '[]'::jsonb),
    'retenciones', COALESCE(configuracion_tns_snapshot->'retenciones', '[]'::jsonb)
))
WHERE configuracion_tns_snapshot IS NOT NULL
  AND configuracion_tns_snapshot->>'ambito' IN ('TESORERIA', 'AMBOS');

-- cuentas_json_snapshot: extraer de configuracion_tns_snapshot
UPDATE causacion_detalle_item
SET cuentas_json_snapshot = jsonb_strip_nulls(jsonb_build_object(
    'subtotal', jsonb_strip_nulls(jsonb_build_object(
        'cuenta_debito_id',  configuracion_tns_snapshot->'subtotal'->>'cuenta_debito_id',
        'cuenta_credito_id', configuracion_tns_snapshot->'subtotal'->>'cuenta_credito_id'
    )),
    'valor_pagar', jsonb_strip_nulls(jsonb_build_object(
        'cuenta_debito_id',  configuracion_tns_snapshot->'valor_pagar'->>'cuenta_debito_id',
        'cuenta_credito_id', configuracion_tns_snapshot->'valor_pagar'->>'cuenta_credito_id'
    ))
))
WHERE configuracion_tns_snapshot IS NOT NULL
  AND configuracion_tns_snapshot->>'ambito' IN ('CONTABILIDAD', 'AMBOS');

-- ─── 6. causacion_detalle_item — eliminar campo unificado ────────────────────

ALTER TABLE causacion_detalle_item
    DROP COLUMN IF EXISTS configuracion_tns_snapshot;

COMMIT;
