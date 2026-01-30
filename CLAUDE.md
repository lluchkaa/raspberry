# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Infrastructure-as-code repository for a Raspberry Pi running NixOS. Managed with Nix Flakes.

Key goals:
- NixOS configuration managed via flakes
- Remote NixOS installation/deployment over SSH
- Kubernetes cluster running on the Pi
- Kubernetes workloads: PiHole, custom container images

## Version Control

Uses both **Git** and **Jujutsu (jj)** for version control. The repo is hosted at `github.com/lluchkaa/raspberry`.

## Status

Project is in early planning/bootstrapping phase. No Nix configurations or Kubernetes manifests exist yet.
