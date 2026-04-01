# FormalizeSEHub — Infraestructura

Stack en AWS SAM que despliega todos los servicios del sistema de facturación electrónica.

## Arquitectura AWS

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                        INTERNET                                         │
└─────────────────────────────────────────┬───────────────────────────────────────────────┘
                                          │
                                          ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                              API Gateway (REST)                                         │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐│
│  │  /clientes  │ │/proveedores │ │  /cuentas-  │ │ /descargas  │ │   /dian/download    ││
│  │             │ │             │ │  contables  │ │ /facturas   │ │                     ││
│  └──────┬──────┘ └──────┬──────┘ └──────┬──────┘ └──────┬──────┘ └──────────┬──────────┘│
└─────────┼───────────────┼───────────────┼───────────────┼───────────────────┼───────────┘
          │               │               │               │                   │
          ▼               ▼               ▼               ▼                   ▼
┌─────────────────────────────────────────────────────────────────┐ ┌─────────────────────┐
│                      Lambda Functions (CRUD)                    │ │  DianDownload       │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────────────┐│ │  Lambda             │
│  │ Clientes  │ │Proveedores│ │  Cuentas  │ │  Parametrización  ││ │  (nodejs22.x, 5min) │
│  │  (5)      │ │   (5)     │ │Contables  │ │  Descargas        ││ └──────────┬──────────┘
│  │           │ │           │ │   (6)     │ │  Facturas         ││            │
│  └─────┬─────┘ └─────┬─────┘ └─────┬─────┘ └─────────┬─────────┘│            │
└────────┼─────────────┼─────────────┼─────────────────┼──────────┘            │
         │             │             │                 │                       │
         └─────────────┴─────────────┴─────────────────┘                       │
                                     │                                         │
                                     ▼                                         ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                      VPC                                                │
│  ┌─────────────────────────────────────────────┐    ┌─────────────────────────────────┐ │
│  │              Private Subnets                │    │           S3 Bucket             │ │
│  │  ┌─────────────────────────────────────┐    │    │    formalizese-invoices-{env}   │ │
│  │  │         RDS PostgreSQL              │    │    │    ┌─────────────────────────┐  │ │
│  │  │       formalizese-db-{env}          │    │    │    │  ZIPs facturas DIAN     │  │ │
│  │  │                                     │    │    │    │  XMLs procesados        │  │ │
│  │  │  • clientes        • facturas       │    │    │    └─────────────────────────┘  │ │
│  │  │  • proveedores     • descargas      │    │    └─────────────────┬───────────────┘ │
│  │  │  • cuentas_contables                │    │                      │                 │
│  │  │  • proveedor_por_cuenta_contable    │    │                      │                 │
│  │  │  • redistribucion_contable          │    │                      ▼                 │
│  │  └─────────────────────────────────────┘    │    ┌─────────────────────────────────┐ │
│  └─────────────────────────────────────────────┘    │         SQS Queues              │ │
│                                                     │  ┌───────────────────────────┐  │ │
│                                                     │  │ invoice-processing-queue  │  │ │
│                                                     │  │          │                │  │ │
│                                                     │  │          ▼                │  │ │
│                                                     │  │ ┌─────────────────────┐   │  │ │
│                                                     │  │ │InvoiceProcessing    │   │  │ │
│                                                     │  │ │Lambda (5min)        │   │  │ │
│                                                     │  │ └─────────────────────┘   │  │ │
│                                                     │  │          │                │  │ │
│                                                     │  │          ▼ (3 retries)    │  │ │
│                                                     │  │ ┌─────────────────────┐   │  │ │
│                                                     │  │ │ DLQ (Dead Letter)   │   │  │ │
│                                                     │  │ └─────────────────────┘   │  │ │
│                                                     │  └───────────────────────────┘  │ │
│                                                     └─────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

## Flujo de Descarga DIAN

```
┌──────────┐     POST /dian/download       ┌─────────────────┐
│ Frontend │ ───────────────────────────▶ │ DianDownload    │
└──────────┘   {clientId, fechas, cookies} │ Lambda          │
                                           └────────┬────────┘
                                                    │
                    ┌───────────────────────────────┼───────────────────────────────┐
                    │                               │                               │
                    ▼                               ▼                               ▼
           ┌────────────────┐            ┌─────────────────┐            ┌─────────────────┐
           │   DIAN Portal  │            │    S3 Bucket    │            │   SQS Queue     │
           │  (autenticación│            │  (guarda ZIP)   │            │ (publica msg)   │
           │   y descarga)  │            └─────────────────┘            └────────┬────────┘
           └────────────────┘                                                    │
                                                                                 ▼
                                                                    ┌─────────────────────┐
                                                                    │ InvoiceProcessing   │
                                                                    │ Lambda              │
                                                                    │ • Descarga ZIP de S3│
                                                                    │ • Procesa Excel+XML │
                                                                    │ • Persiste en RDS   │
                                                                    └──────────┬──────────┘
                                                                               │
                                                              ┌────────────────┴────────────────┐
                                                              │                                 │
                                                              ▼                                 ▼
                                                    ┌─────────────────┐               ┌─────────────────┐
                                                    │    Success      │               │  Failure (x3)   │
                                                    │  facturas en DB │               │  mensaje a DLQ  │
                                                    └─────────────────┘               └─────────────────┘
```

