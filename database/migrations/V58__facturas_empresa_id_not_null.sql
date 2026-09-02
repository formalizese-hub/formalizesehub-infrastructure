-- V58: Hacer empresa_id NOT NULL en facturas
-- Necesario para que ON CONFLICT (cufe, empresa_id) funcione correctamente.
-- PostgreSQL no puede usar un unique index con columnas nullable para ON CONFLICT.
-- Se verificó que no existen filas con empresa_id NULL antes de aplicar esta migración.

ALTER TABLE facturas ALTER COLUMN empresa_id SET NOT NULL;
