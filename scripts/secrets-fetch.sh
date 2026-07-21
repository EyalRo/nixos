#!/usr/bin/env nix-shell
#!nix-shell -i bash -p jq curl
# Fetch a secret from the Homepage secrets service (GraphQL API).
#
# Usage:
#   secrets-fetch.sh <service> <key>
#   secrets-fetch.sh <service>            # list all keys for a service
#
# Environment:
#   SECRETS_URL  — GraphQL endpoint (default: https://secrets.virtualdino.com/graphql)
#
# Examples:
#   secrets-fetch.sh ssh id_ed25519_proxmox   # print the private key
#   secrets-fetch.sh mcp-proxmox              # list keys for mcp-proxmox
set -euo pipefail

SECRETS_URL="${SECRETS_URL:-https://secrets.virtualdino.com/graphql}"

service="${1:?Usage: $0 <service> [key]}"
key="${2:-}"

response=$(curl -sf -X POST "$SECRETS_URL" \
  -H "Content-Type: application/json" \
  -d "{\"query\": \"{ secrets(service: \\\"$service\\\") { key value } }\"}")

if [[ -z "$key" ]]; then
  # List all keys for the service
  echo "$response" | jq -r '.data.secrets[] | "\(.key)=\(.value)"'
else
  # Fetch a single key (-j: no trailing newline, preserves exact content)
  echo "$response" | jq -jr --arg k "$key" '.data.secrets[] | select(.key == $k) | .value'
fi
