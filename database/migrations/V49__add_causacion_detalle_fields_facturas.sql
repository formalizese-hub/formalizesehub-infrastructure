-- V49: Campos de estado y alertas para causación a detalle en facturas

ALTER TABLE facturas
  ADD COLUMN IF NOT EXISTS estado_causacion_detalle VARCHAR(30) DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS alertas_causacion_detalle JSONB DEFAULT NULL;

CREATE INDEX IF NOT EXISTS idx_facturas_estado_causacion_detalle
  ON facturas(estado_causacion_detalle)
  WHERE estado_causacion_detalle IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_facturas_alertas_causacion_detalle
  ON facturas USING gin (alertas_causacion_detalle)
  WHERE alertas_causacion_detalle IS NOT NULL;

COMMENT ON COLUMN facturas.estado_causacion_detalle IS 'Estado de causación detalle: pendiente | completado | completado con alerta | consecutivo_asignado';
COMMENT ON COLUMN facturas.alertas_causacion_detalle IS 'Array JSON de alertas. Ej: ["multiple_parametro","pendiente_homologacion"]';
