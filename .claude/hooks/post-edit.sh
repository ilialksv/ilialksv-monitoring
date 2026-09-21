#!/usr/bin/env bash
# Post-edit hook: prints non-blocking reminders after monitoring config edits.

INPUT=$(cat)

FILE=$(printf '%s' "$INPUT" | python3 -c '
import json
import sys

try:
    data = json.load(sys.stdin)
except Exception:
    print("")
    raise SystemExit

tool_input = data.get("tool_input", {}) or {}
file_path = tool_input.get("file_path") or ""
print(file_path)
' 2>/dev/null)

case "$FILE" in
  */docker-compose.yml|*/.env.example)
    echo "[hook] Compose/env changed: run both compose config commands from AGENTS.md; do not start containers by default."
    ;;
  */victoriametrics/scrape.yml|*/agent/scrape.yml)
    echo "[hook] Scrape config changed: application targets belong in the agent via Docker labels, not in the central scrape file."
    ;;
  */vmalert/rules/*.yml|*/packs/*/alerts.yml)
    echo "[hook] Alert rules changed: generic rules stay product-free; pack rules must filter project."
    ;;
  */alertmanager/*.yml.tpl|*/vmauth/*.yml)
    echo "[hook] Routing or auth config changed: keep secrets as placeholders."
    ;;
  */grafana/dashboards/*.json|*/grafana/dashboards/*/*.json|*/packs/*/dashboards/*.json)
    echo "[hook] Dashboard changed: parse JSON and verify datasource UID victoriametrics."
    ;;
  */grafana/provisioning/*.yml|*/grafana/provisioning/*/*.yml)
    echo "[hook] Grafana provisioning changed: verify mounted paths and dashboard folders."
    ;;
esac

exit 0
