-- V38__add_producto_proveedor_id_factura_productos.sql
-- Vincula cada línea de factura al registro deduplicado en productos_proveedor

ALTER TABLE factura_productos
    ADD COLUMN IF NOT EXISTS producto_proveedor_id VARCHAR(36) DEFAULT NULL
    REFERENCES productos_proveedor(id);

COMMENT ON COLUMN factura_productos.producto_proveedor_id
    IS 'FK al registro deduplicado en productos_proveedor — se popula al sincronizar (Fase 3)';
