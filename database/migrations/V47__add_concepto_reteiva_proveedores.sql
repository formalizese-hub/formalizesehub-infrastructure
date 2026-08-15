-- V47: Agregar campo concepto_reteiva a proveedores (análogo a concepto_reteica y tipo_operacion_id)
ALTER TABLE proveedores
    ADD COLUMN concepto_reteiva VARCHAR REFERENCES retenciones(id);

COMMENT ON COLUMN proveedores.concepto_reteiva
    IS 'Concepto de ReteIVA por defecto para este proveedor. Prioridad sobre la parametrización.';
