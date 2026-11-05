# Arquitetura do Projeto

## Visão Geral

Este projeto implementa um pipeline CI/CD completo usando GitHub Actions para deploy automático no Azure Kubernetes Service (AKS), seguindo o diagrama fornecido.

## Fluxo Completo

```
┌─────────────┐     ┌──────────────┐     ┌──────────────┐
│  Developer  │────▶│   VS Code    │────▶│    GitHub    │
│             │  1  │              │  2  │  Repository  │
└─────────────┘     └──────────────┘     └──────┬───────┘
                                                 │
                                                 │ 3. Trigger
                                                 ▼
                                        ┌─────────────────┐
                                        │ GitHub Actions  │
                                        │   CI Pipeline   │
                                        └────────┬────────┘
                                                 │
                    ┌────────────────────────────┼────────────────────────────┐
                    │ Build Image                │ Push Image                 │
                    ▼                            ▼                            │
           ┌─────────────────┐         ┌──────────────────┐                  │
           │ Docker Build    │────────▶│ Azure Container  │                  │
           │ Multi-stage     │         │   Registry (ACR) │                  │
           └─────────────────┘         └────────┬─────────┘                  │
                                                 │                            │
                                                 │ 4. Pull Image              │
                                                 ▼                            │
                                        ┌─────────────────┐                   │
                                        │ GitHub Actions  │                   │
                                        │   CD Pipeline   │                   │
                                        └────────┬────────┘                   │
                                                 │                            │
                                                 │ 5. Deploy                  │
                                                 ▼                            │
                                        ┌──────────────────┐                  │
                                        │ Azure Kubernetes │                  │
                                        │  Service (AKS)   │                  │
                                        │                  │                  │
                                        │  ┌────────────┐  │                  │
                                        │  │   Pod 1    │  │                  │
                                        │  └────────────┘  │                  │
                                        │  ┌────────────┐  │                  │
                                        │  │   Pod 2    │  │                  │
                                        │  └────────────┘  │                  │
                                        │         │        │                  │
                                        │         ▼        │                  │
                                        │  ┌────────────┐  │                  │
                                        │  │    LB      │  │                  │
                                        │  │ (Service)  │  │                  │
                                        └──┴─────┬──────┴──┘                  │
                                                 │                            │
                                                 │                            │
                                                 ▼                            │
                                        ┌─────────────────┐                   │
                                        │  External IP    │                   │
                                        │  (Public URL)   │                   │
                                        └─────────────────┘                   │
                                                                              │
                                        Azure Cloud Platform                  │
                                        ──────────────────────────────────────┘
```

## Componentes

### 1. Aplicação (Node.js + Express)

**Localização:** `app/`

- Framework: Express.js
- Runtime: Node.js 18
- Endpoints:
  - `GET /` - Informações da aplicação
  - `GET /health` - Health check
  - `GET /info` - Informações do sistema

**Características:**
- Aplicação stateless (12-factor app)
- Graceful shutdown (SIGTERM)
- Health checks configurados
- Logging estruturado

### 2. Containerização (Docker)

**Localização:** `Dockerfile`

**Estratégia:** Multi-stage build

```
Stage 1 (builder):     Stage 2 (production):
- Base: node:18-alpine - Base: node:18-alpine
- npm ci (prod only)   - Copy from builder
                       - Non-root user (nodejs:1001)
                       - Healthcheck
```

**Otimizações:**
- Imagem final < 150MB
- Apenas dependências de produção
- Non-root user (segurança)
- Layer caching eficiente

### 3. Orquestração (Kubernetes)

**Localização:** `k8s/`

#### Deployment (`deployment.yaml`)

```yaml
Replicas: 2
Strategy: RollingUpdate
  - maxSurge: 1
  - maxUnavailable: 0

Container:
  - Resources:
      requests: 100m CPU, 128Mi RAM
      limits: 500m CPU, 512Mi RAM
  - Probes:
      liveness: /health (delay 15s)
      readiness: /health (delay 5s)
  - Security:
      runAsNonRoot: true
      capabilities dropped
```

#### Service (`service.yaml`)

```yaml
Type: LoadBalancer
Port: 80 → 3000
```

**Características:**
- Zero-downtime deployments
- Auto-scaling pronto (HPA)
- Health checks (liveness + readiness)
- Resource limits definidos

### 4. CI/CD (GitHub Actions)

**Localização:** `.github/workflows/ci-cd.yml`

#### Job 1: build-and-push

```
1. Checkout código
2. Setup Docker Buildx
3. Login no ACR
4. Extract metadata (tags)
5. Build & Push
   - Tags: SHA, branch, latest
   - Cache: GitHub Actions cache
```

