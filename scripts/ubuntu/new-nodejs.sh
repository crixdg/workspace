#!/usr/bin/env bash
set -e

read -p "This script will install/fix NVM configuration for Ubuntu only. Continue? (y/n): " confirm
if [[ "$confirm" != "y" ]]; then
	echo "Aborted."
	exit 1
fi

# Install NVM if not already installed
if [ ! -d "$HOME/.nvm" ]; then
	read -p "Enter the NVM version you want to install (e.g., v0.40.1): " NVM_VERSION
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh | bash
	echo "NVM installed."
else
	echo "NVM already installed at $HOME/.nvm"
fi

# Define the markers for the NVM block
START_MARK="# >>> nvm initialize >>>"
DESCRIPTION_MARK="# !! Contents within this block are managed by 'nvm workspace init' !!"
END_MARK="# <<< nvm initialize <<<"

# Create the clean NVM block
NVM_BLOCK=$(
    cat <<EOF
$START_MARK
$DESCRIPTION_MARK
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"
[ -s "\$NVM_DIR/bash_completion" ] && \. "\$NVM_DIR/bash_completion"
$END_MARK
EOF
)

# Detect shell RC file
if [[ "$SHELL" =~ "zsh" ]]; then
	SHELL_RC="$HOME/.zshrc"
else
	SHELL_RC="$HOME/.bashrc"
fi

echo "Cleaning up shell configuration in $SHELL_RC..."

# Remove any existing NVM blocks (both old style and new style with markers)
# This handles multiple scenarios:
# 1. NVM's default installation block
# 2. Any previous managed blocks with markers
awk -v start="$START_MARK" -v end="$END_MARK" '
    BEGIN {inblock=0}

    # Detect start of managed block
    $0 ~ start {inblock=1; next}

    # Detect end of managed block
    $0 ~ end {inblock=0; next}

    # Remove any lines that reference NVM_DIR (old style)
    /^\s*export NVM_DIR=/ {next}
    /^\s*\[ -s "\$NVM_DIR\/nvm\.sh" \] && \\.\s*"\$NVM_DIR\/nvm\.sh"/ {next}
    /^\s*\[ -s "\$NVM_DIR\/bash_completion" \] && \\.\s*"\$NVM_DIR\/bash_completion"/ {next}
    /NVM_DIR/ {next}

    # Print lines not in any block
    !inblock {print}
' "$SHELL_RC" >"${SHELL_RC}.tmp" && mv "${SHELL_RC}.tmp" "$SHELL_RC"

# Add the new managed block
echo "" >>"$SHELL_RC"
echo "$NVM_BLOCK" >>"$SHELL_RC"

echo ""
echo "NVM configuration has been cleaned and fixed!"
echo "Please restart your terminal or run 'source $SHELL_RC' to apply the changes."
echo ""
echo "After sourcing, you can use NVM commands:"
echo "  nvm --version          # Check NVM version"
echo "  nvm install --lts     # Install latest LTS Node.js"
echo "  nvm install 20        # Install Node.js 20.x"
echo "  nvm use 20            # Use Node.js 20.x"
echo "  nvm ls                # List installed versions"
