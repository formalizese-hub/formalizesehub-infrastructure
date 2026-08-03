-- V30: Ajustes comprobantesiigo — renombrar codigo → prefijo_software, agregar prefijo_dian y centro_costos
-- Permite matcheo por prefijo del documento DIAN para facturas emitidas

-- 1. Renombrar columna codigo → prefijo_software
ALTER TABLE comprobantesiigo RENAME COLUMN codigo TO prefijo_software;

-- 2. Agregar prefijo_dian (prefijo del documento DIAN para matcheo, vacío = sin prefijo)
ALTER TABLE comprobantesiigo
  ADD COLUMN IF NOT EXISTS prefijo_dian VARCHAR(50) NOT NULL DEFAULT '';

-- 3. Agregar centro_costos (sugerido al redistribuir emitidas)
ALTER TABLE comprobantesiigo
  ADD COLUMN IF NOT EXISTS centro_costos VARCHAR(50) DEFAULT NULL;

-- 4. Renombrar columna tipo (antes llamada CC, para uso futuro)
ALTER TABLE comprobantesiigo
    RENAME COLUMN cc TO tipo;

ALTER TABLE comprobantesiigo
    ALTER COLUMN tipo DROP DEFAULT;

COMMENT ON COLUMN comprobantesiigo.prefijo_software IS 'Código del comprobante en el software Siigo';
COMMENT ON COLUMN comprobantesiigo.prefijo_dian IS 'Prefijo del documento DIAN para matcheo en emitidas (vacío = documentos sin prefijo)';
COMMENT ON COLUMN comprobantesiigo.centro_costos IS 'Centro de costos sugerido para facturas emitidas con este comprobante';
COMMENT ON COLUMN comprobantesiigo.tipo IS 'Tipo de comprobante (para uso futuro)';
