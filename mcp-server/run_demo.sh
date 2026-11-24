#!/usr/bin/env bash
# Starts the demo MCP server and an ngrok tunnel to it.
# The public address has a long random path, kept in .local/secret_path (not in Git).
# Stop it with Ctrl+C: the tunnel stops too.
set -euo pipefail
cd "$(dirname "$0")"
PORT="${MCP_PORT:-8787}"
mkdir -p .local logs
[ -f .local/secret_path ] || .venv/bin/python -c "import secrets; print('/mcp/' + secrets.token_urlsafe(24))" > .local/secret_path
MCP_PATH="$(cat .local/secret_path)"

ngrok http "$PORT" --log=false > logs/ngrok.out 2>&1 &
NGROK_PID=$!
trap 'kill $NGROK_PID 2>/dev/null || true' EXIT

HOST=""
for _ in $(seq 1 40); do
  HOST=$(curl -s 127.0.0.1:4040/api/tunnels | python3 -c "import json,sys; t=json.load(sys.stdin)['tunnels']; print(t[0]['public_url'].split('://')[1] if t else '')" 2>/dev/null || true)
  [ -n "$HOST" ] && break
  sleep 0.5
done
[ -n "$HOST" ] || { echo "ngrok did not start. See logs/ngrok.out" >&2; exit 1; }
echo "https://$HOST$MCP_PATH" > .local/public_url
echo "Tunnel is up. The address to register is in .local/public_url" >&2

MCP_PORT="$PORT" MCP_PATH="$MCP_PATH" MCP_PUBLIC_HOST="$HOST" .venv/bin/python server.py
