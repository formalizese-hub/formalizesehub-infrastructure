-- V87: Base grupal específica de ReteIVA por factura
--
-- La validación grupal de retención suma los subtotales de las facturas del
-- mismo proveedor+fecha que comparten CONCEPTO de retención, para evaluar la
-- base mínima UVT sobre el grupo. ReteFuente ya guarda su base grupal en
-- facturas.suma_grupo_retencion. Pero la combinación de facturas que comparten
-- ReteIVA puede ser DISTINTA a la de ReteFuente (p. ej. 3 facturas con 2
-- conceptos de ReteFuente pero una sola ReteIVA común), por lo que ReteIVA
-- necesita su propia base grupal, separada de la de ReteFuente.
--
-- Tipo espejo de facturas.suma_grupo_retencion: numeric(15,2).

ALTER TABLE facturas
    ADD COLUMN IF NOT EXISTS suma_grupo_reteiva NUMERIC(15,2) DEFAULT NULL;

COMMENT ON COLUMN facturas.suma_grupo_reteiva IS
'Base grupal de ReteIVA (suma de subtotales del mismo proveedor+fecha que comparten concepto de ReteIVA). Análoga a suma_grupo_retencion (ReteFuente), pero puede agrupar una combinación distinta.';
