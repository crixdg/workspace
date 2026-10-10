#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/check-os.sh"

TIMEZONE="${TIMEZONE:-UTC}"
OPEN_PORTS="${OPEN_PORTS:-}"
SWAP_SIZE="${SWAP_SIZE:-}"
NOFILE_LIMIT="${NOFILE_LIMIT:-1048576}"

sudo dnf -y update
sudo dnf install -y epel-release
sudo dnf install -y \
	bind-utils chrony curl dnf-automatic fail2ban firewalld git htop jq \
	policycoreutils-python-utils rsync tar tmux unzip wget

sudo timedatectl set-timezone "$TIMEZONE"
sudo systemctl enable --now chronyd

sudo systemctl enable --now firewalld
sudo firewall-cmd --permanent --add-service=ssh >/dev/null
for port in $OPEN_PORTS; do
	sudo firewall-cmd --permanent --add-port="$port" >/dev/null
	echo "Opened port $port"
done
sudo firewall-cmd --reload >/dev/null

sudo tee /etc/fail2ban/jail.d/90-sshd.local >/dev/null <<'EOF'
[sshd]
enabled = true
backend = systemd
maxretry = 5
bantime = 1h
findtime = 10m
EOF
sudo systemctl enable --now fail2ban
sudo systemctl restart fail2ban

sudo sed -i \
	-e 's/^upgrade_type = .*/upgrade_type = security/' \
	-e 's/^apply_updates = .*/apply_updates = yes/' \
	/etc/dnf/automatic.conf
sudo systemctl enable --now dnf-automatic.timer

sudo tee /etc/security/limits.d/90-nofile.conf >/dev/null <<EOF
* soft nofile $NOFILE_LIMIT
* hard nofile $NOFILE_LIMIT
EOF
sudo mkdir -p /etc/systemd/system.conf.d
sudo tee /etc/systemd/system.conf.d/90-nofile.conf >/dev/null <<EOF
[Manager]
DefaultLimitNOFILE=$NOFILE_LIMIT
EOF
sudo systemctl daemon-reexec

sudo tee /etc/sysctl.d/90-server.conf >/dev/null <<'EOF'
fs.file-max = 2097152
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 16384
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_tw_reuse = 1
EOF
sudo sysctl --system >/dev/null

if [[ -n "$SWAP_SIZE" ]] && ! swapon --show | grep -q .; then
	sudo fallocate -l "$SWAP_SIZE" /swapfile
	sudo chmod 600 /swapfile
	sudo mkswap /swapfile >/dev/null
	sudo swapon /swapfile
	grep -q '^/swapfile ' /etc/fstab || echo '/swapfile none swap defaults 0 0' | sudo tee -a /etc/fstab >/dev/null
	echo "Created ${SWAP_SIZE} swap at /swapfile"
fi

HARDENING=/etc/ssh/sshd_config.d/90-hardening.conf
{
	echo "PermitRootLogin $([[ "$USER" == root ]] && echo prohibit-password || echo no)"
	if [[ -s "$HOME/.ssh/authorized_keys" ]]; then
		echo "PasswordAuthentication no"
		echo "KbdInteractiveAuthentication no"
	fi
	echo "MaxAuthTries 3"
	echo "X11Forwarding no"
} | sudo tee "$HARDENING" >/dev/null

if sudo sshd -t; then
	sudo systemctl reload sshd
else
	sudo rm -f "$HARDENING"
	echo "sshd config test failed, hardening reverted." >&2
	exit 1
fi

if [[ ! -s "$HOME/.ssh/authorized_keys" ]]; then
	echo "WARNING: $HOME/.ssh/authorized_keys is empty, so password login is still enabled."
	echo "         Add your public key and re-run this script to disable it."
fi

echo "Base server setup done (timezone $TIMEZONE, nofile $NOFILE_LIMIT, open ports: ${OPEN_PORTS:-ssh only})."
