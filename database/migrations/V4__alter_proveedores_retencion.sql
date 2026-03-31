-- V4: Agregar campos de retención y ZESE a tabla proveedores
ALTER TABLE proveedores
  ADD COLUMN IF NOT EXISTS tipo_operacion_id  VARCHAR(36) REFERENCES retenciones(id),
  ADD COLUMN IF NOT EXISTS zese               BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS zese_anos          INTEGER,
  ADD COLUMN IF NOT EXISTS declarante         BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN proveedores.tipo_operacion_id IS 'Retención por defecto del proveedor (referencia a retenciones.id)';
COMMENT ON COLUMN proveedores.zese             IS 'Si el proveedor tiene beneficio ZESE';
COMMENT ON COLUMN proveedores.zese_anos        IS '1-5: sin retención | 6-10: 50% de la tarifa';
COMMENT ON COLUMN proveedores.declarante       IS 'Si el proveedor es declarante de renta';
