sudo apt install podman pipx -y
pipx install podman-compose

# update docker.io in /etc/containers/registries.conf
sudo apt install sed -y
grep -Fxq 'unqualified-search-registries = ["docker.io"]' /etc/containers/registries.conf \
|| sudo sed -i "1i unqualified-search-registries = [\"docker.io\"]" /etc/containers/registries.conf

# update network version 1.0.0 to 0.4.0 to resolve cni error if exists