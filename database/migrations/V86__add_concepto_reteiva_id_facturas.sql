-- V86: Concepto de ReteIVA seleccionable por factura
--
-- Hasta ahora facturas solo persistía concepto_retencion_id (ReteFuente). El
-- concepto de ReteIVA se resolvía por proveedor.concepto_reteiva o la primera
-- parametrización, sin posibilidad de fijarlo por factura. Para la validación
-- grupal de retención (proveedor + fecha) el usuario debe poder escoger la
-- ReteIVA por factura igual que la ReteFuente; esta columna persiste esa
-- selección para que preview.core (y ambos flujos: redistribución y causación
-- a detalle) la hereden.
--
-- Tipo espejo de facturas.concepto_retencion_id: character varying(36).

ALTER TABLE facturas
    ADD COLUMN IF NOT EXISTS concepto_reteiva_id VARCHAR(36) REFERENCES retenciones(id);

COMMENT ON COLUMN facturas.concepto_reteiva_id IS
'Concepto de ReteIVA elegido por factura (referencia a retenciones.id). NULL = resolver por proveedor.concepto_reteiva o primera parametrización. Análogo a concepto_retencion_id (ReteFuente).';
