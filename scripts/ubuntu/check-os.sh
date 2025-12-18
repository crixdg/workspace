#!/bin/bash
set -euo pipefail

. /etc/os-release

if [[ "$ID" != "ubuntu" ]]; then
  echo "ERROR: This script supports Ubuntu only."
  echo "Detected: $NAME ($ID)"
  exit 1
fi

echo "OK: Ubuntu $VERSION_ID detected"
