-- V82: Causación a tesorería y contabilidad — conceptos/cuentas por producto (JSONB)
--
-- Modelo:
--   - codigos_impuestos.concepto_tns_id: concepto TNS asociado a cada impuesto
--   - retenciones.concepto_tns_id: concepto TNS asociado a cada retención
--   - homologacion_productos.conceptos (JSONB): tesorería por producto
--   - homologacion_productos.cuentas  (JSONB): contabilidad por producto
--
-- Se ELIMINAN las columnas individuales viejas concepto_tns_id y cuenta_contable_id
-- de homologacion_productos (reemplazadas por los JSONB).
--
-- Estructura de ambos JSON (conceptos usa concepto_tns_id, cuentas usa cuenta_contable_id):
--   {
--     subtotal:    { concepto_tns_id | cuenta_contable_id },
--     valor_pagar: { concepto_tns_id | cuenta_contable_id },
--     impuestos:   { "<tipo_impuesto>": { codigo_impuesto_id } },
--     retenciones: { "rete_fuente|rete_iva|rete_ica": { retencion_id } }
--   }
-- El concepto/cuenta de impuestos y retenciones se resuelve en LECTURA via JOIN.

-- 1. Concepto TNS asociado a cada código de impuesto
ALTER TABLE codigos_impuestos
    ADD COLUMN IF NOT EXISTS concepto_tns_id VARCHAR(50) REFERENCES concepto_tns(id);
COMMENT ON COLUMN codigos_impuestos.concepto_tns_id IS
'Concepto TNS asociado a este impuesto. Se usa al seleccionar el impuesto en tesorería.';

-- 2. Concepto TNS asociado a cada retención
ALTER TABLE retenciones
    ADD COLUMN IF NOT EXISTS concepto_tns_id VARCHAR(50) REFERENCES concepto_tns(id);
COMMENT ON COLUMN retenciones.concepto_tns_id IS
'Concepto TNS asociado a esta retención. Se usa al seleccionar la retención en tesorería.';

-- 3. Reemplazar campos individuales por JSONB en homologacion_productos
ALTER TABLE homologacion_productos
    DROP COLUMN IF EXISTS concepto_tns_id,
    DROP COLUMN IF EXISTS cuenta_contable_id,
    ADD COLUMN IF NOT EXISTS conceptos JSONB,
    ADD COLUMN IF NOT EXISTS cuentas   JSONB;

COMMENT ON COLUMN homologacion_productos.conceptos IS
'Conceptos de tesorería del producto (JSONB). Estructura: subtotal/valor_pagar con concepto_tns_id; impuestos/retenciones con codigo_impuesto_id/retencion_id. El concepto se resuelve en lectura.';
COMMENT ON COLUMN homologacion_productos.cuentas IS
'Cuentas contables del producto para contabilidad (JSONB). Misma estructura que conceptos pero con cuenta_contable_id.';
