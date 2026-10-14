#!/bin/sh
set -eu

: "${DB_TUNNEL_PUBLIC_KEY:?DB_TUNNEL_PUBLIC_KEY is required}"

# The host key lives in a volume so its fingerprint survives redeploys.
host_key=/etc/ssh/keys/ssh_host_ed25519_key
if [ ! -f "$host_key" ]; then
  ssh-keygen -q -t ed25519 -N "" -f "$host_key"
fi
echo "Host key: $(ssh-keygen -l -f "$host_key")"

printf '%s\n' "$DB_TUNNEL_PUBLIC_KEY" > /etc/ssh/authorized_keys/tunnel
chmod 644 /etc/ssh/authorized_keys/tunnel

exec /usr/sbin/sshd -D -e
