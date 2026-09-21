---
name: add-scrape-target
description: Connect a project or metrics endpoint to ilialksv-monitoring without editing the central scrape file.
---

# Connect A Project

## Workflow

1. Add Docker labels on the application container: `monitoring.scrape`, `monitoring.port`, `monitoring.job`, `monitoring.project`, `monitoring.env`.
2. Do not add the target to `victoriametrics/scrape.yml`. The agent discovers it.
3. Confirm an agent is already deployed on that server. If not, deploy `agent/docker-compose.yml` and set `SERVER_NAME` plus remote-write env.
4. Add `packs/<project>/` only when the app exposes custom metric names. Mount new alert and dashboard paths in the central compose and Grafana provisioning.
5. Update `README.md` only if the label contract or the runbook changes.
6. Validate both compose files with the commands in `AGENTS.md`.

## Safety

- Do not publish exporter ports.
- Do not put product names into generic alerts.
