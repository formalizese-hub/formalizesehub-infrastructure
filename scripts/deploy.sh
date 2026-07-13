#!/bin/bash
# =====================================================
# Deploy consolidado - FormalizeSE Hub
# Uso: ./scripts/deploy.sh [dev|staging|prod] [--force]
# =====================================================

set -e

ENV="${1:-dev}"
FORCE=false
[[ "$2" == "--force" ]] && FORCE=true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"
ROOT_DIR="$(dirname "$INFRA_DIR")"
STATE_DIR="$INFRA_DIR/.deploy-state"

if [[ "$ENV" != "dev" && "$ENV" != "staging" && "$ENV" != "prod" && "$ENV" != "new" ]]; then
    echo "❌ Entorno inválido: $ENV"
    echo "   Uso: ./scripts/deploy.sh [dev|staging|prod|new] [--force]"
    exit 1
fi

if ! command -v sam &> /dev/null; then
    echo "❌ AWS SAM CLI no encontrado."
    echo "   https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html"
    exit 1
fi

# ── Estado de deploy (git hash markers) ──────────────
mkdir -p "$STATE_DIR"

# Retorna 0 (true) si el repo tiene cambios desde el último deploy
# Uso: if has_changes "repo-name"; then ...
has_changes() {
    local repo="$1"
    local repo_path="$ROOT_DIR/$repo"
    local marker_file="$STATE_DIR/${repo}.${ENV}.last-deploy"

    if [ "$FORCE" = true ]; then
        return 0
    fi

    if [ ! -d "$repo_path/.git" ]; then
        # No es repo git, siempre build
        return 0
    fi

    local current_hash
    current_hash=$(git -C "$repo_path" rev-parse HEAD 2>/dev/null)

    if [ ! -f "$marker_file" ]; then
        # Primer deploy, siempre build
        return 0
    fi

    local last_hash
    last_hash=$(cat "$marker_file")

    if [ "$current_hash" != "$last_hash" ]; then
        return 0
    fi

    # Sin cambios
    return 1
}

# Marca un repo como deployado exitosamente
mark_deployed() {
    local repo="$1"
    local repo_path="$ROOT_DIR/$repo"
    local marker_file="$STATE_DIR/${repo}.${ENV}.last-deploy"

    if [ -d "$repo_path/.git" ]; then
        git -C "$repo_path" rev-parse HEAD > "$marker_file"
    fi
}

echo "=================================================="
echo " FormalizeSE Hub — Deploy [$ENV]"
if [ "$FORCE" = true ]; then
    echo " ⚡ Modo FORCE: se ignoran markers de estado"
fi
echo "=================================================="
echo ""

# ── Repos con npm workspaces (build:all) ──────────────
WORKSPACE_REPOS=(
    "formalizesehub-auth"
    "formalizesehub-empresa"
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
    "formalizesehub-invoice-processing"
    "formalizesehub-email-poller"
)

