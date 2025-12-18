#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/check-os.sh"

mkdir -p $HOME/.local/bin

if minikube version &> /dev/null; then
	echo "Minikube is already installed. Exiting."
else
	rm -f $HOME/.local/bin/minikube
	wget https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64 -O $HOME/.local/bin/minikube
	chmod +x $HOME/.local/bin/minikube
fi

if kubectl version --client &> /dev/null; then
	echo "Kubectl is already installed. Exiting."
else
	rm -f $HOME/.local/bin/kubectl
	curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
	curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
	echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
	chmod +x kubectl
	mv ./kubectl $HOME/.local/bin/kubectl
	rm -f kubectl.sha256
fi

if helm version &> /dev/null; then
	echo "Helm is already installed. Exiting."
else
	curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
	echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
	sudo apt update
	sudo apt install helm -y
fi
