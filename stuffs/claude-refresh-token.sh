#!/usr/bin/env bash
set -euo pipefail

ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
SECRETS="$HOME/.secrets"
VAR="CLAUDE_CODE_OAUTH_TOKEN"
LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

unset "$VAR"
script -q -c "claude setup-token" "$LOG"

token="$(sed -E 's/\x1b\[[0-9;?]*[A-Za-z]//g; s/\x1b\][^\x07]*\x07//g' "$LOG" | tr -d '\r\n ' |
  grep -oE 'sk-ant-oat01-[A-Za-z0-9_-]{80,}AA' | tail -n1 || true)"

if [[ -z "$token" ]]; then
  echo
  read -rsp "Could not read the token from the output. Paste it here: " token
  echo
fi

if [[ ! "$token" =~ ^sk-ant-oat01-[A-Za-z0-9_-]+$ ]]; then
  echo "Invalid token, $SECRETS not changed." >&2
  exit 1
fi

(umask 077 && touch "$SECRETS")
chmod 600 "$SECRETS"

if grep -q "^export $VAR=" "$SECRETS"; then
  sed -i "s|^export $VAR=.*|export $VAR=\"$token\"|" "$SECRETS"
else
  printf 'export %s="%s"\n' "$VAR" "$token" >> "$SECRETS"
fi

if grep -q "^export $VAR=" "$ZSHRC"; then
  sed -i "/^export $VAR=/d" "$ZSHRC"
fi

if ! grep -qF '.secrets' "$ZSHRC"; then
  printf '\n[ -f "$HOME/.secrets" ] && source "$HOME/.secrets"\n' >> "$ZSHRC"
fi

echo "Updated $VAR in $SECRETS (expires $(date -d '+1 year' +%F))."
echo "Run: exec zsh"
