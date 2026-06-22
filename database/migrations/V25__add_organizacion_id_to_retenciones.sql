-- =====================================================
-- V25: Agregar organizacion_id a tabla retenciones
-- Corrige brecha de aislamiento multi-tenant
-- =====================================================

-- 1. Agregar columna
ALTER TABLE retenciones ADD COLUMN IF NOT EXISTS organizacion_id UUID;

-- 2. Backfill desde la relación con clientes
UPDATE retenciones r
SET organizacion_id = c.organizacion_id
FROM clientes c
WHERE r.cliente_id = c.id
  AND r.organizacion_id IS NULL;

-- 3. Agregar constraint NOT NULL después del backfill
-- (solo si todas las filas tienen valor)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM retenciones WHERE organizacion_id IS NULL AND deleted_at IS NULL) THEN
        ALTER TABLE retenciones ALTER COLUMN organizacion_id SET NOT NULL;
    END IF;
END $$;

-- 4. Índice para queries filtradas por organización
CREATE INDEX IF NOT EXISTS idx_retenciones_organizacion
    ON retenciones(organizacion_id) WHERE deleted_at IS NULL;

COMMENT ON COLUMN retenciones.organizacion_id IS 'Aislamiento multi-tenant — todas las queries deben filtrar por este campo';
