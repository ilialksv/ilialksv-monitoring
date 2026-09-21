---
name: add-grafana-dashboard
description: Add a Grafana dashboard to the shared folders or to a project pack.
---

# Add A Dashboard

## Workflow

1. Shared host or datastore boards go under `grafana/dashboards/hosts` or `grafana/dashboards/datastores`.
2. Product boards go under `packs/<project>/dashboards`.
3. Use datasource UID `victoriametrics` and a stable unique `uid`.
4. Host queries use `job="node"` and `server`. Datastore queries use `project` and `env`.
5. A new folder needs an entry in `grafana/provisioning/dashboards/dashboards.yml` and a volume mount in `docker-compose.yml`.
6. Parse the JSON before finishing. Dokploy must deploy the stack with `--force-recreate` or Grafana will keep the previous files.
