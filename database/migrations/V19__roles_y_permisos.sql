-- =====================================================
-- V19: Sistema de Roles y Permisos
-- Agrega superadmin, renombra auxiliar → auxiliar_contable,
-- e inserta la organización sistema para el superadmin.
-- =====================================================
-- UP: ejecutar este archivo completo
-- DOWN: ver sección comentada al final
-- =====================================================

BEGIN;

-- ─── 1. Agregar columna descripcion a organizaciones (si no existe) ───────────
-- La tabla fue creada en V16 sin campo descripcion; el diseño lo requiere.
ALTER TABLE organizaciones
    ADD COLUMN IF NOT EXISTS descripcion TEXT;

COMMENT ON COLUMN organizaciones.descripcion IS 'Descripción opcional de la organización';

-- ─── 2. Insertar organización sistema (idempotente) ───────────────────────────
-- UUID fijo reservado para el superadmin. Nunca debe usarse como tenant real.
INSERT INTO organizaciones (id, nombre, descripcion, activo)
VALUES (
    '00000000-0000-0000-0000-000000000001'::uuid,
    'Sistema FormalizeSE',
    'Organización reservada para el superadmin de la plataforma. No usar como tenant.',
    true
)
ON CONFLICT (id) DO NOTHING;

-- ─── 3. Insertar/actualizar los 4 roles canónicos (idempotente) ───────────────
-- ON CONFLICT actualiza descripcion y reactiva el rol si estaba inactivo.
INSERT INTO roles (nombre, descripcion, activo)
VALUES
    ('superadmin',        'Administrador global de la plataforma — acceso sin restricción de organización', true),
    ('admin',             'Administrador de organización — gestión total dentro de su organización',        true),
    ('contador',          'Contador — acceso operativo completo a módulos de su organización',              true),
    ('auxiliar_contable', 'Auxiliar contable — lectura en módulos operativos, escritura en redistribuciones', true)
ON CONFLICT (nombre) DO UPDATE
    SET descripcion = EXCLUDED.descripcion,
        activo      = true,
        -- roles no tienen updated_at en V16, no actualizar ese campo
        nombre      = EXCLUDED.nombre;  -- no-op, solo para que DO UPDATE sea válido

-- ─── 4. Renombrar rol 'auxiliar' → 'auxiliar_contable' ───────────────────────
-- Solo aplica si 'auxiliar' existe Y 'auxiliar_contable' aún no existe.
-- El INSERT anterior ya creó 'auxiliar_contable', así que este UPDATE
-- solo renombra si por alguna razón el INSERT no lo cubrió.
UPDATE roles
SET nombre = 'auxiliar_contable'
WHERE nombre = 'auxiliar'
  AND NOT EXISTS (
      SELECT 1 FROM roles WHERE nombre = 'auxiliar_contable'
  );

COMMIT;

-- =====================================================
-- DOWN — ejecutar manualmente para revertir
-- =====================================================
--
-- BEGIN;
--
-- -- Revertir renombrado auxiliar_contable → auxiliar
-- -- (solo si no hay usuarios activos con ese rol)
-- UPDATE roles
-- SET nombre = 'auxiliar'
-- WHERE nombre = 'auxiliar_contable'
--   AND NOT EXISTS (
--       SELECT 1 FROM usuarios u
--       JOIN roles r ON r.id = u.rol_id
--       WHERE r.nombre = 'auxiliar_contable'
--         AND u.deleted_at IS NULL
--   );
--
-- -- Desactivar rol superadmin (no eliminar — preserva FK de usuarios existentes)
-- UPDATE roles SET activo = false WHERE nombre = 'superadmin';
--
-- -- Desactivar organización sistema (no eliminar — preserva FK de usuarios existentes)
-- UPDATE organizaciones
-- SET activo = false
-- WHERE id = '00000000-0000-0000-0000-000000000001'::uuid;
--
-- COMMIT;
