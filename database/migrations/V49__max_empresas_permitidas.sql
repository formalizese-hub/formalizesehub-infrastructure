-- =====================================================
-- V49: max_empresas_permitidas en organizaciones
-- El tope de empresas es configurable por organización,
-- independiente del plan. El superadmin lo ajusta cuando
-- el cliente paga parametrización adicional.
-- plan.max_empresas queda como referencia comercial.
-- =====================================================

BEGIN;

ALTER TABLE organizaciones
    ADD COLUMN IF NOT EXISTS max_empresas_permitidas INT;

COMMENT ON COLUMN organizaciones.max_empresas_permitidas
    IS 'Tope real de empresas para esta org. NULL = sin límite. El superadmin lo ajusta cuando el cliente paga más.';

-- Inicializar con max_empresas del plan para orgs que ya tengan plan asignado
UPDATE organizaciones o
SET max_empresas_permitidas = p.max_empresas
FROM planes p
WHERE o.plan_id = p.id
  AND o.max_empresas_permitidas IS NULL;

COMMIT;
