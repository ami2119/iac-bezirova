#!/usr/bin/env bash
set -euo pipefail

PREFIX=bezirova-04
VM_COUNT="${1:-3}"

echo "==> балансировщик"
yc load-balancer network-load-balancer delete "$PREFIX-lb"

echo "==> целевая группа"
yc load-balancer target-group delete "$PREFIX-tg"

echo "==> машины"
for i in $(seq 1 "$VM_COUNT"); do
  yc compute instance delete "$PREFIX-app-$i"
done

echo "==> дополнительный диск"
yc compute disk delete "$PREFIX-data"

echo "==> подсети"
yc vpc subnet delete "$PREFIX-subnet-a"
yc vpc subnet delete "$PREFIX-subnet-b"

echo "==> сеть"
yc vpc network delete "$PREFIX-net"