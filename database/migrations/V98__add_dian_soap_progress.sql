-- Progreso propio del worker SOAP. Se separa de `procesados`, que cuenta
-- facturas entregadas al procesamiento posterior de invoice-processing.
ALTER TABLE descargas
    ADD COLUMN IF NOT EXISTS soap_total_cufes INTEGER,
    ADD COLUMN IF NOT EXISTS soap_cufes_intentados INTEGER NOT NULL DEFAULT 0;

COMMENT ON COLUMN descargas.soap_total_cufes IS
    'Cantidad de CUFEs publicados al worker DIAN SOAP para esta descarga';
COMMENT ON COLUMN descargas.soap_cufes_intentados IS
    'Cantidad de CUFEs cuyo intento SOAP terminó, exitoso o fallido';
