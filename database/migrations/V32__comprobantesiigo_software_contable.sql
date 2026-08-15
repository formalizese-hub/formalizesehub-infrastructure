-- V32: Agregar software_contable a comprobantesiigo
-- Permite usar la misma tabla para Siigo y TNS en vez de tablas separadas.
-- Los registros existentes (creados para Siigo) quedan como 'Siigo'.

ALTER TABLE comprobantesiigo
  ADD COLUMN IF NOT EXISTS software_contable VARCHAR(20) NOT NULL DEFAULT 'Siigo';

UPDATE comprobantesiigo SET software_contable = 'Siigo' WHERE software_contable IS NULL OR software_contable = '';

CREATE INDEX IF NOT EXISTS idx_comprobantesiigo_software_contable
  ON comprobantesiigo(software_contable) WHERE deleted_at IS NULL;

COMMENT ON COLUMN comprobantesiigo.software_contable IS 'Software contable al que pertenece el comprobante: Siigo | TNS';
