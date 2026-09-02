-- V65: Agregar dígito de verificación (DV) del NIT a empresas y proveedores.
-- El DV se calcula en la aplicación (algoritmo módulo 11 DIAN) al crear/actualizar,
-- solo cuando el tipo de documento es NIT. Nullable: queda NULL para documentos que
-- no son NIT (CC, CE, etc.) o mientras no se haya calculado.

ALTER TABLE empresas
  ADD COLUMN IF NOT EXISTS dv VARCHAR(1) DEFAULT NULL;

ALTER TABLE proveedores
  ADD COLUMN IF NOT EXISTS dv VARCHAR(1) DEFAULT NULL;

COMMENT ON COLUMN empresas.dv IS
  'Dígito de verificación del NIT (algoritmo módulo 11 DIAN). NULL si no aplica o no calculado.';
COMMENT ON COLUMN proveedores.dv IS
  'Dígito de verificación del NIT (algoritmo módulo 11 DIAN). NULL si no aplica o no calculado.';
