# Deploying Custom Apps to k8s/apps Namespace

## Overview

Stack: **GitHub Actions** builds + pushes OCI image → **GitHub Container Registry (ghcr.io)** stores it → **Flux** deploys via `HelmRelease` or plain `Deployment` manifest in `k8s/releases/`.

---

## Step 1: Build & Publish Container Image

### Option A: GitHub Actions (recommended)

Create `.github/workflows/docker.yml` in your app repo:

```yaml
name: Build and Push

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v4

      - name: Log in to ghcr.io
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Set up QEMU (for aarch64 cross-build)
        uses: docker/setup-qemu-action@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          platforms: linux/arm64        # Pi 5 is aarch64
          push: true
          tags: |
            ghcr.io/lluchkaa/MY-APP:latest
            ghcr.io/lluchkaa/MY-APP:${{ github.sha }}
```

Image lands at `ghcr.io/lluchkaa/MY-APP:latest`. Public by default if repo is public; make it public in GitHub → Packages → visibility if private.

### Option B: Build locally on Mac, push manually

```bash
docker buildx build \
  --platform linux/arm64 \
  --push \
  -t ghcr.io/lluchkaa/MY-APP:latest \
  .
```

Requires `docker login ghcr.io` first (use a GitHub PAT with `write:packages`).

---

## Step 2: Add k8s Manifests

### Simple Deployment (no Helm)

Create `k8s/releases/MY-APP.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: apps
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
        - name: my-app
          image: ghcr.io/lluchkaa/MY-APP:latest
          ports:
            - containerPort: 8080
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 200m
              memory: 128Mi
---
apiVersion: v1
kind: Service
metadata:
  name: my-app
  namespace: apps
spec:
  selector:
    app: my-app
  ports:
    - port: 8080
      targetPort: 8080
```

### Expose via Traefik

Pick a free port (currently used: 8081 pihole, 3000 grafana, 8233 temporal, 9000 capacitor).

Add to `k8s/releases/traefik-config.yaml` under `spec.valuesContent.ports`:

```yaml
    my-app:
      port: 8082
      expose:
        default: true
      exposedPort: 8082
      protocol: TCP
```

Add IngressRoute at bottom of `traefik-config.yaml`:

```yaml
---
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: my-app
  namespace: apps
spec:
  entryPoints:
    - my-app
  routes:
    - match: PathPrefix(`/`)
      kind: Rule
      services:
        - name: my-app
          port: 8080
```

App reachable at `raspberry.home:8082`.

---

## Step 3: Auto-Update Images (optional)

Flux **Image Automation** watches the registry and bumps the image tag in git automatically.

### Add ImageRepository + ImagePolicy

```yaml
# k8s/releases/MY-APP-image.yaml
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImageRepository
metadata:
  name: my-app
  namespace: flux-system
spec:
  image: ghcr.io/lluchkaa/MY-APP
  interval: 5m
---
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImagePolicy
metadata:
  name: my-app
  namespace: flux-system
spec:
  imageRepositoryRef:
    name: my-app
  policy:
    semver:
      range: ">=0.0.1"   # or use 'latest' filter
```

### Mark the image field for auto-update

In your `Deployment`, add marker comment:

```yaml
          image: ghcr.io/lluchkaa/MY-APP:latest # {"$imagepolicy": "flux-system:my-app"}
```

Flux commits the new tag back to this repo on each new image push.

> Requires `image-reflector-controller` and `image-automation-controller` installed in flux-system. Check with:
> ```bash
> kubectl get deploy -n flux-system | grep image
> ```

---

## Checklist

- [ ] `Dockerfile` with `FROM --platform=linux/arm64` or multi-platform base
- [ ] GitHub Actions workflow pushes `linux/arm64` image to ghcr.io
- [ ] `k8s/releases/MY-APP.yaml` with Deployment + Service in `apps` namespace
- [ ] (optional) Port added to `traefik-config.yaml` + IngressRoute
- [ ] `make k8s` or wait for Flux reconcile (`flux reconcile kustomization flux-system --with-source`)
