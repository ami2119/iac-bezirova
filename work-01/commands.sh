#!/usr/bin/env bash

yc iam service-account create --name bezirova-04-sa

export FOLDER_ID=$(yc config get folder-id)
export SA_ID=$(yc iam service-account get --name bezirova-04-sa --format json | jq -r .id)

yc resource-manager folder add-access-binding "$FOLDER_ID" \
  --role editor \
  --subject "serviceAccount:$SA_ID"

mkdir -p ~/.yc-keys
yc iam key create --service-account-name bezirova-04-sa \
  --output ~/.yc-keys/bezirova-04-key.json

# сеть и подсеть 
export PREFIX=bezirova-04
export ZONE=ru-central1-a
export CIDR=10.14.1.0/24
export DISK_SIZE=15

yc vpc network create --name "$PREFIX-net"

yc vpc subnet create \
  --name "$PREFIX-subnet" \
  --network-name "$PREFIX-net" \
  --zone "$ZONE" \
  --range "$CIDR"

# ВМ через CLI 
yc compute instance create \
  --name "$PREFIX-web-1" \
  --zone "$ZONE" \
  --platform standard-v3 \
  --cores=2 \
  --core-fraction=20 \
  --memory=2 \
  --preemptible \
  --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2404-lts,type=network-hdd,size="$DISK_SIZE" \
  --network-interface subnet-name="$PREFIX-subnet",nat-ip-version=ipv4 \
  --hostname "$PREFIX-web-1" \
  --ssh-key ~/.ssh/id_ed25519.pub \
  --labels created-by=cli

# поиск остановленных машин 
yc compute instance list --format json | jq -r '.[] | select(.status != "RUNNING") | .name'

# удаление 
yc compute instance delete "$PREFIX-web-1"
yc compute instance delete "$PREFIX-web-manual"
yc vpc subnet delete "$PREFIX-subnet"
yc vpc network delete "$PREFIX-net"