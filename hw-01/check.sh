#!/usr/bin/env bash
set -uo pipefail

PREFIX=bezirova-04
APP_PORT=8012

LB_IP=$(yc load-balancer network-load-balancer get --name "$PREFIX-lb" \
  --format json 2>/dev/null | jq -r '.listeners[0].address // empty' 2>/dev/null || true)
APP_IP=$(yc compute instance get "$PREFIX-app-1" --format json 2>/dev/null \
  | jq -r '.network_interfaces[0].primary_v4_address.address // empty' 2>/dev/null || true)

RC=0

echo "==> проверка 1: балансировщик отвечает 200"
if [ -z "$LB_IP" ]; then
  echo "FAIL балансировщик ответил: 000"
  RC=1
else
  CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "http://$LB_IP")
  if [ "$CODE" = "200" ]; then
    echo "OK  балансировщик отвечает: $CODE"
  else
    echo "FAIL балансировщик ответил: $CODE"
    RC=1
  fi
fi

echo "==> проверка 2: отвечает больше одной машины"
HOSTS=$(for i in $(seq 1 10); do
          curl -s --max-time 5 "http://$LB_IP"
        done | grep -o "${PREFIX}-web-[0-9]" | sort -u)
N=$(printf '%s\n' "$HOSTS" | grep -c .)
if [ "$N" -gt 1 ]; then
  echo "OK  ответили машины: $(printf '%s' "$HOSTS" | tr '\n' ' ')"
else
  echo "FAIL ответила одна машина: $HOSTS"
  RC=1
fi

echo "==> проверка 3: app-машина доступна с web-1 по внутреннему адресу"
WEB1_IP=$(yc compute instance get "$PREFIX-web-1" --format json 2>/dev/null \
  | jq -r '.network_interfaces[0].primary_v4_address.one_to_one_nat.address // empty' 2>/dev/null || true)
if [ -z "$WEB1_IP" ]; then
  echo "FAIL сервер приложения недоступен с web-1"
  RC=1
elif ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "student@$WEB1_IP" \
     "curl -s --max-time 5 http://$APP_IP:$APP_PORT | grep -q devlab" 2>/dev/null; then
  echo "OK  сервер приложения доступен с web-1"
else
  echo "FAIL сервер приложения недоступен с web-1"
  RC=1
fi

exit $RC