## Requisitos

- AWS SAM CLI
- AWS CLI configurado
- Node.js 20+

## Configuración

1. Copiar el archivo de configuración de ejemplo:
```bash
cp samconfig.toml.example samconfig.toml
```

2. Editar `samconfig.toml` con tus valores:
```toml
[dev.deploy.parameters]
profile = "tu-perfil-aws"
parameter_overrides = "Environment=dev DatabasePassword=xxx VpcId=vpc-xxx Subnet1Id=subnet-xxx Subnet2Id=subnet-xxx"
```

## Deploy

```bash
./scripts/deploy.sh dev      # desarrollo
./scripts/deploy.sh staging  # staging
./scripts/deploy.sh prod     # producción
```

## Endpoints API

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | /clientes | Listar clientes |
| GET | /clientes/{id} | Obtener cliente |
| POST | /clientes | Crear cliente |
| PUT | /clientes/{id} | Actualizar cliente |
| DELETE | /clientes/{id} | Eliminar cliente |
| GET | /proveedores | Listar proveedores |
| GET | /proveedores/{id} | Obtener proveedor |
| POST | /proveedores | Crear proveedor |
| PUT | /proveedores/{id} | Actualizar proveedor |
| DELETE | /proveedores/{id} | Eliminar proveedor |
| GET | /cuentas-contables | Listar cuentas |
| GET | /cuentas-contables/{id} | Obtener cuenta |
| POST | /cuentas-contables | Crear cuenta |
| PUT | /cuentas-contables/{id} | Actualizar cuenta |
| DELETE | /cuentas-contables/{id} | Eliminar cuenta |
| POST | /cuentas-contables/cargar-masiva | Carga masiva |
| GET | /proveedores-por-cuentas | Listar parametrizaciones |
| GET | /proveedores-por-cuentas/{id} | Obtener parametrización |
| POST | /proveedores-por-cuentas | Crear parametrización |
| PUT | /proveedores-por-cuentas/{id} | Actualizar parametrización |
| DELETE | /proveedores-por-cuentas/{id} | Eliminar parametrización |
| GET | /descargas | Listar descargas |
| GET | /descargas/{id} | Obtener descarga |
| GET | /facturas/{id} | Obtener factura |
| POST | /dian/download | Iniciar descarga DIAN |

## Estructura

```
infrastructure/
├── template.yaml              # Stack SAM principal
├── samconfig.toml.example     # Configuración de ejemplo
├── README.md
├── scripts/
│   └── deploy.sh              # Script de build + deploy
├── database/
│   ├── connect-db.sh          # Conectar a la DB
│   ├── dump-db.sh             # Exportar dump de la DB
│   └── queries-ejemplo.sql    # Queries de ejemplo
└── docs/
    ├── api-endpoints.sh       # Ejemplos de llamadas API
    └── test-endpoints.sh      # Tests automatizados
```

## Recursos AWS

| Recurso | Nombre | Descripción |
|---------|--------|-------------|
| API Gateway | FormalizeSEHub-API-{env} | Gateway REST |
| RDS PostgreSQL | formalizese-db-{env} | Base de datos |
| S3 Bucket | formalizese-invoices-{env} | Facturas DIAN |
| SQS Queue | formalizese-invoice-processing-{env} | Cola de procesamiento |
| SQS DLQ | formalizese-invoice-processing-dlq-{env} | Mensajes fallidos |
| IAM Role | formalizese-lambda-role-{env} | Rol para Lambdas |

## Base de Datos

Conectar:
```bash
./database/connect-db.sh
```

Exportar dump:
```bash
./database/dump-db.sh
```

## Notas

- RDS no es accesible públicamente (solo desde VPC)
- SQS VisibilityTimeout (360s) > Lambda Timeout (300s)
- DLQ retiene mensajes fallidos después de 3 reintentos
- S3 lifecycle: 90 días en prod, 30 días en dev/staging
