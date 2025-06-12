### Installation
`sudo dnf install -y ansible`

### Run
`ansible-playbook -i <inventory> <playbook>`

- Cilium for CNI
- CoreDNS: For DNS resolution inside the cluster.
- Metrics Server: For resource usage metrics.
- Ingress Controller: For routing external traffic (e.g., NGINX Ingress).
- Dashboard: Web UI for managing the cluster.