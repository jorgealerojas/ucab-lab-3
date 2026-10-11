SHELL := /bin/bash
.DEFAULT_GOAL := help

IMAGE ?= ucab-api
VERSION ?= v1
CONTAINER ?= ucab-api
PORT ?= 8080
KUBECTL ?= sudo k3s kubectl

.PHONY: help doctor test test-scripts image run smoke stop inspect k8s-start k8s-stop k8s-load k8s-deploy k8s-status k8s-smoke k8s-clean verify clean

help: ## Muestra los comandos disponibles
	@awk 'BEGIN {FS = ":.*## "; printf "Uso: make <objetivo>\n\n"} /^[a-zA-Z0-9_-]+:.*## / {printf "  %-14s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

doctor: ## Comprueba que la instancia está lista
	@./scripts/doctor.sh

test: ## Ejecuta las pruebas unitarias en Node 22
	@docker run --rm -v "$(CURDIR)/app:/workspace" -w /workspace node:22-alpine npm test

test-scripts: ## Prueba el despliegue sin crear recursos reales en AWS
	@./tests/deploy-lab.test.sh

image: ## Prueba y construye IMAGE:VERSION
	@docker build --build-arg APP_VERSION=$(VERSION) -t $(IMAGE):$(VERSION) app

run: ## Ejecuta el contenedor Docker en PORT
	@docker rm -f $(CONTAINER) >/dev/null 2>&1 || true
	@docker run -d --name $(CONTAINER) -p $(PORT):3000 -e APP_MESSAGE="Hola desde Docker" $(IMAGE):$(VERSION)

smoke: ## Verifica el contenedor Docker
	@./scripts/wait-http.sh http://127.0.0.1:$(PORT)/health 30
	@curl -fsS http://127.0.0.1:$(PORT)/ | jq .

stop: ## Elimina el contenedor Docker del laboratorio
	@docker rm -f $(CONTAINER) >/dev/null 2>&1 || true

inspect: ## Muestra configuración y estado del contenedor
	@docker inspect $(CONTAINER) | jq '.[0] | {Image, State, Config: {User: .Config.User, Env: .Config.Env, Healthcheck: .Config.Healthcheck}}'

k8s-start: ## Inicia K3s y espera que el nodo esté listo
	@sudo systemctl start k3s
	@$(KUBECTL) wait --for=condition=Ready node --all --timeout=120s

k8s-stop: ## Detiene K3s
	@sudo systemctl stop k3s

k8s-load: ## Importa IMAGE:VERSION desde Docker hacia containerd/K3s
	@docker save $(IMAGE):$(VERSION) | sudo k3s ctr images import -

k8s-deploy: ## Aplica ConfigMap, Deployment y Service
	@$(KUBECTL) apply -f k8s/
	@$(KUBECTL) rollout status deployment/ucab-api --timeout=120s

k8s-status: ## Muestra nodos, Deployment, Pods y Service
	@$(KUBECTL) get nodes,deployments,pods,services -o wide

k8s-smoke: ## Verifica el Service desde la instancia
	@./scripts/wait-http.sh http://127.0.0.1:30080/health 60
	@curl -fsS http://127.0.0.1:30080/ | jq .

k8s-clean: ## Elimina los objetos Kubernetes del laboratorio
	@$(KUBECTL) delete -f k8s/ --ignore-not-found

verify: ## Ejecuta la verificación funcional de Kubernetes
	@./scripts/verify-lab.sh

clean: stop k8s-clean ## Limpia contenedores y objetos Kubernetes
