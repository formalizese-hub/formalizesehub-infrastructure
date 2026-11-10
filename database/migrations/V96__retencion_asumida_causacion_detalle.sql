-- V96: Retención asumida en causación a detalle.
--
-- 1. Dos campos en cuentas_contables para vincular la cuenta de retención asumida
--    con el concepto TNS que se usa al generar el archivo de Tesorería.
--    La cuenta aplica también a Contabilidad, pero ahí no se usa concepto TNS
--    sino la propia cuenta (igual que redistribución recibida).
--
--    concepto_tns_compra_id     → concepto TNS cuando el documento es una compra (FC)
--    concepto_tns_devolucion_id → concepto TNS cuando el documento es una devolución en compra (DC)
--
-- 2. Tres flags booleanos en causacion_detalle para persistir la decisión
--    de retención asumida al momento del reproceso, siguiendo el mismo patrón
--    que redistribucion_contable.retencion_asumida / reteiva_asumida / reteica_asumida.
--
-- 3. Los campos nuevos en cuentas_contables solo se rellenan en las cuentas que
--    la empresa parametriza como:
--      empresas.cuenta_retencion_asumida
--      empresas.cuenta_reteiva_asumida
--      empresas.cuenta_reteica_asumida
--    La restricción es de negocio, no de BD (cualquier cuenta puede tener el campo,
--    pero solo tiene sentido en las tres de retención asumida).

-- ── 1. Plan de cuentas ────────────────────────────────────────────────────────

ALTER TABLE cuentas_contables
    ADD COLUMN IF NOT EXISTS concepto_tns_compra_id     UUID
        REFERENCES concepto_tns(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS concepto_tns_devolucion_id UUID
        REFERENCES concepto_tns(id) ON DELETE SET NULL;

COMMENT ON COLUMN cuentas_contables.concepto_tns_compra_id
    IS 'Concepto TNS a usar en el archivo de Tesorería cuando el documento es una compra (FC). Solo relevante en cuentas de retención asumida.';
COMMENT ON COLUMN cuentas_contables.concepto_tns_devolucion_id
    IS 'Concepto TNS a usar en el archivo de Tesorería cuando el documento es una devolución en compra (DC). Solo relevante en cuentas de retención asumida.';

-- Índice para lookups rápidos desde los generadores de archivo (tesorería).
CREATE INDEX IF NOT EXISTS idx_cuentas_contables_concepto_tns_compra
    ON cuentas_contables(concepto_tns_compra_id)
    WHERE concepto_tns_compra_id IS NOT NULL AND deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_cuentas_contables_concepto_tns_devolucion
    ON cuentas_contables(concepto_tns_devolucion_id)
    WHERE concepto_tns_devolucion_id IS NOT NULL AND deleted_at IS NULL;

-- ── 2. Flags de retención asumida en causacion_detalle ───────────────────────

ALTER TABLE causacion_detalle
    ADD COLUMN IF NOT EXISTS retencion_asumida   BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS reteiva_asumida     BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS reteica_asumida     BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN causacion_detalle.retencion_asumida
    IS 'Si true, la retención en la fuente de esta causación es asumida por la empresa (no descuenta del valor a pagar al proveedor).';
COMMENT ON COLUMN causacion_detalle.reteiva_asumida
    IS 'Si true, la ReteIVA de esta causación es asumida por la empresa.';
COMMENT ON COLUMN causacion_detalle.reteica_asumida
    IS 'Si true, la ReteICA de esta causación es asumida por la empresa.';
