# Makefile para facilitar comandos comuns

.PHONY: help install dev build run-docker stop-docker clean deploy logs status

# Variáveis
IMAGE_NAME := devops-aks-demo
CONTAINER_NAME := devops-aks-demo-local

help: ## Mostra esta mensagem de ajuda
	@echo "Comandos disponíveis:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## Instala dependências da aplicação
	cd app && npm install

dev: ## Executa aplicação em modo desenvolvimento
	cd app && npm run dev

build: ## Build da imagem Docker
	docker build -t $(IMAGE_NAME):local .

run-docker: ## Executa container Docker localmente
	docker run -d -p 3000:3000 --name $(CONTAINER_NAME) $(IMAGE_NAME):local
	@echo "Aplicação rodando em http://localhost:3000"

stop-docker: ## Para e remove container Docker
	docker stop $(CONTAINER_NAME) || true
	docker rm $(CONTAINER_NAME) || true

docker-compose-up: ## Sobe aplicação com docker-compose
	docker-compose up -d
	@echo "Aplicação rodando em http://localhost:3000"

docker-compose-down: ## Para docker-compose
	docker-compose down

clean: ## Remove node_modules e arquivos temporários
	rm -rf app/node_modules
	rm -rf app/package-lock.json
	docker rmi $(IMAGE_NAME):local || true

# Comandos Kubernetes (requer kubectl configurado)
deploy: ## Deploy no Kubernetes (substitua valores antes)
	@echo "Certifique-se de configurar ACR_LOGIN_SERVER e IMAGE_TAG"
	kubectl apply -f k8s/

logs: ## Ver logs dos pods no Kubernetes
	kubectl logs -l app=devops-aks-demo --tail=50 -f

status: ## Ver status do deployment no Kubernetes
	@echo "=== Deployments ==="
	kubectl get deployments -l app=devops-aks-demo
	@echo ""
	@echo "=== Pods ==="
	kubectl get pods -l app=devops-aks-demo
	@echo ""
	@echo "=== Services ==="
	kubectl get services -l app=devops-aks-demo

delete-k8s: ## Deleta recursos do Kubernetes
	kubectl delete -f k8s/

# Comandos de teste
test-local: ## Testa aplicação local
	@echo "Testing root endpoint..."
	@curl -s http://localhost:3000 | jq
	@echo ""
	@echo "Testing health endpoint..."
	@curl -s http://localhost:3000/health | jq
	@echo ""
	@echo "Testing info endpoint..."
	@curl -s http://localhost:3000/info | jq

test-k8s: ## Testa aplicação no Kubernetes
	@EXTERNAL_IP=$$(kubectl get service devops-aks-demo-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'); \
	if [ -z "$$EXTERNAL_IP" ]; then \
		echo "External IP não disponível ainda. Execute: kubectl get service devops-aks-demo-service"; \
	else \
		echo "Testing http://$$EXTERNAL_IP/"; \
		curl -s http://$$EXTERNAL_IP/ | jq; \
		echo ""; \
		echo "Testing http://$$EXTERNAL_IP/health"; \
		curl -s http://$$EXTERNAL_IP/health | jq; \
	fi
