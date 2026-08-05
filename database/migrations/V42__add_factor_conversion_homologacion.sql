-- V42: Agregar factor de conversión a homologacion_productos
-- 1 unidad del proveedor = factor_conversion unidades de la empresa.
-- Default 1 (sin conversión, 1:1).

ALTER TABLE homologacion_productos
  ADD COLUMN IF NOT EXISTS factor_conversion NUMERIC(10,4) NOT NULL DEFAULT 1;

COMMENT ON COLUMN homologacion_productos.factor_conversion IS
  'Factor de conversión: 1 unidad del proveedor = N unidades de la empresa. Default 1 (sin conversión).';
