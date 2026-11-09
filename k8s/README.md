# Kubernetes

Esta pasta contém os manifests usados pelo workflow para implantar a aplicação no AKS.

## Manifests

- `deployment.yaml`: duas réplicas, atualização gradual, probes HTTP, limites de recursos e contexto de segurança do container.
- `service.yaml`: Service `LoadBalancer`, porta 80 para porta 3000 dos pods.

O `LoadBalancer` pode criar recursos Azure com custo. Verifique o estado e os custos associados na assinatura antes de deixar a aplicação publicada.

## Variáveis da imagem

Antes de aplicar `deployment.yaml`, o workflow substitui estas variáveis via `envsubst`:

- `ACR_LOGIN_SERVER`: endereço do ACR.
- `IMAGE_TAG`: tag SHA curta da imagem publicada.
- `GIT_SHA`: SHA completo do commit.

## Aplicar manualmente

Pré-requisitos: `kubectl`, `envsubst`, contexto Kubernetes configurado e cluster AKS em execução e acessível. Preencha as variáveis com valores do seu ambiente:

```bash
export ACR_LOGIN_SERVER="<seu-acr>.azurecr.io"
export IMAGE_TAG="<tag-da-imagem-publicada>"
export GIT_SHA="<sha-do-commit>"

envsubst < k8s/deployment.yaml | kubectl apply -f -
kubectl apply -f k8s/service.yaml
kubectl rollout status deployment/devops-aks-demo-deployment --timeout=5m
```

Execute os comandos a partir da raiz do repositório. A identidade usada por `kubectl` precisa ter permissão para atualizar os recursos; os nodes do AKS também precisam conseguir baixar a imagem do ACR.

Se o AKS estiver parado, a API Kubernetes pode não resolver ou não estar acessível e o `kubectl apply` falhará. Inicie o cluster e aguarde o estado `Running` antes de tentar novamente. Não use `--validate=false` como correção para indisponibilidade da API: essa opção não torna possível aplicar recursos sem conexão com o cluster.

## Verificar

```bash
kubectl get deployments,pods,services -l app=devops-aks-demo
kubectl logs -l app=devops-aks-demo --tail=50
kubectl get service devops-aks-demo-service
```

O endereço externo é provisionado para o Service pelo Azure. Para detalhes da infraestrutura, consulte [`infra/README.md`](../infra/README.md) e o [guia Terraform](../infra/terraform/README.md).

## GitOps futuro

Hoje, GitHub Actions aplica os manifests diretamente. Argo CD é somente uma proposta futura e ainda não está instalado ou configurado. Consulte o [guia de Argo CD](../argocd/README.md).
