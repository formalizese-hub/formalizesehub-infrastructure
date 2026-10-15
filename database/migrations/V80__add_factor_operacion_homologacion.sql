-- V80: Agregar factor_operacion a homologacion_productos
-- Indica si el factor de conversión se aplica como multiplicación (*) o división (/).
-- Internamente el cálculo SIEMPRE multiplica: cuando el usuario elige ÷N,
-- el frontend guarda factor_conversion = 1/N y factor_operacion = '/'.
-- factor_operacion solo se usa para mostrar la operación correctamente en la UI.

ALTER TABLE homologacion_productos
    ADD COLUMN IF NOT EXISTS factor_operacion CHAR(1) NOT NULL DEFAULT '*'
    CHECK (factor_operacion IN ('*', '/'));

COMMENT ON COLUMN homologacion_productos.factor_operacion IS
'Operación de conversión visible en la UI: * = multiplicar, / = dividir.
Internamente siempre se multiplica; cuando es /, factor_conversion = 1/valor_ingresado.';
