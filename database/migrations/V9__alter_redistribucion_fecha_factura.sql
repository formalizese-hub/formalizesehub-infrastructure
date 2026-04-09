-- V9: Agrega fecha_factura a la tabla redistribucion_contable

ALTER TABLE redistribucion_contable
  ADD COLUMN IF NOT EXISTS fecha_factura  DATE  NULL;
