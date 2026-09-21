global:
  resolve_timeout: 5m
  smtp_from: "__ALERTMANAGER_EMAIL_FROM__"
  smtp_smarthost: "__ALERTMANAGER_EMAIL_SMARTHOST__"
  smtp_auth_username: "__ALERTMANAGER_EMAIL_AUTH_USERNAME__"
  smtp_auth_password: "__ALERTMANAGER_EMAIL_AUTH_PASSWORD__"
  smtp_require_tls: __ALERTMANAGER_EMAIL_REQUIRE_TLS__

route:
  receiver: "default-notifications"
  group_by: ["alertname", "project", "env", "job", "server"]
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h

receivers:
  - name: "default-notifications"
    email_configs:
      - to: "__ALERTMANAGER_EMAIL_TO__"
        send_resolved: true
