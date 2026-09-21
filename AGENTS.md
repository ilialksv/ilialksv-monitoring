# AGENTS.md - ilialksv-monitoring

Canonical working guide for this repository. Tool-specific files may add
workflow detail, but they must not contradict this file.

## Project Snapshot

- Purpose: project-independent monitoring for Dokploy servers.
- Central stack: Grafana, VictoriaMetrics, vmauth, vmalert, Alertmanager, GlitchTip.
- Agents: one `vmagent` + `node_exporter` compose per application server.
- Applications are discovered by Docker labels, not by editing scrape targets.
- Deployment: GitHub Actions deploys the root compose on pushes to `main`.
  Each agent is a separate Dokploy compose app using `agent/docker-compose.yml`.

## Source Of Truth

- `docker-compose.yml` for the central stack.
- `agent/docker-compose.yml` and `agent/scrape.yml` for per-server collection.
- `.env.example` and `agent/.env.example` for required variables.
- `victoriametrics/scrape.yml` for the monitoring host only.
- `vmauth/config.yml` for remote-write auth.
- `vmalert/rules/alerts.yml` for generic alerts.
- `packs/genario/` for Genario HTTP dashboards and alerts.
- `grafana/provisioning/**` and `grafana/dashboards/**` for shared dashboards.
- `README.md` for the Dokploy and DNS runbook.

## Architecture

```text
app containers with monitoring.* labels
  -> vmagent on that server (docker SD + local node_exporter)
  -> HTTPS remote write -> vmauth -> VictoriaMetrics
  -> Grafana and vmalert
GlitchTip stays on the monitoring server and receives client/server errors
```

Public ports: Grafana `3000`, GlitchTip `8000`, vmauth `8427`, all via Dokploy
domains. VictoriaMetrics, vmalert, Alertmanager, node_exporter, and GlitchTip
datastores are not published.

Do not deploy the agent compose onto the monitoring VPS. That host is scraped
by VictoriaMetrics directly.

## Label Contract

Application compose files set:

- `monitoring.scrape=true`
- `monitoring.port` — container port serving `/metrics`
- `monitoring.job` — Prometheus `job`
- `monitoring.project`
- `monitoring.env`

The agent adds `server` from `SERVER_NAME`. `SERVER_NAME` must be unique per VPS.
Host dashboards key off `job="node"` and `server`, because every agent scrapes
its own `node-exporter:9100` and the `instance` label would otherwise collide.

## Safety Rules

- Do not commit real `.env` values, passwords, SMTP credentials, or GlitchTip secrets.
- Do not run `docker compose up`, `down`, `pull`, `restart`, or `exec` unless the
  user explicitly asks for that exact operation.
- Do not publish VictoriaMetrics, vmalert, Alertmanager, exporter ports, or
  GlitchTip PostgreSQL/Valkey.
- The agent mounts the Docker socket read-only. That is still root-equivalent on
  the application server. Do not broaden it.
- Keep Grafana datasource UID `victoriametrics` and stable dashboard `uid`s.
- Generic alerts must not mention a product name. Product metrics belong in `packs/`.
- Do not put `environment: production` on the whole VictoriaMetrics stream. Stage
  and production are the `env` label.

## Validation

```bash
docker compose --env-file .env.example config
docker compose --env-file agent/.env.example -f agent/docker-compose.yml config
```

Parse edited JSON and YAML. Do not start containers as part of default validation.

## Change Workflows

### Connect A Project

1. Add the label contract to that project's compose. Do not edit central scrape config.
2. Add a dashboard pack under `packs/<project>/` only when metric names are custom.
3. Mount the pack's alerts in `vmalert` and its dashboards in Grafana provisioning
   if you added files.
4. Point the app's GlitchTip DSN at this stack. Rebuild clients that bake the DSN in.

### Connect A Server

1. Deploy `agent/docker-compose.yml` on that Dokploy server.
2. Set `SERVER_NAME`, remote-write URL, and the same basic-auth password as vmauth.
3. Do not open exporter ports on the host firewall.

### Alerts And Dashboards

- Generic rules stay in `vmalert/rules/alerts.yml`.
- Product rules stay in `packs/<project>/alerts.yml`.
- Shared dashboards live in `grafana/dashboards/hosts` and `grafana/dashboards/datastores`.
- Use `for:`, `summary`, and `description`.
- vmalert evaluates rules. Alertmanager only routes them.

## Completion Checklist

Report files changed, whether any public port or secret handling changed,
validation commands and results, and which runtime checks were not run.
