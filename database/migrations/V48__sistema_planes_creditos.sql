-- =====================================================
-- V48: Sistema de Planes y Créditos Recargables
-- Modelo de créditos prepagados por organización.
-- Los documentos se consumen sin periodo de expiración
-- y se recargan cuando se agotan.
-- =====================================================

BEGIN;

-- ─── CATÁLOGO DE PLANES ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS planes (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo                  VARCHAR(50) NOT NULL UNIQUE,
    nombre                  VARCHAR(100) NOT NULL,
    max_empresas            INT NOT NULL,
    documentos_incluidos    INT NOT NULL,
    precio_documento        NUMERIC(10,2) NOT NULL DEFAULT 0,
    precio_parametrizacion  NUMERIC(12,2) NOT NULL DEFAULT 0,
    es_promocional          BOOLEAN NOT NULL DEFAULT FALSE,
    activo                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE planes IS 'Catálogo de planes disponibles — define límites y precios por recarga';
COMMENT ON COLUMN planes.codigo IS 'Identificador usado en código: convenio_colegio, basico, profesional, empresarial';
COMMENT ON COLUMN planes.documentos_incluidos IS 'Cantidad de documentos que se entregan por cada recarga del plan';
COMMENT ON COLUMN planes.precio_documento IS 'Precio unitario por documento (para facturación)';
COMMENT ON COLUMN planes.precio_parametrizacion IS 'Precio de parametrización por empresa';

INSERT INTO planes (codigo, nombre, max_empresas, documentos_incluidos, precio_documento, precio_parametrizacion, es_promocional)
VALUES
    ('convenio_colegio', 'Convenio Colegio de Contadores', 3, 500, 0, 0, TRUE),
    ('basico',           'Plan Básico',                    3, 200, 800, 150000, FALSE),
    ('profesional',      'Plan Profesional',               3, 500, 650, 150000, FALSE),
    ('empresarial',      'Plan Empresarial',               5, 1000, 500, 150000, FALSE)
ON CONFLICT (codigo) DO NOTHING;

-- ─── CRÉDITOS POR ORGANIZACIÓN ────────────────────────────────────────────────
-- Cada fila representa una recarga (tanque de documentos).
-- El saldo disponible = SUM(documentos_comprados - documentos_consumidos) WHERE agotado = FALSE
-- Se consumen en orden FIFO (por created_at ASC).
CREATE TABLE IF NOT EXISTS organizacion_creditos (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id         UUID NOT NULL REFERENCES organizaciones(id) ON DELETE RESTRICT,
    plan_id                 UUID NOT NULL REFERENCES planes(id),
    documentos_comprados    INT NOT NULL,
    documentos_consumidos   INT NOT NULL DEFAULT 0,
    agotado                 BOOLEAN NOT NULL DEFAULT FALSE,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    agotado_at              TIMESTAMPTZ
);

COMMENT ON TABLE organizacion_creditos IS 'Recargas de documentos por organización. Cada fila = un tanque. Se consumen FIFO.';
COMMENT ON COLUMN organizacion_creditos.documentos_comprados IS 'Total de documentos de esta recarga';
COMMENT ON COLUMN organizacion_creditos.documentos_consumidos IS 'Documentos gastados de esta recarga';
COMMENT ON COLUMN organizacion_creditos.agotado IS 'TRUE cuando documentos_consumidos >= documentos_comprados';

CREATE INDEX idx_org_creditos_activos
    ON organizacion_creditos(organizacion_id)
    WHERE agotado = FALSE;

CREATE INDEX idx_org_creditos_fifo
    ON organizacion_creditos(organizacion_id, created_at ASC)
    WHERE agotado = FALSE;

-- ─── VINCULAR PLAN ACTIVO A ORGANIZACIÓN ──────────────────────────────────────
ALTER TABLE organizaciones
    ADD COLUMN IF NOT EXISTS plan_id UUID REFERENCES planes(id);

COMMENT ON COLUMN organizaciones.plan_id IS 'Plan activo de la organización. Define max_empresas y tipo de recarga. NULL = sin plan asignado.';

COMMIT;
