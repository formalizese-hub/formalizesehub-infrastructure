-- V7: Ajusta la tabla redistribucion al nuevo esquema y crea detalle_redistribucion

-- ─── TABLA: redistribucion (ENCABEZADO) ─────────────────────────────────────
ALTER TABLE redistribucion_contable
  ADD COLUMN IF NOT EXISTS tipo_comprobante   VARCHAR(20),
  ADD COLUMN IF NOT EXISTS codigo_prefijo     VARCHAR(20),
  ADD COLUMN IF NOT EXISTS numero_comprobante VARCHAR(50),
  ADD COLUMN IF NOT EXISTS total_debitos      NUMERIC(15,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_creditos     NUMERIC(15,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS nit_proveedor      VARCHAR(50),
  ADD COLUMN IF NOT EXISTS numero_factura     VARCHAR(100),
  ADD COLUMN IF NOT EXISTS fecha_asiento      DATE,
  ADD COLUMN IF NOT EXISTS usuario_id         VARCHAR(100),
  ADD COLUMN IF NOT EXISTS updated_at         TIMESTAMP DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS deleted_at         TIMESTAMP NULL;

-- ─── TABLA: detalle_redistribucion (ASIENTOS CONTABLES) ─────────────────────
CREATE TABLE IF NOT EXISTS detalle_redistribucion (
  id                    VARCHAR(36)    PRIMARY KEY,
  redistribucion_id     VARCHAR(36)    NOT NULL REFERENCES redistribucion_contable(id) ON DELETE CASCADE,
  num_cuenta_contable   VARCHAR(50)    NOT NULL,
  concepto              VARCHAR(200),
  valor                 NUMERIC(15,2)  NOT NULL,
  tipo_movimiento       VARCHAR(1)     NOT NULL CHECK (tipo_movimiento IN ('D', 'C')),
  created_at            TIMESTAMP      NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_detalle_redistribucion_redistribucion_id
  ON detalle_redistribucion(redistribucion_id);
