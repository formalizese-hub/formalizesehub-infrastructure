-- V77: Ubicación geográfica (DANE) en empresas y proveedores
-- Se agregan FKs a las tablas catálogo departamentos/municipios (creadas en V62).
-- Se guarda el id (UUID) de cada tabla para poder resolver cualquier dato después
-- (código, nombre). Las columnas de texto libre existentes en proveedores
-- (ciudad, departamento) se conservan por compatibilidad.

-- ─── empresas ──────────────────────────────────────────────────────────────
ALTER TABLE empresas
    ADD COLUMN IF NOT EXISTS departamento_id VARCHAR(36) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS municipio_id    VARCHAR(36) DEFAULT NULL;

ALTER TABLE empresas
    ADD CONSTRAINT fk_empresas_departamento
        FOREIGN KEY (departamento_id) REFERENCES departamentos(id);
ALTER TABLE empresas
    ADD CONSTRAINT fk_empresas_municipio
        FOREIGN KEY (municipio_id) REFERENCES municipios(id);

COMMENT ON COLUMN empresas.departamento_id IS 'FK a departamentos.id (catálogo DANE).';
COMMENT ON COLUMN empresas.municipio_id   IS 'FK a municipios.id (catálogo DANE).';

-- ─── proveedores ───────────────────────────────────────────────────────────
ALTER TABLE proveedores
    ADD COLUMN IF NOT EXISTS departamento_id VARCHAR(36) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS municipio_id    VARCHAR(36) DEFAULT NULL;

ALTER TABLE proveedores
    ADD CONSTRAINT fk_proveedores_departamento
        FOREIGN KEY (departamento_id) REFERENCES departamentos(id);
ALTER TABLE proveedores
    ADD CONSTRAINT fk_proveedores_municipio
        FOREIGN KEY (municipio_id) REFERENCES municipios(id);

COMMENT ON COLUMN proveedores.departamento_id IS 'FK a departamentos.id (catálogo DANE).';
COMMENT ON COLUMN proveedores.municipio_id   IS 'FK a municipios.id (catálogo DANE).';
