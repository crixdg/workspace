#!/bin/bash
set -euo pipefail

# =========================
# Required inputs
# =========================
: "${CONFIG_NAME:?CONFIG_NAME is required}"
: "${CONFIG_CONTENT:?CONFIG_CONTENT is required}"

START_MARK="# >>> managed:${CONFIG_NAME}:auto-config >>>"
DESCRIPTION_MARK="# !! DO NOT EDIT !! managed by ${CONFIG_NAME} (auto-config)"
END_MARK="# <<< managed:${CONFIG_NAME}:auto-config <<<"

CONFIG_BLOCK=$(
  cat <<EOF
$START_MARK
$DESCRIPTION_MARK
$CONFIG_CONTENT
$END_MARK
EOF
)

# =========================
# Detect shell rc file
# =========================
if [[ -n "${ZSH_VERSION:-}" ]]; then
  SHELL_RC="$HOME/.zshrc"
elif [[ -n "${BASH_VERSION:-}" ]]; then
  SHELL_RC="$HOME/.bashrc"
else
  SHELL_RC="$HOME/.profile"
fi

# Ensure rc file exists
touch "$SHELL_RC"

# =========================
# Insert or replace block
# =========================
if grep -qF "$START_MARK" "$SHELL_RC"; then
  awk -v block="$CONFIG_BLOCK" -v start="$START_MARK" -v end="$END_MARK" '
    BEGIN { inblock=0 }
    $0 ~ start {
      print block
      inblock=1
      next
    }
    $0 ~ end { inblock=0; next }
    !inblock { print }
  ' "$SHELL_RC" > "${SHELL_RC}.tmp"
  mv "${SHELL_RC}.tmp" "$SHELL_RC"
else
  printf "\n%s\n" "$CONFIG_BLOCK" >> "$SHELL_RC"
fi
