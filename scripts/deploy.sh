#!/bin/bash
set -e

echo "🚀 Deploying to Scaleway Serverless Containers..."

# Load environment
if [ -f .env.scaleway ]; then
    source .env.scaleway
else
    echo "Error: .env.scaleway file not found"
    exit 1
fi

# Check required variables
if [ -z "$SCW_SECRET_KEY" ] || [ -z "$WEBUI_SECRET_KEY" ]; then
    echo "Error: SCW_SECRET_KEY or WEBUI_SECRET_KEY is not set"
    exit 1
fi

# Build database URL
DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}"

# Check if container already exists
EXISTING_CONTAINER=$(scw container container list namespace-id=$SCW_CONTAINER_NAMESPACE region=fr-par -o json | jq -r '.[] | select(.name=="open-webui") | .id')

if [ -n "$EXISTING_CONTAINER" ]; then
    echo "Container already exists with ID: $EXISTING_CONTAINER"
    echo "Updating existing container..."

    scw container container update \
      container-id=$EXISTING_CONTAINER \
      registry-image="$SCW_REGISTRY_ENDPOINT/openwebui-scaleway:latest" \
      region=fr-par

    CONTAINER_ID=$EXISTING_CONTAINER
else
    echo "Creating new container..."

    # Create container
    CONTAINER_ID=$(scw container container create \
      name=open-webui \
      namespace-id=$SCW_CONTAINER_NAMESPACE \
      registry-image="$SCW_REGISTRY_ENDPOINT/openwebui-scaleway:latest" \
      environment-variables.DATABASE_URL="$DATABASE_URL" \
      environment-variables.VECTOR_DB="pgvector" \
      environment-variables.SCALEWAY_API_KEY="$SCW_SECRET_KEY" \
      environment-variables.SCALEWAY_API_BASE="https://api.scaleway.ai/v1" \
      environment-variables.SCALEWAY_PROJECT_ID="$SCW_DEFAULT_PROJECT_ID" \
      environment-variables.OPENAI_API_BASE_URL="https://api.scaleway.ai/v1" \
      environment-variables.OPENAI_API_KEY="$SCW_SECRET_KEY" \
      environment-variables.WEBUI_SECRET_KEY="$WEBUI_SECRET_KEY" \
      environment-variables.WEBUI_AUTH="True" \
      environment-variables.ENABLE_SIGNUP="True" \
      region=fr-par \
      port=8080 \
      cpu-limit=2000 \
      memory-limit=4096 \
      min-scale=1 \
      max-scale=5 \
      timeout=300s \
      -o json | jq -r '.id')
fi

echo "✅ Container configured! Deploying..."
echo "📝 Container ID: $CONTAINER_ID"

# Deploy
scw container container deploy container-id=$CONTAINER_ID region=fr-par

echo "✅ Deployment initiated!"
echo "⏳ Deployment will take 5-10 minutes..."
echo "🔗 Check status: scw container container get container-id=$CONTAINER_ID region=fr-par"
