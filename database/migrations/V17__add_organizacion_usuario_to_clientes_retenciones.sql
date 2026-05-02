-- =====================================================
-- V17: Organización y usuario dueño en clientes y retenciones
-- =====================================================

-- ─── CLIENTES ─────────────────────────────────────────────────────────────────
ALTER TABLE clientes
    ADD COLUMN IF NOT EXISTS organizacion_id UUID REFERENCES organizaciones(id) ON DELETE RESTRICT,
    ADD COLUMN IF NOT EXISTS usuario_id      UUID REFERENCES usuarios(id)       ON DELETE SET NULL;

COMMENT ON COLUMN clientes.organizacion_id IS 'Organización a la que pertenece el cliente — define el tenant';
COMMENT ON COLUMN clientes.usuario_id      IS 'Usuario que creó el cliente (dueño en fase 1)';

CREATE INDEX IF NOT EXISTS idx_clientes_organizacion ON clientes(organizacion_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_clientes_usuario      ON clientes(usuario_id)      WHERE deleted_at IS NULL;

-- ─── RETENCIONES ──────────────────────────────────────────────────────────────
-- Las retenciones pertenecen al usuario que las creó (cada usuario gestiona las suyas)
ALTER TABLE retenciones
    ADD COLUMN IF NOT EXISTS usuario_id UUID REFERENCES usuarios(id) ON DELETE SET NULL;

COMMENT ON COLUMN retenciones.usuario_id IS 'Usuario dueño de la retención — cada usuario gestiona las suyas';

CREATE INDEX IF NOT EXISTS idx_retenciones_usuario ON retenciones(usuario_id) WHERE deleted_at IS NULL;
