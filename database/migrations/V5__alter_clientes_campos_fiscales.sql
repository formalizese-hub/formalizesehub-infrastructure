-- =====================================================
-- Migración: Agregar campos fiscales al cliente
-- FormalizeSE Hub
-- Fecha: 2026-04-01
-- Spec:
--   - tipo_persona            : natural | juridica (default juridica)
--   - es_gran_contribuyente   : boolean (aplican reglas reteIVA espec.)
--   - es_agente_retencion_iva : boolean (solo aplica a personas naturales)
-- =====================================================

ALTER TABLE clientes
  ADD COLUMN IF NOT EXISTS tipo_persona             VARCHAR(20) NOT NULL DEFAULT 'juridica',
  ADD COLUMN IF NOT EXISTS es_gran_contribuyente    BOOLEAN     NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS es_agente_retencion_iva  BOOLEAN     NOT NULL DEFAULT FALSE;

-- Comentarios
COMMENT ON COLUMN clientes.tipo_persona             IS 'Tipo de persona del cliente: natural o juridica';
COMMENT ON COLUMN clientes.es_gran_contribuyente    IS 'Indica si el cliente es gran contribuyente (aplica reglas especiales de reteIVA)';
COMMENT ON COLUMN clientes.es_agente_retencion_iva  IS 'Solo para persona natural: indica si es agente de retención de IVA';
