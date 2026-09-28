#!/usr/bin/env bash

set -euo pipefail

PREFIX=bezirova-04

for N in 1 2; do
  yc compute instance delete "$PREFIX-app-$N" || true
done

yc vpc subnet delete "$PREFIX-subnet" || true

yc vpc network delete "$PREFIX-net" || true