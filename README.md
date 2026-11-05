# DevOps AKS Demo - CI/CD Pipeline 🚀

[![GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=github-actions&logoColor=white)](https://github.com/features/actions)
[![Azure](https://img.shields.io/badge/Cloud-Azure-0078D4?logo=microsoft-azure&logoColor=white)](https://azure.microsoft.com/)
[![Kubernetes](https://img.shields.io/badge/Orchestration-Kubernetes-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Docker](https://img.shields.io/badge/Container-Docker-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Node.js](https://img.shields.io/badge/Runtime-Node.js%2018-339933?logo=node.js&logoColor=white)](https://nodejs.org/)

Projeto de demonstração de pipeline CI/CD completo usando GitHub Actions, Azure Container Registry e Azure Kubernetes Service.

> **🎯 Objetivo:** Demonstrar implementação completa de DevOps moderno com deploy automático no Azure Kubernetes Service.

## Arquitetura

```
Developer → VS Code → GitHub → GitHub Actions → ACR → AKS
                                     ↓
                                  CI/CD Pipeline
```

## Fluxo de CI/CD

1. **Develop app** (VS Code): Desenvolvimento local
2. **Commit**: Push para GitHub
3. **CI**: GitHub Actions builda a imagem Docker
4. **Push to Registry**: Imagem enviada para Azure Container Registry
5. **CD**: Deploy automático para Azure Kubernetes Service

## Estrutura do Projeto

```
devops-aks-demo/
├── .github/workflows/       # GitHub Actions workflows
│   └── ci-cd.yml           # Pipeline principal CI/CD
├── app/                     # Código da aplicação
│   ├── src/
│   │   └── index.js        # Aplicação Node.js
│   ├── package.json
│   └── package-lock.json
├── k8s/                     # Kubernetes manifests
│   ├── deployment.yaml
│   └── service.yaml
├── Dockerfile               # Imagem Docker da aplicação
└── README.md
```

## Pré-requisitos

### Azure Resources

1. **Azure Container Registry (ACR)**
   - Nome: `<seu-acr-name>.azurecr.io`
   - SKU: Standard ou Premium

2. **Azure Kubernetes Service (AKS)**
   - Cluster configurado
   - ACR attachment habilitado

### GitHub Secrets

Configure os seguintes secrets no repositório GitHub:

```
AZURE_CREDENTIALS           # Service Principal JSON
ACR_LOGIN_SERVER           # <seu-acr>.azurecr.io
ACR_USERNAME               # Service Principal App ID
ACR_PASSWORD               # Service Principal Password
AKS_CLUSTER_NAME           # Nome do cluster AKS
AKS_RESOURCE_GROUP         # Resource Group do AKS
```

## Configuração Inicial

### 1. Criar Service Principal no Azure

```bash
az ad sp create-for-rbac \
  --name "github-actions-demo" \
  --role contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP> \
  --sdk-auth
```

Copie o JSON output para `AZURE_CREDENTIALS`.

### 2. Criar Azure Container Registry

```bash
az acr create \
  --resource-group <RESOURCE_GROUP> \
  --name <ACR_NAME> \
  --sku Standard
```

### 3. Criar AKS Cluster

```bash
az aks create \
  --resource-group <RESOURCE_GROUP> \
  --name <AKS_NAME> \
  --node-count 2 \
  --enable-managed-identity \
  --attach-acr <ACR_NAME>
```

### 4. Configurar kubectl

```bash
az aks get-credentials \
  --resource-group <RESOURCE_GROUP> \
  --name <AKS_NAME>
```

## Como Usar

### Desenvolvimento Local

```bash
# Instalar dependências
cd app
npm install

# Executar aplicação
npm start

# Acessar em http://localhost:3000
```

### Build Local da Imagem Docker

```bash
docker build -t devops-aks-demo:local .
docker run -p 3000:3000 devops-aks-demo:local
```

### Deploy Manual no Kubernetes

```bash
# Aplicar manifests
kubectl apply -f k8s/

# Verificar deployment
kubectl get deployments
kubectl get pods
kubectl get services

# Obter IP externo
kubectl get service devops-aks-demo-service
```

## Pipeline CI/CD

O pipeline GitHub Actions é acionado automaticamente em push para `main`:

### Stage 1: CI (Build & Push)

- Checkout do código
- Login no Azure Container Registry
- Build da imagem Docker
- Tag com SHA do commit
- Push para ACR

### Stage 2: CD (Deploy)

- Login no AKS
- Update dos manifests K8s com nova imagem
- Deploy no cluster AKS
- Verificação do deployment

## Verificação do Deploy

```bash
# Ver status dos pods
kubectl get pods -l app=devops-aks-demo

# Ver logs da aplicação
kubectl logs -l app=devops-aks-demo --tail=50

# Testar aplicação
EXTERNAL_IP=$(kubectl get service devops-aks-demo-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl http://$EXTERNAL_IP
```

## Monitoramento

### Logs do Pod

```bash
kubectl logs -f deployment/devops-aks-demo-deployment
```

### Eventos do Cluster

```bash
kubectl get events --sort-by='.lastTimestamp'
```

### Descrição do Deployment

```bash
kubectl describe deployment devops-aks-demo-deployment
```

## Rollback

```bash
# Ver histórico de revisões
kubectl rollout history deployment/devops-aks-demo-deployment

# Rollback para revisão anterior
kubectl rollout undo deployment/devops-aks-demo-deployment

# Rollback para revisão específica
kubectl rollout undo deployment/devops-aks-demo-deployment --to-revision=2
```

## Limpeza

```bash
# Deletar recursos do Kubernetes
kubectl delete -f k8s/

# Deletar recursos Azure (se necessário)
az group delete --name <RESOURCE_GROUP> --yes --no-wait
```

## Melhorias Futuras

- [ ] Implementar Helm charts
- [ ] Adicionar testes automatizados (unit, integration)
- [ ] Implementar scanning de segurança de imagens
- [ ] Adicionar ambientes (dev, staging, prod)
- [ ] Implementar estratégias de deploy (blue-green, canary)
- [ ] Adicionar monitoramento com Azure Monitor / Prometheus
- [ ] Implementar GitOps com ArgoCD ou Flux

## Referências

- [GitHub Actions Documentation](https://docs.github.com/actions)
- [Azure Container Registry](https://docs.microsoft.com/azure/container-registry/)
- [Azure Kubernetes Service](https://docs.microsoft.com/azure/aks/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## Autor

Edmilson Batista da Silva Filho - DevOps Engineer

