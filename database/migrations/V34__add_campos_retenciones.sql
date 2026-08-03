-- =====================================================
-- V34: Agregar columnas faltantes a tabla retenciones
-- codigo, tipo_retencion, cuenta_debito, cuenta_credito,
-- usuario_id, empresa_id
-- =====================================================

-- Código de la retención (ej: '001', '002')
ALTER TABLE retenciones
    ADD COLUMN IF NOT EXISTS codigo VARCHAR(50);

-- Tipo de retención (RETEFUENTE, RETEIVA, RETEICA, AUTORETE)
ALTER TABLE retenciones
    ADD COLUMN IF NOT EXISTS tipo_retencion VARCHAR(50);

-- Cuenta contable débito (requerida para AUTORETE)
ALTER TABLE retenciones
    ADD COLUMN IF NOT EXISTS cuenta_debito VARCHAR(50);

-- Cuenta contable crédito (requerida para AUTORETE)
ALTER TABLE retenciones
    ADD COLUMN IF NOT EXISTS cuenta_credito VARCHAR(50);

-- Usuario que creó/posee la retención
ALTER TABLE retenciones
    ADD COLUMN IF NOT EXISTS usuario_id VARCHAR(36);

-- Empresa a la que pertenece la retención (equivalente al cliente activo)
ALTER TABLE retenciones
    ADD COLUMN IF NOT EXISTS empresa_id VARCHAR(36);

-- Índices de consulta frecuente
CREATE INDEX IF NOT EXISTS idx_retenciones_empresa
    ON retenciones(empresa_id) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_retenciones_tipo
    ON retenciones(tipo_retencion) WHERE deleted_at IS NULL;

COMMENT ON COLUMN retenciones.codigo          IS 'Código numérico de la retención (ej: 001). Usado para ordenar y referenciar.';
COMMENT ON COLUMN retenciones.tipo_retencion  IS 'Clasificación: RETEFUENTE, RETEIVA, RETEICA, AUTORETE';
COMMENT ON COLUMN retenciones.cuenta_debito   IS 'Cuenta contable débito — requerida para tipo AUTORETE';
COMMENT ON COLUMN retenciones.cuenta_credito  IS 'Cuenta contable crédito — requerida para tipo AUTORETE';
COMMENT ON COLUMN retenciones.usuario_id      IS 'Usuario propietario de la retención';
COMMENT ON COLUMN retenciones.empresa_id      IS 'Empresa (cliente activo) a la que pertenece la retención';
