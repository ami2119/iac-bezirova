#!/usr/bin/env bash
set -euo pipefail

PREFIX=bezirova-04
VM_COUNT="${1:-3}"

echo "==> балансировщик"
if yc load-balancer network-load-balancer get --name "$PREFIX-lb" >/dev/null 2>&1; then
  yc load-balancer network-load-balancer delete "$PREFIX-lb"
else
  echo "  $PREFIX-lb уже нет, этот этап будет пропущен"
fi

echo "==> целевая группа"
if yc load-balancer target-group get --name "$PREFIX-tg" >/dev/null 2>&1; then
  yc load-balancer target-group delete "$PREFIX-tg"
else
  echo "  $PREFIX-tg уже нет, этот этап будет пропущен"
fi

echo "==> машины"
for i in $(seq 1 "$VM_COUNT"); do
  NAME="$PREFIX-app-$i"
  if yc compute instance get --name "$NAME" >/dev/null 2>&1; then
    yc compute instance delete "$NAME"
  else
    echo "  $NAME уже нет, этот этап будет пропущен"
  fi
done

echo "==> дополнительный диск"
if yc compute disk get --name "$PREFIX-data" >/dev/null 2>&1; then
  yc compute disk delete "$PREFIX-data"
else
  echo "  $PREFIX-data уже нет, этот этап будет пропущен"
fi

echo "==> подсети"
for SN in "$PREFIX-subnet-a" "$PREFIX-subnet-b"; do
  if yc vpc subnet get --name "$SN" >/dev/null 2>&1; then
    yc vpc subnet delete "$SN"
  else
    echo "  $SN уже нет, этот этап будет пропущен"
  fi
done

echo "==> сеть"
if yc vpc network get --name "$PREFIX-net" >/dev/null 2>&1; then
  yc vpc network delete "$PREFIX-net"
else
  echo "  $PREFIX-net уже нет, этот этап будет пропущен"
fi