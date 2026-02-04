# Raspberry Pi NixOS deployment
#
# Usage:
#   make deploy     - Deploy NixOS config to Pi
#   make switch     - Apply NixOS config on already-synced repo

ADDR ?= 192.168.0.101
PORT ?= 22
REMOTE_USER ?= ll-raspberry

SSH_OPTIONS = -o PubkeyAuthentication=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
SSH = ssh $(SSH_OPTIONS) -p$(PORT)
KUBECONFIG = /etc/rancher/k3s/k3s.yaml

DOCKER_REPO ?= lluchkaa

.PHONY: deploy switch copy helm-repos k8s k8s-openclaw k8s-pihole k8s-monitoring docker-openclaw

# Sync repo and apply NixOS config
deploy: copy switch

# Copy flake to remote
copy:
	rsync -av -e "ssh $(SSH_OPTIONS) -p$(PORT)" \
		--exclude='.git' \
		--exclude='result' \
		--exclude='.direnv' \
		. $(REMOTE_USER)@$(ADDR):~/raspberry/

# Apply NixOS configuration
switch:
	$(SSH) $(REMOTE_USER)@$(ADDR) 'sudo nixos-rebuild switch --flake ~/raspberry#raspberry'

# Kubernetes deployments
k8s: k8s-openclaw k8s-monitoring k8s-pihole

helm-repos:
	$(SSH) $(REMOTE_USER)@$(ADDR) ' \
		helm repo add mojo2600 https://mojo2600.github.io/pihole-kubernetes/ 2>/dev/null || true && \
		helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true && \
		helm repo update \
	'

k8s-openclaw: copy
	$(SSH) $(REMOTE_USER)@$(ADDR) 'KUBECONFIG=$(KUBECONFIG) kubectl apply -k ~/raspberry/k8s/openclaw'

k8s-pihole: copy helm-repos
	$(SSH) $(REMOTE_USER)@$(ADDR) ' \
		KUBECONFIG=$(KUBECONFIG) helm upgrade --install pihole mojo2600/pihole \
			--namespace pihole --create-namespace \
			-f ~/raspberry/k8s/pihole/values.yaml && \
		KUBECONFIG=$(KUBECONFIG) kubectl apply -k ~/raspberry/k8s/pihole \
	'

k8s-monitoring: copy helm-repos
	$(SSH) $(REMOTE_USER)@$(ADDR) ' \
		KUBECONFIG=$(KUBECONFIG) helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
			--namespace monitoring --create-namespace \
			-f ~/raspberry/k8s/monitoring/values.yaml \
	'

# Docker builds
docker-openclaw:
	docker build -t $(DOCKER_REPO)/openclaw:latest docker/openclaw
	docker push $(DOCKER_REPO)/openclaw:latest