# ── Verificar si faltan artifacts (dist.zip) ──────────
# Un workspace repo necesita build si le falta algún dist.zip en services/
artifacts_missing() {
    local repo="$1"
    local repo_path="$ROOT_DIR/$repo"
    local services_dir="$repo_path/services"

    if [ ! -d "$services_dir" ]; then
        # Standalone repo: verificar dist.zip en raíz
        if [ ! -f "$repo_path/dist.zip" ]; then
            return 0
        fi
        return 1
    fi

    # Workspace repo: verificar que cada servicio tenga dist.zip
    for svc_dir in "$services_dir"/*/; do
        if [ -f "$svc_dir/build.mjs" ] || [ -f "$svc_dir/package.json" ]; then
            if [ ! -f "$svc_dir/dist.zip" ]; then
                return 0
            fi
        fi
    done
    return 1
}

# ── Filtrar repos que necesitan build ─────────────────
CHANGED_WORKSPACE=()
CHANGED_STANDALONE=()
SKIPPED_COUNT=0

for repo in "${WORKSPACE_REPOS[@]}"; do
    if [ ! -d "$ROOT_DIR/$repo" ]; then
        ((SKIPPED_COUNT++)) || true
        continue
    fi
    if has_changes "$repo" || artifacts_missing "$repo"; then
        CHANGED_WORKSPACE+=("$repo")
    else
        ((SKIPPED_COUNT++)) || true
    fi
done

for repo in "${STANDALONE_REPOS[@]}"; do
    if [ ! -d "$ROOT_DIR/$repo" ]; then
        ((SKIPPED_COUNT++)) || true
        continue
    fi
    if has_changes "$repo" || artifacts_missing "$repo"; then
        CHANGED_STANDALONE+=("$repo")
    else
        ((SKIPPED_COUNT++)) || true
    fi
done

TOTAL_CHANGED=$(( ${#CHANGED_WORKSPACE[@]} + ${#CHANGED_STANDALONE[@]} ))

if [ "$TOTAL_CHANGED" -eq 0 ]; then
    echo "✅ Ningún repo tiene cambios desde el último deploy."
    echo "   Usa --force para forzar rebuild completo."
    echo ""
    echo "Continuando con SAM deploy (template/config pueden haber cambiado)..."
    echo ""
else
    echo "📊 Resumen de cambios:"
    echo "   → $TOTAL_CHANGED repo(s) con cambios o artifacts faltantes"
    echo "   → $SKIPPED_COUNT repo(s) sin cambios (saltados)"
    echo ""

    # ── npm ci solo en repos con cambios ──────────────
    echo "📦 Instalando dependencias (solo repos con cambios)..."
    echo ""

    for repo in "${CHANGED_WORKSPACE[@]}" "${CHANGED_STANDALONE[@]}"; do
        REPO_PATH="$ROOT_DIR/$repo"
        echo "  → $repo"
        (cd "$REPO_PATH" && npm ci --silent 2>&1) || { echo "  ❌ npm ci falló en $repo"; exit 1; }
    done

    echo ""
    echo "🔨 Building lambdas (solo repos con cambios)..."
    echo ""

    for repo in "${CHANGED_WORKSPACE[@]}"; do
        REPO_PATH="$ROOT_DIR/$repo"
        echo "  → $repo"
        (cd "$REPO_PATH" && npm run build:all 2>&1) || { echo "  ❌ Build falló en $repo"; exit 1; }
    done

    for repo in "${CHANGED_STANDALONE[@]}"; do
        REPO_PATH="$ROOT_DIR/$repo"
        echo "  → $repo"
        (cd "$REPO_PATH" && npm run build 2>&1) || { echo "  ❌ Build falló en $repo"; exit 1; }
    done
fi

# ── Lambdas grandes (>50MB) → deploy via S3 ──────────
AWS_PROFILE="${AWS_PROFILE:-formalizese-new}"
AWS_REGION="${AWS_REGION:-sa-east-1}"
DEPLOY_BUCKET="formalizese-invoices-${ENV}-152406482061"

# Mapa: directorio-repo → nombre-lambda (arrays paralelos para compatibilidad bash 3.x)
LARGE_LAMBDA_REPOS=(
    "formalizesehub-invoice-processing"
)
LARGE_LAMBDA_NAMES=(
    "formalizese-invoice-processing-${ENV}"
)

echo ""
echo "☁️  Actualizando lambdas grandes via S3..."
echo ""

LARGE_DEPLOYED=false

for i in $(seq 0 $((${#LARGE_LAMBDA_REPOS[@]} - 1))); do
    repo="${LARGE_LAMBDA_REPOS[$i]}"
    LAMBDA_NAME="${LARGE_LAMBDA_NAMES[$i]}"
    REPO_PATH="$ROOT_DIR/$repo"
    ZIP_FILE="$REPO_PATH/dist.zip"

    # Skip si no tiene cambios (y no se hizo build)
    if ! has_changes "$repo" && [ ! -f "$ZIP_FILE" ]; then
        echo "  → $repo: sin cambios, saltando"
        continue
    fi

    if [ ! -f "$ZIP_FILE" ]; then
        echo "  ⚠️  $repo: dist.zip no encontrado, saltando"
        continue
    fi

    S3_KEY="deploy/${repo}.zip"

    # Comparar hash local vs S3 para detectar cambios binarios
    LOCAL_HASH=$(md5 -q "$ZIP_FILE" 2>/dev/null || md5sum "$ZIP_FILE" | awk '{print $1}')
    REMOTE_ETAG=$(aws s3api head-object --bucket "$DEPLOY_BUCKET" --key "$S3_KEY" \
        --profile "$AWS_PROFILE" --region "$AWS_REGION" \
        --query 'ETag' --output text 2>/dev/null | tr -d '"')

    if [ "$LOCAL_HASH" = "$REMOTE_ETAG" ]; then
        echo "  → $repo: zip idéntico en S3, saltando"
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
    LARGE_DEPLOYED=true
    rm -f "$ZIP_FILE"
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

# ── Marcar repos como deployados ──────────────────────
echo ""
echo "📝 Actualizando markers de estado..."

for repo in "${CHANGED_WORKSPACE[@]}" "${CHANGED_STANDALONE[@]}"; do
    mark_deployed "$repo"
done

echo ""
echo "=================================================="
echo "✅ Deploy completado [$ENV]"
if [ "$TOTAL_CHANGED" -gt 0 ]; then
    echo "   Repos actualizados: ${CHANGED_WORKSPACE[*]} ${CHANGED_STANDALONE[*]}"
fi
if [ "$SKIPPED_COUNT" -gt 0 ]; then
    echo "   Repos sin cambios (saltados): $SKIPPED_COUNT"
fi
echo "=================================================="
