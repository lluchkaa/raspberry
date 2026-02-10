# Architecture & Decisions

## Target Hardware

Raspberry Pi 5, aarch64-linux.

## NixOS Configuration

- **Flake input**: `nixos-raspberrypi` (nvmd fork) — provides nixpkgs and Pi-specific modules
- **Boot**: extlinux/U-Boot (no GRUB), SD card root filesystem labeled `NIXOS_SD`
- **Swap**: 2 GB swapfile

## System Builder

`nixos-raspberrypi.lib.nixosSystemFull` called directly in `flake.nix`. Passes `specialArgs` (`self`, `username`, `system`, `nixos-raspberrypi`) and imports Pi modules (`raspberry-pi-5.base`, `raspberry-pi-5.page-size-16k`, `sd-image`) plus `./nix/os`.

## User

- **Username**: `ll-raspberry`
- **Config**: `nix/os/user.nix`
- **Groups**: `wheel`, `networkmanager`, `docker`
- **SSH**: key-based auth, root login disabled

## Nix Settings

- Flakes and nix-command enabled
- Cachix substituters: `nixos-raspberrypi`, `nix-community`
- Auto GC: 7-day retention

## Networking

- **Hostname**: `raspberry`
- **DHCP**: enabled (`useDHCP = true`)
- **Firewall ports**: SSH (22), DNS (53 TCP+UDP), HTTP (80), HTTPS (443), K8s API (6443)

## Kubernetes

- **Distribution**: k3s, single-node server mode
- **Default Traefik disabled**
- **Persistent storage**: local-path-provisioner (ships with k3s)

## Workloads

### PiHole
- Deployed via Helm chart (`mojo2600/pihole`)
- DNS exposed as LoadBalancer on `192.168.1.100`
- 1 GiB persistent volume for config/logs
- Prometheus exporter sidecar enabled

### Monitoring
- kube-prometheus-stack (Prometheus + Grafana)
- Lightweight resource limits tuned for Pi
- Alertmanager disabled (can enable later)
- 5 GiB Prometheus storage, 7-day retention

### OpenClaw
- Personal AI assistant ([openclaw.ai](https://openclaw.ai/))
- Docker image prebuilt and pushed to Docker Hub (`lluchkaa/openclaw`)
- Deployed via Kustomize manifests in `k8s/openclaw/`
- Gateway (18789) and bridge (18790) ports exposed as ClusterIP
- 1 GiB persistent volume for config/workspace data
- Gateway token stored in k8s Secret

## Deployment

- **NixOS config**: `make deploy` — rsync repo to Pi, then `nixos-rebuild switch`
- **K8s workloads**: `make k8s` — deploys OpenClaw (Kustomize), PiHole (Helm), monitoring (Helm)
- **SD image build**: `scripts/build-image.sh` — Docker-based NixOS SD image builder
- **Docker builds**: `make docker-openclaw` — build and push OpenClaw image
- **Rollback**: Built-in NixOS generations

## Repo Structure

```
flake.nix                     # Flake entry point
Makefile                      # Deployment & k8s targets
nix/
  os/
    default.nix               # Base system config, SSH, locale (imports all below)
    hardware.nix              # Pi 5 boot/fs config
    networking.nix            # DHCP, firewall
    k3s.nix                   # k3s service config
    nix.nix                   # Nix settings, cachix, GC
    pkgs/
      default.nix             # System packages & programs.*.enable
    user.nix                  # User account config
k8s/
  openclaw/                   # OpenClaw Kustomize manifests
  pihole/                     # PiHole Helm values + secret
  monitoring/                 # kube-prometheus-stack Helm values
docker/
  openclaw/                   # Dockerfile & build script
scripts/
  build-image.sh              # Docker-based NixOS SD image builder
secrets/
  wireless-env                # WiFi credentials (not committed to public repos)
docs/
  requirements.md             # Full requirements
  architecture.md             # This file
```

## Design Decisions

- **Direct `nixosSystemFull` call**: Single host doesn't need a curried builder abstraction. Config is defined directly in `flake.nix`.
- **`specialArgs`**: Passes `self`, `username`, `system` through the module tree so modules can reference them.
- **Flat module structure**: Single-purpose server doesn't need `core/`+`optional/` hierarchy. Flat `nix/os/*.nix` is sufficient.
- **No host directory**: Only one host, so config lives directly in `nix/os/`.
- **No home-manager**: Minimal server, no user-level desktop/shell config needed.
- **No overlays**: No custom package builds needed.
- **SSH hardened**: Root login disabled.
- **Dedicated user**: `ll-raspberry` with `wheel` group, passwordless sudo.
- **Minimal packages**: Only what's needed (vim, git, curl, htop, kubectl, helm, k9s).
- **Cachix**: `nixos-raspberrypi` and `nix-community` substituters for faster builds.
- **Auto GC**: 7-day retention.
- **Config revision tracking**: `system.configurationRevision` from git/jj rev.
