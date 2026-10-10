#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

STEPS=(
	base
	docker
	zsh
	update-zsh
	neovim
)

usage() {
	cat <<EOF
Usage: $0 [--from STEP] [STEP...]

Without arguments, runs every step in order:
  ${STEPS[*]}

  --from STEP   run STEP and every step after it
  --list        print the steps and exit

Environment (base step):
  OPEN_PORTS    firewall ports to open, e.g. "80/tcp 443/tcp 7777/udp"
  TIMEZONE      default UTC
  SWAP_SIZE     create a swapfile when none exists, e.g. 4G
  NOFILE_LIMIT  default 1048576
EOF
	exit "${1:-0}"
}

script_for() {
	case "$1" in
	update-zsh) echo "update-zsh.sh" ;;
	*) echo "install-$1.sh" ;;
	esac
}

run_step() {
	local step="$1" script
	script="$SCRIPT_DIR/$(script_for "$step")"
	[[ -f "$script" ]] || {
		echo "Unknown step: $step" >&2
		exit 1
	}
	printf '\n\033[1;36m==> [%s] %s\033[0m\n' "$step" "$(basename "$script")"
	case "$step" in
	update-zsh) zsh "$script" ;;
	*) bash "$script" ;;
	esac
	if command -v zsh >/dev/null && [[ -d "$HOME/.oh-my-zsh" ]]; then
		export SHELL="$(command -v zsh)"
	fi
}

selected=()
while [[ $# -gt 0 ]]; do
	case "$1" in
	-h | --help) usage ;;
	--list)
		printf '%s\n' "${STEPS[@]}"
		exit 0
		;;
	--from)
		[[ -n "${2:-}" ]] || usage 1
		found=0
		for s in "${STEPS[@]}"; do
			[[ "$s" == "$2" ]] && found=1
			[[ $found -eq 1 ]] && selected+=("$s")
		done
		[[ $found -eq 1 ]] || {
			echo "Unknown step: $2" >&2
			exit 1
		}
		shift 2
		;;
	*)
		selected+=("$1")
		shift
		;;
	esac
done

[[ ${#selected[@]} -eq 0 ]] && selected=("${STEPS[@]}")

sudo -v
while true; do
	sudo -n true
	sleep 60
	kill -0 "$$" 2>/dev/null || exit
done 2>/dev/null &

for step in "${selected[@]}"; do
	run_step "$step"
done

echo
echo "Server setup finished. Log out and back in for zsh and the docker group to take effect."
