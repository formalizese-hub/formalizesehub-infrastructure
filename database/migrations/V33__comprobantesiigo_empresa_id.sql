-- V33: Agregar empresa_id a comprobantesiigo
-- Los comprobantes se listan por empresa en vez de por usuario.

ALTER TABLE comprobantesiigo
  ADD COLUMN IF NOT EXISTS empresa_id VARCHAR(100) DEFAULT NULL;

-- Índice para búsquedas frecuentes por empresa
CREATE INDEX IF NOT EXISTS idx_comprobantesiigo_empresa_id
  ON comprobantesiigo(empresa_id) WHERE deleted_at IS NULL;

COMMENT ON COLUMN comprobantesiigo.empresa_id IS 'Empresa a la que pertenece el comprobante. Reemplaza el filtro por usuario_id.';
