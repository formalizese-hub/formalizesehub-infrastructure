# AWS CLI — Comandos base FormalizeSE Hub

> Perfil: `formalizese-new` | Región: `sa-east-1`
>
> Agrega `--profile formalizese-new --region sa-east-1` a todos los comandos,
> o exporta las variables para no repetirlos:
> ```bash
> export AWS_PROFILE=formalizese-new
> export AWS_DEFAULT_REGION=sa-east-1
> ```

---

## Verificar credenciales

```bash
# Ver quién eres (account id, user/role)
aws sts get-caller-identity --profile formalizese-new --region sa-east-1
```

---

## Lambdas

```bash
# Listar todas las lambdas
aws lambda list-functions \
  --query 'Functions[*].[FunctionName,Runtime,LastModified]' \
  --output table \
  --profile formalizese-new --region sa-east-1

# Buscar lambdas por nombre (filtro)
aws lambda list-functions \
  --query 'Functions[?contains(FunctionName, `formalizese`)].FunctionName' \
  --output table \
  --profile formalizese-new --region sa-east-1

# Ver detalle de una lambda
aws lambda get-function \
  --function-name formalizese-email-invoice-poller-dev \
  --profile formalizese-new --region sa-east-1

# Ver variables de entorno de una lambda
aws lambda get-function-configuration \
  --function-name formalizese-email-invoice-poller-dev \
  --query 'Environment.Variables' \
  --profile formalizese-new --region sa-east-1

# Invocar una lambda manualmente
aws lambda invoke \
  --function-name formalizese-email-invoice-poller-dev \
  --payload '{}' \
  --cli-binary-format raw-in-base64-out \
  response.json \
  --profile formalizese-new --region sa-east-1
cat response.json

# Ver logs de la última ejecución
aws logs tail /aws/lambda/formalizese-email-invoice-poller-dev \
  --follow \
  --profile formalizese-new --region sa-east-1

# Ver logs de un rango de tiempo (últimos 30 min)
aws logs tail /aws/lambda/formalizese-email-invoice-poller-dev \
  --since 30m \
  --profile formalizese-new --region sa-east-1

# Actualizar código de una lambda (zip directo)
aws lambda update-function-code \
  --function-name formalizese-email-invoice-poller-dev \
  --zip-file fileb://dist.zip \
  --profile formalizese-new --region sa-east-1
```

---

## CloudWatch Logs

```bash
# Listar grupos de logs de lambdas
aws logs describe-log-groups \
  --log-group-name-prefix /aws/lambda/formalizese \
  --query 'logGroups[*].logGroupName' \
  --output table \
  --profile formalizese-new --region sa-east-1

# Ver últimos eventos de un log group
aws logs tail /aws/lambda/formalizese-auth-login-dev \
  --since 1h \
  --format short \
  --profile formalizese-new --region sa-east-1

# Filtrar logs por texto (buscar errores)
aws logs filter-log-events \
  --log-group-name /aws/lambda/formalizese-email-invoice-poller-dev \
  --filter-pattern "ERROR" \
  --start-time $(date -d '1 hour ago' +%s000) \
  --profile formalizese-new --region sa-east-1
```

---

## Secrets Manager

```bash
# Listar todos los secrets
aws secretsmanager list-secrets \
  --query 'SecretList[*].[Name,LastChangedDate]' \
  --output table \
  --profile formalizese-new --region sa-east-1

# Ver valor de un secret
aws secretsmanager get-secret-value \
  --secret-id "formalizese/email-poller/gmail-credentials" \
  --query 'SecretString' \
  --profile formalizese-new --region sa-east-1

# Crear un secret
aws secretsmanager create-secret \
  --name "formalizese/env/nombre-secret" \
  --secret-string '{"key":"value"}' \
  --profile formalizese-new --region sa-east-1

# Actualizar un secret
aws secretsmanager put-secret-value \
  --secret-id "formalizese/env/nombre-secret" \
  --secret-string '{"key":"nuevo-value"}' \
  --profile formalizese-new --region sa-east-1
```

---

## SSM Parameter Store

```bash
# Listar parámetros del proyecto
aws ssm get-parameters-by-path \
  --path "/formalizese/" \
  --recursive \
  --query 'Parameters[*].[Name,Value]' \
  --output table \
  --profile formalizese-new --region sa-east-1

# Ver un parámetro
aws ssm get-parameter \
  --name "/formalizese/dev/gmail-user-email" \
  --profile formalizese-new --region sa-east-1

# Crear / actualizar un parámetro
aws ssm put-parameter \
  --name "/formalizese/dev/nombre-param" \
  --value "valor" \
  --type String \
  --overwrite \
  --profile formalizese-new --region sa-east-1

# Parámetro seguro (contraseñas)
aws ssm put-parameter \
  --name "/formalizese/dev/db-password" \
  --value "mi-password" \
  --type SecureString \
  --overwrite \
  --profile formalizese-new --region sa-east-1
```

