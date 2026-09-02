-- Migración: agregar campos sugerida_id a redistribucion_contable
-- Propósito: guardar los conceptos de retención que se usaron para el cálculo,
-- hayan aplicado o no. Se usan para poblar los selects del modal sin llamadas extra.

ALTER TABLE redistribucion_contable
  ADD COLUMN IF NOT EXISTS retefuente_sugerida_id varchar,
  ADD COLUMN IF NOT EXISTS reteiva_sugerida_id     varchar,
  ADD COLUMN IF NOT EXISTS reteica_sugerida_id     varchar;

COMMENT ON COLUMN redistribucion_contable.retefuente_sugerida_id
  IS 'Concepto de Retefuente usado para el cálculo (haya aplicado o no). Solo para poblar selects del modal.';
COMMENT ON COLUMN redistribucion_contable.reteiva_sugerida_id
  IS 'Concepto de ReteIVA usado para el cálculo (haya aplicado o no). Solo para poblar selects del modal.';
COMMENT ON COLUMN redistribucion_contable.reteica_sugerida_id
  IS 'Concepto de ReteICA usado para el cálculo (haya aplicado o no). Solo para poblar selects del modal.';
