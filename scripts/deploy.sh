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

if [[ "$ENV" != "dev" && "$ENV" != "staging" && "$ENV" != "prod" ]]; then
    echo "❌ Entorno inválido: $ENV"
    echo "   Uso: ./scripts/deploy.sh [dev|staging|prod]"
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
    "formalizesehub-cliente"
    "formalizesehub-cuentas-contables"
    "formalizesehub-parametrizacion"
    "formalizesehub-proveedores"
)

# ── Repos con build propio ────────────────────────────
STANDALONE_REPOS=(
    "formalizesehub-dian-download"
    "formalizesehub-invoice-processing"
)

echo "🔨 Building lambdas..."
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
  --config-env "$ENV"

echo ""
echo "=================================================="
echo "✅ Deploy completado [$ENV]"
echo "=================================================="
