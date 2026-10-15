-- V75__add_consecutivo_causacion_detalle.sql
-- Consecutivo (numero_comprobante) y tipo de comprobante (FC/DC) para la causación
-- a detalle, análogo a redistribucion_contable. El consecutivo se asigna por
-- (empresa_id, tipo_comprobante, codigo_prefijo) al generar el archivo TNS.

ALTER TABLE causacion_detalle
    ADD COLUMN IF NOT EXISTS tipo_comprobante   VARCHAR(10) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS numero_comprobante VARCHAR(20) DEFAULT NULL;

COMMENT ON COLUMN causacion_detalle.tipo_comprobante   IS 'Tipo de transacción TNS: FC (compra) | DC (nota crédito/ajuste)';
COMMENT ON COLUMN causacion_detalle.numero_comprobante IS 'Consecutivo asignado al generar el TNS (por empresa+tipo_comprobante+codigo_prefijo)';

CREATE INDEX IF NOT EXISTS idx_causacion_detalle_consecutivo
    ON causacion_detalle(empresa_id, tipo_comprobante, codigo_prefijo)
    WHERE numero_comprobante IS NOT NULL AND deleted_at IS NULL;
