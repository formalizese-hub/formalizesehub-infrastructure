-- V61: Flags por proveedor — omitir_base_minima e iva_mayor
-- omitir_base_minima: si true, no se valida la base UVT en retefuente, reteIVA y reteICA
-- iva_mayor: override del flag de empresa; NULL = heredar de empresa

ALTER TABLE proveedores
    ADD COLUMN IF NOT EXISTS omitir_base_minima BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS iva_mayor          BOOLEAN DEFAULT NULL;

COMMENT ON COLUMN proveedores.omitir_base_minima
    IS 'Si true, no se valida la base mínima UVT para ninguna retención (retefuente, reteIVA, reteICA) de este proveedor';

COMMENT ON COLUMN proveedores.iva_mayor
    IS 'Override de iva_mayor por proveedor. NULL = heredar de empresa';