---

## S3

```bash
# Listar buckets
aws s3 ls \
  --profile formalizese-new --region sa-east-1

# Listar contenido de un bucket
aws s3 ls s3://formalizese-invoices-dev-152406482061/ \
  --profile formalizese-new --region sa-east-1

# Listar con prefijo (carpeta)
aws s3 ls s3://formalizese-invoices-dev-152406482061/emails/ \
  --profile formalizese-new --region sa-east-1

# Descargar un archivo
aws s3 cp s3://formalizese-invoices-dev-152406482061/emails/2025-06/abc.zip ./abc.zip \
  --profile formalizese-new --region sa-east-1

# Subir un archivo
aws s3 cp ./archivo.zip s3://formalizese-invoices-dev-152406482061/manual/ \
  --profile formalizese-new --region sa-east-1

# Ver tamaño total de un bucket
aws s3 ls s3://formalizese-invoices-dev-152406482061/ \
  --recursive --human-readable --summarize \
  --profile formalizese-new --region sa-east-1
```

---

## SQS

```bash
# Listar colas
aws sqs list-queues \
  --queue-name-prefix formalizese \
  --profile formalizese-new --region sa-east-1

# Ver atributos de una cola (mensajes pendientes, en vuelo, en DLQ)
aws sqs get-queue-attributes \
  --queue-url https://sqs.sa-east-1.amazonaws.com/152406482061/formalizese-invoice-processing-dev \
  --attribute-names All \
  --profile formalizese-new --region sa-east-1

# Ver cuántos mensajes hay en la DLQ
aws sqs get-queue-attributes \
  --queue-url https://sqs.sa-east-1.amazonaws.com/152406482061/formalizese-invoice-processing-dlq-dev \
  --attribute-names ApproximateNumberOfMessages \
  --profile formalizese-new --region sa-east-1

# Enviar mensaje de prueba a una cola
aws sqs send-message \
  --queue-url https://sqs.sa-east-1.amazonaws.com/152406482061/formalizese-invoice-processing-dev \
  --message-body '{"source":"manual","test":true}' \
  --profile formalizese-new --region sa-east-1

# Purgar todos los mensajes de una cola (¡cuidado!)
aws sqs purge-queue \
  --queue-url https://sqs.sa-east-1.amazonaws.com/152406482061/formalizese-invoice-processing-dlq-dev \
  --profile formalizese-new --region sa-east-1
```

---

## CloudFormation / SAM Stack

```bash
# Ver estado del stack
aws cloudformation describe-stacks \
  --stack-name formalizese-hub \
  --query 'Stacks[0].StackStatus' \
  --profile formalizese-new --region sa-east-1

# Ver outputs del stack (URLs, ARNs)
aws cloudformation describe-stacks \
  --stack-name formalizese-hub \
  --query 'Stacks[0].Outputs' \
  --output table \
  --profile formalizese-new --region sa-east-1

# Ver eventos recientes del stack (útil para debuggear deploys fallidos)
aws cloudformation describe-stack-events \
  --stack-name formalizese-hub \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED` || ResourceStatus==`UPDATE_FAILED`].[LogicalResourceId,ResourceStatusReason]' \
  --output table \
  --profile formalizese-new --region sa-east-1
```

---

## RDS

```bash
# Listar instancias RDS
aws rds describe-db-instances \
  --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,Endpoint.Address]' \
  --output table \
  --profile formalizese-new --region sa-east-1

# Ver endpoint de la base de datos
aws rds describe-db-instances \
  --db-instance-identifier formalizese-db-dev \
  --query 'DBInstances[0].Endpoint' \
  --profile formalizese-new --region sa-east-1
```

---

## PostgreSQL (conexión directa)

```bash
# Obtener el host de la BD desde AWS
aws rds describe-db-instances \
  --db-instance-identifier formalizese-db-dev \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text \
  --profile formalizese-new --region sa-east-1

# Listar todas las instancias RDS con su host
aws rds describe-db-instances \
  --query 'DBInstances[*].[DBInstanceIdentifier,Endpoint.Address]' \
  --output table \
  --profile formalizese-new --region sa-east-1

# Conectarse a la BD
psql -h formalizese-db-dev.crm4ysgme3wx.sa-east-1.rds.amazonaws.com \
     -p 5432 -U postgres -d formalizese
```

### Consultas útiles una vez conectado

```sql
-- Listar clientes con su NIT y email de facturas
SELECT id, nombre, nit, email_facturas
FROM clientes
WHERE deleted_at IS NULL
LIMIT 10;

-- Actualizar email_facturas de un cliente (para el alias Gmail)
UPDATE clientes
SET email_facturas = 'facturas+NIT@formalizese.com'
WHERE nit = 'NIT_DEL_CLIENTE';

