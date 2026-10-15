-- V73__add_tipo_procesamiento_facturas.sql
-- Identifica por cuál flujo se procesó la factura:
--   'detalle' → causación a detalle (inventario)
--   'global'  → redistribución/contabilización estándar
-- NULL = aún no ruteada. Evita que los listados de detalle y global se solapen.

ALTER TABLE facturas
    ADD COLUMN IF NOT EXISTS tipo_procesamiento VARCHAR(10) DEFAULT NULL
        CHECK (tipo_procesamiento IN ('detalle', 'global'));

COMMENT ON COLUMN facturas.tipo_procesamiento IS 'Flujo de procesamiento de la factura: detalle (causación a detalle/inventario) | global (redistribución estándar). NULL = sin rutear.';

-- Índice parcial para el listado de causación a detalle
CREATE INDEX IF NOT EXISTS idx_facturas_tipo_procesamiento
    ON facturas(tipo_procesamiento)
    WHERE tipo_procesamiento IS NOT NULL;

-- Backfill de facturas ya procesadas antes de este campo:
--   si tiene estado_causacion_detalle → fue por detalle
UPDATE facturas
   SET tipo_procesamiento = 'detalle'
 WHERE tipo_procesamiento IS NULL
   AND estado_causacion_detalle IS NOT NULL;

--   si tiene redistribución (estado_distribucion procesado) y no es detalle → global
UPDATE facturas
   SET tipo_procesamiento = 'global'
 WHERE tipo_procesamiento IS NULL
   AND estado_distribucion IN ('completado', 'completado con alerta', 'contabilizado', 'requiere_revision');
