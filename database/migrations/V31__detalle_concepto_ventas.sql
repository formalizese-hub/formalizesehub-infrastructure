-- V31: Agregar detalle_concepto_ventas a proveedor_por_cuenta_contable
-- Permite configurar el tipo de retención/IVA para facturas emitidas (ventas)
-- análogo a detalle_concepto que ya existe para compras (recibidas)

ALTER TABLE proveedor_por_cuenta_contable
  ADD COLUMN IF NOT EXISTS detalle_concepto_ventas VARCHAR(36) DEFAULT NULL;

COMMENT ON COLUMN proveedor_por_cuenta_contable.detalle_concepto_ventas
  IS 'UUID de la retención o código de impuesto (tabla retenciones/codigos_impuestos) para emitidas/ventas. Análogo a detalle_concepto para compras/recibidas.';
