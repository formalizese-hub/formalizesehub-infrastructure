-- V43: Eliminar tabla proveedor_aprendizaje y columna tiene_aprendizaje
-- La lógica de aprendizaje automático fue removida del código.
-- La observación ya fue migrada a proveedores.observacion en V42.

-- 1. Eliminar columna tiene_aprendizaje de proveedores
ALTER TABLE proveedores DROP COLUMN IF EXISTS tiene_aprendizaje;

-- 2. Eliminar tabla proveedor_aprendizaje
DROP TABLE IF EXISTS proveedor_aprendizaje;
