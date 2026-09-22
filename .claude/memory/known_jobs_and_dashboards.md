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

- `grafana/dashboards/hosts` — Host Overview, uid `host-overview`
- `grafana/dashboards/datastores` — Postgres and Redis
- `packs/genario/dashboards` — Backend Overview and API Endpoints, uids `backend-overview`, `api-endpoints`
- `packs/genicly/dashboards` — Backend Overview and API Endpoints, uids `genicly-backend-overview`, `genicly-api-endpoints`
