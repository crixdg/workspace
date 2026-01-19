#!/bin/bash
set -euo pipefail

# Ensure required environment variables are set
: "${CONFIG_NAME:?CONFIG_NAME is required}"
: "${CONFIG_CONTENT:?CONFIG_CONTENT is required}"

# Define markers for the configuration block
START_MARK="# >>> managed:${CONFIG_NAME}:auto>>>"
DESCRIPTION_MARK="# !! DO NOT EDIT !! managed by ${CONFIG_NAME} (auto)"
END_MARK="# <<< managed:${CONFIG_NAME}:auto<<<"

CONFIG_BLOCK=$(
	cat <<EOF
$START_MARK
$DESCRIPTION_MARK
$CONFIG_CONTENT
$END_MARK
EOF
)

# Determine the user's shell and corresponding rc file
USER_SHELL="$(basename "${SHELL:-}")"

case "$USER_SHELL" in
zsh) SHELL_RC="$HOME/.zshrc" ;;
bash) SHELL_RC="$HOME/.bashrc" ;;
*) SHELL_RC="$HOME/.profile" ;;
esac

touch "$SHELL_RC"

# Remove existing block if present, then append the new block
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
  ' "$SHELL_RC" >"${SHELL_RC}.tmp"
	mv "${SHELL_RC}.tmp" "$SHELL_RC"
else
	printf "\n%s\n" "$CONFIG_BLOCK" >>"$SHELL_RC"
fi
