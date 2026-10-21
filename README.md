# ilialksv-monitoring

Shared monitoring for projects deployed with Dokploy. The stack runs on its own VPS and does not know the application list in advance. A new project is attached with container labels. A new server is attached by deploying the agent and setting environment variables.

There is one Dokploy panel: `dokploy.ilialksv.ru`. Each deploy server has its own Traefik, so a domain's A record points at the IP of the server that runs the service, not at the panel IP.

## What runs where

| Service | Where | Public |
| --- | --- | --- |
| Grafana, VictoriaMetrics, vmalert, Alertmanager, GlitchTip, vmauth, DbGate, Umami, node_exporter for this VPS | Monitoring VPS | Grafana `:3000`, GlitchTip `:8000`, vmauth `:8427`, DbGate `:3000`, Umami `:3000` |
| vmagent + node_exporter + db-tunnel | Each deploy server that runs applications | Only db-tunnel `:2222`, open to the monitoring VPS IP. Metrics are pushed to ingest |
| Application Postgres and Redis | Application server, Dokploy services | Only inside `dokploy-network` |

Do not install the agent on the monitoring VPS. VictoriaMetrics scrapes that host itself.

```mermaid
flowchart LR
  Agent["vmagent on the app server"] -->|"HTTPS basic auth"| Vmauth["ingest.ilialksv.ru"]
  Vmauth --> VM["VictoriaMetrics"]
  VM --> Grafana["grafana.ilialksv.ru"]
  VM --> Vmalert["vmalert"]
  Vmalert --> Alertmanager
  Apps["API and client"] -->|errors| GlitchTip["glitchtip.ilialksv.ru"]
```

## Domains

Rename these in Dokploy if the names below do not fit. Each A record points at the monitoring VPS.

- `grafana.ilialksv.ru` → Grafana, container port `3000`
- `glitchtip.ilialksv.ru` → GlitchTip, port `8000`
- `ingest.ilialksv.ru` → vmauth, port `8427`
- `db.ilialksv.ru` → DbGate, port `3000`
- `umami.ilialksv.ru` → Umami, port `3000`

`dokploy.ilialksv.ru` stays on the panel VPS.

## Connect a project

A container that serves `/metrics` needs labels. The Genario backend compose already has an example.

```yaml
labels:
  monitoring.scrape: "true"
  monitoring.port: "3000"
  monitoring.job: backend
  monitoring.project: genario
  monitoring.env: ${DEPLOY_ENVIRONMENT}
```

`monitoring.job` becomes the `job` label (`backend`, `postgres`, `redis`, or another name). `monitoring.project` and `monitoring.env` filter dashboards and alerts. The port is the container port, not a host port.

`victoriametrics/scrape.yml` stays unchanged. The agent finds the container on `dokploy-network` and remote-writes the series to ingest.

Errors are registered in the GlitchTip UI: create a project and put the DSN in the application env. The Genario frontend bakes `VITE_GLITCHTIP_DSN` into the bundle at build time, so a GlitchTip domain change needs a new frontend build, not only a restart. The backend reads `GLITCHTIP_DSN` when the process starts.

Grafana has one folder per project, named after its directory in `grafana/dashboards/`: `genario`, `genicly`, `buiavchiann`, `monitoring`. A folder holds that project's `host-overview`, `postgres-overview`, `redis-overview` (only where the project runs Redis), `api-endpoints` and `backend-overview`, each pinned to the project's `server` or `project` label; `monitoring` holds `host-overview` only. A dashboard's `uid` is `<project>-<dashboard>`. Product alerts for custom metric names (`genario_http_*`, `genicly_http_*`) live in `packs/<project>/alerts.yml`.

## Connect a server

In Dokploy, on the target deploy server, create a separate Compose application from this repository:

- Compose path: `agent/docker-compose.yml`
- Env from `agent/.env.example`
- `SERVER_NAME` is unique across servers, one word, for example `genario`
- `VMAGENT_REMOTE_WRITE_URL=https://ingest.ilialksv.ru/api/v1/write`
- Username and password match `VMAUTH_USERNAME` and `VMAUTH_PASSWORD` on the central stack

