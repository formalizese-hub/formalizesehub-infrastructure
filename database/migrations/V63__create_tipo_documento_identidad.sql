-- V63: Catálogo global de tipos de documento de identidad (códigos oficiales DIAN).
-- Normaliza los valores que hoy viven como VARCHAR libre en:
--   proveedores.tipo_documento, facturas.tipo_documento_receptor, comprobantesiigo.tipo_documento
-- Estándar: Anexo Técnico de Facturación Electrónica DIAN (tabla de tipos de documento de identificación).

CREATE TABLE IF NOT EXISTS tipo_documento_identidad (
    codigo      VARCHAR(2)    PRIMARY KEY,       -- código oficial DIAN
    nombre      VARCHAR(100)  NOT NULL,          -- nombre oficial DIAN
    abreviatura VARCHAR(10)   NOT NULL,          -- sigla de uso común (CC, NIT, CE...)
    activo      BOOLEAN       NOT NULL DEFAULT TRUE
);

COMMENT ON TABLE  tipo_documento_identidad             IS 'Catálogo de tipos de documento de identidad según codificación oficial DIAN.';
COMMENT ON COLUMN tipo_documento_identidad.codigo      IS 'Código DIAN del tipo de documento de identificación.';
COMMENT ON COLUMN tipo_documento_identidad.nombre      IS 'Nombre oficial del tipo de documento según DIAN.';
COMMENT ON COLUMN tipo_documento_identidad.abreviatura IS 'Sigla de uso común (CC, NIT, CE, TI, etc.).';

INSERT INTO tipo_documento_identidad (codigo, nombre, abreviatura) VALUES
('11', 'Registro civil',                                  'RC'),
('12', 'Tarjeta de identidad',                            'TI'),
('13', 'Cédula de ciudadanía',                            'CC'),
('21', 'Tarjeta de extranjería',                          'TE'),
('22', 'Cédula de extranjería',                           'CE'),
('31', 'NIT',                                             'NIT'),
('41', 'Pasaporte',                                       'PAS'),
('42', 'Documento de identificación extranjero',          'DIE'),
('47', 'PEP (Permiso Especial de Permanencia)',           'PEP'),
('48', 'PPT (Permiso por Protección Temporal)',           'PPT'),
('50', 'NIT de otro país',                                'NIT-OP'),
('91', 'NUIP',                                            'NUIP')
ON CONFLICT (codigo) DO NOTHING;
