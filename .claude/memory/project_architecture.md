---
name: Project architecture
description: ilialksv-monitoring stack and how projects attach
type: project
---

Central stack on the monitoring VPS: Grafana, VictoriaMetrics, vmauth, vmalert, Alertmanager, GlitchTip, and a local node_exporter.

Each application server runs `agent/docker-compose.yml`. vmagent discovers containers labeled `monitoring.scrape=true` on `dokploy-network` and remote-writes to `ingest` with basic auth. The label `server` comes from `SERVER_NAME`.

`victoriametrics/scrape.yml` scrapes only the monitoring host. Do not put application domains or IPs there.

Genario HTTP dashboards and alerts live in `packs/genario/`. Shared host and datastore boards do not name Genario.

The agent is not deployed on the monitoring VPS.
