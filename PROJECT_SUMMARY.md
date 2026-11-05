# Resumo do Projeto - DevOps AKS Demo

## 📋 O Que Foi Criado

Este projeto implementa o **pipeline CI/CD completo** mostrado no diagrama, com todos os componentes necessários para deploy automático no Azure Kubernetes Service.

## 🗂️ Estrutura Completa

```
devops-aks-demo/
│
├── 📱 APLICAÇÃO
│   ├── app/
│   │   ├── src/index.js          # Aplicação Node.js + Express
│   │   └── package.json           # Dependências
│   │
│   ├── Dockerfile                 # Multi-stage build otimizado
│   ├── .dockerignore              # Exclusões do build
│   └── docker-compose.yml         # Teste local com Docker Compose
│
├── ☸️ KUBERNETES
│   └── k8s/
│       ├── deployment.yaml        # Deployment (2 replicas, RollingUpdate)
│       └── service.yaml           # LoadBalancer service
│
├── 🔄 CI/CD
│   └── .github/workflows/
│       └── ci-cd.yml              # Pipeline GitHub Actions
│                                  #   Job 1: Build & Push to ACR
│                                  #   Job 2: Deploy to AKS
│
├── 📚 DOCUMENTAÇÃO
│   ├── README.md                  # Visão geral e guia principal
│   ├── QUICKSTART.md              # Início rápido (10 min)
│   ├── SETUP.md                   # Setup detalhado passo a passo
│   ├── ARCHITECTURE.md            # Arquitetura e decisões técnicas
│   └── PROJECT_SUMMARY.md         # Este arquivo
│
└── 🛠️ UTILITÁRIOS
    ├── Makefile                   # Comandos facilitados
    ├── .gitignore                 # Exclusões do Git
    └── .env.example               # Template de variáveis de ambiente
```

## 🎯 Componentes do Pipeline

### 1️⃣ Developer → VS Code
- Desenvolvimento local
- Testes locais: `npm start` ou `docker-compose up`

### 2️⃣ Commit → GitHub
- Push para branch `main`
- Versionamento Git

### 3️⃣ GitHub Actions (CI)
- **Trigger:** Push para `main` ou Pull Request
- **Build:** Docker multi-stage build
- **Tag:** SHA do commit + `latest`
- **Push:** Imagem para Azure Container Registry
- **Cache:** GitHub Actions cache para otimizar builds

### 4️⃣ Azure Container Registry (ACR)
- Registry privado de imagens Docker
- Integração nativa com AKS
- Geo-replication (opcional)

### 5️⃣ GitHub Actions (CD)
- **Login:** Azure via Service Principal
- **Context:** Configura kubectl para AKS
- **Deploy:** Aplica manifests Kubernetes
- **Verify:** Aguarda rollout + verifica status

### 6️⃣ Azure Kubernetes Service (AKS)
- **Deployment:** 2 réplicas da aplicação
- **Strategy:** RollingUpdate (zero downtime)
- **Service:** LoadBalancer com IP externo
- **Health Checks:** Liveness + Readiness probes

## ✨ Características Implementadas

### Aplicação
- ✅ Node.js 18 + Express
- ✅ Endpoints: `/`, `/health`, `/info`
- ✅ Graceful shutdown (SIGTERM)
- ✅ Logging estruturado
- ✅ Health checks

### Container
- ✅ Multi-stage build (imagem < 150MB)
- ✅ Non-root user (segurança)
- ✅ Healthcheck embutido
- ✅ Layer caching otimizado

### Kubernetes
- ✅ 2 réplicas (alta disponibilidade)
- ✅ RollingUpdate (zero downtime)
- ✅ Resource limits (CPU/RAM)
- ✅ Liveness + Readiness probes
- ✅ Security context (non-root, capabilities dropped)
- ✅ LoadBalancer service (IP público)

### CI/CD
- ✅ Build automático no push
- ✅ Deploy automático para `main`
- ✅ PR checks (CI only)
- ✅ Manual dispatch
- ✅ Image tagging (SHA + latest)
- ✅ Rollout verification

## 🚀 Como Usar

### Opção 1: Teste Local (2 min)
```bash
cd app && npm install && npm start
# ou
make install && make dev
# ou
docker-compose up
```

### Opção 2: Deploy Azure (10 min)
```bash
# 1. Criar recursos Azure
./scripts/create-azure-resources.sh  # (você pode criar este script)

# 2. Configurar GitHub Secrets
# Ver SETUP.md ou QUICKSTART.md

# 3. Push para GitHub
git push origin main

# 4. Pipeline roda automaticamente!
gh run watch
```

## 📊 Pipeline Flow Detalhado

