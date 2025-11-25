#!/usr/bin/env bash
set -e

read -p "This script is intended for Ubuntu systems only. Continue? (y/n): " confirm
if [[ "$confirm" != "y" ]]; then
	echo "Aborted."
	exit 1
fi

sudo apt update
sudo apt install -y build-essential
sudo apt install -y gdb
sudo apt install -y cmake
sudo apt install -y ninja-build
sudo apt install -y clang lldb llvm

mkdir -p "$HOME/.local/bin/cppbin"
cp -r "workspace/cppbin/." "$HOME/.local/bin/cppbin/"
cp -f "workspace/.clang-format" "$HOME/.clang-format"

START_MARK="# >>> cpp workspace initialize >>>"
DESCRIPTION_MARK="# !! Contents within this block are managed by 'cpp workspace init' !!"
END_MARK="# <<< cpp workspace initialize <<<"

CPP_BLOCK=$(
	cat <<EOF
$START_MARK
$DESCRIPTION_MARK
export PATH="\$HOME/.local/bin/cppbin:\$PATH"
$END_MARK
EOF
)

if [[ "$SHELL" =~ "zsh" ]]; then
	SHELL_RC="$HOME/.zshrc"
else
	SHELL_RC="$HOME/.bashrc"
fi

if grep -q "$START_MARK" "$SHELL_RC"; then
	# Replace existing block, ensure empty line before block
	awk -v block="$CPP_BLOCK" -v start="$START_MARK" -v end="$END_MARK" '
        BEGIN {inblock=0}
        $0 ~ start {
            print block;
            inblock=1;
            next
        }
        $0 ~ end {inblock=0; next}
        !inblock {print}
    ' "$SHELL_RC" >"${SHELL_RC}.tmp" && mv "${SHELL_RC}.tmp" "$SHELL_RC"
else
	# Append block with empty line before
	echo "" >>"$SHELL_RC"
	echo "$CPP_BLOCK" >>"$SHELL_RC"
fi

echo "C++ workspace initialized and configured. Please restart your terminal or run 'source $SHELL_RC' to apply the changes."
