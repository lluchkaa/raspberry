# Raspberry Pi NixOS deployment
#
# Usage:
#   make build-image     - Build SD card image via Docker (cross-build from macOS)
#   make deploy          - Deploy NixOS config to Pi
#   make switch          - Apply NixOS config on already-synced repo
#   make pihole-secret               - Create pihole-admin secret (run once; requires PIHOLE_PASSWORD)
#   make temporal-db-secret          - Create temporal-db secret (run once; requires TEMPORAL_DB_PASSWORD)
#   make smartass-subscriber-secret  - Create smartass-subscriber secret (run once; requires tokens)
#   make ghcr-secret                 - Create ghcr.io pull secret (run once; requires GITHUB_TOKEN with read:packages)
#   make e-queue-secret              - Create e-queue secret (run once; requires tokens)
#   make e-queue-key                 - Upload the e-queue login key file (run once; rotate on key renewal)
#   make flux-bootstrap  - Bootstrap Flux GitOps (run once; requires GITHUB_TOKEN)
#
# After flux-bootstrap, k8s workloads are managed automatically on git push.

ADDR ?= 192.168.0.101
PORT ?= 22
REMOTE_USER ?= ll-raspberry

SSH_OPTIONS = -o PubkeyAuthentication=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
SSH = ssh $(SSH_OPTIONS) -p$(PORT)
KUBECONFIG = /etc/rancher/k3s/k3s.yaml

GITHUB_TOKEN ?= CHANGE_ME
GITHUB_OWNER ?= lluchkaa
GITHUB_REPO  ?= raspberry

TAILSCALE_AUTHKEY_FILE ?= secrets/tailscale-authkey

PIHOLE_PASSWORD ?= CHANGE_ME

TEMPORAL_DB_PASSWORD ?= CHANGE_ME

CAPACITOR_LICENSE_KEY       ?= CHANGE_ME
CAPACITOR_SESSION_HASH_KEY  ?= CHANGE_ME
CAPACITOR_SESSION_BLOCK_KEY ?= CHANGE_ME

SMARTASS_TELEGRAM_BOT_TOKEN  ?= CHANGE_ME
SMARTASS_TELEGRAM_USER_IDS   ?= CHANGE_ME
SMARTASS_TEMPORAL_HOST       ?= temporal-frontend:7233
SMARTASS_TEMPORAL_NAMESPACE  ?= cronjobs
SMARTASS_URL                 ?= https://smartass.club/lviv-myrnoho/calendar

EQUEUE_KEY_FILE             ?= secrets/e-queue-key
EQUEUE_KEY_PASSWORD         ?= CHANGE_ME
EQUEUE_KEY_PROVIDER         ?= КНЕДП АЦСК АТ КБ "ПриватБанк"
EQUEUE_TELEGRAM_BOT_TOKEN   ?= CHANGE_ME
EQUEUE_TELEGRAM_USER_IDS    ?= CHANGE_ME
EQUEUE_TEMPORAL_HOST        ?= temporal-frontend:7233
EQUEUE_TEMPORAL_NAMESPACE   ?= e-queue
EQUEUE_SERVICE_ID           ?= 47
EQUEUE_TARGET_CITY          ?= м. Львів

.PHONY: build-image deploy switch copy flux-bootstrap pihole-secret temporal-db-secret capacitor-next-secret smartass-subscriber-secret ghcr-secret e-queue-secret e-queue-key tailscale-authkey wireless-secret secrets status k3s-rotate-certs k3s-reset reconcile restart-pod hooks

# Build SD image inside a linux/arm64 Docker container (works from aarch64-darwin)
# Result image lands in ./result-image/ on the host.
build-image:
	mkdir -p result-image
	docker run --rm \
		--platform linux/arm64 \
		-v "$(CURDIR):/repo" \
		-v nix-store:/nix \
		-w /repo \
		nixos/nix \
		sh -c "nix build .#images.raspberry \
			--extra-experimental-features 'nix-command flakes' \
			--always-allow-substitutes \
			--accept-flake-config && \
			cp -L --remove-destination result/sd-image/*.img* /repo/result-image/ && \
			chmod u+w /repo/result-image/*.img*"

