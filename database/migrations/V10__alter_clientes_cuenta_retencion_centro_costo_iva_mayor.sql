-- =====================================================
-- Migración: Nuevos campos en la tabla clientes
-- FormalizeSE Hub
-- Fecha: 2026-04-07
-- Spec:
--   - cuenta_retencion_asumida : FK conceptual al catálogo de cuentas contables (NULL = no configurada)
--   - centro_costo             : array de prefijos de centros de costo del cliente
--   - iva_mayor                : indicador booleano de IVA mayor (default FALSE)
-- =====================================================

ALTER TABLE clientes
  ADD COLUMN IF NOT EXISTS cuenta_retencion_asumida  VARCHAR          NULL,
  ADD COLUMN IF NOT EXISTS centro_costo              TEXT[]  NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS iva_mayor                 BOOLEAN NOT NULL DEFAULT FALSE;

-- Comentarios
COMMENT ON COLUMN clientes.cuenta_retencion_asumida IS 'ID de la cuenta contable usada para retenciones asumidas por el cliente (referencia al catálogo de cuentas del cliente)';
COMMENT ON COLUMN clientes.centro_costo             IS 'Prefijos de centros de costo asociados al cliente; puede contener múltiples valores';
COMMENT ON COLUMN clientes.iva_mayor                IS 'Indica si el cliente aplica IVA mayor en sus transacciones';
