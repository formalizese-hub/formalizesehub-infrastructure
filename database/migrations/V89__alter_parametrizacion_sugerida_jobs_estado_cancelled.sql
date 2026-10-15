-- =============================================================================
-- V89: Añade el estado 'cancelled' al CHECK de parametrizacion_sugerida_jobs
-- Spec/servicio: formalizesehub-parametrizacion
--                services/cancelar-parametrizacion-ia-job
--                (POST /parametrizacion/sugerir-ia/{job_id}/cancelar)
-- =============================================================================
--
-- El flujo asíncrono de "sugerencia de parametrización con IA" (tabla creada en
-- V88) incorpora la CANCELACIÓN por parte del creador del job. Un nuevo servicio
-- Lambda permite cancelar un job que está en 'pending' o 'processing',
-- dejándolo en el nuevo estado terminal 'cancelled'. El worker, entre lotes,
-- detecta la cancelación y aborta de forma limpia sin marcar 'done' ni escribir
-- resultado.
--
-- Esta migración amplía la máquina de estados:
--   pending -> processing -> done
--                         \-> error      (terminal alterno)
--   pending|processing     -> cancelled  (terminal por cancelación del creador)
--
-- La CHECK constraint de `estado` se definió SIN nombre explícito en V88
-- (CHECK (estado IN (...)) inline en la columna), por lo que PostgreSQL le
-- asignó el nombre autogenerado `parametrizacion_sugerida_jobs_estado_check`
-- (patrón <tabla>_<columna>_check). Reusamos ese nombre real al recrearla.
--
-- Idempotencia defensiva (coherente con el estilo del repo): se elimina la
-- constraint con DROP CONSTRAINT IF EXISTS antes de volver a crearla, de modo
-- que la migración pueda reaplicarse sin fallar si ya existe/falta.
-- =============================================================================

BEGIN;

-- Elimina la CHECK actual (acepta 'pending','processing','done','error').
ALTER TABLE parametrizacion_sugerida_jobs
    DROP CONSTRAINT IF EXISTS parametrizacion_sugerida_jobs_estado_check;

-- Recrea la CHECK incluyendo el nuevo estado terminal 'cancelled'.
ALTER TABLE parametrizacion_sugerida_jobs
    ADD CONSTRAINT parametrizacion_sugerida_jobs_estado_check
    CHECK (estado IN ('pending', 'processing', 'done', 'error', 'cancelled'));

COMMENT ON COLUMN parametrizacion_sugerida_jobs.estado
    IS 'Máquina de estados: pending -> processing -> done; error como estado terminal alterno; cancelled como estado terminal cuando el creador cancela un job en pending/processing.';

COMMIT;