Turn on auto-deploy for that Dokploy application. The root GitHub Action deploys only the central stack: it has a single `DOKPLOY_APPLICATION_ID`.

The agent mounts the Docker socket read-only. That is still root-equivalent access on this server. Ports 9100, 9187, and 9121 are not published.

Backend `/metrics` is also closed by `METRICS_ALLOWED_IPS`. Set it to the `dokploy-network` subnet (`docker network inspect dokploy-network`). An empty list denies everyone. The agent calls the container directly, not through Traefik.

Set `POSTGRES_EXPORTER_DATA_SOURCE_NAME` in the application env, separate from `POSTGRES_URL`. If the URL has no query string, add `?sslmode=disable`. If it already has `?`, add `&sslmode=disable`. Do not append that suffix to `POSTGRES_URL`: a second `?` breaks the URL.

## Database access

DbGate at `db.ilialksv.ru` is the one panel for every project database. Databases stay unpublished: DbGate reaches each app server through SSH to the agent's `db-tunnel` container, which sits on `dokploy-network` and forwards to Dokploy service names.

```mermaid
flowchart LR
  Browser -->|HTTPS| DbGate["DbGate, db.ilialksv.ru"]
  DbGate -->|"SSH :2222, key only"| Tunnel["db-tunnel on the app server"]
  Tunnel -->|dokploy-network| PG["Postgres :5432 / Redis :6379"]
```

`db-tunnel` accepts one key and permits nothing but TCP forwards to ports 5432 and 6379: no shell, no other ports. Production connections are marked read only, stage is editable.

The panel shows personal data. Keep it on this VPS in Russia (152-FZ); do not move it to a server abroad.

### Set up the key

Create one key pair on your machine:

```bash
ssh-keygen -t ed25519 -N "" -C db-tunnel -f db-tunnel
```

- `db-tunnel.pub` goes into `DB_TUNNEL_PUBLIC_KEY` of every agent.
- `base64 -w0 db-tunnel` goes into `DB_TUNNEL_PRIVATE_KEY_BASE64` of the central stack.

Then delete both files. To rotate, repeat and redeploy the central stack and every agent.

### Connect a server

1. Redeploy the agent on that server with `DB_TUNNEL_PUBLIC_KEY` set. Its log prints the host key fingerprint.
2. In the provider's cloud firewall, allow TCP `2222` from the monitoring VPS IP only. Docker-published ports bypass ufw, so the cloud firewall is the filter.
3. Check from the monitoring VPS: `nc -vz <server IP> 2222`. Check from anywhere else: it must time out.

### Add a database

In DbGate, **Add new connection**. Nothing changes in this repository or on the app server.

- **General:** leave **Use database URL** off: the SSH tunnel takes its target from the Server and Port fields, and with a URL it has none. Take the values from that backend's `POSTGRES_URL` (`postgres://USER:PASSWORD@HOST:5432/DATABASE`):
  - Server: `HOST`, the Dokploy service name;
  - Port: `5432`, or `6379` for Redis;
  - User, Password and Default database from the URL;
  - Display name: for example `Genicly production`.
- **Is read only:** tick it on every production connection. DbGate then opens read-only Postgres sessions, so even a typed `UPDATE` fails.
- **SSH Tunnel:**
  - tick **Use SSH tunnel**;
  - Host: the app server IP; Port: type `2222` (the `22` shown is only a placeholder);
  - SSH Authentication: **Key file**; Login: `tunnel`;
  - leave the key path at its default `/root/.ssh/id_rsa`.
- Press **Test**, then **Save**.

Connections live in the `dbgate_data` volume, with passwords encrypted. Do not delete that volume: the connections would have to be added again.

## Analytics

Umami at `umami.ilialksv.ru` is the web analytics for every project: the dashboard, the tracker and the collect endpoint. It stores IPs, account IDs and session replays, so it stays on this VPS in Russia (152-FZ).

The tracker is served as `/p.js` and sends to `/api/p`: ad blockers match Umami's default `script.js` and `/api/send`. Session replay uses `/recorder.js` and `/api/record`, which cannot be renamed.

### First start

