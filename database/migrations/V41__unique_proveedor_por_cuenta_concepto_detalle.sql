-- V41: Constraint unicidad en proveedor_por_cuenta_contable
-- Previene duplicados del mismo concepto+detalle para un proveedor.
-- Todos los conceptos (Subtotal, IVA, Retenciones, Valor a pagar) se validan por detalle.

CREATE UNIQUE INDEX IF NOT EXISTS idx_ppc_unique_concepto_detalle
  ON proveedor_por_cuenta_contable (
    proveedor_id,
    concepto,
    COALESCE(detalle_concepto, ''),
    COALESCE(detalle_concepto_ventas, '')
  )
  WHERE activo = true;
