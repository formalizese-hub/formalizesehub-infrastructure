-- Proceso elegido explícitamente para toda una factura en causación detalle.
ALTER TABLE facturas
    ADD COLUMN IF NOT EXISTS tipo_proceso_override TEXT;

ALTER TABLE facturas
    DROP CONSTRAINT IF EXISTS facturas_tipo_proceso_override_check;

ALTER TABLE facturas
    ADD CONSTRAINT facturas_tipo_proceso_override_check
    CHECK (tipo_proceso_override IS NULL OR tipo_proceso_override IN ('inventario', 'tesoreria', 'contabilidad'));
