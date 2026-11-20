-- V96: agregar columna iva_mayor a causacion_detalle_item
--
-- null  = sin override manual; el backend aplica la jerarquía:
--         override manual > proveedores.iva_mayor > false
-- true  = IVA del ítem va a la misma cuenta del subtotal (IVA mayor valor)
-- false = override explícito desactivado

ALTER TABLE causacion_detalle_item
  ADD COLUMN IF NOT EXISTS iva_mayor boolean DEFAULT null;
