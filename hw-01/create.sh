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