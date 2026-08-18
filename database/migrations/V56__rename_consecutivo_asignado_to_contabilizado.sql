-- Renombrar estado 'consecutivo_asignado' → 'contabilizado' en facturas
UPDATE facturas
SET estado_distribucion = 'contabilizado'
WHERE estado_distribucion = 'consecutivo_asignado';
