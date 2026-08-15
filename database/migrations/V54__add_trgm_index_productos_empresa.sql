-- V54__add_trgm_index_productos_empresa.sql
-- Índices GIN con pg_trgm para búsquedas ILIKE eficientes en productos_empresa

CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_productos_empresa_descripcion_trgm
    ON productos_empresa USING GIN (descripcion gin_trgm_ops);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_productos_empresa_codigo_trgm
    ON productos_empresa USING GIN (codigo gin_trgm_ops);
