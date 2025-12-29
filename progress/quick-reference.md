# Quick Reference

## Access
**Open WebUI URL**: http://51.15.135.199

## SSH Access
```bash
ssh root@51.15.135.199
```

## Key Resources

| Resource | ID | Details |
|----------|-----|---------|
| VM Instance | `30c6b790-1145-4e3b-a229-14fb45613034` | 51.15.135.199 (DEV1-S) |
| PostgreSQL | `9961c465-142a-4708-b6ea-ec7956166e06` | 51.159.25.65:22062 |
| Registry Namespace | `853d6ace-2477-43e2-bbbe-9b2e999184e3` | openwebui-registry |
| Container Namespace | `16346ded-0df0-4047-9356-701b5e629fb3` | openwebui-ns (unused) |

## Quick Commands

### Restart Application
```bash
ssh root@51.15.135.199 'docker compose restart'
```

### View Logs
```bash
ssh root@51.15.135.199 'docker compose logs -f'
```

### Check Status
```bash
ssh root@51.15.135.199 'docker compose ps && df -h'
```

### Update Deployment
```bash
./scripts/build.sh && ./scripts/push.sh
ssh root@51.15.135.199 'docker compose pull && docker compose up -d'
```

## Environment File Location
- **Local**: `/workspaces/civi/.env.scaleway` (NOT in git)
- **VM**: `/root/.env` on 51.15.135.199

## Model Configuration
- **Model**: gpt-oss-120b (only)
- **API**: https://api.scaleway.ai/14a9e91c-dbc2-4c2f-b3d7-3958ce9e0071/v1

## Monthly Cost
**Total**: ~€9-10/month
- VM (DEV1-S): €6.42/month
- PostgreSQL (db-dev-s): ~€3/month

## First Time Setup
1. Go to http://51.15.135.199
2. Click "Sign Up"
3. Create account (you become admin)
4. Select `gpt-oss-120b` model
5. Start chatting!
