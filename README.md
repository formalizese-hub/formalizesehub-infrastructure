# FormalizeSEHub — Infraestructura

Stack AWS SAM que despliega todos los recursos del sistema de facturación electrónica FormalizeSE Hub.

## Cuentas AWS

| Ambiente | Account ID | Región | Profile CLI |
|----------|-----------|--------|-------------|
| Dev (management) | 152406482061 | sa-east-1 | `formalizese-new` |
| Prod (hija) | 558567543665 | us-east-2 | `formalizese-prod` |

### Acceso a consola web de prod

1. Login con cuenta dev (formalizese123aws@gmail.com)
2. Click tu nombre → "Switch role"
3. Account: `558567543665`, Role: `OrganizationAccountAccessRole`

## Recursos AWS por ambiente

| Recurso | Nombre | Descripción |
|---------|--------|-------------|
| API Gateway | `FormalizeSEHub-API-{env}` | REST API para todos los servicios |
| RDS PostgreSQL | `formalizese-db-{env}` | Base de datos |
| S3 Bucket | `formalizese-invoices-{env}-{account}` | Facturas (ZIPs, XMLs, PDFs) |
| SQS Queue | `formalizese-invoice-processing-{env}` | Cola procesamiento facturas |
| SQS Queue | `formalizese-redistribucion-processing-{env}` | Cola redistribución automática |
| Lambda Functions | `formalizese-*-{env}` | ~76 funciones |

## Deploy

### Pre-requisitos

- AWS CLI con profiles `formalizese-new` y `formalizese-prod` configurados
- SAM CLI instalado (`brew install aws-sam-cli`)
- Node.js 20+

### Comandos de deploy

```bash
cd formalizesehub-infrastructure
```

#### Solo infraestructura (código placeholder en Lambdas)

No requiere repos locales. Crea/actualiza infra y Lambdas con código placeholder.
GitHub Actions se encarga de deployar el código real.

```bash
# Dev
./scripts/deploy.sh dev --infra-only

# Prod
AWS_PROFILE=formalizese-prod ./scripts/deploy.sh prod --infra-only
```

#### Build completo + deploy

Buildea todos los repos locales y sube código real.

```bash
# Dev
./scripts/deploy.sh dev --force

# Prod (asegurarse de estar en rama main en todos los repos)
./update-all-repos.sh prod
AWS_PROFILE=formalizese-prod ./scripts/deploy.sh prod --force
```

#### Deploy incremental

Detecta cambios por git hash. Solo buildea repos con cambios.

```bash
./scripts/deploy.sh dev
```

### ¿Cuándo usar cada modo?

| Situación | Comando |
|-----------|---------|
| Crear stack desde cero (primera vez) | `--infra-only` |
| Agregar nueva Lambda al template | `--infra-only` |
| Cambiar variables de entorno | `--infra-only` |
| Cambiar IAM, VPC, SQS, API Gateway | `--infra-only` |
| Deploy manual con código local | `--force` |

## CI/CD (GitHub Actions)

El código de las Lambdas se deploya automáticamente:

- **Push a `develop`** → deploy a dev
- **Push/merge a `main`** → deploy a prod

El deploy de infra es siempre manual desde terminal.

## Flujos comunes

### Nuevo feature a producción

```
1. git checkout -b feature/mi-feature (desde develop)
2. Desarrollar + commit + push
3. Crear PR → develop (GitHub)
4. Merge → CI/CD deploya a dev automáticamente
5. Probar en dev
6. Crear PR → main (GitHub)
7. Merge → CI/CD deploya a prod automáticamente
```

### Agregar nueva Lambda

```
1. Crear servicio en su repo (services/nuevo-servicio/)
2. Agregar build.mjs y package.json
3. Agregar función en template.yaml (CodeUri: ./placeholder/)
4. Deploy infra: ./scripts/deploy.sh dev --infra-only
5. Push código a develop → GitHub Actions deploya código real
```

### Cambiar variable de entorno

```
1. Agregar parámetro en template.yaml (Parameters + Globals > Environment)
2. Actualizar samconfig.toml con el valor
3. Deploy infra: ./scripts/deploy.sh dev --infra-only
```

## Actualizar repos locales

```bash
# Sincronizar con develop (para trabajar)
./update-all-repos.sh dev

# Sincronizar con main (antes de deploy prod con --force)
./update-all-repos.sh prod
```

## Migraciones de BD

```bash
cd database

# Interactivo (pide password)
./run-migrations.sh dev
./run-migrations.sh prod

# Manual
export PGPASSWORD="<password>"
psql -h <endpoint> -p 5432 -U postgres -d formalizese -f migrations/V1__xxx.sql
```

## Estructura

```
formalizesehub-infrastructure/
├── template.yaml          # Stack SAM (todos los recursos)
├── samconfig.toml         # Configuración por entorno (dev/prod)
├── placeholder/           # Código placeholder para Lambdas (creación inicial)
│   └── index.mjs
├── scripts/
│   └── deploy.sh          # Script principal de deploy
├── database/
│   ├── migrations/        # SQL migrations (V1, V2, ...)
│   ├── run-migrations.sh  # Ejecutor de migraciones
│   └── connect-db.sh      # Conectar via psql
└── docs/
    └── ssm-parameters.md
```

## SSM Parameters requeridos

Deben existir en cada cuenta/región antes del deploy:

| Parámetro | Descripción |
|-----------|-------------|
| `/formalizese/{env}/db-password` | Password de PostgreSQL |
| `/formalizese/{env}/jwt-secret` | (opcional, se puede pasar en samconfig) |
| `/formalizese/{env}/gmail-user-email` | Email para polling Gmail |
