-- V82: Factor de conversión Mayor / Detal (inventario)
--
-- Un producto homologado puede manejar dos conversiones de cantidad:
--   - DETAL: el factor existente (factor_conversion + factor_operacion). Lo más común.
--   - MAYOR: una conversión alternativa (nullable; si NULL, solo maneja detal).
-- La factura NO indica si es mayor o detal; el usuario decide. El selector en el
-- modal aparece solo cuando el producto tiene AMBAS conversiones configuradas.

-- ── homologacion_productos: factor mayor + modo por defecto ──────────────────
ALTER TABLE homologacion_productos
    ADD COLUMN IF NOT EXISTS factor_conversion_mayor NUMERIC(10,4),
    ADD COLUMN IF NOT EXISTS factor_operacion_mayor  CHAR(1) CHECK (factor_operacion_mayor IN ('*','/')),
    ADD COLUMN IF NOT EXISTS modo_conversion_defecto VARCHAR(10) NOT NULL DEFAULT 'detal'
        CHECK (modo_conversion_defecto IN ('mayor','detal'));

COMMENT ON COLUMN homologacion_productos.factor_conversion_mayor IS
'Factor de conversión para venta/compra al por MAYOR. NULL = el producto solo maneja detal.';
COMMENT ON COLUMN homologacion_productos.factor_operacion_mayor IS
'Operación del factor mayor: * = multiplicar, / = dividir.';
COMMENT ON COLUMN homologacion_productos.modo_conversion_defecto IS
'Modo que usa el auto-causado por defecto: mayor | detal (default detal). El factor_conversion/factor_operacion existentes son el DETAL.';

-- ── causacion_detalle_item: modo aplicado en el ítem ─────────────────────────
ALTER TABLE causacion_detalle_item
    ADD COLUMN IF NOT EXISTS modo_conversion VARCHAR(10) NOT NULL DEFAULT 'detal'
        CHECK (modo_conversion IN ('mayor','detal'));

COMMENT ON COLUMN causacion_detalle_item.modo_conversion IS
'Modo de conversión aplicado al ítem (mayor | detal). Permite recalcular cantidad/valor al cambiar.';
