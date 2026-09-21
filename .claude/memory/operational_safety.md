---
name: Operational safety
description: Mutating commands and secrets policy for ilialksv-monitoring
type: project
---

## Do Not Run By Default

- `docker compose up`
- `docker compose down`
- `docker compose pull`
- `docker compose restart`
- `docker compose exec`
- destructive Docker volume commands

There are no host bootstrap scripts. Do not recreate them.

Run mutating Docker commands only when the user explicitly asks for that exact operation.

## Secrets

Do not commit real `.env` values, SMTP credentials, GlitchTip secrets, remote-write passwords, or production tokens.
