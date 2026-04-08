-- V12: Eliminar porcentaje (no se usa) y agregar concepto_retencion
-- concepto_retencion almacena el id de la tabla retenciones para hacer match exacto
-- cuando el concepto sea 'Retención en la fuente' y existan múltiples tipos

ALTER TABLE proveedor_por_cuenta_contable
  DROP COLUMN IF EXISTS porcentaje;

ALTER TABLE proveedor_por_cuenta_contable
  ADD COLUMN IF NOT EXISTS concepto_retencion VARCHAR NULL;

COMMENT ON COLUMN proveedor_por_cuenta_contable.concepto_retencion IS 'ID de la retención (tabla retenciones) para distinguir entre tipos cuando concepto = Retención en la fuente';
