-- Agregar columnas y estados para el flujo DIAN SOAP download
-- Permite trackear progreso de descarga de CUFEs desde la DIAN

-- Columna para contar CUFEs procesados (incrementa 1 por cada factura persistida)
ALTER TABLE descargas ADD COLUMN IF NOT EXISTS procesados INTEGER DEFAULT 0;

-- Columna para almacenar razón de error (certificado no disponible, etc.)
ALTER TABLE descargas ADD COLUMN IF NOT EXISTS error_reason TEXT;

-- Agregar estados DESCARGANDO_DIAN y COMPLETADO_PARCIAL al CHECK constraint
ALTER TABLE descargas DROP CONSTRAINT IF EXISTS chk_estado_descarga;
ALTER TABLE descargas ADD CONSTRAINT chk_estado_descarga
    CHECK (estado IN ('PENDIENTE', 'EN_PROCESO', 'COMPLETADO', 'COMPLETADO_PARCIAL', 'ERROR', 'DESCARGANDO_DIAN'));
