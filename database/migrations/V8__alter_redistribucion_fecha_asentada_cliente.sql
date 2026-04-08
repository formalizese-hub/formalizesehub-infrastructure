-- V8: Agrega fecha_asentada y cliente_id a la tabla redistribucion

ALTER TABLE redistribucion_contable
  ADD COLUMN IF NOT EXISTS fecha_asentada  DATE          NULL,
  ADD COLUMN IF NOT EXISTS cliente_id      VARCHAR(100)  NULL;

CREATE INDEX IF NOT EXISTS idx_redistribucion_cliente_id
  ON redistribucion_contable(cliente_id);
