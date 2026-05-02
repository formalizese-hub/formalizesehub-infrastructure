-- =====================================================
-- V16: Organizaciones, roles y usuarios
-- FormalizeSE Hub
-- =====================================================

-- Habilitar pgcrypto para hash de contraseñas desde psql
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ─── ORGANIZACIONES ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS organizaciones (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre      VARCHAR(200) NOT NULL,
    nit         VARCHAR(20)  UNIQUE,
    activo      BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMPTZ
);

COMMENT ON TABLE  organizaciones        IS 'Entidad raíz del sistema — cada organización es un tenant independiente';
COMMENT ON COLUMN organizaciones.nit    IS 'NIT de la organización (opcional, único)';

-- ─── ROLES ────────────────────────────────────────────────────────────────────
-- Catálogo extensible: agregar nuevos roles es un INSERT, sin cambios de esquema.
-- El rol 'admin' es el único con lógica especial en el código.
CREATE TABLE IF NOT EXISTS roles (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre      VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(200),
    activo      BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  roles         IS 'Catálogo de roles del sistema — extensible sin cambios de esquema';
COMMENT ON COLUMN roles.nombre  IS 'Identificador del rol usado en el código: admin, contador, auxiliar, etc.';

-- Roles iniciales
INSERT INTO roles (nombre, descripcion) VALUES
    ('admin',    'Administrador — gestión total de la organización'),
    ('contador', 'Contador — acceso a redistribuciones y reportes'),
    ('auxiliar', 'Auxiliar contable — acceso operativo básico')
ON CONFLICT (nombre) DO NOTHING;

-- ─── USUARIOS ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS usuarios (
    id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id  UUID        NOT NULL REFERENCES organizaciones(id) ON DELETE RESTRICT,
    rol_id           UUID        NOT NULL REFERENCES roles(id)          ON DELETE RESTRICT,
    username         VARCHAR(100) NOT NULL UNIQUE,
    password         VARCHAR(255) NOT NULL,   -- bcrypt hash (cost 12)
    nombre           VARCHAR(200),
    email            VARCHAR(200) UNIQUE,
    activo           BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at       TIMESTAMPTZ
);

COMMENT ON TABLE  usuarios              IS 'Usuarios del sistema, pertenecen a una organización';
COMMENT ON COLUMN usuarios.password     IS 'Hash bcrypt generado con cost 12. Usar crypt($pass, gen_salt(''bf'', 12)) desde psql';
COMMENT ON COLUMN usuarios.rol_id       IS 'FK a roles — solo admin tiene lógica especial en el código';

-- ─── USUARIO_CLIENTES (preparado para fase 2) ─────────────────────────────────
-- Fase 1: no se usa en la lógica de autorización.
--         Todos los usuarios de una organización acceden a todos sus clientes.
-- Fase 2: el admin asigna clientes específicos a cada usuario.
--         Se activa la validación en el middleware sin cambios de BD.
CREATE TABLE IF NOT EXISTS usuario_clientes (
    usuario_id  UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    cliente_id  UUID NOT NULL REFERENCES clientes(id) ON DELETE CASCADE,
    PRIMARY KEY (usuario_id, cliente_id)
);

COMMENT ON TABLE usuario_clientes IS 'Relación N:M usuario-cliente. Fase 1: sin uso en autorización. Fase 2: acceso granular por usuario.';

-- ─── ÍNDICES ──────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_usuarios_organizacion  ON usuarios(organizacion_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_usuarios_username      ON usuarios(username)        WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_usuarios_rol           ON usuarios(rol_id)          WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_usuario_clientes_uid   ON usuario_clientes(usuario_id);
CREATE INDEX IF NOT EXISTS idx_usuario_clientes_cid   ON usuario_clientes(cliente_id);
