-- V14: Agrega base_imponible y porcentaje a detalle_redistribucion
-- base_imponible: subtotal de la factura (para retefuente) o valor del IVA (para reteiva)
-- porcentaje: tarifa de retención o del IVA aplicado en la línea

ALTER TABLE detalle_redistribucion
  ADD COLUMN IF NOT EXISTS base_imponible  NUMERIC(15,2) NULL,
  ADD COLUMN IF NOT EXISTS porcentaje      NUMERIC(7,4)  NULL;
