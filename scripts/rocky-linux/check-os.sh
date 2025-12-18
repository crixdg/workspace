#!/bin/bash
set -euo pipefail

. /etc/os-release

if [[ "$ID" != "rocky" ]]; then
  echo "ERROR: This script supports Rocky Linux only."
  echo "Detected: $NAME ($ID)"
  exit 1
fi

echo "OK: Rocky Linux $VERSION_ID detected"
