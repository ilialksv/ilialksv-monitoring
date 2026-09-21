@AGENTS.md

# Claude Code Notes

Use `AGENTS.md` as the shared project contract.

## Default Task Flow

1. Identify the area: central compose, agent, vmauth, generic alerts, a project
   pack, Grafana, or the README runbook.
2. Read the matching local files before editing.
3. Keep product-specific metric names inside `packs/<project>/`.
4. A new project does not get a new job in `victoriametrics/scrape.yml`.
5. Validate with the compose config commands in `AGENTS.md`. Do not start
   containers unless the user explicitly asks.

## Claude-Specific Guidance

- Prefer `.claude/commands/**` for repeatable workflows.
- Use `.claude/agents/**` for focused config review.
- Keep project memory aligned with `AGENTS.md`.
- Do not commit local Claude permissions or secrets.
