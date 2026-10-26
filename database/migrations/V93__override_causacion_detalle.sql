-- Override de homologación elegida manualmente por el usuario (por línea de factura)
ALTER TABLE factura_productos
  ADD COLUMN IF NOT EXISTS homologacion_id_override VARCHAR
    REFERENCES homologacion_productos(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS modo_conversion_override TEXT
    CHECK (modo_conversion_override IN ('detal', 'mayor'));

-- Override de conceptos de retención elegidos manualmente desde el modal del cabezal
ALTER TABLE facturas
  ADD COLUMN IF NOT EXISTS retencion_id_override  VARCHAR REFERENCES retenciones(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS reteiva_id_override    VARCHAR REFERENCES retenciones(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS reteica_id_override    VARCHAR REFERENCES retenciones(id) ON DELETE SET NULL;
