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
  --with-decryption \
  --profile personal --region sa-east-1 \
  --query 'Parameters[].Name'
```

## Notas

- CloudFormation resuelve estos valores en tiempo de deploy con `{{resolve:ssm:...}}` para String y `{{resolve:ssm-secure:...}}` para SecureString
- Las Lambdas los reciben como variables de entorno — no leen SSM en runtime
- Si cambias un valor en SSM, debes hacer un nuevo deploy para que la Lambda lo tome
- Guarda los valores reales en un gestor de contraseñas (1Password, Bitwarden, etc.)
