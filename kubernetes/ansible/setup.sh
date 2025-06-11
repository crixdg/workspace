#!/bin/bash

INVENTORY_FILE="inventory/hosts"
SSH_KEY_PATH="$HOME/.ssh/id_rsa.pub"
USER="root"

grep 'ansible_host=' "$INVENTORY_FILE" | while read -r line; do
    ip=$(echo "$line" | sed -n 's/.*ansible_host=\([0-9.]*\).*/\1/p')
    user=$(echo "$line" | sed -n 's/.*ansible_user=\([a-zA-Z0-9_-]*\).*/\1/p')
    echo "Copying SSH key to $user@$ip..."
    ssh -o PasswordAuthentication=no "$user@$ip" "exit" 2>/dev/null || ssh-copy-id -i "$SSH_KEY_PATH" "$user@$ip"
done