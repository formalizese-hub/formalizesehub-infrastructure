-- V60: Tabla de parametrización global de empresa para facturas emitidas
-- Cuando un proveedor/cliente no tiene parametrización propia en
-- proveedor_por_cuenta_contable, el sistema busca aquí como fallback.
-- Solo aplica al flujo de facturas emitidas (grupo_codigo = '1').

CREATE TABLE IF NOT EXISTS parametrizacion_global (
    id                      VARCHAR(36)   PRIMARY KEY DEFAULT gen_random_uuid()::text,
    empresa_id              VARCHAR(100)  NOT NULL,
    concepto                VARCHAR(100)  NOT NULL,
    detalle_concepto        VARCHAR(36)   DEFAULT NULL,
    detalle_concepto_ventas VARCHAR(36)   DEFAULT NULL,
    cuenta_ventas_id        VARCHAR(36)   DEFAULT NULL,
    cuenta_devolucion_venta_id VARCHAR(36) DEFAULT NULL,
    activo                  BOOLEAN       NOT NULL DEFAULT true,
    notas                   TEXT          DEFAULT NULL,
    created_by              UUID          REFERENCES usuarios(id) ON DELETE SET NULL,
    updated_by              UUID          REFERENCES usuarios(id) ON DELETE SET NULL,
    created_at              TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    deleted_at              TIMESTAMPTZ   DEFAULT NULL,

    CONSTRAINT fk_pg_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id),
    CONSTRAINT fk_pg_cuenta_ventas
        FOREIGN KEY (cuenta_ventas_id) REFERENCES cuentas_contables(id),
    CONSTRAINT fk_pg_cuenta_devolucion_venta
        FOREIGN KEY (cuenta_devolucion_venta_id) REFERENCES cuentas_contables(id)
);

-- Unicidad: un solo registro por empresa + concepto + detalle_ventas
CREATE UNIQUE INDEX IF NOT EXISTS idx_pg_unique_concepto
    ON parametrizacion_global (empresa_id, concepto, COALESCE(detalle_concepto_ventas, ''))
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_pg_empresa_id
    ON parametrizacion_global (empresa_id)
    WHERE deleted_at IS NULL;

COMMENT ON TABLE parametrizacion_global
    IS 'Parametrización contable global por empresa — fallback para facturas emitidas cuando el proveedor no tiene parametrización propia';
