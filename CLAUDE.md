# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Infrastructure-as-code repository for a **Raspberry Pi 5** (aarch64-linux) running NixOS. Managed with Nix Flakes.

Key goals:
- NixOS configuration managed via flakes
- Remote NixOS installation/deployment over SSH (nixos-anywhere)
- Kubernetes (k3s) single-node cluster
- Workloads: PiHole, monitoring (Prometheus + Grafana), custom container images
- Secrets via sops-nix with Age encryption

## Version Control

Uses both **Git** and **Jujutsu (jj)** for version control. The repo is hosted at `github.com/lluchkaa/raspberry`.

## Key Conventions

- **`nix/lib/make.nix`**: Curried system builder — do not add host directories, there is only one host
- **Username**: `ll-raspberry` (not `lluchkaa` — that's the workstation user)
- **Nixpkgs**: `nixos-unstable` — all flake inputs follow nixpkgs
- **Module structure**: Flat `nix/os/*.nix` files — no `core/`+`optional/` hierarchy
- **No home-manager, no overlays, no desktop tools** — this is a minimal server
- **Packages**: Keep minimal — only what the server needs
- **SSH**: Hardened — no password auth, no root login
- **Secrets**: Age keys via sops-nix, private key at `/var/lib/sops-nix/key.txt` on Pi
- **Deployment**: Shell scripts in `scripts/`, not Makefile

## Status

Project skeleton is complete. Flake checks pass. SSH key and Age key are configured. Ready for first deployment via nixos-anywhere.
