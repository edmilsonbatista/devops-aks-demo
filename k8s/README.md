# Kubernetes

Esta pasta contém os manifests que executam e expõem a aplicação no Azure Kubernetes Service (AKS).

## Arquivos

- `deployment.yaml`: duas réplicas, atualização gradual, probes de saúde e limites de CPU/memória.
- `service.yaml`: Service `LoadBalancer` que encaminha tráfego da porta 80 para a porta 3000 dos pods.

## Variáveis do deployment

O `deployment.yaml` usa substituição de ambiente antes de ser aplicado:

- `ACR_LOGIN_SERVER`: endereço do Azure Container Registry.
- `IMAGE_TAG`: tag da imagem Docker.
- `GIT_SHA`: commit completo usado para gerar a imagem.

O workflow do GitHub Actions define essas variáveis e aplica os manifests. Para executar manualmente, configure as três variáveis e rode:

```bash
envsubst < k8s/deployment.yaml | kubectl apply -f -
kubectl apply -f k8s/service.yaml
kubectl rollout status deployment/devops-aks-demo-deployment
```

## Verificação

```bash
kubectl get deployments,pods,services -l app=devops-aks-demo
kubectl logs -l app=devops-aks-demo --tail=50
kubectl get service devops-aks-demo-service
```

O endereço público é provisionado pelo Azure para o Service `LoadBalancer`. A infraestrutura do cluster e do registry será documentada em [`infra/terraform/README.md`](../infra/terraform/README.md).
