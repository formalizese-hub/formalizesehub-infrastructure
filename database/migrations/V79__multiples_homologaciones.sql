-- V79: Múltiples homologaciones por producto proveedor
-- Elimina el índice único que impedía más de una homologación activa
-- por (empresa_id, producto_proveedor_id). Ahora un producto puede tener
-- varias homologaciones activas; la resolución automática usa la primera
-- creada (ORDER BY created_at ASC LIMIT 1).

-- 1. Eliminar índice único
DROP INDEX IF EXISTS uq_homologacion_productos;

-- 2. Índice no único para búsquedas eficientes (reemplaza al único)
CREATE INDEX IF NOT EXISTS idx_homologacion_productos_pp_empresa
    ON homologacion_productos(empresa_id, producto_proveedor_id)
    WHERE deleted_at IS NULL AND activo = true;

-- 3. homologacion_id en causacion_detalle_item
-- Permite saber qué homologación específica usó cada ítem y cambiarla
-- desde el modal de detalle sin reprocesar toda la causación.
ALTER TABLE causacion_detalle_item
    ADD COLUMN IF NOT EXISTS homologacion_id VARCHAR(50)
    REFERENCES homologacion_productos(id);

COMMENT ON COLUMN causacion_detalle_item.homologacion_id IS
'Homologación usada para este ítem. Permite cambiarla manualmente desde el modal de detalle cuando hay múltiples disponibles.';
