#!/usr/bin/env bash
set -euo pipefail

# Build NixOS SD card image for Raspberry Pi using Docker
# Required: Docker with aarch64-linux support (Docker Desktop on Apple Silicon)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

echo "Building NixOS SD card image in Docker..."

docker run --rm \
  --platform linux/arm64 \
  --privileged \
  -v "$REPO_DIR:/workspace" \
  -v nix-store:/nix \
  -w /workspace \
  nixos/nix:latest \
  sh -c '
    # Configure nix
    mkdir -p ~/.config/nix /etc/nix
    cat > /etc/nix/nix.conf << EOF
experimental-features = nix-command flakes
sandbox = false
filter-syscalls = false
extra-substituters = https://nixos-raspberrypi.cachix.org https://nix-community.cachix.org
extra-trusted-public-keys = nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=
EOF

    # Build the image
    nix build .#images.raspberry --accept-flake-config --option sandbox false -L

    # Copy image to workspace (since nix store is in Docker volume)
    rm -rf /workspace/output
    mkdir -p /workspace/output/sd-image
    cp ./result/sd-image/* /workspace/output/sd-image/
    chmod -R 755 /workspace/output

    echo ""
    echo "Build complete! Image at:"
    ls -lh /workspace/output/sd-image/
  '

echo ""
echo "Image built successfully!"
echo "Decompress and flash:"
echo "  zstd -d output/sd-image/*.img.zst"
echo "  sudo dd if=output/sd-image/*.img of=/dev/rdiskX bs=4m status=progress"
