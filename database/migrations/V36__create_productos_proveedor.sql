-- V36__create_productos_proveedor.sql
-- Catálogo deduplicado de productos vistos en facturas por proveedor

CREATE TABLE IF NOT EXISTS productos_proveedor (
    id              VARCHAR(36)    PRIMARY KEY DEFAULT gen_random_uuid()::text,
    empresa_id      VARCHAR(36)    NOT NULL REFERENCES empresas(id),
    proveedor_id    VARCHAR(36)    NOT NULL REFERENCES proveedores(id),
    codigo          VARCHAR(100)   DEFAULT NULL,
    descripcion     VARCHAR(500)   NOT NULL,
    unidad_medida   VARCHAR(50)    DEFAULT NULL,
    created_at      TIMESTAMP      NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP      NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMP      DEFAULT NULL
);

-- Un producto es único por (empresa, proveedor, descripción)
CREATE UNIQUE INDEX IF NOT EXISTS uq_productos_proveedor
    ON productos_proveedor(empresa_id, proveedor_id, descripcion)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_productos_proveedor_empresa
    ON productos_proveedor(empresa_id, proveedor_id)
    WHERE deleted_at IS NULL;

COMMENT ON TABLE  productos_proveedor             IS 'Catálogo deduplicado de productos vistos en facturas por proveedor';
COMMENT ON COLUMN productos_proveedor.codigo      IS 'Código del producto según el proveedor (puede ser null si no lo informa)';
COMMENT ON COLUMN productos_proveedor.descripcion IS 'Descripción exacta del producto tal como viene en la factura — clave de matcheo';
