-- V37__create_homologacion_productos.sql
-- Asociación manual entre producto de proveedor y producto de la empresa

CREATE TABLE IF NOT EXISTS homologacion_productos (
    id                    VARCHAR(36)    PRIMARY KEY DEFAULT gen_random_uuid()::text,
    empresa_id            VARCHAR(36)    NOT NULL REFERENCES empresas(id),
    proveedor_id          VARCHAR(36)    NOT NULL REFERENCES proveedores(id),
    producto_proveedor_id VARCHAR(36)    NOT NULL REFERENCES productos_proveedor(id),
    producto_empresa_id   VARCHAR(36)    NULL     REFERENCES productos_empresa(id),
    concepto_tns_id       VARCHAR(36)    NULL     REFERENCES concepto_tns(id),
    cuenta_contable_id    VARCHAR(36)    NULL     REFERENCES cuentas_contables(id),
    activo                BOOLEAN        NOT NULL DEFAULT TRUE,
    created_at            TIMESTAMP      NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMP      NOT NULL DEFAULT NOW(),
    deleted_at            TIMESTAMP      DEFAULT NULL,
    created_by            UUID    DEFAULT NULL,
    updated_by            UUID    DEFAULT NULL
);

-- Un producto del proveedor solo puede homologarse una vez por empresa
CREATE UNIQUE INDEX IF NOT EXISTS uq_homologacion_productos
    ON homologacion_productos(empresa_id, producto_proveedor_id)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_homologacion_empresa
    ON homologacion_productos(empresa_id)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_homologacion_proveedor
    ON homologacion_productos(empresa_id, proveedor_id)
    WHERE deleted_at IS NULL;

COMMENT ON TABLE  homologacion_productos                      IS 'Asociación manual entre producto de proveedor y producto de la empresa';
COMMENT ON COLUMN homologacion_productos.proveedor_id         IS 'FK al proveedor (denormalizado para consultas directas)';
COMMENT ON COLUMN homologacion_productos.producto_proveedor_id IS 'FK al producto deduplicado del proveedor';
COMMENT ON COLUMN homologacion_productos.producto_empresa_id  IS 'FK al producto del catálogo de la empresa';
