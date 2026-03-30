-- V2: Modificar tabla proveedores
-- - Renombrar regimen_fiscal → responsable_iva (BOOLEAN)
-- - Agregar campos tributarios: tipo_persona, regimen, autorretenedor, gran_contribuyente, codigo_ciiu

ALTER TABLE proveedores RENAME COLUMN regimen_fiscal TO responsable_iva;

ALTER TABLE proveedores
  ALTER COLUMN responsable_iva TYPE BOOLEAN
    USING CASE WHEN LOWER(responsable_iva::text) IN ('si', 'true', '1', 'yes') THEN TRUE ELSE FALSE END;

ALTER TABLE proveedores
  ALTER COLUMN responsable_iva SET DEFAULT FALSE;

ALTER TABLE proveedores
  ADD COLUMN IF NOT EXISTS tipo_persona        VARCHAR(10),        -- 'natural' | 'juridica'
  ADD COLUMN IF NOT EXISTS regimen             VARCHAR(10),        -- 'ordinario' | 'simple'
  ADD COLUMN IF NOT EXISTS autorretenedor      BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS gran_contribuyente  BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS codigo_ciiu         VARCHAR(10);        -- código de actividad económica CIIU
