---
name: add-alert-rule
description: Add a vmalert rule, generic or inside a project pack.
---

# Add An Alert

## Workflow

1. Generic host, datastore, and `up` rules go in `vmalert/rules/alerts.yml`.
2. Rules that mention a product metric go in `packs/<project>/alerts.yml` and filter `project="<project>"`.
3. Use labels `project`, `env`, `job`, and `server`.
4. Add `for:`, `summary`, and `description`.
5. If the pack file is new, add a `-rule=` path in `docker-compose.yml`.
6. Remember that vmalert evaluates and Alertmanager only routes.
7. Validate YAML and `docker compose --env-file .env.example config`.