```
┌─────────────────────────────────────────────────────────────┐
│ DEVELOPER                                                   │
│   git commit -m "feat: new feature"                         │
│   git push origin main                                      │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│ GITHUB (Repository)                                         │
│   ✓ Code pushed to main branch                             │
└───────────────────────┬─────────────────────────────────────┘
                        │ webhook trigger
                        ▼
┌─────────────────────────────────────────────────────────────┐
│ GITHUB ACTIONS - JOB 1: CI (Build & Push)                  │
│   1. Checkout code                                          │
│   2. Setup Docker Buildx                                    │
│   3. Login to ACR (secrets.ACR_USERNAME/PASSWORD)           │
│   4. Extract metadata (tags: sha-abc123, latest)            │
│   5. Build image (multi-stage Dockerfile)                   │
│   6. Push to ACR                                            │
│   ⏱️ Duration: ~2-3 min                                      │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│ AZURE CONTAINER REGISTRY                                    │
│   ✓ Image stored: acrname.azurecr.io/app:sha-abc123        │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│ GITHUB ACTIONS - JOB 2: CD (Deploy)                        │
│   1. Checkout code                                          │
│   2. Azure login (Service Principal)                        │
│   3. Set AKS context (kubectl config)                       │
│   4. Substitute vars in manifests (envsubst)                │
│   5. Apply deployment.yaml                                  │
│   6. Apply service.yaml                                     │
│   7. Wait for rollout (5 min timeout)                       │
│   8. Verify deployment                                      │
│   ⏱️ Duration: ~1-2 min                                      │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│ AZURE KUBERNETES SERVICE                                    │
│   RollingUpdate Strategy:                                   │
│     1. Create new pod (v2)                                  │
│     2. Wait for readiness probe                             │
│     3. Add to service endpoints                             │
│     4. Terminate old pod (v1)                               │
│     5. Repeat for replica 2                                 │
│   ✓ Zero downtime achieved                                 │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│ LOAD BALANCER                                               │
│   External IP: x.x.x.x                                      │
│   Port 80 → Pod 3000                                        │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
                  ┌──────────┐
                  │ END USER │
                  └──────────┘
```

## 🔐 Secrets Necessários

| Secret                | Descrição                           | Como obter                      |
| --------------------- | ----------------------------------- | ------------------------------- |
| `AZURE_CREDENTIALS`   | Service Principal JSON              | `az ad sp create-for-rbac`      |
| `ACR_LOGIN_SERVER`    | URL do ACR                          | `az acr show --query loginServer` |
| `ACR_USERNAME`        | Username do ACR                     | `az acr credential show`        |
| `ACR_PASSWORD`        | Password do ACR                     | `az acr credential show`        |
| `AKS_CLUSTER_NAME`    | Nome do cluster AKS                 | Nome escolhido na criação       |
| `AKS_RESOURCE_GROUP`  | Resource Group do AKS               | Nome escolhido na criação       |

## 💰 Custos Estimados

| Recurso          | Especificação   | Custo/mês |
| ---------------- | --------------- | --------- |
| AKS              | 2x Standard_B2s | ~$70      |
| ACR              | Standard        | ~$5       |
| Load Balancer    | Basic           | ~$18      |
| Egress (saída)   | Estimado        | ~$10      |
| **TOTAL**        |                 | **~$103** |

## 📈 Próximas Melhorias

### Curto Prazo
- [ ] Adicionar testes unitários
- [ ] Implementar code coverage
- [ ] Adicionar linting (ESLint)
- [ ] Configurar Dependabot

### Médio Prazo
- [ ] Helm charts ao invés de manifests YAML
- [ ] Ambientes separados (dev/staging/prod)
- [ ] Ingress Controller + TLS (HTTPS)
- [ ] Monitoramento (Prometheus/Grafana)

### Longo Prazo
- [ ] GitOps com ArgoCD ou Flux
- [ ] Service Mesh (Istio/Linkerd)
- [ ] Canary/Blue-Green deployments
- [ ] Multi-region deployment

## 🎓 Conceitos Demonstrados

Este projeto demonstra:

✅ **CI/CD:** Pipeline automatizado end-to-end  
✅ **Containerização:** Docker multi-stage builds  
✅ **Orquestração:** Kubernetes deployment patterns  
✅ **Cloud Native:** 12-factor app principles  
✅ **DevOps:** Infrastructure as Code  
✅ **Segurança:** Non-root containers, RBAC, secrets  
✅ **Alta Disponibilidade:** Multiple replicas, health checks  
✅ **Zero Downtime:** RollingUpdate strategy  

## 📞 Suporte

- 📖 **Documentação completa:** Veja todos os `.md` files
- 🐛 **Issues:** Abra uma issue no GitHub
- 💬 **Discussões:** Use GitHub Discussions

## 👨‍💻 Autor

**Edmilson Batista da Silva Filho**  
DevOps Consultant | Platform Engineer

LinkedIn: [Seu LinkedIn]  
GitHub: [Seu GitHub]

---

**Criado com ❤️ para demonstrar CI/CD moderno com Azure + Kubernetes**
