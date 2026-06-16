#!/bin/bash
# =====================================================
# Deploy consolidado - FormalizeSE Hub
# Uso: ./scripts/deploy.sh [dev|staging|prod]
# =====================================================

set -e

ENV="${1:-dev}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"
ROOT_DIR="$(dirname "$INFRA_DIR")"

if [[ "$ENV" != "dev" && "$ENV" != "staging" && "$ENV" != "prod" && "$ENV" != "new" ]]; then
    echo "❌ Entorno inválido: $ENV"
    echo "   Uso: ./scripts/deploy.sh [dev|staging|prod|new]"
    exit 1
fi

if ! command -v sam &> /dev/null; then
    echo "❌ AWS SAM CLI no encontrado."
    echo "   https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html"
    exit 1
fi

echo "=================================================="
echo " FormalizeSE Hub — Deploy [$ENV]"
echo "=================================================="
echo ""

# ── Repos con npm workspaces (build:all) ──────────────
WORKSPACE_REPOS=(
    "formalizesehub-auth"
    "formalizesehub-cliente"
    "formalizesehub-cuentas-contables"
    "formalizesehub-parametrizacion"
    "formalizesehub-proveedores"
    "formalizesehub-retenciones"
    "formalizesehub-descargas"
    "formalizesehub-redistribuciones"
    "formalizesehub-codigo-impuestos"
    "formalizesehub-comprobante-siigo"
)

# ── Repos con build propio ────────────────────────────
STANDALONE_REPOS=(
    "formalizesehub-dian-download"
    "formalizesehub-invoice-processing"
    "formalizesehub-dian-download-proxy"
)

echo "� Instalando dependencias..."
echo ""

for repo in "${WORKSPACE_REPOS[@]}" "${STANDALONE_REPOS[@]}"; do
    REPO_PATH="$ROOT_DIR/$repo"
    if [ -d "$REPO_PATH" ]; then
        echo "  → $repo"
        (cd "$REPO_PATH" && npm ci --silent 2>&1) || { echo "  ❌ npm ci falló en $repo"; exit 1; }
    fi
done

echo ""
echo "�🔨 Building lambdas..."
echo ""

for repo in "${WORKSPACE_REPOS[@]}"; do
    REPO_PATH="$ROOT_DIR/$repo"
    if [ -d "$REPO_PATH" ]; then
        echo "  → $repo"
        (cd "$REPO_PATH" && npm run build:all 2>&1) || { echo "  ❌ Build falló en $repo"; exit 1; }
    else
        echo "  ⚠️  No encontrado: $repo"
    fi
done

for repo in "${STANDALONE_REPOS[@]}"; do
    REPO_PATH="$ROOT_DIR/$repo"
    if [ -d "$REPO_PATH" ]; then
        echo "  → $repo"
        (cd "$REPO_PATH" && npm run build 2>&1) || { echo "  ❌ Build falló en $repo"; exit 1; }
    else
        echo "  ⚠️  No encontrado: $repo"
    fi
done

# ── Lambdas grandes (>50MB) → deploy via S3 ──────────
AWS_PROFILE="${AWS_PROFILE:-formalizese-new}"
AWS_REGION="${AWS_REGION:-sa-east-1}"
DEPLOY_BUCKET="formalizese-invoices-${ENV}-152406482061"

# Mapa: directorio-repo → nombre-lambda
declare -A LARGE_LAMBDAS=(
    ["formalizesehub-dian-download"]="formalizese-dian-processing-${ENV}"
    ["formalizesehub-invoice-processing"]="formalizese-invoice-processing-${ENV}"
)

echo ""
echo "☁️  Actualizando lambdas grandes via S3..."
echo ""

for repo in "${!LARGE_LAMBDAS[@]}"; do
    REPO_PATH="$ROOT_DIR/$repo"
    LAMBDA_NAME="${LARGE_LAMBDAS[$repo]}"
    ZIP_FILE="$REPO_PATH/dist.zip"

    if [ ! -f "$ZIP_FILE" ]; then
        echo "  ⚠️  $repo: dist.zip no encontrado, saltando"
        continue
    fi

    S3_KEY="deploy/${repo}.zip"

    # Comparar hash local vs S3 para detectar cambios
    LOCAL_HASH=$(md5 -q "$ZIP_FILE" 2>/dev/null || md5sum "$ZIP_FILE" | awk '{print $1}')
    REMOTE_ETAG=$(aws s3api head-object --bucket "$DEPLOY_BUCKET" --key "$S3_KEY" \
        --profile "$AWS_PROFILE" --region "$AWS_REGION" \
        --query 'ETag' --output text 2>/dev/null | tr -d '"')

    if [ "$LOCAL_HASH" = "$REMOTE_ETAG" ]; then
        echo "  → $repo: sin cambios, saltando"
        continue
    fi

    echo "  → $repo → s3://$DEPLOY_BUCKET/$S3_KEY"
    aws s3 cp "$ZIP_FILE" "s3://$DEPLOY_BUCKET/$S3_KEY" \
        --profile "$AWS_PROFILE" --region "$AWS_REGION" 2>&1 \
        || { echo "  ❌ S3 upload falló para $repo"; exit 1; }

    echo "    Actualizando $LAMBDA_NAME..."
    aws lambda update-function-code \
        --function-name "$LAMBDA_NAME" \
        --s3-bucket "$DEPLOY_BUCKET" \
        --s3-key "$S3_KEY" \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION" > /dev/null 2>&1 \
        || { echo "  ❌ Lambda update falló para $LAMBDA_NAME"; exit 1; }

    echo "    ✅ $LAMBDA_NAME actualizada"
done

echo ""
echo "📦 SAM build..."
sam build \
  --config-file "$INFRA_DIR/samconfig.toml" \
  --template-file "$INFRA_DIR/template.yaml" \
  --build-dir "$INFRA_DIR/.aws-sam/build"

echo ""
echo "🚀 SAM deploy [$ENV]..."
sam deploy \
  --config-file "$INFRA_DIR/samconfig.toml" \
  --config-env "$ENV" \
  --template-file "$INFRA_DIR/template.yaml"

echo ""
echo "=================================================="
echo "✅ Deploy completado [$ENV]"
echo "=================================================="
