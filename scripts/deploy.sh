#!/usr/bin/env bash
set -euo pipefail

# Remote NixOS rebuild
# Usage: ./scripts/deploy.sh <target-host>

TARGET="${1:?Usage: $0 <target-host>}"

nixos-rebuild switch \
  --flake ".#raspberry" \
  --target-host "ll-raspberry@${TARGET}" \
  --use-remote-sudo
