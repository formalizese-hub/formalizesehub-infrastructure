# Parámetros SSM — FormalizeSE Hub

Estos parámetros deben existir en AWS SSM Parameter Store antes de ejecutar un deploy.
**Nunca guardes los valores aquí — solo los nombres.**

## Entorno: dev

| Nombre | Tipo | Descripción |
|--------|------|-------------|
| `/formalizese/dev/db-password` | String | Contraseña del usuario `postgres` en RDS |
| `/formalizese/dev/vpc-id` | String | ID de la VPC donde viven las Lambdas y RDS |
| `/formalizese/dev/subnet-1-id` | String | Subnet privada 1 (AZ-a) |
| `/formalizese/dev/subnet-2-id` | String | Subnet privada 2 (AZ-b) |
| `/formalizese/dev/jwt-secret` | SecureString | Clave para firmar JWT (mínimo 32 caracteres) |
| `/formalizese/dev/gmail-user-email` | String | Email del buzón de facturas (`facturas@dominio.co`) |

## Secrets Manager

Estos secrets se almacenan en AWS Secrets Manager (no SSM) por contener credenciales JSON extensas.

| Nombre | Descripción | Formato |
|--------|-------------|---------|
| `formalizese/dev/gmail-service-account` | Llave JSON del Service Account de Google Cloud para Gmail API | JSON (`type`, `project_id`, `private_key`, `client_email`, etc.) |

### Crear/actualizar el secret

```bash
# Crear (primera vez)
aws secretsmanager create-secret \
  --name formalizese/dev/gmail-service-account \
  --secret-string file://service-account-key.json \
  --description "Gmail Service Account key para email-invoice-poller" \
  --profile formalizese-new --region sa-east-1

# Actualizar (reemplazar placeholder por credenciales reales)
aws secretsmanager put-secret-value \
  --secret-id formalizese/dev/gmail-service-account \
  --secret-string file://service-account-key.json \
  --profile formalizese-new --region sa-east-1
```

### Requisitos del Service Account

1. Proyecto en Google Cloud con Gmail API habilitada
2. Service Account con Domain-Wide Delegation activado
3. En Google Admin Console → Security → API Controls → Domain-Wide Delegation:
   - Client ID del Service Account
   - Scopes: `https://www.googleapis.com/auth/gmail.readonly`, `https://www.googleapis.com/auth/gmail.modify`
4. El buzón `facturas@dominio` debe existir en Google Workspace

## Cómo crear un parámetro

```bash
# String normal
aws ssm put-parameter \
  --name /formalizese/dev/vpc-id \
  --value "vpc-xxxxxxxxxxxxxxxxx" \
  --type String \
  --profile personal --region sa-east-1

# SecureString (para secretos)
aws ssm put-parameter \
  --name /formalizese/dev/jwt-secret \
  --value "tu-secret-aqui" \
  --type SecureString \
  --profile personal --region sa-east-1
```

## Cómo verificar que todos existen

```bash
aws ssm get-parameters \
  --names \
    /formalizese/dev/db-password \
    /formalizese/dev/vpc-id \
    /formalizese/dev/subnet-1-id \
    /formalizese/dev/subnet-2-id \
    /formalizese/dev/jwt-secret \
    /formalizese/dev/gmail-user-email \
  --with-decryption \
  --profile formalizese-new --region sa-east-1 \
  --query 'Parameters[].Name'

# Verificar secret de Gmail
aws secretsmanager get-secret-value \
  --secret-id formalizese/dev/gmail-service-account \
  --profile formalizese-new --region sa-east-1 \
  --query 'Name'
```

## Notas

- CloudFormation resuelve estos valores en tiempo de deploy con `{{resolve:ssm:...}}` para String y `{{resolve:ssm-secure:...}}` para SecureString
- Las Lambdas los reciben como variables de entorno — no leen SSM en runtime
- Si cambias un valor en SSM, debes hacer un nuevo deploy para que la Lambda lo tome
- Guarda los valores reales en un gestor de contraseñas (1Password, Bitwarden, etc.)
