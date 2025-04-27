1. Install minikube
	```
	curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
	sudo dpkg -i minikube_latest_amd64.deb
	```
2. Install podman
	```
	sudo apt install -y podman
	```
3. Set minikube rootless
	```
	minikube config set rootless true
	```
4. Start your cluster
	```
	minikube start --driver=podman
	```
5. Install kubectl
	```
	curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
	curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
	echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
	sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
	rm -f kubectl kubectl.sha256
	kubectl version --client
	```
6. Useful commands
	```
    minikube status
    minikube stop
    minikube delete
	```