#### Job 2: deploy-to-aks

```
1. Checkout código
2. Azure Login (Service Principal)
3. Set AKS context
4. Deploy manifests (envsubst)
5. Wait for rollout
6. Verify deployment
```

**Triggers:**
- Push para `main` → CI + CD
- Pull Request → CI only
- Manual (workflow_dispatch)

### 5. Infraestrutura Azure

#### Azure Container Registry (ACR)

```
SKU: Standard
Features:
  - Private registry
  - Geo-replication (opcional)
  - Webhook integration
  - Image scanning
```

#### Azure Kubernetes Service (AKS)

```
Node Pool:
  - VM: Standard_B2s (2 vCPU, 4GB RAM)
  - Count: 2 nodes
  - Auto-scaling: Habilitado

Features:
  - Managed identity
  - ACR integration
  - Azure CNI networking
  - RBAC habilitado
```

## Segurança

### Secrets Management

**GitHub Secrets:**
- `AZURE_CREDENTIALS` - Service Principal (least privilege)
- `ACR_USERNAME` / `ACR_PASSWORD` - ACR credentials
- `AKS_CLUSTER_NAME` / `AKS_RESOURCE_GROUP` - AKS info

**Kubernetes Secrets:**
- Gerenciados via Azure Key Vault (extensão CSI)
- Service Account com RBAC mínimo

### Container Security

- ✅ Non-root user (UID 1001)
- ✅ Read-only filesystem (pode ser habilitado)
- ✅ Capabilities dropped
- ✅ Security context definido
- ✅ Image scanning (Trivy/Snyk recomendado)

### Network Security

- ✅ Network Policies (pode ser habilitado)
- ✅ Ingress com TLS (próximo passo)
- ✅ Private endpoints ACR ↔ AKS (opcional)

## Observabilidade

### Logs

```bash
# Application logs
kubectl logs -l app=devops-aks-demo -f

# Cluster events
kubectl get events --sort-by='.lastTimestamp'
```

### Métricas

**Built-in:**
- Container metrics (CPU, RAM)
- Pod health (liveness/readiness)

**Recomendado:**
- Azure Monitor
- Prometheus + Grafana
- Application Insights

### Tracing

**Próximos passos:**
- OpenTelemetry integration
- Distributed tracing
- APM (Application Performance Monitoring)

## Estratégias de Deploy

### Atual: Rolling Update

```
maxSurge: 1       → Cria 1 novo pod antes de deletar antigo
maxUnavailable: 0 → Zero downtime garantido
```

### Futuro: Blue-Green / Canary

```bash
# Blue-Green
kubectl apply -f k8s/blue/
kubectl apply -f k8s/green/
# Switch service selector

# Canary (com Istio/Flagger)
kubectl apply -f k8s/canary.yaml
# Gradual traffic shift: 10% → 50% → 100%
```

## Disaster Recovery

### Backup

- **ACR:** Geo-replication para DR region
- **AKS:** GitOps (repo é source of truth)
- **Data:** Velero para backup de PVCs

### Rollback

```bash
# Ver histórico
kubectl rollout history deployment/devops-aks-demo-deployment

# Rollback
kubectl rollout undo deployment/devops-aks-demo-deployment
```

## Performance

### Otimizações Aplicadas

- ✅ Docker multi-stage build
- ✅ Layer caching (GitHub Actions)
- ✅ Resource limits definidos
- ✅ Horizontal Pod Autoscaling (pronto)

### Benchmarks Esperados

- **Build time:** ~2-3 min
- **Deploy time:** ~1-2 min
- **Pod startup:** ~10s
- **Response time:** < 100ms (p95)

## Custos

### Breakdown Mensal (East US)

| Recurso          | Tipo             | Custo/mês |
| ---------------- | ---------------- | --------- |
| AKS              | 2x Standard_B2s  | ~$70      |
| ACR              | Standard         | ~$5       |
| Load Balancer    | Basic            | ~$18      |
| Bandwidth        | Saída (estimado) | ~$10      |
| **Total**        |                  | **~$103** |

### Otimização de Custos

- Use Azure Dev/Test pricing
- Reserved Instances para nodes
- Spot instances para non-prod
- Auto-scale down fora do horário

## Referências

### Documentação

- [Azure AKS Best Practices](https://docs.microsoft.com/azure/aks/best-practices)
- [Kubernetes Production Best Practices](https://kubernetes.io/docs/setup/best-practices/)
- [Docker Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)
- [GitHub Actions CI/CD](https://docs.github.com/actions)

### Diagramas Originais

- Baseado no modelo fornecido: Developer → VS Code → GitHub → ACR → AKS
