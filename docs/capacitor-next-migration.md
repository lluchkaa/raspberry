# Migrating to capacitor-next

Currently running the free OSS `capacitor` via OCIRepository + Kustomization.
`capacitor-next` has more features but requires a license key (free for self-hosting).

## Steps to migrate

### 1. Get a license key

Email laszlo@gimlet.io and ask for a self-hosted license key.

### 2. Create the RBAC resources

Apply the manifests from the capacitor GitHub repo:

```bash
kubectl apply -f https://raw.githubusercontent.com/gimlet-io/capacitor/main/self-host/yaml/capacitor-next/sa.yaml
kubectl apply -f https://raw.githubusercontent.com/gimlet-io/capacitor/main/self-host/yaml/capacitor-next/rbac-preset-clusteradmin.yaml
kubectl apply -f https://raw.githubusercontent.com/gimlet-io/capacitor/main/self-host/yaml/capacitor-next/rbac-impersonator.yaml
kubectl apply -f https://raw.githubusercontent.com/gimlet-io/capacitor/main/self-host/yaml/capacitor-next/service.yaml
```

### 3. Create the secret with LICENSE_KEY

Add a `make` target or run once on the Pi:

```bash
kubectl create namespace flux-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic capacitor-next -n flux-system \
  --from-literal=LICENSE_KEY="<your-key>" \
  --from-literal=registry.yaml="" \
  --dry-run=client -o yaml | kubectl apply -f -
```

### 4. Replace the Flux source in k8s/sources/capacitor.yaml

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: capacitor
  namespace: flux-system
spec:
  type: oci
  interval: 1h
  url: oci://ghcr.io/gimlet-io/charts
```

### 5. Replace the HelmRelease in k8s/releases/capacitor.yaml

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: capacitor
  namespace: flux-system
spec:
  interval: 1h
  install:
    timeout: 15m
    createNamespace: true
  upgrade:
    timeout: 15m
  chart:
    spec:
      chart: capacitor-next
      sourceRef:
        kind: HelmRepository
        name: capacitor
        namespace: flux-system
      interval: 1h
  values:
    env:
      LICENSE_KEY: ""        # set via existingSecret instead
      AUTH: noauth
      IMPERSONATE_SA_RULES: "noauth=flux-system:capacitor-next-preset-clusteradmin"
      AZURE_WORKLOAD_IDENTITY_ENABLED: "false"
    existingSecret:
      name: capacitor-next
    resources:
      requests:
        cpu: 50m
        memory: 128Mi
      limits:
        cpu: 200m
        memory: 512Mi
```

> Use `existingSecret.name: capacitor-next` so LICENSE_KEY stays out of git.

### 6. Commit and push — Flux will reconcile automatically