# Install pre-commit hooks (requires pre-commit: nix shell nixpkgs#pre-commit)
hooks:
	nix shell nixpkgs#pre-commit --command pre-commit install

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
	$(SSH) $(REMOTE_USER)@$(ADDR) 'sudo nixos-rebuild switch --flake ~/raspberry#raspberry --accept-flake-config' --verbose

# Copy WiFi credentials to Pi (run once before nixos-rebuild switch)
wireless-secret:
	$(SSH) $(REMOTE_USER)@$(ADDR) 'sudo mkdir -p /var/lib/secrets'
	scp -P$(PORT) $(SSH_OPTIONS) secrets/wireless-env $(REMOTE_USER)@$(ADDR):/tmp/wireless-env
	$(SSH) $(REMOTE_USER)@$(ADDR) 'sudo install -m 640 -o root -g wpa_supplicant /tmp/wireless-env /var/lib/secrets/wireless-env && rm -f /tmp/wireless-env && sudo systemctl restart wpa_supplicant'

# Copy Tailscale auth key to Pi (run once; rotate every 90 days)
tailscale-authkey:
	$(SSH) $(REMOTE_USER)@$(ADDR) 'sudo install -m 600 -o root /dev/null /etc/tailscale-authkey'
	$(SSH) $(REMOTE_USER)@$(ADDR) 'cat > /tmp/tailscale-authkey' < $(TAILSCALE_AUTHKEY_FILE)
	$(SSH) $(REMOTE_USER)@$(ADDR) 'sudo mv /tmp/tailscale-authkey /etc/tailscale-authkey && sudo chmod 600 /etc/tailscale-authkey'

# Create pihole-admin secret (run once before flux-bootstrap)
pihole-secret:
	@$(SSH) $(REMOTE_USER)@$(ADDR) ' \
		kubectl create namespace apps --dry-run=client -o yaml | kubectl apply -f - && \
		kubectl create secret generic pihole-admin -n apps \
			--from-literal=password="$(PIHOLE_PASSWORD)" \
			--dry-run=client -o yaml | kubectl apply -f - \
	'

capacitor-next-secret:
	@$(SSH) $(REMOTE_USER)@$(ADDR) ' \
		kubectl create namespace flux-system --dry-run=client -o yaml | kubectl apply -f - && \
		kubectl create secret generic capacitor -n flux-system \
			--from-literal=LICENSE_KEY="$(CAPACITOR_LICENSE_KEY)" \
			--from-literal=SESSION_HASH_KEY="$(CAPACITOR_SESSION_HASH_KEY)" \
			--from-literal=SESSION_BLOCK_KEY="$(CAPACITOR_SESSION_BLOCK_KEY)" \
			--from-literal=registry.yaml="$$(printf "clusters:\n- id: in-cluster\n  name: In-cluster\n  apiServerURL: https://kubernetes.default.svc\n  certificateAuthorityFile: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt\n  serviceAccount:\n    tokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token")" \
			--dry-run=client -o yaml | kubectl apply -f -\
	'

smartass-subscriber-secret:
	@$(SSH) $(REMOTE_USER)@$(ADDR) ' \
		kubectl create namespace apps --dry-run=client -o yaml | kubectl apply -f - && \
		kubectl create secret generic smartass-subscriber -n apps \
			--from-literal=TELEGRAM_BOT_TOKEN="$(SMARTASS_TELEGRAM_BOT_TOKEN)" \
			--from-literal=TELEGRAM_USER_IDS='"'"'$(SMARTASS_TELEGRAM_USER_IDS)'"'"' \
			--from-literal=TEMPORAL_HOST="$(SMARTASS_TEMPORAL_HOST)" \
			--from-literal=TEMPORAL_NAMESPACE="$(SMARTASS_TEMPORAL_NAMESPACE)" \
			--from-literal=SMARTASS_URL="$(SMARTASS_URL)" \
			--dry-run=client -o yaml | kubectl apply -f - \
	'

