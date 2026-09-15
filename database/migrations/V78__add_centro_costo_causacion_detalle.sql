-- V78__add_centro_costo_causacion_detalle.sql
-- Centro de costos editable por causación a detalle. Hasta ahora el TNS lo tomaba
-- de empresas.centro_costo; con esta columna el usuario puede fijarlo por causación
-- desde el cabezal del modal de detalle. Si queda NULL, se hereda de empresas.

ALTER TABLE causacion_detalle
    ADD COLUMN IF NOT EXISTS centro_costo VARCHAR(50) DEFAULT NULL;

COMMENT ON COLUMN causacion_detalle.centro_costo IS
'Centro de costos editable por causación (columna del maestro TNS). Si NULL, se hereda de empresas.centro_costo.';
