# Raspberry Pi Infrastructure — Requirements

## 1. NixOS System Configuration

- Declarative NixOS config managed via **Nix Flakes**
- Pi-specific hardware config (boot, firmware, ARM64) via `nixos-raspberrypi`
- DHCP networking with firewall rules (SSH, DNS, HTTP/HTTPS, K8s API)
- User accounts and SSH authorized keys

## 2. Deployment

- Build NixOS SD image via Docker (`scripts/build-image.sh`)
- Deploy NixOS config to Pi via rsync + `nixos-rebuild switch` (`make deploy`)
- Deploy k8s workloads via `make k8s` (Helm and Kustomize)
- Rollback support (built into NixOS generations)

## 3. Kubernetes (k3s)

- **k3s** single-node cluster provisioned via NixOS module
- Traefik disabled — services exposed directly via LoadBalancer/ClusterIP
- Local-path-provisioner for persistent volumes (SD card storage)
- Helm and Kustomize for workload management

## 4. Workloads

### PiHole
- Deployed via Helm chart (`mojo2600/pihole`)
- Exposed on the Pi's IP as the network DNS server (LoadBalancer)
- Persistent storage for config/query logs
- Prometheus exporter sidecar for metrics

### OpenClaw
- Personal AI assistant — deployed via Kustomize manifests
- Docker image prebuilt and pushed to Docker Hub (`lluchkaa/openclaw`)
- Gateway and bridge ports exposed as ClusterIP

### Monitoring
- Lightweight stack suitable for single-Pi resources
- **Prometheus** (metrics collection) + **Grafana** (dashboards)
- Deployed via Helm chart (`kube-prometheus-stack`)
- Key metrics: CPU, memory, disk, pod health, DNS query rates (PiHole)

## 5. Repo Structure

```
.
├── flake.nix                  # Nix flake entry point
├── flake.lock
├── Makefile                   # Deployment & k8s targets
├── nix/
│   └── os/
│       ├── default.nix        # Main NixOS config (imports all modules)
│       ├── hardware.nix       # Pi hardware specifics
│       ├── networking.nix     # DHCP, firewall
│       ├── k3s.nix            # k3s service config
│       ├── nix.nix            # Nix settings, cachix, GC
│       ├── pkgs/
│       │   └── default.nix    # System packages
│       └── user.nix           # User account config
├── k8s/
│   ├── openclaw/              # OpenClaw Kustomize manifests
│   ├── pihole/                # PiHole Helm values + secret
│   └── monitoring/            # kube-prometheus-stack Helm values
├── docker/
│   └── openclaw/              # Dockerfile & build script
├── scripts/
│   └── build-image.sh         # Docker-based NixOS SD image builder
├── secrets/
│   └── wireless-env           # WiFi credentials
└── docs/
    ├── requirements.md        # This file
    └── architecture.md        # Architecture decisions
```

## 6. Out of Scope (for now)

- Multi-node cluster
- USB SSD / advanced storage
- Automated backups
- GitOps (Flux/ArgoCD) — using Helm/Kustomize directly for now
- CI/CD pipeline
