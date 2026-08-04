-- V41__add_fk_empresa_id_missing_tables.sql
-- Agrega FKs de empresa_id en tablas que no la tenían
-- Previo: se elimina registro huérfano de prueba en codigos_impuestos

-- 1. Eliminar registro de prueba sin empresa_id
DELETE FROM codigos_impuestos WHERE id = '4f6c62ad-55da-4920-82be-b23cc5a06fed';

-- 2. FK facturas.empresa_id → empresas(id)
ALTER TABLE facturas
    ADD CONSTRAINT fk_facturas_empresa
    FOREIGN KEY (empresa_id) REFERENCES empresas(id);

-- 3. FK descargas.empresa_id → empresas(id)
ALTER TABLE descargas
    ADD CONSTRAINT fk_descargas_empresa
    FOREIGN KEY (empresa_id) REFERENCES empresas(id);

-- 4. FK redistribucion_contable.empresa_id → empresas(id)
ALTER TABLE redistribucion_contable
    ADD CONSTRAINT fk_redistribucion_contable_empresa
    FOREIGN KEY (empresa_id) REFERENCES empresas(id);

-- 5. FK codigos_impuestos.empresa_id → empresas(id)
ALTER TABLE codigos_impuestos
    ADD CONSTRAINT fk_codigos_impuestos_empresa
    FOREIGN KEY (empresa_id) REFERENCES empresas(id);

-- 6. Indices para queries multi-tenant en tablas principales
CREATE INDEX IF NOT EXISTS idx_facturas_empresa
    ON facturas(empresa_id) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_descargas_empresa
    ON descargas(empresa_id);

CREATE INDEX IF NOT EXISTS idx_redistribucion_empresa
    ON redistribucion_contable(empresa_id) WHERE deleted_at IS NULL;
