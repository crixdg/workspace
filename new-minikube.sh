#!/usr/bin/env bash
set -e

read -p "This script is intended for Ubuntu systems only. Continue? (y/n): " confirm
if [[ "$confirm" != "y" ]]; then
	echo "Aborted."
	exit 1
fi

rm -f $HOME/.local/bin/minikube
wget https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64 -O $HOME/.local/bin/minikube
chmod +x $HOME/.local/bin/minikube
