# AGENTS.md - ilialksv-monitoring

Canonical working guide for this repository. Tool-specific files may add
workflow detail, but they must not contradict this file.

## Language

Write every repository artifact in English: comments, README files, agent
rules, commit messages, dashboards, alerts, and configuration. This applies
to every repository, not only this one. User-facing product copy that is
intentionally localized stays in that locale; repository prose does not.

## Project Snapshot

- Purpose: project-independent monitoring for Dokploy servers.
- Central stack: Grafana, VictoriaMetrics, vmauth, vmalert, Alertmanager, GlitchTip,
  DbGate (database panel), Umami (web analytics).
- Agents: one `vmagent` + `node_exporter` + `db-tunnel` compose per application server.
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
- `packs/genario/` and `packs/genicly/` for product alerts on custom metric names.
- `grafana/dashboards/<project>/` for that project's Grafana folder.
- `grafana/provisioning/**` for the datasource and the dashboard provider.
- `README.md` for the Dokploy and DNS runbook.

## Architecture

```text
app containers with monitoring.* labels
  -> vmagent on that server (docker SD + local node_exporter)
  -> HTTPS remote write -> vmauth -> VictoriaMetrics
  -> Grafana and vmalert
GlitchTip stays on the monitoring server and receives client/server errors
```

Public ports: Grafana `3000`, GlitchTip `8000`, vmauth `8427`, DbGate `3000`, Umami
`3000`, all via Dokploy domains. Umami also answers on `go.ilialksv.ru`, where
every path maps to its short-link route `/q/<slug>`. VictoriaMetrics, vmalert, Alertmanager,
node_exporter, and the GlitchTip and Umami datastores are not published. On app servers only `db-tunnel` `2222` is
published, filtered to the monitoring VPS IP by the provider firewall.

```text
DbGate -> SSH :2222 (key only, forward-only) -> db-tunnel on dokploy-network
  -> Postgres :5432 / Redis :6379 by Dokploy service name
```

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
- Image tags are pinned in the compose files, not in env, so one commit upgrades
  every server. Never bump the `postgres` major of GlitchTip's database: the
  data directory does not survive a major upgrade.
- Do not run `docker compose up`, `down`, `pull`, `restart`, or `exec` unless the
  user explicitly asks for that exact operation.
- Do not publish VictoriaMetrics, vmalert, Alertmanager, exporter ports, or
  GlitchTip PostgreSQL/Valkey.
- Only the agent's `docker-socket-proxy` mounts the Docker socket, and it lets
  through GETs of containers and networks alone: vmagent's discovery needs no
  more. Do not mount the socket into another service or enable more endpoints.
- Keep Grafana datasource UID `victoriametrics` and stable dashboard `uid`s.
- Generic alerts must not mention a product name. Product metrics belong in `packs/`.
- Never publish a database port. DbGate reaches databases only through
  `db-tunnel`; widen its `PermitOpen` only for a new database port.
- DbGate connections are added in its UI and stored in the `dbgate_data` volume;
  never remove that volume. Production connections are marked read only.
- DbGate and Umami hold personal data: they stay on the monitoring VPS in Russia
  (152-FZ).
- Umami's `TRACKER_SCRIPT_NAME` (`p.js`) and `COLLECT_API_ENDPOINT` (`/api/p`) are
  baked into every site; renaming them breaks tracking until the sites redeploy.
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
2. Add `grafana/dashboards/<project>/` with `host-overview`, `postgres-overview`,
   `redis-overview` (if the project runs Redis), `api-endpoints` and
   `backend-overview`, copied from another project and pinned to this one.
   The directory becomes the Grafana folder; no provisioning change is needed.
3. Add `packs/<project>/alerts.yml` only when metric names are custom, and mount
   it in `vmalert`.
4. Point the app's GlitchTip DSN at this stack. Rebuild clients that bake the DSN in.

### Connect A Server

1. Deploy `agent/docker-compose.yml` on that Dokploy server, with the Compose
   command `--force-recreate`: vmagent reads the bind-mounted `scrape.yml` only at
   start.
2. Set `SERVER_NAME`, remote-write URL, and the same basic-auth password as vmauth.
3. Do not open exporter ports on the host firewall.

### Alerts And Dashboards

- Generic rules stay in `vmalert/rules/alerts.yml`.
- Product rules stay in `packs/<project>/alerts.yml`.
- Every dashboard lives in its project's folder, `grafana/dashboards/<project>/`.
  There are no shared folders. Project folders and dashboard names are
  lowercase (`genicly`, `host-overview`); a dashboard's `uid` is
  `<project>-<dashboard>`.
- Use `for:`, `summary`, and `description`.
- vmalert evaluates rules. Alertmanager only routes them.

## Completion Checklist

Report files changed, whether any public port or secret handling changed,
validation commands and results, and which runtime checks were not run.
