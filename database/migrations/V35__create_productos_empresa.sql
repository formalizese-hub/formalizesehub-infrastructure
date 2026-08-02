-- V35__create_productos_empresa.sql
-- Catálogo maestro de productos de la empresa para homologación
-- Esta migración NO se corre en develop hasta que se apruebe la rama feat/homologacion-productos

CREATE TABLE IF NOT EXISTS productos_empresa (
    id              VARCHAR(36)    PRIMARY KEY DEFAULT gen_random_uuid()::text,
    empresa_id      VARCHAR(36)    NOT NULL REFERENCES empresas(id),
    codigo          VARCHAR(100)   NOT NULL,
    descripcion     VARCHAR(500)   NOT NULL,
    unidad          VARCHAR(50)    DEFAULT NULL,
    activo          BOOLEAN        NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP      NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP      NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMP      DEFAULT NULL,
    created_by      UUID   DEFAULT NULL,
    updated_by      UUID    DEFAULT NULL
);

-- Un código de producto es único por empresa (entre los no eliminados)
CREATE UNIQUE INDEX IF NOT EXISTS uq_productos_empresa_codigo
    ON productos_empresa(empresa_id, codigo)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_productos_empresa_empresa
    ON productos_empresa(empresa_id)
    WHERE deleted_at IS NULL;

COMMENT ON TABLE  productos_empresa             IS 'Catálogo maestro de productos de la empresa para homologación';
COMMENT ON COLUMN productos_empresa.codigo      IS 'Código interno del producto en la empresa (único por empresa)';
COMMENT ON COLUMN productos_empresa.descripcion IS 'Descripción del producto';
COMMENT ON COLUMN productos_empresa.unidad      IS 'Unidad de medida (UN, KG, LT, etc.)';
