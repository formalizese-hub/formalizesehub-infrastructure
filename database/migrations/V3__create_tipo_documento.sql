CREATE TABLE IF NOT EXISTS tipo_documento (
    id     VARCHAR(36)  PRIMARY KEY DEFAULT gen_random_uuid()::text,
    nombre VARCHAR(255) NOT NULL 
);
