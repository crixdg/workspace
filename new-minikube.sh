#!/usr/bin/env bash
set -e

read -p "This script is intended for Ubuntu systems only. Continue? (y/n): " confirm
if [[ "$confirm" != "y" ]]; then
	echo "Aborted."
	exit 1
fi

rm -rf $HOME/.local/minikube
mkdir -p $HOME/.local/minikube
wget https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64 -O $HOME/.local/minikube-linux-amd64
sudo install $HOME/.local/minikube-linux-amd64 "$HOME/.local/minikube" && rm $HOME/.local/minikube-linux-amd64
