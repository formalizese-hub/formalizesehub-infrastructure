-- V51: Tabla bancos — catálogo de bancos con cuenta contable, se asigna al proveedor

CREATE TABLE IF NOT EXISTS bancos (
    id                VARCHAR(50)   PRIMARY KEY DEFAULT gen_random_uuid()::text,
    empresa_id        VARCHAR(50)   NOT NULL REFERENCES empresas(id),
    codigo            VARCHAR(50)   NOT NULL,
    nombre            VARCHAR(255)  NOT NULL,
    cuenta_contable   VARCHAR(50)   NOT NULL,
    activo            BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMP     NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMP     NOT NULL DEFAULT NOW(),
    deleted_at        TIMESTAMP     DEFAULT NULL,
    created_by        UUID          DEFAULT NULL,
    updated_by        UUID          DEFAULT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_bancos_empresa_codigo
    ON bancos(empresa_id, codigo)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_bancos_empresa
    ON bancos(empresa_id)
    WHERE deleted_at IS NULL;

COMMENT ON TABLE  bancos                  IS 'Catálogo de bancos con cuenta contable — se asigna al proveedor';
COMMENT ON COLUMN bancos.codigo           IS 'Código del banco';
COMMENT ON COLUMN bancos.nombre           IS 'Nombre del banco';
COMMENT ON COLUMN bancos.cuenta_contable  IS 'Cuenta contable asociada al banco';
