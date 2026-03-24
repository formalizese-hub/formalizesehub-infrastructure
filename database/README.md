# Base de Datos FormalizeSE Hub

Sistema de gestión de facturación electrónica y contabilidad para Colombia.

## 📊 Diagrama de Relaciones

```
┌─────────────────┐
│    CLIENTES     │
│─────────────────│
│ id (PK)         │
│ nombre          │
│ nit (UNIQUE)    │
│ email           │
│ prefijo_facturas[]
│ configuracion_json
└────────┬────────┘
         │
         │ 1:N
         │
┌────────▼────────────────┐
│  CUENTAS_CONTABLES      │◄───┐
│─────────────────────────│    │ Auto-referencia
│ id (PK)                 │    │ (jerarquía)
│ codigo_cuenta           │    │
│ nombre_cuenta           │    │
│ tipo_cuenta             │    │
│ nivel_cuenta            │    │
│ cuenta_padre_id (FK)────┘    │
│ naturaleza_cuenta       │    │
│ acepta_movimientos      │    │
│ cliente_id (FK)         │    │
└─────────┬───────────────┘    │
          │                     │
          │ N:M                 │
          │                     │
┌─────────▼───────────────────────┐
│ PROVEEDOR_POR_CUENTA_CONTABLE   │
│─────────────────────────────────│
│ id (PK)                         │
│ cuenta_contable_id (FK)─────────┘
│ proveedor_id (FK)───────┐
│ prioridad               │
└─────────────────────────┼───────┘
                          │
           ┌──────────────┘
           │
┌──────────▼──────┐
│  PROVEEDORES    │
│─────────────────│
│ id (PK)         │
│ nit (UNIQUE)    │
│ nombre          │
│ email           │
│ notas           │
└────────┬────────┘
         │
         │ 1:N
         │
┌────────▼────────┐       ┌──────────────────┐
│    FACTURAS     │       │    DESCARGAS     │
│─────────────────│       │──────────────────│
│ id (PK)         │       │ id (PK)          │
│ numero_factura  │◄──────│ cufe_listado     │
│ cufe (UNIQUE)   │  N:1  │ fecha_inicio     │
│ proveedor_id(FK)│       │ fecha_fin        │
│ descarga_id (FK)│       │ estado           │
│ fecha_emision   │       │ total_facturas   │
│ procesada       │       └──────────────────┘
│ ruta_archivo    │
└────────┬────────┘
         │ 1:N
         │
┌────────▼──────────────────┐
│ REDISTRIBUCION_CONTABLE   │
│───────────────────────────│
│ id (PK)                   │
│ factura_id (FK)           │
│ cuenta_contable_id (FK)   │
│ proveedor_id (FK)         │
│ valor                     │
│ es_sugerida               │
│ aprobado                  │
│ aprobado_por              │
└───────────────────────────┘
```

## 📋 Descripción de Tablas

### 1. **clientes**
Empresas que utilizan el sistema de contabilidad.
- `prefijo_facturas`: Array de prefijos autorizados para facturación
- `configuracion_json`: Configuraciones personalizadas en formato JSONB
- Soft delete: `deleted_at`

### 2. **proveedores**
Proveedores que emiten facturas electrónicas.
- Identificados por NIT único
- Soft delete: `deleted_at`

### 3. **descargas**
Control de descargas masivas de facturas desde la DIAN.
- Estados: PENDIENTE, EN_PROCESO, COMPLETADO, ERROR

### 4. **cuentas_contables**
Plan Único de Cuentas (PUC) por cliente con estructura jerárquica.
- `nivel_cuenta`: 1=Clase, 2=Grupo, 3=Cuenta, 4=Subcuenta, 5=Auxiliar
- `acepta_movimientos`: Solo cuentas auxiliares pueden recibir redistribuciones

### 5. **proveedor_por_cuenta_contable**
Parametrización de cuentas sugeridas por proveedor.
- `prioridad`: Orden de prioridad para asignación automática (1=mayor prioridad)

### 6. **facturas**
Facturas electrónicas recibidas y procesadas desde la DIAN.
- `cufe`: Código Único de Facturación Electrónica (DIAN Colombia) - UNIQUE

### 7. **redistribucion_contable**
Distribución y asignación contable de facturas.
- `es_sugerida`: Indica si fue sugerida automáticamente
- `aprobado`: Requiere aprobación de un contador

## 🚀 Inicialización de la Base de Datos

### Opción 1: Script automatizado (Recomendado)

```bash
cd infrastructure/database
chmod +x setup-db.sh
./setup-db.sh
```

El script obtiene automáticamente el endpoint del stack `formalizese-hub` de CloudFormation y ejecuta el schema completo.

### Opción 2: Desde línea de comandos

```bash
DB_ENDPOINT=$(aws cloudformation describe-stacks \
  --stack-name formalizese-hub \
  --query 'Stacks[0].Outputs[?OutputKey==`DatabaseEndpoint`].OutputValue' \
  --output text \
  --profile personal \
  --region sa-east-1)

psql -h $DB_ENDPOINT -U postgres -d formalizese -f infrastructure/database/schema.sql
```

### Opción 3: Cliente GUI (DBeaver / pgAdmin)
1. Conectar con las credenciales del stack
2. Abrir `schema.sql`
3. Ejecutar el script completo

## 🔄 Conectarse a la Base de Datos

```bash
cd infrastructure/database
chmod +x connect-db.sh
./connect-db.sh
```

## 📝 Queries de ejemplo

Ver [queries-ejemplo.sql](queries-ejemplo.sql) para consultas útiles.

## 📊 Diagrama detallado

Ver [DIAGRAMA.md](DIAGRAMA.md) para el diagrama ER completo con flujos.
