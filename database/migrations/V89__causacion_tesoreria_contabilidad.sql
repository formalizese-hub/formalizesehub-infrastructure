-- V88: Causación a Tesorería y Contabilidad (conceptos y cuentas por movimiento)
--
-- 1. codigos_impuestos: reemplazar concepto_tns_id por 4 campos (débito/crédito × concepto/cuenta)
-- 2. retenciones: agregar los mismos 4 campos
-- 3. homologacion_productos: reemplazar concepto_tns_id y cuenta_contable_id por configuracion_tns JSONB
-- 4. causacion_detalle_item: agregar snapshot y cuenta resuelta
--
-- Los scripts de migración de datos se ejecutan ANTES de los DROP para preservar los valores existentes.

BEGIN;

-- ─── 1. codigos_impuestos ─────────────────────────────────────────────────────

-- Migrar valor existente: concepto_tns_id → concepto_credito_id (facturas son crédito)
ALTER TABLE codigos_impuestos
    ADD COLUMN IF NOT EXISTS concepto_credito_id  VARCHAR(50) REFERENCES concepto_tns(id);

UPDATE codigos_impuestos
SET concepto_credito_id = concepto_tns_id
WHERE concepto_tns_id IS NOT NULL
  AND concepto_credito_id IS NULL;

-- Agregar los 3 campos restantes y eliminar el campo viejo
ALTER TABLE codigos_impuestos
    ADD COLUMN IF NOT EXISTS concepto_debito_id   VARCHAR(50) REFERENCES concepto_tns(id),
    ADD COLUMN IF NOT EXISTS cuenta_debito_id     VARCHAR(50) REFERENCES cuentas_contables(id),
    ADD COLUMN IF NOT EXISTS cuenta_credito_id    VARCHAR(50) REFERENCES cuentas_contables(id),
    DROP COLUMN IF EXISTS concepto_tns_id;

COMMENT ON COLUMN codigos_impuestos.concepto_debito_id  IS 'Concepto TNS cuando el movimiento es débito (NC)';
COMMENT ON COLUMN codigos_impuestos.concepto_credito_id IS 'Concepto TNS cuando el movimiento es crédito (factura)';
COMMENT ON COLUMN codigos_impuestos.cuenta_debito_id    IS 'Cuenta contable cuando el movimiento es débito (NC)';
COMMENT ON COLUMN codigos_impuestos.cuenta_credito_id   IS 'Cuenta contable cuando el movimiento es crédito (factura)';

-- ─── 2. retenciones ───────────────────────────────────────────────────────────

-- retenciones no tenía concepto_tns_id previo — solo se agregan los 4 campos
ALTER TABLE retenciones
    ADD COLUMN IF NOT EXISTS concepto_debito_id   VARCHAR(50) REFERENCES concepto_tns(id),
    ADD COLUMN IF NOT EXISTS concepto_credito_id  VARCHAR(50) REFERENCES concepto_tns(id),
    ADD COLUMN IF NOT EXISTS cuenta_debito_id     VARCHAR(50) REFERENCES cuentas_contables(id),
    ADD COLUMN IF NOT EXISTS cuenta_credito_id    VARCHAR(50) REFERENCES cuentas_contables(id);

COMMENT ON COLUMN retenciones.concepto_debito_id  IS 'Concepto TNS cuando el movimiento es débito';
COMMENT ON COLUMN retenciones.concepto_credito_id IS 'Concepto TNS cuando el movimiento es crédito';
COMMENT ON COLUMN retenciones.cuenta_debito_id    IS 'Cuenta contable cuando el movimiento es débito';
COMMENT ON COLUMN retenciones.cuenta_credito_id   IS 'Cuenta contable cuando el movimiento es crédito';

-- ─── 3. homologacion_productos ────────────────────────────────────────────────

-- Agregar configuracion_tns antes de los DROP para poder migrar los datos
ALTER TABLE homologacion_productos
    ADD COLUMN IF NOT EXISTS configuracion_tns JSONB;

-- Migrar concepto_tns_id → configuracion_tns JSONB
-- Solo registros sin producto_empresa_id (flujo inventario no se toca)
UPDATE homologacion_productos
SET configuracion_tns = jsonb_build_object(
    'ambito',      'TESORERIA',
    'subtotal',    jsonb_build_object('concepto_credito_id', concepto_tns_id),
    'valor_pagar', jsonb_build_object('concepto_credito_id', concepto_tns_id),
    'impuestos',   '[]'::jsonb,
    'retenciones', '[]'::jsonb
)
WHERE concepto_tns_id IS NOT NULL
  AND producto_empresa_id IS NULL
  AND configuracion_tns IS NULL;

-- Eliminar las dos columnas reemplazadas por el JSONB
ALTER TABLE homologacion_productos
    DROP COLUMN IF EXISTS concepto_tns_id,
    DROP COLUMN IF EXISTS cuenta_contable_id;

COMMENT ON COLUMN homologacion_productos.configuracion_tns IS
'JSON con la configuración de tesorería/contabilidad del producto.
 Estructura: { ambito, subtotal: {concepto_debito_id, concepto_credito_id, cuenta_debito_id, cuenta_credito_id},
               valor_pagar: {...}, impuestos: [{codigo_impuesto_id}], retenciones: [{retencion_id}] }';

-- ─── 4. causacion_detalle_item ────────────────────────────────────────────────

ALTER TABLE causacion_detalle_item
    ADD COLUMN IF NOT EXISTS configuracion_tns_snapshot  JSONB,
    ADD COLUMN IF NOT EXISTS cuenta_contable_resuelta_id VARCHAR(50) REFERENCES cuentas_contables(id);

COMMENT ON COLUMN causacion_detalle_item.configuracion_tns_snapshot  IS
'Copia del configuracion_tns de la homologación al momento de procesar la factura. Permite auditar qué configuración se usó.';
COMMENT ON COLUMN causacion_detalle_item.cuenta_contable_resuelta_id IS
'Cuenta contable final asignada al ítem (flujo contabilidad/ambos), resuelta según el tipo de movimiento del documento.';

COMMIT;
