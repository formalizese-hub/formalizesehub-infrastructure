-- =====================================================
-- V23: Tabla emails_procesados (idempotencia flujo Gmail)
-- FormalizeSE Hub - GH-21
-- =====================================================

CREATE TABLE IF NOT EXISTS emails_procesados (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id      VARCHAR(255) NOT NULL UNIQUE,
    cliente_id      VARCHAR NOT NULL REFERENCES clientes(id) ON DELETE RESTRICT,
    email_from      VARCHAR(255),
    subject         VARCHAR(500),
    processed_at    TIMESTAMPTZ DEFAULT NOW(),
    facturas_count  INTEGER DEFAULT 0,
    status          VARCHAR(50) DEFAULT 'pending',
    error_message   TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);

COMMENT ON TABLE  emails_procesados             IS 'Registro de emails procesados desde el buzón de facturas — garantiza idempotencia del poller';
COMMENT ON COLUMN emails_procesados.message_id  IS 'ID único del mensaje en Gmail — clave de idempotencia';
COMMENT ON COLUMN emails_procesados.status      IS 'Estado del procesamiento: pending, success, partial, error';

CREATE INDEX idx_emails_procesados_cliente  ON emails_procesados(cliente_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_emails_procesados_status   ON emails_procesados(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_emails_procesados_date     ON emails_procesados(processed_at DESC);
