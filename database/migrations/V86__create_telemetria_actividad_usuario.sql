-- =============================================================================
-- V86: Telemetría de actividad de usuario (Fase 1)
-- Spec: telemetria-actividad-usuario (microservicio formalizesehub-telemetria)
-- =============================================================================
--
-- Crea las dos tablas que persisten los heartbeats de actividad de usuario:
--   * user_activity_sessions   — una fila por sesión del cliente, con el total
--                                acumulado de ms activos y la última actividad.
--   * user_activity_heartbeats — un registro por heartbeat individual, con
--                                deduplicación por (session_id, heartbeat_id).
--
-- Depende de tablas ya existentes en el esquema:
--   usuarios (V16) y organizaciones (V16) tienen PK uuid.
--   empresas (rename de `clientes`, V26) tiene PK `character varying` (ids de
--   aplicación tipo `empresa-<ts>-<rand>`, NO uuid); por eso empresa_id es
--   varchar aquí, consistente con las otras 15 tablas que la referencian.
--
-- Requisitos cubiertos: 5.5, 5.6, 2.8, 6.1
-- =============================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS user_activity_sessions (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id       text        NOT NULL UNIQUE,          -- id de sesión del cliente
    usuario_id       uuid        NOT NULL REFERENCES usuarios(id),
    organizacion_id  uuid        NOT NULL REFERENCES organizaciones(id),
    empresa_id       varchar     NOT NULL REFERENCES empresas(id),  -- empresas.id es varchar
    started_at       timestamptz NOT NULL DEFAULT now(),
    last_activity_at timestamptz NOT NULL DEFAULT now(),
    total_active_ms  bigint      NOT NULL DEFAULT 0 CHECK (total_active_ms >= 0),
    created_at       timestamptz NOT NULL DEFAULT now(),
    updated_at       timestamptz NOT NULL DEFAULT now(),
    deleted_at       timestamptz
);

CREATE TABLE IF NOT EXISTS user_activity_heartbeats (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    heartbeat_id     text        NOT NULL,                 -- id único por heartbeat (cliente)
    session_id       text        NOT NULL REFERENCES user_activity_sessions(session_id),
    usuario_id       uuid        NOT NULL REFERENCES usuarios(id),
    organizacion_id  uuid        NOT NULL REFERENCES organizaciones(id),
    empresa_id       varchar     NOT NULL REFERENCES empresas(id),  -- empresas.id es varchar
    ruta             text        NOT NULL,                 -- ya truncada a RUTA_MAX_LEN en el servicio
    active_ms        integer     NOT NULL CHECK (active_ms >= 0),  -- tope aplicado en el servicio
    client_timestamp timestamptz NOT NULL,
    created_at       timestamptz NOT NULL DEFAULT now(),
    -- Deduplicación: un heartbeat_id es único DENTRO de su sesión (Req 6.1, 6.2)
    CONSTRAINT uq_heartbeat_por_sesion UNIQUE (session_id, heartbeat_id)
);

-- Índices para reportes futuros (Fase 2) y para el UPDATE del total por sesión
CREATE INDEX IF NOT EXISTS idx_uah_session       ON user_activity_heartbeats (session_id);
CREATE INDEX IF NOT EXISTS idx_uah_usuario       ON user_activity_heartbeats (usuario_id);
CREATE INDEX IF NOT EXISTS idx_uah_empresa       ON user_activity_heartbeats (empresa_id);
CREATE INDEX IF NOT EXISTS idx_uah_organizacion  ON user_activity_heartbeats (organizacion_id);
CREATE INDEX IF NOT EXISTS idx_uah_ruta          ON user_activity_heartbeats (ruta);
CREATE INDEX IF NOT EXISTS idx_uas_usuario       ON user_activity_sessions (usuario_id);
CREATE INDEX IF NOT EXISTS idx_uas_empresa       ON user_activity_sessions (empresa_id);
CREATE INDEX IF NOT EXISTS idx_uas_organizacion  ON user_activity_sessions (organizacion_id);

COMMIT;
