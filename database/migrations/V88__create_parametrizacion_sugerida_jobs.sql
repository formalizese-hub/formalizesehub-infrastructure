-- =============================================================================
-- V88: Tabla de jobs del flujo asíncrono de "sugerencia de parametrización con IA"
-- Spec/servicio: formalizesehub-parametrizacion
--                services/sugerir-parametrizacion-ia (POST + worker SQS + GET)
-- =============================================================================
--
-- Esta tabla da soporte al patrón JOB + SQS + polling de la sugerencia de
-- parametrización con IA. Es la ÚNICA tabla que escribe ese servicio; NUNCA se
-- tocan tablas de negocio: la parametrización definitiva NO se persiste, solo
-- se guarda el RESULTADO SUGERIDO en la columna `resultado` (JSONB).
--
-- Flujo:
--   * POST crea el job en estado 'pending' con la ENTRADA (archivos base64)
--     persistida en `entrada` (JSONB), para no exceder el límite de 256KB de
--     SQS; el mensaje SQS lleva SOLO el job_id.
--   * El worker marca 'processing', procesa por lotes actualizando `procesados`
--     y, al terminar, guarda `resultado` con estado 'done' (o 'error').
--   * GET lee estado/resultado filtrando SIEMPRE por empresa_id (aislamiento
--     multi-tenant) y por deleted_at IS NULL.
--
-- Las columnas y tipos casan 1:1 con services/sugerir-parametrizacion-ia/src/jobs.ts:
--   id, empresa_id, usuario_id, estado, total_items, procesados, entrada,
--   resultado, error_mensaje, created_at, updated_at, deleted_at.
--
-- Dependencias de esquema ya existentes:
--   * usuarios (V16): PK uuid -> usuario_id es uuid con FK a usuarios(id).
--   * empresas (rename de `clientes`, V26): su PK es `character varying`
--     (ids de aplicación tipo `empresa-<ts>-<rand>`, NO uuid). Por eso
--     empresa_id es VARCHAR aquí, consistente con el resto de tablas que
--     referencian empresas(id) (p. ej. V35, V37, V50, V51, V53, V86).
--
-- Decisión FKs: se añaden FKs duras a empresas(id) y usuarios(id) porque es el
-- patrón consistente de las migraciones recientes de creación de tablas de
-- negocio multi-tenant (V51, V53, V86). Refuerza la integridad referencial del
-- tenant y del usuario propietario del job.
--
-- Decisión trigger updated_at: NO se añade trigger. El servicio gestiona
-- `updated_at = now()` explícitamente en cada UPDATE de jobs.ts (marcarProcesando,
-- actualizarProgreso, marcarCompletado, marcarError), consistente con el resto
-- de tablas del esquema, que dejan la auditoría a la app.
-- =============================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS parametrizacion_sugerida_jobs (
    id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id     varchar     NOT NULL REFERENCES empresas(id),   -- empresas.id es varchar
    usuario_id     uuid        NOT NULL REFERENCES usuarios(id),
    estado         text        NOT NULL DEFAULT 'pending'
                               CHECK (estado IN ('pending', 'processing', 'done', 'error')),
    total_items    integer     NOT NULL DEFAULT 0,
    procesados     integer     NOT NULL DEFAULT 0,
    entrada        jsonb,                                           -- archivos base64 de entrada (persiste el POST)
    resultado      jsonb,                                           -- resultado sugerido final (se escribe al pasar a 'done')
    error_mensaje  text,                                            -- mensaje genérico cuando estado = 'error'
    created_at     timestamptz NOT NULL DEFAULT now(),
    updated_at     timestamptz NOT NULL DEFAULT now(),
    deleted_at     timestamptz                                      -- borrado lógico; todas las queries filtran deleted_at IS NULL
);

-- Listados/lecturas filtradas por tenant (GET por empresa_id), ignorando borrados.
CREATE INDEX IF NOT EXISTS idx_psj_empresa_created
    ON parametrizacion_sugerida_jobs (empresa_id, created_at)
    WHERE deleted_at IS NULL;

-- Índice parcial para que el worker/monitorización localice jobs en curso.
CREATE INDEX IF NOT EXISTS idx_psj_estado_pendientes
    ON parametrizacion_sugerida_jobs (estado)
    WHERE deleted_at IS NULL AND estado IN ('pending', 'processing');

COMMENT ON TABLE  parametrizacion_sugerida_jobs
    IS 'Job asíncrono de sugerencia de parametrización con IA (patrón job + SQS + polling). Multi-tenant por empresa_id. La parametrización definitiva NO se persiste: solo el resultado sugerido en jsonb.';
COMMENT ON COLUMN parametrizacion_sugerida_jobs.estado
    IS 'Máquina de estados: pending -> processing -> done; error como estado terminal alterno.';
COMMENT ON COLUMN parametrizacion_sugerida_jobs.entrada
    IS 'Archivos base64 de entrada persistidos por el POST para que el worker los procese (SQS solo transporta el job_id).';
COMMENT ON COLUMN parametrizacion_sugerida_jobs.resultado
    IS 'Resultado sugerido final que escribe el worker al pasar a estado done; NO es la parametrización definitiva.';
COMMENT ON COLUMN parametrizacion_sugerida_jobs.error_mensaje
    IS 'Mensaje genérico (sin stack ni detalles de BD) cuando el job termina en error.';

COMMIT;
