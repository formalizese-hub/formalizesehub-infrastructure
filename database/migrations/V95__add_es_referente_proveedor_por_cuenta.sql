-- Copiar parametrización de proveedor: marca de "referente".
--
-- Agrega la columna es_referente a proveedor_por_cuenta_contable. Un proveedor
-- marcado como referente sirve de plantilla para copiar su parametrización a
-- otros proveedores. Una empresa puede tener MÚLTIPLES referentes (no hay
-- restricción de unicidad). Las filas copiadas siempre llevan es_referente = FALSE.
--
-- Nota de esquema: esta tabla NO tiene empresa_id (el tenant se resuelve por
-- join con proveedores) ni deleted_at (el estado se gobierna por `activo`). Por
-- eso el índice es por proveedor_id filtrando es_referente y activo.

ALTER TABLE proveedor_por_cuenta_contable
    ADD COLUMN IF NOT EXISTS es_referente BOOLEAN NOT NULL DEFAULT FALSE;

-- Índice parcial para listar referentes de forma eficiente (sin unicidad).
CREATE INDEX IF NOT EXISTS idx_ppc_es_referente
    ON proveedor_por_cuenta_contable (proveedor_id)
    WHERE es_referente = TRUE AND activo = TRUE;
