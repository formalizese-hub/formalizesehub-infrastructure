-- =====================================================
-- Migración: Crear tabla retenciones
-- FormalizeSE Hub - Sistema de Retenciones Tributarias
-- Fecha: 2026-03-30
-- Spec:
--   - nombre      : texto descriptivo de la retención
--   - base_uvt    : mínimo en UVT a partir del cual aplica
--   - porcentaje  : tasa de retención (0-100)
--   - soft-delete : deleted_at / activo
-- =====================================================

CREATE TABLE IF NOT EXISTS retenciones (
    id          VARCHAR(36)              PRIMARY KEY DEFAULT gen_random_uuid()::text,
    nombre      VARCHAR(255)             NOT NULL,
    base_uvt    NUMERIC(10, 4)           NOT NULL CHECK (base_uvt >= 0),
    porcentaje  NUMERIC(5, 4)            NOT NULL CHECK (porcentaje >= 0 AND porcentaje <= 100),
    activo      BOOLEAN                  NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMP WITH TIME ZONE
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_retenciones_activo
    ON retenciones (activo)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_retenciones_nombre
    ON retenciones (nombre)
    WHERE deleted_at IS NULL;

-- Comentarios
COMMENT ON TABLE  retenciones             IS 'Retenciones tributarias (retención en la fuente)';
COMMENT ON COLUMN retenciones.nombre      IS 'Nombre descriptivo de la retención (ej: Honorarios, Servicios)';
COMMENT ON COLUMN retenciones.base_uvt    IS 'Base mínima en UVT a partir de la cual aplica la retención';
COMMENT ON COLUMN retenciones.porcentaje  IS 'Porcentaje de retención a aplicar (0-100)';
COMMENT ON COLUMN retenciones.activo      IS 'Indica si la retención está vigente';
COMMENT ON COLUMN retenciones.deleted_at  IS 'Fecha de eliminación lógica; NULL = registro activo';
