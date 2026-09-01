-- V64: Agregar tipo_documento a empresas con FK al catálogo tipo_documento_identidad.
-- La columna queda NULL a propósito: los valores se cargarán manualmente (sin inferencia
-- automática desde tipo_persona para no introducir datos potencialmente incorrectos).

ALTER TABLE empresas
  ADD COLUMN IF NOT EXISTS tipo_documento VARCHAR(2) DEFAULT NULL;

COMMENT ON COLUMN empresas.tipo_documento IS
  'Código DIAN del tipo de documento de identidad de la empresa (FK a tipo_documento_identidad). NULL hasta carga manual.';

-- FK: RESTRICT en delete para no borrar un código de catálogo referenciado;
-- CASCADE en update por si un código del catálogo se corrigiera.
ALTER TABLE empresas
  DROP CONSTRAINT IF EXISTS fk_empresas_tipo_documento;

ALTER TABLE empresas
  ADD CONSTRAINT fk_empresas_tipo_documento
    FOREIGN KEY (tipo_documento)
    REFERENCES tipo_documento_identidad(codigo)
    ON UPDATE CASCADE
    ON DELETE RESTRICT;
