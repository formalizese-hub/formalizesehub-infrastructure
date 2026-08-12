-- V52: Columnas de bodega, banco_id y medio_pago para causación a detalle

-- Bodega en productos_empresa
ALTER TABLE productos_empresa
    ADD COLUMN IF NOT EXISTS bodega VARCHAR(50) DEFAULT NULL;
COMMENT ON COLUMN productos_empresa.bodega IS 'Bodega por defecto para este producto';

-- Bodega en proveedores
ALTER TABLE proveedores
    ADD COLUMN IF NOT EXISTS bodega VARCHAR(50) DEFAULT NULL;
COMMENT ON COLUMN proveedores.bodega IS 'Bodega por defecto para productos de este proveedor';

-- Banco en proveedores
ALTER TABLE proveedores
    ADD COLUMN IF NOT EXISTS banco_id VARCHAR(36) REFERENCES bancos(id);
COMMENT ON COLUMN proveedores.banco_id IS 'Banco asociado al proveedor para pagos';

-- Bodega por defecto en empresas
ALTER TABLE empresas
    ADD COLUMN IF NOT EXISTS bodega_defecto VARCHAR(50) DEFAULT NULL;
COMMENT ON COLUMN empresas.bodega_defecto IS 'Bodega por defecto de la empresa (fallback final)';

-- Medio de pago en factura_productos (viene del XML de la factura)
ALTER TABLE factura_productos
    ADD COLUMN IF NOT EXISTS medio_pago VARCHAR(50) DEFAULT NULL;
COMMENT ON COLUMN factura_productos.medio_pago IS 'Medio de pago del ítem (hereda del encabezado si no se especifica)';
