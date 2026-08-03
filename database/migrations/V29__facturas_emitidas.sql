-- V29: Soporte para facturas emitidas (contabilización de ventas)
-- Agrega: tipo_tercero en proveedores, tabla factura_retenciones, grupo_codigo en redistribucion_contable

-- ─── 1. Campo tipo_tercero en proveedores ─────────────────────────────────────
-- Permite identificar si un tercero es proveedor (compras), cliente (ventas), o ambos.
ALTER TABLE proveedores
  ADD COLUMN IF NOT EXISTS tipo_tercero VARCHAR(20) NOT NULL DEFAULT 'proveedor';

-- Agregar CHECK constraint (solo si no existe)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'chk_proveedores_tipo_tercero'
  ) THEN
    ALTER TABLE proveedores
      ADD CONSTRAINT chk_proveedores_tipo_tercero
      CHECK (tipo_tercero IN ('proveedor', 'cliente', 'ambos'));
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_proveedores_tipo_tercero
  ON proveedores(tipo_tercero) WHERE deleted_at IS NULL;

COMMENT ON COLUMN proveedores.tipo_tercero IS 'Rol del tercero: proveedor (compras), cliente (ventas), o ambos';

-- ─── 2. Tabla factura_retenciones ─────────────────────────────────────────────
-- Almacena retenciones extraídas directamente del XML para facturas emitidas.
-- No se calculan: se guardan tal como vienen en WithholdingTaxTotal del XML UBL 2.1 DIAN.
CREATE TABLE IF NOT EXISTS factura_retenciones (
  id               VARCHAR(36)    PRIMARY KEY,
  factura_id       VARCHAR(36)    NOT NULL REFERENCES facturas(id) ON DELETE CASCADE,
  tipo_retencion   VARCHAR(100)   NOT NULL,
  porcentaje       NUMERIC(7,4),
  base_imponible   NUMERIC(15,2),
  valor            NUMERIC(15,2)  NOT NULL,
  created_at       TIMESTAMP      NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_factura_retenciones_factura_id
  ON factura_retenciones(factura_id);

COMMENT ON TABLE factura_retenciones IS 'Retenciones del XML (WithholdingTaxTotal) para facturas emitidas — sin cálculo';

-- ─── 3. Campo grupo_codigo en redistribucion_contable ─────────────────────────
-- Permite consecutivos independientes entre emitidas (1) y recibidas (2).
ALTER TABLE redistribucion_contable
  ADD COLUMN IF NOT EXISTS grupo_codigo VARCHAR(2) DEFAULT '2';

-- Agregar CHECK constraint
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'chk_redistribucion_grupo_codigo'
  ) THEN
    ALTER TABLE redistribucion_contable
      ADD CONSTRAINT chk_redistribucion_grupo_codigo
      CHECK (grupo_codigo IN ('1', '2'));
  END IF;
END $$;

-- Asignar '2' (recibidas) a todas las redistribuciones existentes que no tengan valor
UPDATE redistribucion_contable SET grupo_codigo = '2' WHERE grupo_codigo IS NULL;

CREATE INDEX IF NOT EXISTS idx_redistribucion_contable_grupo_codigo
  ON redistribucion_contable(grupo_codigo) WHERE deleted_at IS NULL;

COMMENT ON COLUMN redistribucion_contable.grupo_codigo IS 'Tipo: 1 = Emitidas, 2 = Recibidas. Permite consecutivos independientes.';
