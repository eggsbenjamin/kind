# Kind - https://kind.sigs.k8s.io
kind_cluster_name := scratchpad
kind_config := config.yaml
kind_context := kind-$(kind_cluster_name)
kind_kubeconfig := $(CURDIR)/$(kind_context).kubeconfig
kind_delete_cluster := true
