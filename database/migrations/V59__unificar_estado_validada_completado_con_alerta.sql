-- V59: Unificar estado 'validada' → 'completado con alerta' en facturas
-- El estado 'validada' era funcionalmente idéntico a 'completado con alerta':
-- ambos indican redistribución calculada automáticamente con alertas pendientes de revisión.
-- Se elimina 'validada' para simplificar el modelo.

UPDATE facturas
SET estado_distribucion = 'completado con alerta',
    updated_at = NOW()
WHERE estado_distribucion = 'validada'
  AND deleted_at IS NULL;
