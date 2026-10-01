#!/usr/bin/env bash
set -euo pipefail

PREFIX=bezirova-04
ZONE_A=ru-central1-a
ZONE_B=ru-central1-b
CIDR_A=10.14.1.0/24
CIDR_B=10.14.2.0/24
APP_PORT=8012
GREETING=devlab
BOOT_SIZE=15
IMAGE_FAMILY=ubuntu-2404-lts

WEB_COUNT="${1:-${WEB_COUNT:-3}}"
DISK_SIZE="${2:-${DISK_SIZE:-20}}"

echo "==> сеть и подсети"
if yc vpc network get "$PREFIX-net" >/dev/null 2>&1; then
  echo "сеть $PREFIX-net уже есть, этот этап будет пропущен"
else
  yc vpc network create --name "$PREFIX-net"
fi

if yc vpc subnet get "$PREFIX-subnet-a" >/dev/null 2>&1; then
  echo "подсеть $PREFIX-subnet-a уже есть, этот этап будет пропущен"
else
  yc vpc subnet create \
    --name "$PREFIX-subnet-a" \
    --network-name "$PREFIX-net" \
    --zone "$ZONE_A" \
    --range "$CIDR_A"
fi

if yc vpc subnet get "$PREFIX-subnet-b" >/dev/null 2>&1; then
  echo "подсеть $PREFIX-subnet-b уже есть, этот этап будет пропущен"
else
  yc vpc subnet create \
    --name "$PREFIX-subnet-b" \
    --network-name "$PREFIX-net" \
    --zone "$ZONE_B" \
    --range "$CIDR_B"
fi

echo "==> NAT-шлюз и таблица маршрутизации"
if yc vpc gateway get "$PREFIX-nat" >/dev/null 2>&1; then
  echo "шлюз $PREFIX-nat уже есть, этот этап будет пропущена"
else
  yc vpc gateway create --name "$PREFIX-nat"
fi
GW_ID=$(yc vpc gateway get --name "$PREFIX-nat" --format json | jq -r .id)

if yc vpc route-table get "$PREFIX-rt" >/dev/null 2>&1; then
  echo "таблица $PREFIX-rt уже есть, этот этап будет пропущен"
else
  yc vpc route-table create \
    --name "$PREFIX-rt" \
    --network-name "$PREFIX-net" \
    --route "destination=0.0.0.0/0,gateway-id=$GW_ID"
fi

yc vpc subnet update "$PREFIX-subnet-a" --route-table-name "$PREFIX-rt"

echo "==> файл настройки из шаблона"
SSH_KEY=$(cat ~/.ssh/id_ed25519.pub)
export APP_PORT GREETING SSH_KEY
envsubst '${APP_PORT} ${GREETING} ${SSH_KEY}' \
  < hw-01/cloud-init.tpl.yaml > hw-01/cloud-init.yaml

echo "==> файл настройки из шаблона"
SSH_KEY=$(cat ~/.ssh/id_ed25519.pub)
export APP_PORT GREETING SSH_KEY
envsubst '${APP_PORT} ${GREETING} ${SSH_KEY}' \
  < hw-01/cloud-init.tpl.yaml > hw-01/cloud-init.yaml

echo "==> веб-серверы"
ZONES=("$ZONE_A" "$ZONE_B")
SUBNETS=("$PREFIX-subnet-a" "$PREFIX-subnet-b")
for i in $(seq 1 "$WEB_COUNT"); do
  idx=$(( (i - 1) % 2 ))
  NAME="$PREFIX-web-$i"
  if yc compute instance get "$NAME" >/dev/null 2>&1; then
    echo "машина $NAME уже есть, этот этап будет пропущен"
    continue
  fi
  yc compute instance create \
    --name "$NAME" \
    --zone "${ZONES[$idx]}" \
    --platform standard-v3 \
    --cores=2 --core-fraction=20 --memory=2 \
    --preemptible \
    --create-boot-disk image-folder-id=standard-images,image-family="$IMAGE_FAMILY",type=network-hdd,size="$BOOT_SIZE" \
    --network-interface subnet-name="${SUBNETS[$idx]}",nat-ip-version=ipv4 \
    --hostname "$NAME" \
    --metadata-from-file user-data=hw-01/cloud-init.yaml
done

echo "==> сервер приложения (без публичного адреса)"
APP_NAME="$PREFIX-app-1"

if yc compute instance get "$APP_NAME" >/dev/null 2>&1; then
  echo "машина $APP_NAME уже есть, этот этап будет пропущен"
else
  if yc compute disk get "$PREFIX-data" >/dev/null 2>&1; then
    echo "диск $PREFIX-data уже есть, этот этап будет пропущен"
  else
    yc compute disk create \
      --name "$PREFIX-data" \
      --zone "$ZONE_A" \
      --size "$DISK_SIZE" \
      --type network-hdd
  fi

  yc compute instance create \
    --name "$APP_NAME" \
    --zone "$ZONE_A" \
    --platform standard-v3 \
    --cores=2 --core-fraction=20 --memory=2 \
    --preemptible \
    --create-boot-disk image-folder-id=standard-images,image-family="$IMAGE_FAMILY",type=network-hdd,size="$BOOT_SIZE" \
    --network-interface subnet-name="$PREFIX-subnet-a" \
    --hostname "$APP_NAME" \
    --attach-disk disk-name="$PREFIX-data",device-name=data,auto-delete=false \
    --metadata-from-file user-data=hw-01/cloud-init.yaml
fi