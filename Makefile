# Raspberry Pi Home Manager deployment
#
# Usage:
#   make install    - Install Nix on the Pi
#   make deploy     - Deploy Home Manager config
#   make switch     - Apply config on already-synced repo

ADDR ?= 192.168.0.101
PORT ?= 22
REMOTE_USER ?= ll-raspberry

SSH_OPTIONS = -o PubkeyAuthentication=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
SSH = ssh $(SSH_OPTIONS) -p$(PORT)
NIX_CONFIG = experimental-features = nix-command flakes
KUBECONFIG = /etc/rancher/k3s/k3s.yaml

DOCKER_REPO ?= lluchkaa

.PHONY: install deploy switch copy k8s k8s-openclaw k8s-pihole k8s-monitoring docker-openclaw

# Install Nix on Raspberry Pi OS
install:
	$(SSH) $(REMOTE_USER)@$(ADDR) ' \
		if command -v nix &> /dev/null; then \
			echo "Nix is already installed"; \
		else \
			sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon \
			echo "Nix installed. Log out and back in, then run: make deploy"; \
		fi \
	'

# Sync repo and apply Home Manager config
deploy: copy switch

# Copy flake to remote
copy:
	rsync -av -e "ssh $(SSH_OPTIONS) -p$(PORT)" \
		--exclude='.git' \
		--exclude='result' \
		--exclude='.direnv' \
		. $(REMOTE_USER)@$(ADDR):~/raspberry/

# Apply Home Manager configuration
switch:
	$(SSH) $(REMOTE_USER)@$(ADDR) ' \
		cd ~/raspberry && \
		NIX_CONFIG="$(NIX_CONFIG)" nix run home-manager -- switch --flake .#$(REMOTE_USER) \
	'

# Kubernetes deployments
k8s: k8s-openclaw k8s-pihole k8s-monitoring

k8s-openclaw: copy
	$(SSH) $(REMOTE_USER)@$(ADDR) 'KUBECONFIG=$(KUBECONFIG) kubectl apply -k ~/raspberry/k8s/openclaw'

k8s-pihole: copy
	$(SSH) $(REMOTE_USER)@$(ADDR) ' \
		KUBECONFIG=$(KUBECONFIG) kubectl apply -k ~/raspberry/k8s/pihole && \
		KUBECONFIG=$(KUBECONFIG) helm upgrade --install pihole mojo2600/pihole \
			--namespace pihole --create-namespace \
			-f ~/raspberry/k8s/pihole/values.yaml \
	'

k8s-monitoring: copy
	$(SSH) $(REMOTE_USER)@$(ADDR) ' \
		KUBECONFIG=$(KUBECONFIG) helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
			--namespace monitoring --create-namespace \
			-f ~/raspberry/k8s/monitoring/values.yaml \
	'

# Docker builds
docker-openclaw:
	docker build -t $(DOCKER_REPO)/openclaw:latest docker/openclaw
	docker push $(DOCKER_REPO)/openclaw:latest
