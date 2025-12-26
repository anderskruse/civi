#!/bin/bash
set -e

echo "📤 Pushing to Scaleway Container Registry..."

# Load environment
if [ -f .env.scaleway ]; then
    source .env.scaleway
else
    echo "Error: .env.scaleway file not found"
    exit 1
fi

# Check required variables
if [ -z "$SCW_SECRET_KEY" ]; then
    echo "Error: SCW_SECRET_KEY is not set"
    exit 1
fi

if [ -z "$SCW_REGISTRY_ENDPOINT" ]; then
    echo "Error: SCW_REGISTRY_ENDPOINT is not set"
    exit 1
fi

# Login to registry
echo "$SCW_SECRET_KEY" | docker login \
  $SCW_REGISTRY_ENDPOINT \
  -u nologin \
  --password-stdin

# Tag image
docker tag openwebui-scaleway:latest \
  $SCW_REGISTRY_ENDPOINT/openwebui-scaleway:latest

# Also tag with version
VERSION=$(date +%Y%m%d-%H%M%S)
docker tag openwebui-scaleway:latest \
  $SCW_REGISTRY_ENDPOINT/openwebui-scaleway:$VERSION

# Push both tags
docker push $SCW_REGISTRY_ENDPOINT/openwebui-scaleway:latest
docker push $SCW_REGISTRY_ENDPOINT/openwebui-scaleway:$VERSION

echo "✅ Pushed version: $VERSION"
echo "✅ Pushed tag: latest"
