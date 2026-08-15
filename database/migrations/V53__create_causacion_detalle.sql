-- V53: Tablas causacion_detalle (encabezado) y causacion_detalle_item (líneas por ítem)

-- Encabezado de causación a detalle
CREATE TABLE IF NOT EXISTS causacion_detalle (
    id                  VARCHAR(36)   PRIMARY KEY DEFAULT gen_random_uuid()::text,
    empresa_id          VARCHAR(36)   NOT NULL REFERENCES empresas(id),
    factura_id          VARCHAR(36)   NOT NULL REFERENCES facturas(id),
    proveedor_id        VARCHAR(36)   REFERENCES proveedores(id),
    numero_factura      VARCHAR(100)  NOT NULL,
    nit_proveedor       VARCHAR(50)   NOT NULL,
    fecha_factura       DATE          NOT NULL,
    tipo_proceso        VARCHAR(20)   NOT NULL CHECK (tipo_proceso IN ('inventario', 'tesoreria', 'contabilidad')),
    es_sugerida         BOOLEAN       NOT NULL DEFAULT TRUE,
    aprobado            BOOLEAN       NOT NULL DEFAULT FALSE,
    subtotal            NUMERIC(15,2) NOT NULL DEFAULT 0,
    total_iva           NUMERIC(15,2) NOT NULL DEFAULT 0,
    total_retencion     NUMERIC(15,2) NOT NULL DEFAULT 0,
    total_descuento     NUMERIC(15,2) NOT NULL DEFAULT 0,
    valor_a_pagar       NUMERIC(15,2) NOT NULL DEFAULT 0,
    aplica_retencion    BOOLEAN       DEFAULT NULL,
    retencion_id        VARCHAR(36)   REFERENCES retenciones(id),
    tarifa_retencion    NUMERIC(5,4)  DEFAULT NULL,
    medio_pago          VARCHAR(50)   DEFAULT NULL,
    plazo_dias          INTEGER       DEFAULT NULL,
    tasa_cambio         NUMERIC(10,4) NOT NULL DEFAULT 1,
    banco_id            VARCHAR(36)   REFERENCES bancos(id),
    bodega              VARCHAR(50)   DEFAULT NULL,
    observaciones       TEXT          DEFAULT NULL,
    usuario_id          VARCHAR(36)   NOT NULL,
    created_at          TIMESTAMP     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP     NOT NULL DEFAULT NOW(),
    deleted_at          TIMESTAMP     DEFAULT NULL,
    created_by          UUID          DEFAULT NULL,
    updated_by          UUID          DEFAULT NULL
);

-- Una factura solo puede tener una causación a detalle activa
CREATE UNIQUE INDEX IF NOT EXISTS uq_causacion_detalle_factura
    ON causacion_detalle(factura_id) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_causacion_detalle_empresa
    ON causacion_detalle(empresa_id, aprobado) WHERE deleted_at IS NULL;

COMMENT ON TABLE  causacion_detalle IS 'Encabezado de causación a detalle por factura';
COMMENT ON COLUMN causacion_detalle.es_sugerida IS 'true = generada automáticamente, false = editada/confirmada';
COMMENT ON COLUMN causacion_detalle.aprobado IS 'true = aprobada por usuario, false = pendiente';
COMMENT ON COLUMN causacion_detalle.tipo_proceso IS 'inventario | tesoreria | contabilidad';

-- Detalle por ítem de factura
CREATE TABLE IF NOT EXISTS causacion_detalle_item (
    id                      VARCHAR(36)   PRIMARY KEY DEFAULT gen_random_uuid()::text,
    causacion_detalle_id    VARCHAR(36)   NOT NULL REFERENCES causacion_detalle(id) ON DELETE CASCADE,
    factura_producto_id     VARCHAR(36)   NOT NULL REFERENCES factura_productos(id),
    linea_numero            INTEGER       NOT NULL,
    producto_empresa_id     VARCHAR(36)   REFERENCES productos_empresa(id),
    concepto_tns_id         VARCHAR(36)   REFERENCES concepto_tns(id),
    cuenta_contable_id      VARCHAR(36)   REFERENCES cuentas_contables(id),
    codigo_producto         VARCHAR(100)  DEFAULT NULL,
    descripcion_producto    VARCHAR(500)  NOT NULL,
    cantidad_original       NUMERIC(15,4) NOT NULL,
    factor_conversion       NUMERIC(10,4) NOT NULL DEFAULT 1,
    cantidad_convertida     NUMERIC(15,4) NOT NULL,
    unidad_medida           VARCHAR(50)   DEFAULT NULL,
    valor_unitario_original NUMERIC(15,4) NOT NULL,
    valor_unitario          NUMERIC(15,4) NOT NULL,
    valor_total_linea       NUMERIC(15,2) NOT NULL,
    descuento_porcentaje    NUMERIC(5,2)  DEFAULT 0,
    descuento_valor         NUMERIC(15,2) DEFAULT 0,
    tarifa_iva              NUMERIC(5,2)  DEFAULT 0,
    base_iva                NUMERIC(15,2) DEFAULT 0,
    valor_iva               NUMERIC(15,2) DEFAULT 0,
    aplica_retencion        BOOLEAN       DEFAULT FALSE,
    tipo_retencion          VARCHAR(50)   DEFAULT NULL,
    porcentaje_retencion    NUMERIC(5,4)  DEFAULT 0,
    valor_retencion         NUMERIC(15,2) DEFAULT 0,
    retencion_revertida     BOOLEAN       DEFAULT FALSE,
    bodega                  VARCHAR(50)   DEFAULT NULL,
    homologado              BOOLEAN       NOT NULL DEFAULT FALSE,
    alertas                 JSONB         DEFAULT '[]',
    created_at              TIMESTAMP     NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_causacion_detalle_item_causacion
    ON causacion_detalle_item(causacion_detalle_id);

COMMENT ON TABLE  causacion_detalle_item IS 'Línea por ítem de factura en la causación a detalle';
COMMENT ON COLUMN causacion_detalle_item.homologado IS 'true si el ítem tiene homologación, false si falta homologar';
COMMENT ON COLUMN causacion_detalle_item.cantidad_convertida IS 'Cantidad después de aplicar factor_conversion';
COMMENT ON COLUMN causacion_detalle_item.valor_unitario IS 'Precio unitario ajustado por conversión (original / factor)';
COMMENT ON COLUMN causacion_detalle_item.retencion_revertida IS 'true si el usuario revirtió la retención en el modal';
