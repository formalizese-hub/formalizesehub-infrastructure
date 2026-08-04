-- V42: Mover columna observacion de proveedor_aprendizaje a proveedores
-- La observación es un campo de configuración del proveedor, no de aprendizaje.
-- Se mantiene proveedor_aprendizaje para la lógica de retenciones/cuentas aprendidas.

-- 1. Agregar columna observacion a proveedores
ALTER TABLE proveedores ADD COLUMN IF NOT EXISTS observacion TEXT;

COMMENT ON COLUMN proveedores.observacion IS 'Observación por defecto del proveedor para redistribuciones contables';

-- 2. Migrar datos existentes desde proveedor_aprendizaje
UPDATE proveedores p
SET observacion = pa.observacion
FROM proveedor_aprendizaje pa
WHERE pa.nit_proveedor = p.nit
  AND pa.empresa_id = p.empresa_id
  AND pa.observacion IS NOT NULL;
