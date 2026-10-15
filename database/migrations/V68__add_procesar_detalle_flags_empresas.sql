-- V68__add_procesar_detalle_flags_empresas.sql
-- Flags que determinan si las facturas de una empresa se procesan por
-- el flujo "a detalle" (inventario TNS) o por el flujo estándar de contabilización.

ALTER TABLE empresas
    ADD COLUMN IF NOT EXISTS procesar_detalle_emitidas  BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS procesar_detalle_recibidas BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN empresas.procesar_detalle_emitidas  IS 'true = facturas emitidas se procesan por detalle (inventario); false = flujo estándar de contabilización';
COMMENT ON COLUMN empresas.procesar_detalle_recibidas IS 'true = facturas recibidas se procesan por detalle (inventario); false = flujo estándar de contabilización';
