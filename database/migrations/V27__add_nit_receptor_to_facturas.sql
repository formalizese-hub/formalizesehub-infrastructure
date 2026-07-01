-- V27: Agregar campos nit_receptor y tipo_documento_receptor a tabla facturas
-- El NIT receptor es el NIT de la empresa que recibe la factura (adquirente),
-- extraído del XML (AccountingCustomerParty). Permite validar que la factura
-- realmente corresponde a la empresa asignada.
-- tipo_documento_receptor es el código DIAN del tipo de documento (13=CC, 31=NIT, etc.)

ALTER TABLE facturas
  ADD COLUMN IF NOT EXISTS nit_receptor VARCHAR(20),
  ADD COLUMN IF NOT EXISTS tipo_documento_receptor VARCHAR(5);

COMMENT ON COLUMN facturas.nit_receptor IS 'NIT/CC del receptor/adquirente de la factura, extraído del XML (AccountingCustomerParty)';
COMMENT ON COLUMN facturas.tipo_documento_receptor IS 'Código tipo documento del receptor (schemeName DIAN: 13=CC, 31=NIT, 22=CE, etc.)';

-- Índice para validaciones rápidas por nit_receptor + empresa
CREATE INDEX IF NOT EXISTS idx_facturas_nit_receptor ON facturas (nit_receptor) WHERE nit_receptor IS NOT NULL;
