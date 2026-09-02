-- =====================================================
-- V66: Cobro de facturas contra el plan de créditos
-- =====================================================
-- Regla de negocio: cada factura que alcanza el estado
-- 'completado' o 'completado con alerta' consume 1 crédito
-- (documento) del plan de la organización, una sola vez.
--
-- Se agrega la bandera facturas.cobrada (idempotencia) y
-- facturas.cobrada_at. El descuento en tiempo real se hace
-- en el servicio de redistribuciones (helper cobrarFactura),
-- dentro de la misma transacción que marca el estado.
--
-- El saldo puede quedar NEGATIVO: el último tanque de créditos
-- absorbe el sobregiro (documentos_consumidos > documentos_comprados).
-- Para que el saldo negativo sea visible, el tanque que sobregira
-- NO se marca como agotado; solo se marca agotado cuando queda
-- exactamente en su tope sin sobregiro pendiente.
--
-- Cobro retroactivo (Opción C) — fecha de corte: 2026-08-31.
--   * Facturas completadas ANTES del corte  → cobrada = TRUE sin descontar.
--   * Facturas completadas DESDE el corte    → se cobran retroactivamente
--     (descuento FIFO por organización).
-- =====================================================

BEGIN;

-- ─── 1. Bandera de cobro en facturas ──────────────────────────────────────────
ALTER TABLE facturas
    ADD COLUMN IF NOT EXISTS cobrada    BOOLEAN     NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS cobrada_at TIMESTAMPTZ;

COMMENT ON COLUMN facturas.cobrada IS 'TRUE cuando la factura ya consumió 1 crédito del plan. Evita doble cobro.';
COMMENT ON COLUMN facturas.cobrada_at IS 'Momento en que se cobró la factura (se descontó el crédito).';

CREATE INDEX IF NOT EXISTS idx_facturas_no_cobradas
    ON facturas(empresa_id)
    WHERE cobrada = FALSE AND deleted_at IS NULL;

-- ─── 2. Estados que se consideran "cobrables" ─────────────────────────────────
-- Una factura es cobrable cuando su estado_distribucion es
-- 'completado' o 'completado con alerta'.

-- ─── 3. Backfill histórico ANTES del corte → marcar cobrada sin descontar ─────
-- Fecha de corte: 2026-08-31 (inclusive hacia adelante se cobra retroactivo).
UPDATE facturas
SET cobrada = TRUE,
    cobrada_at = updated_at
WHERE deleted_at IS NULL
  AND estado_distribucion IN ('completado', 'completado con alerta')
  AND updated_at < TIMESTAMPTZ '2026-08-31 00:00:00'
  AND cobrada = FALSE;

-- ─── 4. Cobro retroactivo DESDE el corte ──────────────────────────────────────
-- Para cada organización, contamos las facturas completadas (no cobradas aún)
-- con updated_at >= corte, y descontamos ese total de sus créditos FIFO.
-- El último tanque absorbe cualquier sobregiro (saldo negativo permitido).
DO $$
DECLARE
    org             RECORD;
    tanque          RECORD;
    por_cobrar      INT;
    restante        INT;
    capacidad       INT;
    consumir        INT;
BEGIN
    FOR org IN
        SELECT e.organizacion_id AS org_id,
               COUNT(*)::int      AS total
        FROM facturas f
        JOIN empresas e ON e.id = f.empresa_id
        WHERE f.deleted_at IS NULL
          AND f.estado_distribucion IN ('completado', 'completado con alerta')
          AND f.updated_at >= TIMESTAMPTZ '2026-08-31 00:00:00'
          AND f.cobrada = FALSE
          AND e.organizacion_id IS NOT NULL
        GROUP BY e.organizacion_id
    LOOP
        -- Solo cobramos si la organización tiene un plan asignado.
        IF NOT EXISTS (
            SELECT 1 FROM organizaciones o
            WHERE o.id = org.org_id AND o.plan_id IS NOT NULL AND o.deleted_at IS NULL
        ) THEN
            -- Sin plan → marcamos las facturas como cobradas sin descontar.
            UPDATE facturas f
            SET cobrada = TRUE, cobrada_at = NOW()
            FROM empresas e
            WHERE e.id = f.empresa_id
              AND e.organizacion_id = org.org_id
              AND f.deleted_at IS NULL
              AND f.estado_distribucion IN ('completado', 'completado con alerta')
              AND f.updated_at >= TIMESTAMPTZ '2026-08-31 00:00:00'
              AND f.cobrada = FALSE;
            CONTINUE;
        END IF;

        por_cobrar := org.total;
        restante   := por_cobrar;

        -- Consumo FIFO por tanques activos (más antiguo primero).
        FOR tanque IN
            SELECT id, documentos_comprados, documentos_consumidos
            FROM organizacion_creditos
            WHERE organizacion_id = org.org_id
              AND agotado = FALSE
            ORDER BY created_at ASC
        LOOP
            EXIT WHEN restante <= 0;

            capacidad := tanque.documentos_comprados - tanque.documentos_consumidos;
            IF capacidad <= 0 THEN
                CONTINUE;
            END IF;

            consumir := LEAST(capacidad, restante);

            UPDATE organizacion_creditos
            SET documentos_consumidos = documentos_consumidos + consumir,
                agotado    = (documentos_consumidos + consumir) >= documentos_comprados,
                agotado_at = CASE WHEN (documentos_consumidos + consumir) >= documentos_comprados THEN NOW() ELSE agotado_at END
            WHERE id = tanque.id;

            restante := restante - consumir;
        END LOOP;

        -- Sobregiro: si queda restante y no hubo tanques con capacidad,
        -- el tanque más reciente absorbe el negativo (queda con
        -- documentos_consumidos > documentos_comprados y agotado = FALSE
        -- para que el saldo negativo sea visible en el SUM).
        IF restante > 0 THEN
            UPDATE organizacion_creditos
            SET documentos_consumidos = documentos_consumidos + restante,
                agotado = FALSE,
                agotado_at = NULL
            WHERE id = (
                SELECT id FROM organizacion_creditos
                WHERE organizacion_id = org.org_id
                ORDER BY created_at DESC
                LIMIT 1
            );
            restante := 0;
        END IF;

        -- Marcar como cobradas las facturas de esta organización.
        UPDATE facturas f
        SET cobrada = TRUE, cobrada_at = NOW()
        FROM empresas e
        WHERE e.id = f.empresa_id
          AND e.organizacion_id = org.org_id
          AND f.deleted_at IS NULL
          AND f.estado_distribucion IN ('completado', 'completado con alerta')
          AND f.updated_at >= TIMESTAMPTZ '2026-08-31 00:00:00'
          AND f.cobrada = FALSE;
    END LOOP;
END $$;

COMMIT;