# Pull secret for private ghcr.io packages (e-queue). GITHUB_TOKEN needs read:packages.
ghcr-secret:
	@$(SSH) $(REMOTE_USER)@$(ADDR) ' \
		kubectl create namespace apps --dry-run=client -o yaml | kubectl apply -f - && \
		kubectl create secret docker-registry ghcr -n apps \
			--docker-server=ghcr.io \
			--docker-username=$(GITHUB_OWNER) \
			--docker-password="$(GITHUB_TOKEN)" \
			--dry-run=client -o yaml | kubectl apply -f - \
	'

e-queue-secret:
	@$(SSH) $(REMOTE_USER)@$(ADDR) ' \
		kubectl create namespace apps --dry-run=client -o yaml | kubectl apply -f - && \
		kubectl create secret generic e-queue -n apps \
			--from-literal=LOGIN_KEY_PASSWORD="$(EQUEUE_KEY_PASSWORD)" \
			--from-literal=LOGIN_KEY_PROVIDER='"'"'$(EQUEUE_KEY_PROVIDER)'"'"' \
			--from-literal=TELEGRAM_BOT_TOKEN="$(EQUEUE_TELEGRAM_BOT_TOKEN)" \
			--from-literal=TELEGRAM_USER_IDS='"'"'$(EQUEUE_TELEGRAM_USER_IDS)'"'"' \
			--from-literal=TEMPORAL_HOST="$(EQUEUE_TEMPORAL_HOST)" \
			--from-literal=TEMPORAL_NAMESPACE="$(EQUEUE_TEMPORAL_NAMESPACE)" \
			--from-literal=EQUEUE_SERVICE_ID="$(EQUEUE_SERVICE_ID)" \
			--from-literal=EQUEUE_TARGET_CITY="$(EQUEUE_TARGET_CITY)" \
			--dry-run=client -o yaml | kubectl apply -f - \
	'

e-queue-key:
	@scp -P$(PORT) $(SSH_OPTIONS) $(EQUEUE_KEY_FILE) $(REMOTE_USER)@$(ADDR):/tmp/e-queue-key
	@$(SSH) $(REMOTE_USER)@$(ADDR) ' \
		kubectl create namespace apps --dry-run=client -o yaml | kubectl apply -f - && \
		kubectl create secret generic e-queue-key -n apps \
			--from-file=key=/tmp/e-queue-key \
			--dry-run=client -o yaml | kubectl apply -f - ; \
		rm -f /tmp/e-queue-key \
	'

secrets: pihole-secret temporal-db-secret capacitor-next-secret smartass-subscriber-secret ghcr-secret e-queue-secret e-queue-key

temporal-db-secret:
	@$(SSH) $(REMOTE_USER)@$(ADDR) ' \
		kubectl create namespace apps --dry-run=client -o yaml | kubectl apply -f - && \
		kubectl create secret generic temporal-db -n apps \
			--from-literal=password="$(TEMPORAL_DB_PASSWORD)" \
			--dry-run=client -o yaml | kubectl apply -f - \
	'

# Rotate k3s TLS certificates (run when certs expire ~annually; restarts k3s)
k3s-rotate-certs:
	$(SSH) $(REMOTE_USER)@$(ADDR) 'sudo k3s certificate rotate && sudo systemctl restart k3s'

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

# Restart a deployment to pull the latest image (usage: make restart-pod POD=e-queue)
restart-pod:
	$(SSH) $(REMOTE_USER)@$(ADDR) 'KUBECONFIG=$(KUBECONFIG) kubectl rollout restart deployment/$(POD) -n apps'

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
	@$(SSH) $(REMOTE_USER)@$(ADDR) ' \
		GITHUB_TOKEN=$(GITHUB_TOKEN) \
		KUBECONFIG=$(KUBECONFIG) \
		flux bootstrap github \
			--owner=$(GITHUB_OWNER) \
			--repository=$(GITHUB_REPO) \
			--branch=main \
			--path=k8s \
			--personal \
	'
