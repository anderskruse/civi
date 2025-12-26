# Open WebUI Scaleway Deployment Plan

## Project Overview

Deploy a forked Open WebUI instance on Scaleway with managed services, integrated with Scaleway Generative AI endpoints and custom RAG capabilities.

**Strategy:** Git Fork Sync with Custom Branch  
**Timeline:** 2-3 days for initial setup  
**Maintenance:** Weekly/monthly update checks

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Phase 1: Repository Setup](#phase-1-repository-setup)
3. [Phase 2: Scaleway Infrastructure](#phase-2-scaleway-infrastructure)
4. [Phase 3: Custom Modifications](#phase-3-custom-modifications)
5. [Phase 4: Build & Deploy](#phase-4-build--deploy)
6. [Phase 5: Testing & Validation](#phase-5-testing--validation)
7. [Phase 6: Maintenance & Updates](#phase-6-maintenance--updates)
8. [Troubleshooting](#troubleshooting)
9. [Rollback Procedures](#rollback-procedures)

---

## 1. Prerequisites

### 1.1 Local Development Environment

- [ ] **Git** installed and configured
- [ ] **Docker Desktop** installed (for local testing)
- [ ] **Node.js** 22.x or higher
- [ ] **Python** 3.11 or higher
- [ ] Code editor (VS Code recommended)

### 1.2 Scaleway Account Setup

- [ ] Scaleway account created
- [ ] Payment method added and KYC completed
- [ ] API keys generated (Access Key + Secret Key)
- [ ] Project created for this deployment

### 1.3 Install Scaleway CLI

```bash
# macOS
brew install scw

# Linux
curl -s https://raw.githubusercontent.com/scaleway/scaleway-cli/master/scripts/get.sh | sh

# Initialize
scw init
# Enter your Access Key, Secret Key, and default region (fr-par)
```

### 1.4 Environment Variables Setup

Create `.env.local` for development:

```bash
# Scaleway
export SCW_ACCESS_KEY="your-access-key"
export SCW_SECRET_KEY="your-secret-key"
export SCW_DEFAULT_PROJECT_ID="your-project-id"
export SCW_DEFAULT_REGION="fr-par"

# Database (will be created later)
export DB_PASSWORD="generate-strong-password-here"

# Application
export WEBUI_SECRET_KEY="generate-jwt-secret-here"
```

Generate secrets:

```bash
# Generate strong passwords
openssl rand -base64 32  # For DB_PASSWORD
openssl rand -base64 32  # For WEBUI_SECRET_KEY
```

---

## Phase 1: Repository Setup

### 1.1 Fork Open WebUI Repository

- [ ] Navigate to https://github.com/open-webui/open-webui
- [ ] Click "Fork" button
- [ ] Select your GitHub account
- [ ] Wait for fork to complete

### 1.2 Clone Your Fork

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/open-webui.git
cd open-webui

# Add upstream remote
git remote add upstream https://github.com/open-webui/open-webui.git

# Verify remotes
git remote -v
```

### 1.3 Create Custom Branch

```bash
# Create and switch to custom branch
git checkout -b custom-scaleway

# Tag the starting point
git tag scaleway-base-v1
```

### 1.4 Project Documentation

Create project documentation:

```bash
# Create docs directory
mkdir -p docs/scaleway

# Create initial documentation
touch docs/scaleway/README.md
touch docs/scaleway/DEPLOYMENT.md
touch docs/scaleway/UPDATES.md
```

Add to `docs/scaleway/README.md`:

```markdown
# Scaleway Deployment Documentation

## Overview
Custom Open WebUI deployment on Scaleway infrastructure.

## Features
- Scaleway Generative AI integration
- Managed PostgreSQL with pgvector
- Custom RAG pipeline
- Serverless Containers deployment

## Architecture
[Add architecture diagram here]

## Contacts
- Maintainer: [Your Name]
- Repository: [Your Fork URL]
```

---

## Phase 2: Scaleway Infrastructure

### 2.1 Create Container Registry Namespace

```bash
# Create namespace
scw registry namespace create \
  name=openwebui-registry \
  region=fr-par

# Save the namespace ID
export SCW_REGISTRY_NAMESPACE="your-namespace-id"

# Add to .env.local
echo "export SCW_REGISTRY_NAMESPACE='$SCW_REGISTRY_NAMESPACE'" >> .env.local
```

### 2.2 Create Managed PostgreSQL Database

```bash
# Create database instance
scw rdb instance create \
  name=openwebui-db \
  node-type=db-dev-s \
  engine=PostgreSQL-17 \
  is-ha-cluster=false \
  user-name=openwebui \
  password="$DB_PASSWORD" \
  region=fr-par

# Wait for provisioning (takes 5-10 minutes)
scw rdb instance wait openwebui-db region=fr-par

# Get database endpoint
scw rdb instance get openwebui-db region=fr-par

# Note the endpoint (host:port)
# Example: 51.159.123.45:5432
export DB_HOST="your-db-host"
export DB_PORT="5432"
```

### 2.3 Enable pgvector Extension

```bash
# Connect to database
psql -h $DB_HOST -p $DB_PORT -U openwebui -d rdb

# In psql prompt:
CREATE EXTENSION IF NOT EXISTS vector;

# Verify
\dx

# Exit
\q
```

### 2.4 Create Serverless Container Namespace

```bash
# Create namespace for containers
scw container namespace create \
  name=openwebui-ns \
  region=fr-par

# Save namespace ID
export SCW_CONTAINER_NAMESPACE="your-container-namespace-id"
echo "export SCW_CONTAINER_NAMESPACE='$SCW_CONTAINER_NAMESPACE'" >> .env.local
```

### 2.5 Infrastructure Checklist

- [ ] Container Registry namespace created
- [ ] PostgreSQL database provisioned
- [ ] pgvector extension enabled
- [ ] Container namespace created
- [ ] All IDs saved in `.env.local`

---

## Phase 3: Custom Modifications

### 3.1 Create Custom Configuration

```bash
# Create custom config directory
mkdir -p backend/open_webui/config/custom
```

Create `backend/open_webui/config/custom/__init__.py`:

```python
"""Custom configurations for Scaleway deployment"""
```

Create `backend/open_webui/config/custom/scaleway.py`:

```python
"""
Scaleway Generative AI Configuration
"""
import os
from typing import List, Optional

class ScalewayConfig:
    """Configuration for Scaleway Generative AI endpoints"""
    
    def __init__(self):
        self.api_base = os.getenv(
            "SCALEWAY_API_BASE",
            "https://api.scaleway.ai/v1"
        )
        self.api_key = os.getenv("SCALEWAY_API_KEY", os.getenv("SCW_SECRET_KEY", ""))
        self.project_id = os.getenv("SCALEWAY_PROJECT_ID", "")
        
        # Use project-specific endpoint if provided
        if self.project_id:
            self.api_base = f"https://api.scaleway.ai/{self.project_id}/v1"
    
    @property
    def available_models(self) -> List[str]:
        """List of Scaleway Gen AI models"""
        return [
            "llama-3.3-70b-instruct",
            "llama-3.1-8b-instruct",
            "qwen2.5-coder-32b-instruct",
            "mistral-small-3.1-24b-instruct",
            "pixtral-12b-2409",
        ]
    
    @property
    def default_model(self) -> str:
        return os.getenv("SCALEWAY_DEFAULT_MODEL", "llama-3.3-70b-instruct")
    
    @property
    def embedding_model(self) -> str:
        return os.getenv(
            "SCALEWAY_EMBEDDING_MODEL",
            "sentence-transformers-multilingual-e5-base"
        )
    
    def get_connection_info(self) -> dict:
        """Get connection information for Scaleway Gen AI"""
        return {
            "api_base": self.api_base,
            "api_key": self.api_key,
            "default_model": self.default_model,
            "embedding_model": self.embedding_model,
        }

# Global instance
scaleway_config = ScalewayConfig()
```

### 3.2 Modify Environment Configuration

Edit `backend/open_webui/env.py`:

Add near the top after other imports:

```python
# Scaleway integration
try:
    from open_webui.config.custom.scaleway import scaleway_config
    SCALEWAY_ENABLED = True
except ImportError:
    SCALEWAY_ENABLED = False
    scaleway_config = None
```

Find the `OPENAI_API_BASE_URLS` section and modify:

```python
# If Scaleway is enabled, use it as default
if SCALEWAY_ENABLED and scaleway_config and scaleway_config.api_key:
    OPENAI_API_BASE_URLS = [scaleway_config.api_base]
    OPENAI_API_KEYS = [scaleway_config.api_key]
else:
    OPENAI_API_BASE_URLS = [
        url.strip() if url else "https://api.openai.com/v1"
        for url in os.environ.get("OPENAI_API_BASE_URLS", "").split(";")
    ]
    OPENAI_API_KEYS = [
        key.strip() if key else ""
        for key in os.environ.get("OPENAI_API_KEYS", "").split(";")
    ]
```

### 3.3 Create Custom Dockerfile

Create `Dockerfile.scaleway`:

```dockerfile
# Start from official Open WebUI base
FROM ghcr.io/open-webui/open-webui:main

# Metadata
LABEL maintainer="your-email@example.com"
LABEL description="Open WebUI with Scaleway Gen AI integration"
LABEL version="1.0.0"

# Copy custom configuration
COPY backend/open_webui/config/custom/ /app/backend/open_webui/config/custom/

# Install additional dependencies for advanced RAG (optional)
RUN pip install --no-cache-dir \
    langchain==0.1.0 \
    langchain-openai==0.0.5 \
    psycopg2-binary==2.9.9

# Set default environment variables for Scaleway
ENV SCALEWAY_API_BASE=https://api.scaleway.ai/v1 \
    OPENAI_API_BASE_URL=https://api.scaleway.ai/v1 \
    VECTOR_DB=pgvector \
    ENABLE_RAG_WEB_LOADER_SSL_VERIFICATION=True

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Expose port
EXPOSE 8080

# Use default start command from base image
CMD ["/bin/bash", "/app/backend/start.sh"]
```

### 3.4 Create Docker Compose for Local Testing

Create `docker-compose.scaleway.yml`:

```yaml
version: '3.8'

services:
  postgres:
    image: pgvector/pgvector:pg17
    container_name: openwebui-postgres
    environment:
      POSTGRES_DB: openwebui
      POSTGRES_USER: openwebui
      POSTGRES_PASSWORD: ${DB_PASSWORD:-changeMe123}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U openwebui"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - openwebui-network

  openwebui:
    build:
      context: .
      dockerfile: Dockerfile.scaleway
    container_name: openwebui-app
    ports:
      - "3000:8080"
    environment:
      - DATABASE_URL=postgresql://openwebui:${DB_PASSWORD:-changeMe123}@postgres:5432/openwebui
      - VECTOR_DB=pgvector
      - SCALEWAY_API_KEY=${SCW_SECRET_KEY}
      - SCALEWAY_API_BASE=https://api.scaleway.ai/v1
      - SCALEWAY_PROJECT_ID=${SCW_DEFAULT_PROJECT_ID}
      - OPENAI_API_BASE_URL=https://api.scaleway.ai/v1
      - OPENAI_API_KEY=${SCW_SECRET_KEY}
      - WEBUI_SECRET_KEY=${WEBUI_SECRET_KEY}
      - WEBUI_AUTH=True
      - ENABLE_SIGNUP=True
    volumes:
      - openwebui_data:/app/backend/data
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - openwebui-network
    restart: unless-stopped

volumes:
  postgres_data:
  openwebui_data:

networks:
  openwebui-network:
    driver: bridge
```

### 3.5 Create Deployment Scripts

Create `scripts/build.sh`:

```bash
#!/bin/bash
set -e

echo "🔨 Building Open WebUI for Scaleway..."

# Load environment
source .env.local

# Build image
docker build \
  -f Dockerfile.scaleway \
  -t openwebui-scaleway:latest \
  --platform linux/amd64 \
  .

echo "✅ Build complete!"
```

Create `scripts/push.sh`:

```bash
#!/bin/bash
set -e

echo "📤 Pushing to Scaleway Container Registry..."

# Load environment
source .env.local

# Login to registry
echo "$SCW_SECRET_KEY" | docker login \
  rg.fr-par.scw.cloud/$SCW_REGISTRY_NAMESPACE \
  -u nologin \
  --password-stdin

# Tag image
docker tag openwebui-scaleway:latest \
  rg.fr-par.scw.cloud/$SCW_REGISTRY_NAMESPACE/openwebui-scaleway:latest

# Also tag with version
VERSION=$(date +%Y%m%d-%H%M%S)
docker tag openwebui-scaleway:latest \
  rg.fr-par.scw.cloud/$SCW_REGISTRY_NAMESPACE/openwebui-scaleway:$VERSION

# Push both tags
docker push rg.fr-par.scw.cloud/$SCW_REGISTRY_NAMESPACE/openwebui-scaleway:latest
docker push rg.fr-par.scw.cloud/$SCW_REGISTRY_NAMESPACE/openwebui-scaleway:$VERSION

echo "✅ Pushed version: $VERSION"
echo "✅ Pushed tag: latest"
```

Create `scripts/deploy.sh`:

```bash
#!/bin/bash
set -e

echo "🚀 Deploying to Scaleway Serverless Containers..."

# Load environment
source .env.local

# Build database URL
DATABASE_URL="postgresql://openwebui:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/rdb"

# Create or update container
scw container container create \
  name=open-webui \
  namespace-id=$SCW_CONTAINER_NAMESPACE \
  registry-image="rg.fr-par.scw.cloud/$SCW_REGISTRY_NAMESPACE/openwebui-scaleway:latest" \
  environment-variables.DATABASE_URL="$DATABASE_URL" \
  environment-variables.VECTOR_DB="pgvector" \
  environment-variables.SCALEWAY_API_KEY="$SCW_SECRET_KEY" \
  environment-variables.SCALEWAY_API_BASE="https://api.scaleway.ai/v1" \
  environment-variables.SCALEWAY_PROJECT_ID="$SCW_DEFAULT_PROJECT_ID" \
  environment-variables.OPENAI_API_BASE_URL="https://api.scaleway.ai/v1" \
  secret-environment-variables.0.key="OPENAI_API_KEY" \
  secret-environment-variables.0.value="$SCW_SECRET_KEY" \
  secret-environment-variables.1.key="WEBUI_SECRET_KEY" \
  secret-environment-variables.1.value="$WEBUI_SECRET_KEY" \
  environment-variables.WEBUI_AUTH="True" \
  environment-variables.ENABLE_SIGNUP="True" \
  region=fr-par \
  port=8080 \
  cpu-limit=2000 \
  memory-limit=4096 \
  min-scale=1 \
  max-scale=5 \
  timeout=300s

echo "✅ Container created! Deploying..."

# Get container ID (from output or query)
CONTAINER_ID=$(scw container container list namespace-id=$SCW_CONTAINER_NAMESPACE region=fr-par -o json | jq -r '.[0].id')

# Deploy
scw container container deploy container-id=$CONTAINER_ID region=fr-par

echo "✅ Deployment initiated!"
echo "📝 Container ID: $CONTAINER_ID"
echo "⏳ Deployment will take 5-10 minutes..."
echo "🔗 Check status: scw container container get container-id=$CONTAINER_ID region=fr-par"
```

Make scripts executable:

```bash
chmod +x scripts/*.sh
```

### 3.6 Commit Custom Changes

```bash
# Stage all changes
git add .

# Commit
git commit -m "Add Scaleway integration and custom configuration

- Added Scaleway Gen AI configuration
- Created custom Dockerfile for Scaleway deployment
- Added deployment scripts
- Configured pgvector integration
- Added Docker Compose for local testing"

# Tag this version
git tag scaleway-v1.0.0

# Push to your fork
git push origin custom-scaleway
git push origin --tags
```

### 3.7 Modifications Checklist

- [ ] Custom Scaleway configuration created
- [ ] Environment configuration modified
- [ ] Custom Dockerfile created
- [ ] Docker Compose for testing created
- [ ] Deployment scripts created
- [ ] Changes committed and tagged
- [ ] Pushed to fork

---

## Phase 4: Build & Deploy

### 4.1 Local Testing

```bash
# Load environment variables
source .env.local

# Start local stack
docker compose -f docker-compose.scaleway.yml up -d

# Watch logs
docker compose -f docker-compose.scaleway.yml logs -f openwebui

# Wait for startup (check for "Application startup complete")

# Test locally
open http://localhost:3000
```

**Local Testing Checklist:**
- [ ] Application starts without errors
- [ ] Database connection works
- [ ] Can create an account
- [ ] Can select Scaleway models
- [ ] Chat functionality works
- [ ] RAG document upload works

### 4.2 Build for Production

```bash
# Run build script
./scripts/build.sh

# Verify image
docker images | grep openwebui-scaleway
```

### 4.3 Push to Scaleway Registry

```bash
# Run push script
./scripts/push.sh

# Verify in registry
scw registry image list namespace-id=$SCW_REGISTRY_NAMESPACE region=fr-par
```

### 4.4 Deploy to Scaleway

```bash
# Run deployment script
./scripts/deploy.sh

# Monitor deployment
CONTAINER_ID=$(scw container container list namespace-id=$SCW_CONTAINER_NAMESPACE region=fr-par -o json | jq -r '.[0].id')

# Watch status
watch -n 5 "scw container container get container-id=$CONTAINER_ID region=fr-par | grep -E 'Status|Endpoint'"
```

### 4.5 Get Deployment URL

```bash
# Get endpoint URL
scw container container get container-id=$CONTAINER_ID region=fr-par | grep endpoint

# Example output:
# endpoint: https://openwebui-xxxxx.functions.fnc.fr-par.scw.cloud
```

### 4.6 Build & Deploy Checklist

- [ ] Local testing passed
- [ ] Production image built
- [ ] Image pushed to registry
- [ ] Container deployed to Scaleway
- [ ] Deployment URL obtained
- [ ] Container status is "ready"

---

## Phase 5: Testing & Validation

### 5.1 Application Access

```bash
# Get your deployment URL
DEPLOYMENT_URL=$(scw container container get container-id=$CONTAINER_ID region=fr-par -o json | jq -r '.endpoint')

echo "🔗 Access your deployment at: $DEPLOYMENT_URL"

# Open in browser
open $DEPLOYMENT_URL  # macOS
# or
xdg-open $DEPLOYMENT_URL  # Linux
```

### 5.2 Create Admin Account

- [ ] Navigate to deployment URL
- [ ] Click "Sign Up"
- [ ] Create admin account (first user is admin)
- [ ] Login successfully

### 5.3 Configure Scaleway Models

1. **Navigate to Settings**
   - Click settings icon (top right)
   - Go to "Connections" → "OpenAI API"

2. **Verify Configuration**
   - API URL should show: `https://api.scaleway.ai/v1`
   - API Key should be configured (hidden)
   - Click "Check Connection" - should show ✅

3. **Select Models**
   - Go to "Models"
   - Verify Scaleway models appear:
     - llama-3.3-70b-instruct
     - llama-3.1-8b-instruct
     - qwen2.5-coder-32b-instruct
     - Others...

### 5.4 Test Chat Functionality

- [ ] Start new chat
- [ ] Select a Scaleway model
- [ ] Send test message: "Hello! Can you confirm you're running on Scaleway infrastructure?"
- [ ] Verify response is received
- [ ] Test streaming works (tokens appear progressively)

### 5.5 Test RAG (Retrieval Augmented Generation)

1. **Upload Document**
   - Click "+" → "Upload files"
   - Upload a test PDF or text file
   - Wait for processing

2. **Test RAG Query**
   - In chat, type `#` to see documents
   - Select uploaded document
   - Ask question about document content
   - Verify response uses document context

### 5.6 Test Database Persistence

```bash
# Check database
psql -h $DB_HOST -p $DB_PORT -U openwebui -d rdb

# List tables
\dt

# Check users
SELECT id, email, role FROM public.user;

# Check chats
SELECT id, title, created_at FROM public.chat LIMIT 5;

# Exit
\q
```

### 5.7 Performance Testing

```bash
# Monitor container metrics
scw container container get container-id=$CONTAINER_ID region=fr-par

# Check logs for errors
scw container container logs container-id=$CONTAINER_ID region=fr-par
```

### 5.8 Validation Checklist

- [ ] Application accessible via URL
- [ ] Admin account created
- [ ] Scaleway models available
- [ ] Chat functionality works
- [ ] Streaming responses work
- [ ] Document upload works
- [ ] RAG queries work
- [ ] Data persists in PostgreSQL
- [ ] No errors in logs
- [ ] Response times acceptable

---

## Phase 6: Maintenance & Updates

### 6.1 Regular Update Schedule

**Weekly:**
- [ ] Check for security updates
- [ ] Review logs for errors
- [ ] Monitor resource usage

**Monthly:**
- [ ] Check for Open WebUI updates
- [ ] Update if necessary
- [ ] Test after update

### 6.2 Check for Upstream Updates

```bash
# Fetch latest from upstream
git fetch upstream

# Check what's new
git log HEAD..upstream/main --oneline

# See detailed changes
git log HEAD..upstream/main --stat

# Check if there are updates
git rev-list --count HEAD..upstream/main
# If > 0, there are updates available
```

### 6.3 Update Process

```bash
# 1. Ensure you're on main branch
git checkout main

# 2. Pull latest from upstream
git merge upstream/main

# 3. Push updated main to your fork
git push origin main

# 4. Switch to custom branch
git checkout custom-scaleway

# 5. Rebase on updated main
git rebase main

# If conflicts occur:
# - Edit conflicted files
# - git add <resolved-files>
# - git rebase --continue

# 6. Force push (history was rewritten)
git push origin custom-scaleway --force-with-lease

# 7. Tag new version
git tag scaleway-v1.1.0
git push origin --tags
```

### 6.4 Rebuild and Redeploy

```bash
# Test locally first
docker compose -f docker-compose.scaleway.yml down
docker compose -f docker-compose.scaleway.yml build
docker compose -f docker-compose.scaleway.yml up -d

# Test thoroughly locally
# ...

# If tests pass, deploy to production
./scripts/build.sh
./scripts/push.sh

# Before deploying, backup current version
CURRENT_VERSION=$(date +%Y%m%d-%H%M%S)
scw container container create \
  name=open-webui-backup-$CURRENT_VERSION \
  namespace-id=$SCW_CONTAINER_NAMESPACE \
  registry-image="rg.fr-par.scw.cloud/$SCW_REGISTRY_NAMESPACE/openwebui-scaleway:latest" \
  ... (same config as current)

# Deploy new version
scw container container deploy container-id=$CONTAINER_ID region=fr-par

# Monitor deployment
scw container container logs container-id=$CONTAINER_ID region=fr-par -f
```

### 6.5 Database Backup

```bash
# Create backup
pg_dump -h $DB_HOST -p $DB_PORT -U openwebui -d rdb > backup-$(date +%Y%m%d).sql

# Upload to S3 or Scaleway Object Storage (optional)
# scw object upload backup-$(date +%Y%m%d).sql ...
```

### 6.6 Monitoring Setup

Create `scripts/monitor.sh`:

```bash
#!/bin/bash

echo "📊 Open WebUI Scaleway Monitoring"
echo "=================================="

source .env.local

CONTAINER_ID=$(scw container container list namespace-id=$SCW_CONTAINER_NAMESPACE region=fr-par -o json | jq -r '.[0].id')

echo ""
echo "Container Status:"
scw container container get container-id=$CONTAINER_ID region=fr-par | grep -E 'Name|Status|CpuLimit|MemoryLimit|MinScale|MaxScale'

echo ""
echo "Recent Logs:"
scw container container logs container-id=$CONTAINER_ID region=fr-par --tail 20

echo ""
echo "Database Connection:"
psql -h $DB_HOST -p $DB_PORT -U openwebui -d rdb -c "SELECT COUNT(*) as total_chats FROM chat;"

echo ""
echo "Endpoint:"
scw container container get container-id=$CONTAINER_ID region=fr-par | grep endpoint
```

```bash
chmod +x scripts/monitor.sh
```

### 6.7 Update Checklist

- [ ] Upstream changes reviewed
- [ ] Main branch updated
- [ ] Custom branch rebased
- [ ] Conflicts resolved
- [ ] Local testing passed
- [ ] Production image built and pushed
- [ ] Backup created (optional)
- [ ] New version deployed
- [ ] Post-deployment tests passed
- [ ] Version tagged

---

## Troubleshooting

### Common Issues

#### 1. Container Won't Start

```bash
# Check logs
scw container container logs container-id=$CONTAINER_ID region=fr-par

# Common causes:
# - Database connection failed
# - Missing environment variables
# - Invalid Scaleway API key

# Verify environment variables
scw container container get container-id=$CONTAINER_ID region=fr-par | grep -A 50 "EnvironmentVariables"
```

#### 2. Database Connection Failed

```bash
# Test connection manually
psql -h $DB_HOST -p $DB_PORT -U openwebui -d rdb

# Check IP allowlist (if configured)
scw rdb instance get openwebui-db region=fr-par | grep -A 10 "AllowedIPs"

# Verify DATABASE_URL format
# Should be: postgresql://openwebui:PASSWORD@HOST:PORT/rdb
```

#### 3. Scaleway API Not Working

```bash
# Test API key
curl -H "Authorization: Bearer $SCW_SECRET_KEY" \
  https://api.scaleway.ai/v1/models

# Verify project ID (if using project-specific endpoint)
scw account project list
```

#### 4. Merge Conflicts During Update

```bash
# View conflicted files
git status

# For each conflicted file:
# 1. Edit the file
# 2. Remove conflict markers (<<<<<<<, =======, >>>>>>>)
# 3. Stage the file
git add <file>

# Continue rebase
git rebase --continue

# If you want to abort
git rebase --abort
```

#### 5. Image Too Large

```bash
# Use multi-stage build
# Check current size
docker images openwebui-scaleway:latest

# If > 2GB, optimize Dockerfile
# - Use slim Python base
# - Combine RUN commands
# - Remove unnecessary files
```

---

## Rollback Procedures

### Quick Rollback

```bash
# Deploy previous tagged version
scw container container create \
  name=open-webui \
  namespace-id=$SCW_CONTAINER_NAMESPACE \
  registry-image="rg.fr-par.scw.cloud/$SCW_REGISTRY_NAMESPACE/openwebui-scaleway:PREVIOUS_VERSION" \
  ... (same config)

# Or rollback git changes
git checkout custom-scaleway
git reset --hard scaleway-v1.0.0  # Previous working version
git push origin custom-scaleway --force
```

### Database Rollback

```bash
# Restore from backup
psql -h $DB_HOST -p $DB_PORT -U openwebui -d rdb < backup-YYYYMMDD.sql
```

---

## Project Milestones

### Milestone 1: Infrastructure Ready ✅
- [ ] Scaleway account configured
- [ ] CLI installed and authenticated
- [ ] Container Registry created
- [ ] PostgreSQL database provisioned
- [ ] Container namespace created

### Milestone 2: Repository Setup ✅
- [ ] Repository forked
- [ ] Custom branch created
- [ ] Upstream remote configured
- [ ] Documentation created

### Milestone 3: Customizations Complete ✅
- [ ] Scaleway integration added
- [ ] Custom Dockerfile created
- [ ] Deployment scripts created
- [ ] Changes committed and tagged

### Milestone 4: Deployment Complete ✅
- [ ] Local testing passed
- [ ] Production image built
- [ ] Image pushed to registry
- [ ] Container deployed
- [ ] Application accessible

### Milestone 5: Validation Complete ✅
- [ ] Admin account created
- [ ] Chat functionality verified
- [ ] RAG functionality verified
- [ ] Performance acceptable
- [ ] No critical errors

### Milestone 6: Maintenance Procedures ✅
- [ ] Update procedures documented
- [ ] Monitoring scripts created
- [ ] Backup procedures established
- [ ] Rollback procedures tested

---

## Resources

### Documentation
- [Open WebUI Docs](https://docs.openwebui.com/)
- [Scaleway Docs](https://www.scaleway.com/en/docs/)
- [Scaleway Gen AI](https://www.scaleway.com/en/docs/generative-apis/)

### Scripts Location
- `scripts/build.sh` - Build Docker image
- `scripts/push.sh` - Push to registry
- `scripts/deploy.sh` - Deploy to Scaleway
- `scripts/monitor.sh` - Monitor deployment

### Environment Files
- `.env.local` - Local development secrets
- `docker-compose.scaleway.yml` - Local testing

### Git Branches
- `main` - Synced with upstream
- `custom-scaleway` - Your customizations

---

## Next Steps

After completing this plan:

1. **Set up monitoring**
   - Scaleway Cockpit
   - Custom alerts
   - Log aggregation

2. **Add advanced features**
   - Custom RAG pipelines
   - Additional vector databases
   - Multi-model routing

3. **Performance optimization**
   - Enable Redis for scaling
   - Add CDN for static assets
   - Optimize database queries

4. **Security hardening**
   - Set up custom domain with SSL
   - Configure IP allowlists
   - Enable 2FA for admin

---

## Support

- **Issues**: https://github.com/YOUR_USERNAME/open-webui/issues
- **Upstream**: https://github.com/open-webui/open-webui/discussions
- **Scaleway**: https://console.scaleway.com/support

---

**Project Status**: 🚧 In Progress | ✅ Complete  
**Last Updated**: [Date]  
**Version**: 1.0.0