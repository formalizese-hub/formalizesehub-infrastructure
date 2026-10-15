-- V74__add_reteiva_reteica_causacion_detalle.sql
-- Agrega totales y tarifas de ReteIVA y ReteICA a la causación a detalle,
-- calculados con la misma lógica que preview.core (recibidas).

ALTER TABLE causacion_detalle
    ADD COLUMN IF NOT EXISTS total_reteiva   NUMERIC(15,2) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS tarifa_reteiva  NUMERIC(5,4)  DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS reteiva_id      VARCHAR(50)   REFERENCES retenciones(id),
    ADD COLUMN IF NOT EXISTS total_reteica   NUMERIC(15,2) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS tarifa_reteica  NUMERIC(7,4)  DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS reteica_id      VARCHAR(50)   REFERENCES retenciones(id);

COMMENT ON COLUMN causacion_detalle.total_reteiva  IS 'Valor calculado de ReteIVA';
COMMENT ON COLUMN causacion_detalle.tarifa_reteiva IS 'Tarifa ReteIVA (fracción, ej. 0.15 = 15%)';
COMMENT ON COLUMN causacion_detalle.total_reteica  IS 'Valor calculado de ReteICA';
COMMENT ON COLUMN causacion_detalle.tarifa_reteica IS 'Tarifa ReteICA por mil (ej. 9.6600 = 9.66 x1000)';
