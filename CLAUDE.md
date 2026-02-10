# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Infrastructure-as-code repository for a **Raspberry Pi 5** (aarch64-linux) running NixOS. Managed with Nix Flakes.

Key goals:
- NixOS configuration managed via flakes
- Deployment via rsync + `nixos-rebuild switch` (Makefile targets)
- Kubernetes (k3s) single-node cluster
- Workloads: PiHole, monitoring (Prometheus + Grafana), OpenClaw AI assistant
- Docker image builds for custom workloads (pushed to Docker Hub)

## Version Control

Uses both **Git** and **Jujutsu (jj)** for version control. The repo is hosted at `github.com/lluchkaa/raspberry`.

## Key Conventions

- **Flake input**: `nixos-raspberrypi` (nvmd fork) — sole input, provides nixpkgs and Pi-specific modules
- **System builder**: `nixos-raspberrypi.lib.nixosSystemFull` called directly in `flake.nix` — no wrapper; there is only one host
- **Username**: `ll-raspberry` (not `lluchkaa` — that's the workstation user)
- **Module structure**: Flat `nix/os/*.nix` files — no `core/`+`optional/` hierarchy
- **No home-manager, no overlays, no desktop tools** — this is a minimal server
- **Packages**: Keep minimal — only what the server needs
- **SSH**: Root login disabled; key-based auth configured
- **Deployment**: `make deploy` (rsync to Pi + nixos-rebuild switch); `make k8s` for workloads
- **K8s manifests**: `k8s/` — Kustomize for OpenClaw, Helm values for PiHole and monitoring
- **Docker builds**: `docker/openclaw/` — custom image pushed to `lluchkaa/openclaw`

## Status

NixOS config, k8s manifests, and deployment tooling are functional.
