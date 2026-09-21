---
name: validate-monitoring-change
description: Validate monitoring compose, agent compose, alert YAML, and dashboard JSON without starting containers.
---

# Validate A Monitoring Change

## Workflow

1. Read `AGENTS.md` and the files you changed.
2. Run:

```bash
docker compose --env-file .env.example config
docker compose --env-file agent/.env.example -f agent/docker-compose.yml config
```

3. Parse changed JSON and YAML.
4. Check that application targets were not added to `victoriametrics/scrape.yml`.
5. Check that Grafana, GlitchTip, and vmauth are the only services on `dokploy-network` in the central stack.
6. Do not start containers or contact a VPS.
