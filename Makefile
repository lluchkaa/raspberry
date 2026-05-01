# Raspberry Pi NixOS deployment
#
# Usage:
#   make deploy          - Deploy NixOS config to Pi
#   make switch          - Apply NixOS config on already-synced repo
#   make pihole-secret   - Create pihole-admin secret (run once; requires PIHOLE_PASSWORD)
#   make flux-bootstrap  - Bootstrap Flux GitOps (run once; requires GITHUB_TOKEN)
#
# After flux-bootstrap, k8s workloads are managed automatically on git push.

ADDR ?= 192.168.0.101
PORT ?= 22
REMOTE_USER ?= ll-raspberry

SSH_OPTIONS = -o PubkeyAuthentication=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
SSH = ssh $(SSH_OPTIONS) -p$(PORT)
KUBECONFIG = /etc/rancher/k3s/k3s.yaml

GITHUB_TOKEN   ?= CHANGE_ME
GITHUB_OWNER   ?= lluchkaa
GITHUB_REPO    ?= raspberry
PIHOLE_PASSWORD ?= CHANGE_ME

TEMPORAL_DB_PASSWORD ?= CHANGE_ME

CAPACITOR_LICENSE_KEY ?= CHANGE_ME
CAPACITOR_SESSION_HASH_KEY ?= CHANGE_ME
CAPACITOR_SESSION_BLOCK_KEY ?= CHANGE_ME

.PHONY: deploy switch copy flux-bootstrap pihole-secret temporal-db-secret capacitor-next-secret secrets status k3s-reset reconcile

# Sync repo and apply NixOS config
deploy: copy switch

# Copy flake to remote
copy:
	rsync -av -e "ssh $(SSH_OPTIONS) -p$(PORT)" \
		--exclude='.git' \
		--exclude='.jj' \
		--exclude='result' \
		--exclude='.direnv' \
		. $(REMOTE_USER)@$(ADDR):~/raspberry/

# Apply NixOS configuration
switch:
	$(SSH) $(REMOTE_USER)@$(ADDR) 'sudo nixos-rebuild switch --flake ~/raspberry#raspberry --accept-flake-config'

# Create pihole-admin secret (run once before flux-bootstrap)
pihole-secret:
	$(SSH) $(REMOTE_USER)@$(ADDR) ' \
		kubectl create namespace apps --dry-run=client -o yaml | kubectl apply -f - && \
		kubectl create secret generic pihole-admin -n apps \
			--from-literal=password=$(PIHOLE_PASSWORD) \
			--dry-run=client -o yaml | kubectl apply -f - \
	'

capacitor-next-secret:
	$(SSH) $(REMOTE_USER)@$(ADDR) ' \
		kubectl create namespace flux-system --dry-run=client -o yaml | kubectl apply -f - && \
		kubectl create secret generic capacitor -n flux-system \
			--from-literal=LICENSE_KEY=$(CAPACITOR_LICENSE_KEY) \
			--from-literal=SESSION_HASH_KEY=$(CAPACITOR_SESSION_HASH_KEY) \
			--from-literal=SESSION_BLOCK_KEY=$(CAPACITOR_SESSION_BLOCK_KEY) \
			--from-literal=registry.yaml="clusters:
- id: in-cluster
  name: In-cluster
  apiServerURL: https://kubernetes.default.svc
  certificateAuthorityFile: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
  serviceAccount:
    tokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token" \
			--dry-run=client -o yaml | kubectl apply -f -\
	'

secrets: pihole-secret temporal-db-secret capacitor-next-secret

temporal-db-secret:
	$(SSH) $(REMOTE_USER)@$(ADDR) ' \
		kubectl create namespace apps --dry-run=client -o yaml | kubectl apply -f - && \
		kubectl create secret generic temporal-db -n apps \
			--from-literal=password=$(TEMPORAL_DB_PASSWORD) \
			--dry-run=client -o yaml | kubectl apply -f - \
	'

# Wipe all k3s state and restart (nuclear reset; re-run flux-bootstrap + secrets after)
k3s-reset:
	$(SSH) $(REMOTE_USER)@$(ADDR) ' \
		sudo systemctl stop k3s && \
		sudo rm -rf /var/lib/rancher /etc/rancher /var/lib/cni && \
		sudo systemctl start k3s \
	'

# Show cluster status: Flux sync + all pods
status:
	$(SSH) $(REMOTE_USER)@$(ADDR) ' \
		KUBECONFIG=$(KUBECONFIG) kubectl get helmrelease -A && \
		echo "" && \
		KUBECONFIG=$(KUBECONFIG) kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded 2>/dev/null || true && \
		echo "" && \
		KUBECONFIG=$(KUBECONFIG) kubectl get pods -A \
	'

# Force Flux to reconcile immediately
reconcile:
	$(SSH) $(REMOTE_USER)@$(ADDR) ' \
		KUBECONFIG=$(KUBECONFIG) \
		flux reconcile kustomization flux-system --with-source \
	'

# Bootstrap Flux (run once after initial deploy)
# Requires: GITHUB_TOKEN env var with repo write access
# Creates deploy key in GitHub, installs Flux controllers, commits flux-system/ manifests
flux-bootstrap:
	$(SSH) $(REMOTE_USER)@$(ADDR) ' \
		GITHUB_TOKEN=$(GITHUB_TOKEN) \
		KUBECONFIG=$(KUBECONFIG) \
		flux bootstrap github \
			--owner=$(GITHUB_OWNER) \
			--repository=$(GITHUB_REPO) \
			--branch=main \
			--path=k8s \
			--personal \
	'
