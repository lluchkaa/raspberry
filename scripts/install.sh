#!/usr/bin/env bash
set -euo pipefail

# Remote NixOS installation using nixos-anywhere
# Usage: ./scripts/install.sh <target-ip>

TARGET="${1:?Usage: $0 <target-ip>}"

nix run github:nix-community/nixos-anywhere -- \
  --flake ".#raspberry" \
  --target-host "root@${TARGET}" \
  --build-on-remote
