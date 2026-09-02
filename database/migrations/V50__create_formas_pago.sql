-- V50: Tabla formas_pago — mapeo entre código de factura XML y código del sistema contable

CREATE TABLE IF NOT EXISTS formas_pago (
    id              VARCHAR(50)   PRIMARY KEY DEFAULT gen_random_uuid()::text,
    empresa_id      VARCHAR(50)   NOT NULL REFERENCES empresas(id),
    codigo_factura  VARCHAR(50)   NOT NULL,
    codigo_sistema  VARCHAR(50)   NOT NULL,
    nombre          VARCHAR(255)  DEFAULT NULL,
    activo          BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP     NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMP     DEFAULT NULL,
    created_by      UUID          DEFAULT NULL,
    updated_by      UUID          DEFAULT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_formas_pago_empresa_codigo
    ON formas_pago(empresa_id, codigo_factura)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_formas_pago_empresa
    ON formas_pago(empresa_id)
    WHERE deleted_at IS NULL;

COMMENT ON TABLE  formas_pago              IS 'Mapeo entre código forma de pago de factura XML y código del sistema contable';
COMMENT ON COLUMN formas_pago.codigo_factura IS 'Código que viene en el XML (ej: 1=Contado, 2=Crédito)';
COMMENT ON COLUMN formas_pago.codigo_sistema IS 'Código equivalente en el sistema contable de la empresa';
