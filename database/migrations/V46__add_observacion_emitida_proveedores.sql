-- V43: Agregar campo observacion_emitida a proveedores
-- Se usa cuando el tipo_tercero es 'cliente' para notas de facturas emitidas.

ALTER TABLE proveedores
  ADD COLUMN IF NOT EXISTS observacion_emitida TEXT DEFAULT NULL;

COMMENT ON COLUMN proveedores.observacion_emitida IS 'Observación para facturas emitidas (cuando tipo_tercero es cliente)';
