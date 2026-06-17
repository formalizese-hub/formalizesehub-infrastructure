-- V20: Agregar columna grupo_codigo a tabla facturas
-- grupo_codigo: 1 = Documentos Emitidos, 2 = Documentos Recibidos
-- Esta columna se utiliza para clasificar las facturas según su origen en DIAN

ALTER TABLE facturas
  ADD COLUMN IF NOT EXISTS grupo_codigo VARCHAR(2) DEFAULT '2' CHECK (grupo_codigo IN ('1', '2'));

CREATE INDEX IF NOT EXISTS idx_facturas_grupo_codigo
  ON facturas (grupo_codigo)
  WHERE deleted_at IS NULL;

COMMENT ON COLUMN facturas.grupo_codigo IS 'Código de grupo de documento DIAN: 1 = Emitidos, 2 = Recibidos';
