#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/check-os.sh"

sudo apt install build-essential gdb -y
sudo apt install cmake ninja-build -y
sudo apt install clang lldb llvm -y

mkdir -p "$HOME/.local/bin/cppbin"
cp -r "workspace/cppbin/." "$HOME/.local/bin/cppbin/"
cp -f "workspace/.clang-format" "$HOME/.clang-format"

CONFIG_NAME="c++"
CONFIG_CONTENT='export PATH="$HOME/.local/bin/cppbin:$PATH"'
source "$SCRIPT_DIR/add-auto-config.sh"

echo "C++ workspace initialized and configured. Please restart your terminal or run 'source $SHELL_RC' to apply the changes."
