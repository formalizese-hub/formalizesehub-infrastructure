-- V11: Convertir prefijo_facturas de TEXT/VARCHAR a TEXT[]
-- Los datos existentes en formato CSV se migran con string_to_array

ALTER TABLE clientes
  ALTER COLUMN prefijo_facturas TYPE TEXT[]
  USING CASE
    WHEN prefijo_facturas IS NULL OR prefijo_facturas = '' THEN ARRAY[]::TEXT[]
    ELSE string_to_array(prefijo_facturas, ',')
  END;

ALTER TABLE clientes
  ALTER COLUMN prefijo_facturas SET DEFAULT '{}';

COMMENT ON COLUMN clientes.prefijo_facturas IS 'Prefijos de facturas del cliente almacenados como array (migrado de formato CSV en V11)';
