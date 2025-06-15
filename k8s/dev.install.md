# kubectl

```shell
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm -f kubectl kubectl.sha256
kubectl version --client
```
---
# minikube

```shell
curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64
```
---

# Docker

### Install docker dependencies
```shell
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```

### Install docker
```shell
sudo apt install docker-ce docker-ce-cli docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER && newgrp docker
```

---
# Helm

```shell
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm -f get_helm.sh
```

### Add completion for helm
```shell
mkdir -p ~/.config/zsh/completions
helm completion zsh > ~/.config/zsh/completions/helm.zsh
echo '# HELM' >> ~/.zshrc
echo 'source ~/.config/zsh/completions/helm.zsh' >> ~/.zshrc
source ~/.zshrc
```

---
# Setup Minikube

### Start minikube
```shell
minikube start --container-runtime=containerd --driver=docker
```

### Enable dashboard
```shell
minikube addons enable metrics-server
minikube addons enable dashboard
```

### Run dashboard
```shell
minikube dashboard
```
---