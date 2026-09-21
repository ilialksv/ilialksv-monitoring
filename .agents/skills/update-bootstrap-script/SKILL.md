---
name: update-bootstrap-script
description: Add a Dokploy server to monitoring by deploying the agent. Host bootstrap scripts are gone.
---

# Add A Server

Host exporter bootstrap scripts have been removed. Do not recreate `scripts/bootstrap-*.sh`.

## Workflow

1. Deploy `agent/docker-compose.yml` as its own Dokploy compose app on the target server.
2. Set `SERVER_NAME`, `VMAGENT_REMOTE_WRITE_URL`, and the vmauth basic-auth pair from `agent/.env.example`.
3. Keep the Docker socket mount read-only.
4. Do not open ports 9100, 9187, or 9121 on the host.
5. Do not deploy this agent on the monitoring VPS.
6. Validate with `docker compose --env-file agent/.env.example -f agent/docker-compose.yml config`.