-- Ver emails procesados por el poller
SELECT message_id, cliente_id, email_from, subject, status, created_at
FROM emails_procesados
ORDER BY created_at DESC
LIMIT 20;

-- Ver emails pendientes de procesar
SELECT * FROM emails_procesados WHERE status = 'pending';
```

---

## Deploy de Lambdas grandes (>70MB) vía S3

Las lambdas `formalizese-invoice-processing` y `formalizese-dian-processing` superan el límite de 70MB de subida directa. Se deben desplegar vía S3.

```bash
# ── invoice-processing ────────────────────────────────────────────

# 1. Build
cd /home/josedariopaezperez/Documentos/formalizese-all/formalizesehub-invoice-processing
npm run build

# 2. Subir ZIP a S3
aws s3 cp dist.zip s3://formalizese-invoices-dev-152406482061/deploy/formalizesehub-invoice-processing.zip \
  --profile formalizese-new --region sa-east-1

# 3. Actualizar la lambda desde S3
aws lambda update-function-code \
  --function-name formalizese-invoice-processing-dev \
  --s3-bucket formalizese-invoices-dev-152406482061 \
  --s3-key deploy/formalizesehub-invoice-processing.zip \
  --profile formalizese-new --region sa-east-1

# ── dian-processing ───────────────────────────────────────────────

# 1. Build
cd /home/josedariopaezperez/Documentos/formalizese-all/formalizesehub-dian-download
npm run build

# 2. Subir ZIP a S3
aws s3 cp dist.zip s3://formalizese-invoices-dev-152406482061/deploy/formalizesehub-dian-download.zip \
  --profile formalizese-new --region sa-east-1

# 3. Actualizar la lambda desde S3
aws lambda update-function-code \
  --function-name formalizese-dian-processing-dev \
  --s3-bucket formalizese-invoices-dev-152406482061 \
  --s3-key deploy/formalizesehub-dian-download.zip \
  --profile formalizese-new --region sa-east-1

# ── Verificar que el código se actualizó (revisar LastModified) ───

aws lambda get-function \
  --function-name formalizese-invoice-processing-dev \
  --query 'Configuration.[LastModified,CodeSize]' \
  --output table \
  --profile formalizese-new --region sa-east-1
```

---

## Reprocesar emails — limpiar datos duplicados

### Conectarse a la BD

```bash
psql -h formalizese-db-dev.crm4ysgme3wx.sa-east-1.rds.amazonaws.com \
     -p 5432 -U postgres -d formalizese
```

### Eliminar factura duplicada por CUFE

```sql
-- 1. Buscar la factura por CUFE
SELECT id, cufe, numero_factura, fecha_emision, proveedor_id
FROM facturas
WHERE cufe = '3bddbfea50aff3eadf262725eb14c918186aee92ac3c660a350f220e1867cb9dc176075e2a509b2384ac9cf751fba1e6';

-- 2. Eliminar impuestos y productos asociados (respetar FK)
DELETE FROM factura_productos
WHERE factura_id = (
    SELECT id FROM facturas
    WHERE cufe = '3bddbfea50aff3eadf262725eb14c918186aee92ac3c660a350f220e1867cb9dc176075e2a509b2384ac9cf751fba1e6'
);

DELETE FROM factura_impuestos
WHERE factura_id = (
    SELECT id FROM facturas
    WHERE cufe = '3bddbfea50aff3eadf262725eb14c918186aee92ac3c660a350f220e1867cb9dc176075e2a509b2384ac9cf751fba1e6'
);

-- 3. Eliminar redistribuciones si existen
DELETE FROM redistribucion_contable
WHERE factura_id = (
    SELECT id FROM facturas
    WHERE cufe = '3bddbfea50aff3eadf262725eb14c918186aee92ac3c660a350f220e1867cb9dc176075e2a509b2384ac9cf751fba1e6'
);

-- 4. Eliminar la factura
DELETE FROM facturas
WHERE cufe = '3bddbfea50aff3eadf262725eb14c918186aee92ac3c660a350f220e1867cb9dc176075e2a509b2384ac9cf751fba1e6';

-- 5. Eliminar el registro del email procesado para que el poller lo vuelva a tomar
DELETE FROM emails_procesados
WHERE message_id = '19ef676ed46d3df0';
```

### Flujo completo de reproceso

```bash
# 1. Marcar el correo como no leído en Gmail (manual)

# 2. Limpiar BD (queries de arriba)

# 3. Invocar el poller
aws lambda invoke \
  --function-name formalizese-email-invoice-poller-dev \
  --payload '{}' \
  --cli-binary-format raw-in-base64-out \
  response.json \
  --profile formalizese-new --region sa-east-1 && cat response.json

# 4. Ver logs del procesamiento
aws logs tail /aws/lambda/formalizese-invoice-processing-dev \
  --since 3m \
  --format short \
  --profile formalizese-new --region sa-east-1
```
