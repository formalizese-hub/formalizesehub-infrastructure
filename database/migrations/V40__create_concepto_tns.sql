-- V40__create_concepto_tns.sql
-- Catálogo de conceptos TNS para homologación de productos

CREATE TABLE IF NOT EXISTS concepto_tns (
    id              VARCHAR(36)    PRIMARY KEY DEFAULT gen_random_uuid()::text,
    empresa_id      VARCHAR(36)    NOT NULL REFERENCES empresas(id),
    codigo          VARCHAR(100)   NOT NULL,
    nombre          VARCHAR(500)   NOT NULL,
    tipo            VARCHAR(100)   NOT NULL,
    activo          BOOLEAN        NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP      NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP      NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMP      DEFAULT NULL,
    usuario_id      UUID    DEFAULT NULL,
    created_by      UUID    DEFAULT NULL,
    updated_by      UUID    DEFAULT NULL
);

-- Un código es único por empresa
CREATE UNIQUE INDEX IF NOT EXISTS uq_concepto_tns_codigo
    ON concepto_tns(empresa_id, codigo)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_concepto_tns_empresa
    ON concepto_tns(empresa_id)
    WHERE deleted_at IS NULL;

COMMENT ON TABLE  concepto_tns           IS 'Catálogo de conceptos TNS para homologación de productos';
COMMENT ON COLUMN concepto_tns.codigo    IS 'Código del concepto TNS (único por empresa)';
COMMENT ON COLUMN concepto_tns.nombre    IS 'Nombre del concepto';
COMMENT ON COLUMN concepto_tns.tipo      IS 'Tipo de concepto (clasificación)';
