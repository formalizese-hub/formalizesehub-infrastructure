-- V67__rename_bancos_to_metodo_pago.sql
-- Renombrar tabla bancos → metodo_pago para reflejar su uso real

ALTER TABLE bancos RENAME TO metodo_pago;

-- Renombrar índices para consistencia
ALTER INDEX IF EXISTS uq_bancos_empresa_codigo RENAME TO uq_metodo_pago_empresa_codigo;
ALTER INDEX IF EXISTS idx_bancos_empresa RENAME TO idx_metodo_pago_empresa;

COMMENT ON TABLE metodo_pago IS 'Catálogo de métodos de pago con cuenta contable (antes: bancos)';
