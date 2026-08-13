-- V55: Cambiar constraint UNIQUE(cufe) a UNIQUE(cufe, empresa_id)
-- Permite que el mismo CUFE exista en diferentes empresas (ej: emisor y receptor)
-- Normaliza CUFEs existentes a minúsculas para consistencia

-- 1. Normalizar CUFEs existentes a minúsculas
UPDATE facturas SET cufe = LOWER(cufe) WHERE cufe IS NOT NULL AND cufe != LOWER(cufe);

-- 2. Eliminar constraint/índice único actual sobre cufe
DROP INDEX IF EXISTS facturas_cufe_key;
DROP INDEX IF EXISTS idx_facturas_cufe;
ALTER TABLE facturas DROP CONSTRAINT IF EXISTS facturas_cufe_key;
ALTER TABLE facturas DROP CONSTRAINT IF EXISTS facturas_cufe_unique;

-- 3. Crear nuevo índice único sobre (cufe, empresa_id) con LOWER para case-insensitive
CREATE UNIQUE INDEX uq_facturas_cufe_empresa
    ON facturas (LOWER(cufe), empresa_id)
    WHERE deleted_at IS NULL;
