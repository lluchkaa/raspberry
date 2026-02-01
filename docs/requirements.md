# Raspberry Pi Infrastructure — Requirements

## 1. NixOS System Configuration

- Declarative NixOS config managed via **Nix Flakes**
- Pi-specific hardware config (boot, firmware, ARM64)
- Static IP assignment for reliable DNS (PiHole)
- Firewall rules (SSH, DNS, HTTP/HTTPS, K8s API)
- User accounts and SSH authorized keys

## 2. Remote Deployment

- Install NixOS on the Pi over SSH (nixos-anywhere or custom script)
- Rebuild/redeploy NixOS config remotely (`nixos-rebuild switch --target-host`)
- Rollback support (built into NixOS generations)

## 3. Kubernetes (k3s)

- **k3s** single-node cluster provisioned via NixOS module
- Traefik ingress (ships with k3s) for service access
- Local-path-provisioner for persistent volumes (SD card storage)
- Helm as the package manager for workloads

## 4. Workloads

### PiHole
- Deployed via Helm chart
- Exposed on the Pi's static IP as the network DNS server
- Persistent storage for config/query logs

### OpenClaw
- Personal AI assistant — deployed via Kustomize manifests
- Docker image prebuilt and pushed to Docker Hub (`lluchkaa/openclaw`)

### Custom Images
- Built and pushed to Docker Hub (`lluchkaa/`)
- Deployed via manifests stored in this repo

## 5. Secrets Management

- **sops-nix** for NixOS-level secrets (SSH keys, passwords)
- **sealed-secrets** or **SOPS with Flux/Helm** for Kubernetes secrets
- Age or GPG key for encryption; public key committed, private key stays on Pi

## 6. Monitoring

- Lightweight stack suitable for single-Pi resources
- **Prometheus** (metrics collection) + **Grafana** (dashboards)
- Deployed via Helm charts
- Key metrics: CPU, memory, disk, pod health, DNS query rates (PiHole)
- Alerts optional (can add later)

## 7. Repo Structure (proposed)

```
.
├── flake.nix                  # Nix flake entry point
├── flake.lock
├── nix/
│   ├── lib/
│   │   └── make.nix           # Curried system builder
│   └── os/
│       ├── default.nix        # Main NixOS config (imports all modules)
│       ├── hardware.nix       # Pi hardware specifics
│       ├── networking.nix     # Static IP, firewall
│       ├── k3s.nix            # k3s service config
│       ├── secrets.nix        # sops-nix integration
│       ├── nix.nix            # Nix settings, cachix, GC
│       ├── pkgs.nix           # System packages
│       └── user.nix           # User account config
├── k8s/
│   ├── pihole/                # PiHole Helm values
│   ├── monitoring/            # Prometheus + Grafana Helm values
│   └── apps/                  # Custom app Helm values
├── scripts/
│   ├── install.sh             # Remote NixOS install via SSH
│   └── deploy.sh              # Remote NixOS rebuild
└── docs/
    └── requirements.md        # This file
```

## 8. Out of Scope (for now)

- Multi-node cluster
- USB SSD / advanced storage
- Automated backups
- GitOps (Flux/ArgoCD) — using Helm directly for now
- CI/CD pipeline
