---
name: Known jobs and dashboards
description: Label contract, jobs, and dashboard folders
type: project
---

## Jobs

- `node` — host metrics. One series set per `server`.
- Any `monitoring.job` value from a container label. Genario and Genicly use `backend`, `postgres`, and `redis`.

There are no `backend-node`, `frontend-node`, `db-node`, or `monitoring-node` jobs.

## Labels

`project`, `env`, `job`, `server`.

## Dashboards

One Grafana folder per project, `grafana/dashboards/<project>/`, uid `<project>-<dashboard>`:

- `genario`, `genicly` — host-overview, postgres-overview, redis-overview, api-endpoints, backend-overview
- `buiavchiann` — host-overview, postgres-overview, api-endpoints, backend-overview (no Redis)
- `monitoring` — host-overview
