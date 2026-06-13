-- V22: Modificar columna numero_comprobante en redistribucion_contable para permitir NULL
-- Antes: numero_comprobante se asignaba al momento de guardar (NOT NULL implícito por lógica de app).
-- Ahora: numero_comprobante será NULL durante el guardado automático y se asignará
-- posteriormente al generar el archivo de salida (TXT/Excel).
-- Requirements: 3.1, 3.5

-- Eliminar constraint NOT NULL (idempotente si ya es nullable)
ALTER TABLE redistribucion_contable
  ALTER COLUMN numero_comprobante DROP NOT NULL;

-- Asegurar que el default sea NULL para nuevos registros
ALTER TABLE redistribucion_contable
  ALTER COLUMN numero_comprobante SET DEFAULT NULL;
