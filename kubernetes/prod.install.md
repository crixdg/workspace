### Dependencies

```shell
containerd config default | sudo tee /etc/containerd/config.toml
```

### Disable Swap memory
- You **need to turn off swap** when setting up Kubernetes (especially on nodes) because **Kubernetes assumes the node's memory is fully under its control**.
- If swap is enabled, it **confuses the scheduler** and **breaks resource guarantees** like:
    - **`requests`** (minimum resources a pod expects)
    - **`limits`** (maximum resources a pod can use)
```shell
sudo swapoff -a
```

# Container Runtime

### Install containerd on all machines
```shell
curl -LO https://github.com/containerd/containerd/releases/download/v2.0.5/containerd-2.0.5-linux-amd64.tar.gz
curl -LO https://github.com/containerd/containerd/releases/download/v2.0.5/containerd-2.0.5-linux-amd64.tar.gz.sha256sum
sha256sum -c containerd-2.0.5-linux-amd64.tar.gz.sha256sum
sudo tar Cxzvf /usr/local containerd-2.0.5-linux-amd64.tar.gz
rm -rf containerd-2.0.5-linux-amd64.tar.gz containerd-2.0.5-linux-amd64.tar.gz.sha256sum
```
### Start containerd via systemd
```shell
curl -LO https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
sudo mkdir -p /usr/local/lib/systemd/system/
sudo mv containerd.service /usr/local/lib/systemd/system/
systemctl daemon-reload
systemctl enable --now containerd
```

# Control Plane

TBD