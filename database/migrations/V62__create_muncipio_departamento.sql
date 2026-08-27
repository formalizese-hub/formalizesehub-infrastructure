CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS departamentos (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    codigo VARCHAR(2) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL
);

COMMENT ON TABLE departamentos IS
'Catálogo de departamentos de Colombia basado en la codificación oficial DANE.';

COMMENT ON COLUMN departamentos.codigo IS
'Código DANE del departamento (2 dígitos).';

COMMENT ON COLUMN departamentos.nombre IS
'Nombre oficial del departamento según DANE.';


INSERT INTO departamentos (codigo, nombre) VALUES
('05', 'ANTIOQUIA'),
('08', 'ATLÁNTICO'),
('11', 'BOGOTÁ D.C.'),
('13', 'BOLÍVAR'),
('15', 'BOYACÁ'),
('17', 'CALDAS'),
('18', 'CAQUETÁ'),
('19', 'CAUCA'),
('20', 'CESAR'),
('23', 'CÓRDOBA'),
('25', 'CUNDINAMARCA'),
('27', 'CHOCÓ'),
('41', 'HUILA'),
('44', 'LA GUAJIRA'),
('47', 'MAGDALENA'),
('50', 'META'),
('52', 'NARIÑO'),
('54', 'NORTE DE SANTANDER'),
('63', 'QUINDÍO'),
('66', 'RISARALDA'),
('68', 'SANTANDER'),
('70', 'SUCRE'),
('73', 'TOLIMA'),
('76', 'VALLE DEL CAUCA'),
('81', 'ARAUCA'),
('85', 'CASANARE'),
('86', 'PUTUMAYO'),
('88', 'ARCHIPIÉLAGO DE SAN ANDRÉS, PROVIDENCIA Y SANTA CATALINA'),
('91', 'AMAZONAS'),
('94', 'GUAINÍA'),
('95', 'GUAVIARE'),
('97', 'VAUPÉS'),
('99', 'VICHADA')
ON CONFLICT (codigo) DO NOTHING;


CREATE TABLE IF NOT EXISTS municipios (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    codigo VARCHAR(10) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    departamento_codigo VARCHAR(2) NOT NULL,

    CONSTRAINT fk_municipios_departamentos
        FOREIGN KEY (departamento_codigo)
        REFERENCES departamentos(codigo)
);

COMMENT ON TABLE municipios IS
'Catálogo de municipios de Colombia basado en la codificación oficial DANE.';

COMMENT ON COLUMN municipios.codigo IS
'Código DANE del municipio (5 dígitos).';

COMMENT ON COLUMN municipios.nombre IS
'Nombre oficial del municipio según DANE.';

COMMENT ON COLUMN municipios.departamento_codigo IS
'Código DANE del departamento al que pertenece el municipio.';

CREATE INDEX IF NOT EXISTS idx_municipios_departamento_codigo
    ON municipios (departamento_codigo);