-- V57: Agregar campos de retención sugerida a redistribucion_contable
-- Guardan el snapshot del concepto calculado al momento de la redistribución,
-- independientemente del concepto persistido que finalmente se aplica.

ALTER TABLE redistribucion_contable
    ADD COLUMN IF NOT EXISTS retefuente_sugerida_id VARCHAR(50) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS reteiva_sugerida_id    VARCHAR(50) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS reteica_sugerida_id    VARCHAR(50) DEFAULT NULL;

COMMENT ON COLUMN redistribucion_contable.retefuente_sugerida_id IS 'ID de retención en la fuente sugerida por el cálculo automático (snapshot)';
COMMENT ON COLUMN redistribucion_contable.reteiva_sugerida_id    IS 'ID de reteIVA sugerida por el cálculo automático (snapshot)';
COMMENT ON COLUMN redistribucion_contable.reteica_sugerida_id    IS 'ID de reteICA sugerida por el cálculo automático (snapshot)';
