#!/usr/bin/env bash
set -uo pipefail
export YC_CLI_INITIALIZATION_SILENCE=true

PREFIX=bezirova-04

echo "==> балансировщик"
for name in $(yc load-balancer network-load-balancer list --format json \
              | jq -r ".[] | select(.name | startswith(\"$PREFIX\")) | .name"); do
  yc load-balancer network-load-balancer delete "$name"
done

echo "==> целевая группа"
for name in $(yc load-balancer target-group list --format json \
              | jq -r ".[] | select(.name | startswith(\"$PREFIX\")) | .name"); do
  yc load-balancer target-group delete "$name"
done

echo "==> машины"
for name in $(yc compute instance list --format json \
              | jq -r ".[] | select(.name | startswith(\"$PREFIX\")) | .name"); do
  yc compute instance delete "$name"
done

echo "==> диски"
for name in $(yc compute disk list --format json \
              | jq -r ".[] | select(.name | startswith(\"$PREFIX\")) | .name"); do
  yc compute disk delete "$name"
done

echo "==> отвязать таблицу маршрутизации от подсети A"
for name in $(yc vpc subnet list --format json \
              | jq -r ".[] | select(.name | startswith(\"$PREFIX\")) | .name"); do
  yc vpc subnet update "$name" --route-table-name ""
done

echo "==> таблица маршрутизации"
for name in $(yc vpc route-table list --format json \
              | jq -r ".[] | select(.name | startswith(\"$PREFIX\")) | .name"); do
  yc vpc route-table delete "$name"
done

echo "==> подсети"
for name in $(yc vpc subnet list --format json \
              | jq -r ".[] | select(.name | startswith(\"$PREFIX\")) | .name"); do
  yc vpc subnet delete "$name"
done

echo "==> NAT-шлюз"
for name in $(yc vpc gateway list --format json \
              | jq -r ".[] | select(.name | startswith(\"$PREFIX\")) | .name"); do
  yc vpc gateway delete "$name"
done

echo "==> сеть"
for name in $(yc vpc network list --format json \
              | jq -r ".[] | select(.name | startswith(\"$PREFIX\")) | .name"); do
  yc vpc network delete "$name"
done