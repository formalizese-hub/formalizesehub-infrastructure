-- V15: Agrega columna iva_mayor a redistribucion_contable
-- Permite registrar si la redistribución usó IVA mayor al momento de ser creada,
-- independientemente de cambios futuros en la configuración del cliente.

ALTER TABLE redistribucion_contable
  ADD COLUMN IF NOT EXISTS iva_mayor BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN redistribucion_contable.iva_mayor
  IS 'Indica si se aplicó IVA mayor en esta redistribución (snapshot al momento de crear)';
