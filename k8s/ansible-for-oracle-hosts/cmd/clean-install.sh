#!/bin/bash

ansible-playbook -i inventory/hosts playbook/stop-k8s-docker-podman.yaml
ansible-playbook -i inventory/hosts playbook/wipe-k8s-docker-podman.yaml
ansible-playbook -i inventory/hosts playbook/install-k8s-dependencies.yaml
ansible-playbook -i inventory/hosts playbook/install-k8s-main-master.yaml
ansible-playbook -i inventory/hosts playbook/install-k8s-join-masters.yaml
ansible-playbook -i inventory/hosts playbook/install-k8s-join-workers.yaml