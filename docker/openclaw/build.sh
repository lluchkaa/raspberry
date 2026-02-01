#!/usr/bin/env bash
set -euo pipefail

IMAGE="lluchkaa/openclaw"
TAG="${1:-latest}"
OPENCLAW_REPO="https://github.com/openclaw/openclaw.git"
WORKDIR="$(mktemp -d)"

trap 'rm -rf "$WORKDIR"' EXIT

echo "Cloning openclaw..."
git clone --depth 1 "$OPENCLAW_REPO" "$WORKDIR/openclaw"

echo "Building image ${IMAGE}:${TAG} for linux/arm64..."
docker buildx build \
  --platform linux/arm64 \
  -f "$(dirname "$0")/Dockerfile" \
  -t "${IMAGE}:${TAG}" \
  --push \
  "$WORKDIR/openclaw"
