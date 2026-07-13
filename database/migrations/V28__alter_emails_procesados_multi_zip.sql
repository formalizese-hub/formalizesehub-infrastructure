-- =====================================================
-- V28: Soporte múltiples adjuntos ZIP por email
-- FormalizeSE Hub
-- =====================================================
-- Un email reenviado puede contener N archivos .zip.
-- Se registra un row por cada ZIP procesado.
-- La idempotencia pasa de (message_id) a (message_id, attachment_filename).

-- 1. Agregar columna para el nombre del archivo adjunto
ALTER TABLE emails_procesados
    ADD COLUMN attachment_filename TEXT;

-- 2. Backfill: emails existentes quedan con valor genérico
UPDATE emails_procesados
    SET attachment_filename = 'attachment.zip'
    WHERE attachment_filename IS NULL;

-- 3. Marcar como NOT NULL después del backfill
ALTER TABLE emails_procesados
    ALTER COLUMN attachment_filename SET NOT NULL;

-- 4. Eliminar constraint UNIQUE anterior (solo message_id)
ALTER TABLE emails_procesados
    DROP CONSTRAINT emails_procesados_message_id_key;

-- 5. Crear constraint compuesto (message_id + attachment_filename)
ALTER TABLE emails_procesados
    ADD CONSTRAINT uq_emails_procesados_message_attachment
    UNIQUE (message_id, attachment_filename);

COMMENT ON COLUMN emails_procesados.attachment_filename
    IS 'Nombre del archivo ZIP adjunto — permite múltiples ZIPs por email';
