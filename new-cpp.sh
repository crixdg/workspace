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
