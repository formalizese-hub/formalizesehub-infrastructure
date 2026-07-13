-- =====================================================
-- V24: Agregar campo email_facturas a tabla clientes
-- FormalizeSE Hub - GH-21
-- =====================================================

ALTER TABLE clientes ADD COLUMN IF NOT EXISTS email_facturas VARCHAR(255);

COMMENT ON COLUMN clientes.email_facturas IS 'Alias de correo asignado al cliente para recepción de facturas (ej: facturas+890123456@dominio)';
