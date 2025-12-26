#!/bin/bash
set -e

echo "🔨 Building Open WebUI for Scaleway..."

# Load environment
if [ -f .env.scaleway ]; then
    source .env.scaleway
else
    echo "Error: .env.scaleway file not found"
    exit 1
fi

# Build image
docker build \
  -f Dockerfile.scaleway \
  -t openwebui-scaleway:latest \
  --platform linux/amd64 \
  .

echo "✅ Build complete!"
