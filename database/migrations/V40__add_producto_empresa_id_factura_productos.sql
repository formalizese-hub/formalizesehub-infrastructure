-- V39__add_producto_empresa_id_factura_productos.sql
-- Vincula cada línea de factura al producto de la empresa resuelto por homologación

ALTER TABLE factura_productos
    ADD COLUMN IF NOT EXISTS producto_empresa_id VARCHAR(36) DEFAULT NULL
    REFERENCES productos_empresa(id);

COMMENT ON COLUMN factura_productos.producto_empresa_id
    IS 'FK al producto de la empresa resuelto por homologación — null si no homologado';