1. Fill `UMAMI_*` in the stack env; generate the two secrets as `.env.example` shows. Add the domain `umami.ilialksv.ru` → service `umami`, port `3000`, and redeploy.
2. Log in as `admin` / `umami`, change the password at once, and turn on two-factor authentication in the profile.

### Add a website

1. **Websites → Add website** with the site's domain. Copy its website ID into that site's build secret `VITE_UMAMI_WEBSITE_ID`.
2. **Edit → Replays & Heatmaps:** turn on Replays and Heatmaps. Set:
   - Mask level `moderate`, which masks every input;
   - Block selector `[data-analytics-private]`, which the sites put on private content;
   - Sample rate `1` while traffic is small.

Sites load the tracker only after the visitor accepts analytics cookies.

## Genario move runbook

Prepare this repository and the Dokploy panel before the DNS cutover. You restore the PostgreSQL contents. Redis starts empty. VictoriaMetrics history and GlitchTip events are not migrated.

1. Push this repository to `ilialksv/ilialksv-monitoring`. In Dokploy, add two deploy servers if they are not there yet: Genario and Monitoring. The panel does not move.
2. On the monitoring VPS, deploy the root `docker-compose.yml`. Set the Compose command to `--force-recreate`, or Grafana will not pick up new JSON from the bind mount. Fill env from `.env.example` and attach the Grafana, GlitchTip, and ingest domains. In GlitchTip, create projects for the API, workers, and web. Production and stage are environments inside a project, not a second instance.
3. On the Genario VPS, create two Postgres services and two Redis services in Dokploy. Restore the PostgreSQL dumps before the first backend deploy. The dump already contains the Drizzle migrations table, so a later migrate is a no-op. If migrate creates an empty schema before the restore, the restore has to be untangled by hand.
4. On that same server, create the applications: backend compose for production and for stage, frontend application for production and for stage. Keep the existing `stage.` domain prefix. In the backend env, set the new `POSTGRES_URL`, `REDIS_URL`, `POSTGRES_EXPORTER_DATA_SOURCE_NAME`, `METRICS_ALLOWED_IPS`, and `GLITCHTIP_DSN`.
5. Deploy the agent on the Genario VPS. `SERVER_NAME=genario`.
6. Update the GitHub Environment secrets for `production` and `stage`: `DOKPLOY_APPLICATION_ID` of the new applications, `DOKPLOY_URL` still `https://dokploy.ilialksv.ru`, the GlitchTip secrets, and `VITE_GLITCHTIP_DSN`. Push the frontend so the bundle is built with the new DSN. The backend and frontend workflows are unchanged.
7. Switch A records. `stage.` domains first, then production. Genario domains point at the Genario VPS IP. Monitoring domains point at the monitoring VPS IP.
8. Check stage, then production:
   - the site and API open on the existing hostnames;
   - Grafana, folders `genario` and `monitoring`: `host-overview` shows each server;
   - `genario/postgres-overview` and `genario/redis-overview` show both envs;
   - `genario/backend-overview` shows backend traffic for production and stage;
   - a test client error and an API error land in the new GlitchTip.
9. Turn off the old frontend, backend, database, and monitoring VPS. Firewall holes on 9100, 9187, 9121, and the stage ports are no longer needed.

## Repository map

| Path | Purpose |
| --- | --- |
| `docker-compose.yml` | Central stack |
| `agent/` | Agent for a deploy server |
| `db-tunnel/` | Forward-only SSH image the agent runs for DbGate |
| `victoriametrics/scrape.yml` | node_exporter on the monitoring VPS only |
| `vmauth/config.yml` | Remote-write ingress |
| `vmalert/rules/alerts.yml` | Generic alerts |
| `packs/genario/` | Genario metric alerts |
| `packs/genicly/` | Genicly metric alerts |
| `grafana/dashboards/<project>/` | One Grafana folder per project |
| `grafana/provisioning/` | Datasource and dashboard provisioning |
| `.github/workflows/deploy.yaml` | Deploy the central stack to Dokploy on push to `main` |

## Config check

```bash
docker compose --env-file .env.example config
docker compose --env-file agent/.env.example -f agent/docker-compose.yml config
```

These commands do not start containers.
