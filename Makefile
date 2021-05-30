# Allow compilation for target OS
GOOS := $(shell go env GOOS)
GOARCH := $(shell go env GOARCH)

## Include environment config
include envs.mk

# Ensure local binaries in bin take precedence when running targets
BIN_PATH := $(CURDIR)/bin
PATH := $(BIN_PATH):$(PATH)
export PATH

SHELL := env PATH=$(PATH) $(SHELL)

kind_url := https://github.com/kubernetes-sigs/kind/releases/download/v0.11.0/kind-$(GOOS)-$(GOARCH)
kubectl_url := https://dl.k8s.io/v1.21.1/kubernetes-client-$(GOOS)-$(GOARCH).tar.gz
cilium_url := https://github.com/cilium/cilium-cli/releases/latest/download/cilium-$(GOOS)-$(GOARCH).tar.gz
hubble_url := https://github.com/cilium/hubble/releases/download/v0.8.0/hubble-$(GOOS)-$(GOARCH).tar.gz

all: kind resources

kind: $(kind_kubeconfig) ## Spin up local kind cluster

# Kind - https://kind.sigs.k8s.io/
$(kind_kubeconfig): $(BIN_PATH)/kind
	echo $(kind_kubeconfig)
	kind create cluster --config=$(kind_config) --name=$(kind_cluster_name)
	kind export kubeconfig --name $(kind_cluster_name) --kubeconfig $(kind_kubeconfig)
	@echo "Waiting for nodes to become ready..."
	kubectl wait --for=condition=Ready nodes --timeout=60s --all

kind-teardown: $(BIN_PATH)/kind ## Remove local kind cluster
ifneq (true,$(kind_delete_cluster))
	@echo "Skipping kind cluster deletion... (kind_delete_cluster=$(kind_delete_cluster))"
else ifneq (,$(wildcard $(kind_kubeconfig)))
	printf "\nCleaning up kind...\n"
	kind delete cluster --name $(kind_cluster_name)
	rm -f $(kind_kubeconfig)
else 
	@echo "kind cluster $(kind_cluster_name) does not exist"
endif

.PHONY: resources
resources: $(BIN_PATH)/kubectl
	kubectl apply -k resources

admin_token:
	kubectl get secret -n kube-system cluster-admin-token -o jsonpath='{.data.token}' | base64 -d 

cilium: $(BIN_PATH)/cilium
	cilium install 
	cilium status --wait
	cilium connectivity test

hubble: $(BIN_PATH)/hubble
	cilium hubble enable

$(BIN_PATH)/kind:
	@echo "== install kind"
	@mkdir -p $(BIN_PATH)
	@curl --fail -sL $(kind_url) --output $(BIN_PATH)/kind
	@chmod +x $(BIN_PATH)/kind

$(BIN_PATH)/kubectl:
	@echo "== install kubectl"
	@mkdir -p $(BIN_PATH)
	@curl --fail -sL $(kubectl_url) | tar -xz -C $(BIN_PATH)
	@mv $(BIN_PATH)/kubernetes/client/bin/kubectl $(BIN_PATH)
	@chmod +x $(BIN_PATH)/kubectl
	@rm -rf $(BIN_PATH)/kubernetes

$(BIN_PATH)/cilium:
	@echo "== install cilium"
	@mkdir -p $(BIN_PATH)
	@curl --fail -sL $(cilium_url) | tar -xz -C $(BIN_PATH)
	@chmod +x $(BIN_PATH)/cilium

$(BIN_PATH)/hubble:
	@echo "== install hubble"
	@mkdir -p $(BIN_PATH)
	@curl --fail -sL $(hubble_url) | tar -xz -C $(BIN_PATH)
	@chmod +x $(BIN_PATH)/hubble
