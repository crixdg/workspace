#!/usr/bin/env bash
set -e

read -p "This script is intended for Ubuntu systems only. Continue? (y/n): " confirm
if [[ "$confirm" != "y" ]]; then
	echo "Aborted."
	exit 1
fi

mkdir -p $HOME/.local/bin

rm -f $HOME/.local/bin/minikube
wget https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64 -O $HOME/.local/bin/minikube
chmod +x $HOME/.local/bin/minikube

rm -f $HOME/.local/bin/kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
chmod +x kubectl
mv ./kubectl $HOME/.local/bin/kubectl
rm -f kubectl.sha256
