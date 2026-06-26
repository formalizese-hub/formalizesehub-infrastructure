-- V26: Rename clientes → empresas (big bang)
-- Contexto: "clientes" son realmente las empresas que el contador administra.
-- El término "cliente" se reserva para la futura tabla de compradores (facturas emitidas).

BEGIN;

-- 1. Renombrar tabla principal
ALTER TABLE clientes RENAME TO empresas;

-- 2. Renombrar columnas FK en todas las tablas
ALTER TABLE proveedores RENAME COLUMN cliente_id TO empresa_id;
ALTER TABLE facturas RENAME COLUMN cliente_id TO empresa_id;
ALTER TABLE descargas RENAME COLUMN cliente_id TO empresa_id;
ALTER TABLE redistribucion_contable RENAME COLUMN cliente_id TO empresa_id;
ALTER TABLE emails_procesados RENAME COLUMN cliente_id TO empresa_id;
ALTER TABLE retenciones RENAME COLUMN cliente_id TO empresa_id;
ALTER TABLE cuentas_contables RENAME COLUMN cliente_id TO empresa_id;
ALTER TABLE proveedor_por_cuenta_contable RENAME COLUMN cliente_id TO empresa_id;

-- 3. Renombrar tabla pivote usuario_clientes → usuario_empresas
ALTER TABLE usuario_clientes RENAME TO usuario_empresas;
ALTER TABLE usuario_empresas RENAME COLUMN cliente_id TO empresa_id;

-- 4. Renombrar índices (PostgreSQL no renombra automáticamente con ALTER TABLE)
ALTER INDEX IF EXISTS idx_clientes_organizacion RENAME TO idx_empresas_organizacion;
ALTER INDEX IF EXISTS idx_clientes_usuario RENAME TO idx_empresas_usuario;
ALTER INDEX IF EXISTS idx_usuario_clientes_uid RENAME TO idx_usuario_empresas_uid;
ALTER INDEX IF EXISTS idx_usuario_clientes_cid RENAME TO idx_usuario_empresas_eid;
ALTER INDEX IF EXISTS idx_redistribucion_cliente_id RENAME TO idx_redistribucion_empresa_id;
ALTER INDEX IF EXISTS idx_emails_procesados_cliente RENAME TO idx_emails_procesados_empresa;

-- 5. Actualizar comentarios relevantes
COMMENT ON TABLE empresas IS 'Empresas administradas por la organización (contador). Antes: clientes.';
COMMENT ON TABLE usuario_empresas IS 'Relación N:M usuario-empresa. Fase 2: acceso granular por usuario.';

COMMIT;
