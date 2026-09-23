-- V81: Agregar homologacion_confirmada a causacion_detalle_item
-- Distingue entre homologacion asignada automaticamente por el sistema (false)
-- y homologacion confirmada/cambiada manualmente por el usuario (true).
-- El auto-causado inserta false. Al actualizar el item desde el modal se pone true.

ALTER TABLE causacion_detalle_item
    ADD COLUMN IF NOT EXISTS homologacion_confirmada BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN causacion_detalle_item.homologacion_confirmada IS
'true = el usuario confirmó o cambió la homologación manualmente. false = asignada automáticamente por el sistema (primera opción).';
