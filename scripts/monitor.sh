#!/bin/bash

echo "📊 Open WebUI Scaleway Monitoring"
echo "=================================="

# Load environment
if [ -f .env.scaleway ]; then
    source .env.scaleway
else
    echo "Error: .env.scaleway file not found"
    exit 1
fi

# Get container ID
CONTAINER_ID=$(scw container container list namespace-id=$SCW_CONTAINER_NAMESPACE region=fr-par -o json | jq -r '.[] | select(.name=="open-webui") | .id')

if [ -z "$CONTAINER_ID" ]; then
    echo "No container found with name 'open-webui'"
    exit 1
fi

echo ""
echo "Container Status:"
scw container container get container-id=$CONTAINER_ID region=fr-par | grep -E 'Name|Status|CpuLimit|MemoryLimit|MinScale|MaxScale'

echo ""
echo "Endpoint:"
scw container container get container-id=$CONTAINER_ID region=fr-par | grep endpoint

echo ""
echo "Recent Logs (last 20 lines):"
scw container container logs container-id=$CONTAINER_ID region=fr-par --tail 20

echo ""
echo "Database Connection Test:"
PGPASSWORD="$DB_PASSWORD" psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT COUNT(*) as total_chats FROM chat;" 2>/dev/null || echo "Note: Chat table may not exist yet if app hasn't been initialized"
