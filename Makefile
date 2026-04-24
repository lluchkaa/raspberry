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

.PHONY: deploy switch copy flux-bootstrap pihole-secret

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
		kubectl create namespace pihole --dry-run=client -o yaml | kubectl apply -f - && \
		kubectl create secret generic pihole-admin -n pihole \
			--from-literal=password=$(PIHOLE_PASSWORD) \
			--dry-run=client -o yaml | kubectl apply -f - \
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
