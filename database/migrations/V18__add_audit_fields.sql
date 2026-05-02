-- =====================================================
-- V18: Campos de auditoría created_by / updated_by
-- Todos nullable para compatibilidad con registros existentes.
-- El backend los inyecta desde el token JWT — nunca desde el frontend.
-- =====================================================

-- ─── CLIENTES ─────────────────────────────────────────────────────────────────
ALTER TABLE clientes
    ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES usuarios(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES usuarios(id) ON DELETE SET NULL;

-- ─── PROVEEDORES ──────────────────────────────────────────────────────────────
ALTER TABLE proveedores
    ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES usuarios(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES usuarios(id) ON DELETE SET NULL;

-- ─── CUENTAS CONTABLES ────────────────────────────────────────────────────────
ALTER TABLE cuentas_contables
    ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES usuarios(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES usuarios(id) ON DELETE SET NULL;

-- ─── PARAMETRIZACIONES ────────────────────────────────────────────────────────
ALTER TABLE proveedor_por_cuenta_contable
    ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES usuarios(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES usuarios(id) ON DELETE SET NULL;

-- ─── RETENCIONES ──────────────────────────────────────────────────────────────
ALTER TABLE retenciones
    ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES usuarios(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES usuarios(id) ON DELETE SET NULL;

-- ─── DESCARGAS ────────────────────────────────────────────────────────────────
ALTER TABLE descargas
    ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES usuarios(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES usuarios(id) ON DELETE SET NULL;

-- ─── REDISTRIBUCION CONTABLE ──────────────────────────────────────────────────
ALTER TABLE redistribucion_contable
    ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES usuarios(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES usuarios(id) ON DELETE SET NULL;

-- ─── COMENTARIOS ──────────────────────────────────────────────────────────────
COMMENT ON COLUMN clientes.created_by                    IS 'Usuario que creó el registro';
COMMENT ON COLUMN clientes.updated_by                    IS 'Último usuario que modificó el registro';
COMMENT ON COLUMN proveedores.created_by                 IS 'Usuario que creó el registro';
COMMENT ON COLUMN proveedores.updated_by                 IS 'Último usuario que modificó el registro';
COMMENT ON COLUMN cuentas_contables.created_by           IS 'Usuario que creó el registro';
COMMENT ON COLUMN cuentas_contables.updated_by           IS 'Último usuario que modificó el registro';
COMMENT ON COLUMN proveedor_por_cuenta_contable.created_by IS 'Usuario que creó el registro';
COMMENT ON COLUMN proveedor_por_cuenta_contable.updated_by IS 'Último usuario que modificó el registro';
COMMENT ON COLUMN retenciones.created_by                 IS 'Usuario que creó el registro';
COMMENT ON COLUMN retenciones.updated_by                 IS 'Último usuario que modificó el registro';
COMMENT ON COLUMN descargas.created_by                   IS 'Usuario que creó el registro';
COMMENT ON COLUMN descargas.updated_by                   IS 'Último usuario que modificó el registro';
COMMENT ON COLUMN redistribucion_contable.created_by     IS 'Usuario que creó el registro';
COMMENT ON COLUMN redistribucion_contable.updated_by     IS 'Último usuario que modificó el registro';
