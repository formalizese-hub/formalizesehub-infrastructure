-- V6: Agrega campo estado_distribucion a la tabla facturas
-- Se usa como bandera para indicar si la redistribución contable ha sido completada.
-- Valores: 'pendiente' (default), 'completado'

ALTER TABLE facturas
  ADD COLUMN estado_distribucion VARCHAR(20) NOT NULL DEFAULT 'pendiente';
