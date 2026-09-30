#!/usr/bin/env bash
set -euo pipefail

PREFIX=bezirova-04
ZONE_A=ru-central1-a
ZONE_B=ru-central1-b
CIDR_A=10.14.1.0/24
CIDR_B=10.14.2.0/24
APP_PORT=8012
GREETING=devlab
VM_COUNT=3
DISK_SIZE=20
BOOT_SIZE=15
IMAGE_FAMILY=ubuntu-2404-lts

echo "==> сеть и подсети"
yc vpc network create --name "$PREFIX-net"
yc vpc subnet create \
  --name "$PREFIX-subnet-a" \
  --network-name "$PREFIX-net" \
  --zone "$ZONE_A" \
  --range "$CIDR_A"
yc vpc subnet create \
  --name "$PREFIX-subnet-b" \
  --network-name "$PREFIX-net" \
  --zone "$ZONE_B" \
  --range "$CIDR_B"

echo "==> файл настройки из шаблона"
SSH_KEY=$(cat ~/.ssh/id_ed25519.pub)
export APP_PORT GREETING SSH_KEY
envsubst '${APP_PORT} ${GREETING} ${SSH_KEY}' \
  < work-02/cloud-init.tpl.yaml > work-02/cloud-init.yaml

