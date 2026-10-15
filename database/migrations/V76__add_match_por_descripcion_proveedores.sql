-- V76: Flag por proveedor — match_por_descripcion
-- Cuando un proveedor reutiliza el mismo código para muchos repuestos distintos,
-- el código deja de ser un identificador confiable. Con este flag activo, la
-- homologación de sus productos se resuelve DIRECTAMENTE por descripción
-- (normalizada al vuelo: lower + sin acentos + sin caracteres especiales),
-- ignorando el código. Con el flag en false (por defecto) se mantiene el
-- comportamiento histórico: prioridad por código y descripción como fallback.

ALTER TABLE proveedores
    ADD COLUMN IF NOT EXISTS match_por_descripcion BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN proveedores.match_por_descripcion
    IS 'Si true, la homologación de productos de este proveedor se resuelve por descripción normalizada (lower+sin acentos+sin caracteres especiales), ignorando el código. Si false, prioriza el código y usa la descripción como fallback.';
