-- V13: Agrega columna prefijo a la tabla facturas
-- El prefijo es el código alfanumérico del documento DIAN (ej. "FCV", "SETP")
-- separado del número correlativo (folio)

ALTER TABLE facturas
  ADD COLUMN IF NOT EXISTS prefijo VARCHAR(50) NULL;

COMMENT ON COLUMN facturas.prefijo IS 'Prefijo del documento DIAN (ej. FCV, SETP). Distinto del numero_factura (folio).';
