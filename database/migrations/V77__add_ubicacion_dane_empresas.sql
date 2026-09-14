-- V77: Ubicación geográfica (código DANE) en empresas
-- Se guarda el CÓDIGO DANE que viene en la factura electrónica:
--   - departamento = CountrySubentityCode (2 dígitos)
--   - ciudad       = cbc:ID del Address / municipio (5 dígitos)
-- Proveedores ya tiene las columnas departamento y ciudad (texto), que se
-- reutilizan para guardar el código. Empresas no las tenía: se crean aquí.
-- El nombre se resuelve contra los catálogos departamentos/municipios al mostrar.

ALTER TABLE empresas
    ADD COLUMN IF NOT EXISTS departamento VARCHAR(10) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS ciudad       VARCHAR(10) DEFAULT NULL;

COMMENT ON COLUMN empresas.departamento IS 'Código DANE del departamento (CountrySubentityCode, 2 dígitos).';
COMMENT ON COLUMN empresas.ciudad       IS 'Código DANE del municipio (Address ID, 5 dígitos).';
