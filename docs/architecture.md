# Architecture & Decisions

## Target Hardware

Raspberry Pi 5, aarch64-linux.

## NixOS Configuration

- **Nixpkgs channel**: unstable
- **Flake inputs**: `nixpkgs`, `nixos-hardware` (raspberry-pi-5 module), `sops-nix` — `sops-nix` follows nixpkgs
- **Boot**: extlinux/U-Boot (no GRUB), SD card root filesystem labeled `NIXOS_SD`
- **Swap**: 2 GB swapfile
## `nix/lib/make.nix`

Curried system builder. First call provides flake-level context (`nixpkgs`, `inputs`), second call provides per-host config (`system`, `username`). Injects `nixos-hardware` and `sops-nix` modules, plus `nix/os/` (which includes user config).

## User

- **Username**: `ll-raspberry`
- **Config**: `nix/os/user.nix`
- **Groups**: `wheel`, `networkmanager`, `docker`
- **SSH**: key-based auth only (password auth disabled, no root login)

## Nix Settings

- Flakes and nix-command enabled
- Cachix substituters: `nix-community`, `lluchkaa`
- Auto GC: 7-day retention
- `keep-outputs` and `keep-derivations` enabled

## Networking

- **Hostname**: `raspberry`
- **Static IP**: `192.168.1.100/24`, gateway `192.168.1.1`
- **DNS upstream**: `1.1.1.1`, `8.8.8.8`
- **Firewall ports**: SSH (22), DNS (53 TCP+UDP), HTTP (80), HTTPS (443), K8s API (6443)
- **Interface**: `end0` (verify on actual hardware)

## Kubernetes

- **Distribution**: k3s, single-node server mode
- **Default Traefik disabled** — managed via Helm instead
- **Persistent storage**: local-path-provisioner (ships with k3s)

## Workloads

### PiHole
- Deployed via Helm chart
- DNS exposed as LoadBalancer on the Pi's static IP
- 1 GiB persistent volume for config/logs

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

### Custom Apps
- `k8s/apps/` placeholder for future Helm charts

## Secrets Management

- **sops-nix** for NixOS-level secrets
- **Age** encryption (public key in `.sops.yaml`, private key on Pi at `/var/lib/sops-nix/key.txt`)
- Encrypted files stored in `secrets/`

## Deployment

- **Initial install**: `scripts/install.sh` — uses nixos-anywhere over SSH
- **Updates**: `scripts/deploy.sh` — `nixos-rebuild switch --target-host`
- **Rollback**: Built-in NixOS generations

## Repo Structure

```
flake.nix                     # Flake entry point
nix/
  lib/
    make.nix                  # System builder
  os/
    default.nix               # Base system config, SSH, locale (imports all below)
    hardware.nix              # Pi 5 boot/fs config
    networking.nix            # Static IP, firewall
    k3s.nix                   # k3s service config
    secrets.nix               # sops-nix integration
    nix.nix                   # Nix settings, cachix, GC
    pkgs/
      default.nix             # System packages & programs.*.enable
    user.nix                  # User account config
secrets/                      # Encrypted secret files (sops)
.sops.yaml                    # Age key creation rules
k8s/
  pihole/values.yaml          # PiHole Helm values
  monitoring/values.yaml      # kube-prometheus-stack Helm values
  openclaw/                   # OpenClaw Kustomize manifests
  apps/                       # Future custom app charts
scripts/
  install.sh                  # Remote NixOS install (nixos-anywhere)
  deploy.sh                   # Remote nixos-rebuild
docs/
  requirements.md             # Full requirements
  architecture.md             # This file
```

## Design Decisions

- **`nix/lib/make.nix` pattern**: Curried system builder separates flake-level context from per-host config. Keeps `flake.nix` clean.
- **`specialArgs`**: Passes `self`, `username`, `system` through the module tree so modules can reference them.
- **Flat module structure**: Single-purpose server doesn't need `core/`+`optional/` hierarchy. Flat `nix/os/*.nix` is sufficient.
- **No host directory**: Only one host, so config lives directly in `nix/os/`.
- **No home-manager**: Minimal server, no user-level desktop/shell config needed.
- **No overlays**: No custom package builds needed.
- **SSH hardened**: Password auth disabled, root login disabled.
- **Dedicated user**: `ll-raspberry` with `wheel` group, passwordless sudo.
- **Unstable nixpkgs**: Using `nixos-unstable` for latest packages.
- **Minimal packages**: Only what's needed (vim, git, curl, htop, kubectl, helm, k9s).
- **Cachix**: `nix-community` and `lluchkaa` substituters for faster builds.
- **Auto GC**: 7-day retention, `keep-outputs`/`keep-derivations` enabled.
- **Config revision tracking**: `system.configurationRevision` from git/jj rev.

## TODOs

- [x] Add real SSH public key in `nix/os/user.nix`
- [ ] Generate Age key (`age-keygen`) and update `.sops.yaml` with real public key
- [x] Run `nix flake check` to validate configuration
- [ ] Copy Age private key (`secrets/age-key.txt`) to `/var/lib/sops-nix/key.txt` on the Pi
- [ ] Create `secrets/secrets.yaml` with sops-encrypted values
- [ ] Verify network interface name (`end0`) matches actual Pi 5
- [ ] Run `scripts/install.sh <pi-ip>` for first deployment via nixos-anywhere
- [ ] Build and push OpenClaw image to Docker Hub (`lluchkaa/openclaw`)
- [ ] Set real gateway token in `k8s/openclaw/secret.yaml`
- [ ] Deploy OpenClaw: `kubectl apply -k k8s/openclaw/`
