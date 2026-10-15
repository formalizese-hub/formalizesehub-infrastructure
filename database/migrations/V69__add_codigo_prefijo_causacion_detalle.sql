-- V69: Columna codigo_prefijo para causación a detalle
-- Análogo a redistribucion_contable.codigo_prefijo: se anexa como código de prefijo
-- en la columna C del maestro (registro tipo 1) del archivo TNS.

ALTER TABLE causacion_detalle
    ADD COLUMN IF NOT EXISTS codigo_prefijo VARCHAR(10) DEFAULT NULL;
COMMENT ON COLUMN causacion_detalle.codigo_prefijo IS 'Código de prefijo del comprobante (columna C del maestro TNS); heredado de empresas.prefijo_facturas';
