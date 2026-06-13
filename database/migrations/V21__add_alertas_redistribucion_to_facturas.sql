-- V21: Agregar columna alertas_redistribucion a tabla facturas
-- alertas_redistribucion: Array JSON con tipos de alerta detectados durante la redistribución automática
-- Valores posibles: ["proveedor_no_parametrizado", "conflicto_cuenta_contable", "multiples_conceptos_retencion"]

ALTER TABLE facturas
  ADD COLUMN IF NOT EXISTS alertas_redistribucion JSONB DEFAULT NULL;

CREATE INDEX IF NOT EXISTS idx_facturas_alertas_redistribucion
  ON facturas USING gin (alertas_redistribucion)
  WHERE alertas_redistribucion IS NOT NULL;

COMMENT ON COLUMN facturas.alertas_redistribucion IS 'Array JSON de tipos de alerta detectados en redistribución automática. Ej: ["proveedor_no_parametrizado", "multiples_conceptos_retencion"]';
