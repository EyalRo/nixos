#!/usr/bin/env nix-shell
#!nix-shell -i bash -p openssh jq curl
# Fetch SSH private keys from the Homepage secrets service and load them into ssh-agent.
#
# Usage:
#   ssh-keys-from-secrets.sh                    # load all keys from service "ssh"
#   SSH_SECRETS_SERVICE=my-ssh ssh-keys-from-secrets.sh  # use a different service name
#
# Environment:
#   SECRETS_URL          — GraphQL endpoint (default: https://secrets.virtualdino.com/graphql)
#   SSH_SECRETS_SERVICE  — service name in the secrets store (default: ssh)
#   SSH_AUTH_SOCK        — must be set (ssh-agent must be running)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_FETCH="$SCRIPT_DIR/secrets-fetch.sh"
SECRETS_URL="${SECRETS_URL:-https://secrets.virtualdino.com/graphql}"
SERVICE="${SSH_SECRETS_SERVICE:-ssh}"

if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
  echo "ERROR: SSH_AUTH_SOCK is not set. Is ssh-agent running?" >&2
  exit 1
fi

# Create a temporary directory for key files (deleted on exit)
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Fetch all key names for the service
KEY_NAMES=$(curl -sf -X POST "$SECRETS_URL" \
  -H "Content-Type: application/json" \
  -d "{\"query\": \"{ secrets(service: \\\"$SERVICE\\\") { key } }\"}" \
  | jq -r '.data.secrets[].key')

if [[ -z "$KEY_NAMES" ]]; then
  echo "No keys found in secrets service under service \"$SERVICE\"" >&2
  exit 1
fi

LOADED=0
for key_name in $KEY_NAMES; do
  key_file="$TEMP_DIR/$key_name"

  # Fetch the key content and write to temp file
  "$SECRETS_FETCH" "$SERVICE" "$key_name" > "$key_file"
  chmod 600 "$key_file"

  # Add to ssh-agent (suppress "already loaded" warnings)
  if ssh-add "$key_file" 2>/dev/null; then
    echo "Loaded: $key_name"
    LOADED=$((LOADED + 1))
  else
    echo "Skipped (already loaded or error): $key_name" >&2
  fi
done

echo "$LOADED key(s) loaded into ssh-agent"
