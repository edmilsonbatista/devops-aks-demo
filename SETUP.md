# Setup Guide - DevOps AKS Demo

Guia passo a passo para configurar toda a infraestrutura necessária.

## Pré-requisitos

- Azure CLI instalado
- kubectl instalado
- Conta Azure ativa
- Repositório GitHub criado

## Passo 1: Criar Resource Group

```bash
export RESOURCE_GROUP="rg-devops-demo"
export LOCATION="eastus"

az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION
```

## Passo 2: Criar Azure Container Registry

```bash
export ACR_NAME="acrdevopsdemo"  # Deve ser único globalmente

az acr create \
  --resource-group $RESOURCE_GROUP \
  --name $ACR_NAME \
  --sku Standard \
  --location $LOCATION

# Habilitar admin user (para testes - não recomendado em produção)
az acr update --name $ACR_NAME --admin-enabled true

# Obter credenciais
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer --output tsv)
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username --output tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query "passwords[0].value" --output tsv)

echo "ACR_LOGIN_SERVER: $ACR_LOGIN_SERVER"
echo "ACR_USERNAME: $ACR_USERNAME"
echo "ACR_PASSWORD: $ACR_PASSWORD"
```

## Passo 3: Criar AKS Cluster

```bash
export AKS_NAME="aks-devops-demo"

az aks create \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_NAME \
  --node-count 2 \
  --node-vm-size Standard_B2s \
  --enable-managed-identity \
  --attach-acr $ACR_NAME \
  --location $LOCATION \
  --generate-ssh-keys

# Configurar kubectl
az aks get-credentials \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_NAME \
  --overwrite-existing

# Verificar conexão
kubectl cluster-info
kubectl get nodes
```

## Passo 4: Criar Service Principal para GitHub Actions

```bash
# Obter Subscription ID
SUBSCRIPTION_ID=$(az account show --query id --output tsv)

# Criar Service Principal com escopo no Resource Group
az ad sp create-for-rbac \
  --name "sp-github-actions-devops-demo" \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP \
  --sdk-auth

# Copie TODO o JSON output - será usado no GitHub Secret AZURE_CREDENTIALS
```

O output será algo como:

```json
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

## Passo 5: Configurar GitHub Secrets

No seu repositório GitHub, vá em **Settings → Secrets and variables → Actions** e adicione:

### Secrets necessários:

| Secret Name          | Value                                    | Onde obter                           |
| -------------------- | ---------------------------------------- | ------------------------------------ |
| `AZURE_CREDENTIALS`  | JSON completo do Service Principal       | Output do comando no Passo 4         |
| `ACR_LOGIN_SERVER`   | Ex: `acrdevopsdemo.azurecr.io`          | Output do Passo 2                    |
| `ACR_USERNAME`       | Username do ACR                          | Output do Passo 2                    |
| `ACR_PASSWORD`       | Password do ACR                          | Output do Passo 2                    |
| `AKS_CLUSTER_NAME`   | Ex: `aks-devops-demo`                   | Nome definido no Passo 3             |
| `AKS_RESOURCE_GROUP` | Ex: `rg-devops-demo`                    | Nome definido no Passo 1             |

### Como adicionar:

```bash
# Exemplo usando GitHub CLI (gh)
gh secret set AZURE_CREDENTIALS < azure-credentials.json
gh secret set ACR_LOGIN_SERVER --body "$ACR_LOGIN_SERVER"
gh secret set ACR_USERNAME --body "$ACR_USERNAME"
gh secret set ACR_PASSWORD --body "$ACR_PASSWORD"
gh secret set AKS_CLUSTER_NAME --body "$AKS_NAME"
gh secret set AKS_RESOURCE_GROUP --body "$RESOURCE_GROUP"
```

## Passo 6: Testar Deploy Manual

Antes de rodar o pipeline automatizado, teste o deploy manual:

```bash
# Build da imagem localmente
docker build -t $ACR_LOGIN_SERVER/devops-aks-demo:test .

# Login no ACR
az acr login --name $ACR_NAME

# Push da imagem
docker push $ACR_LOGIN_SERVER/devops-aks-demo:test

# Deploy no AKS
export ACR_LOGIN_SERVER=$ACR_LOGIN_SERVER
export IMAGE_TAG="test"
envsubst < k8s/deployment.yaml | kubectl apply -f -
kubectl apply -f k8s/service.yaml

# Verificar
kubectl get all -l app=devops-aks-demo

# Aguardar External IP
kubectl get service devops-aks-demo-service --watch
```

## Passo 7: Primeiro Deploy via GitHub Actions

```bash
# Fazer commit e push
git add .
git commit -m "ci: setup CI/CD pipeline"
git push origin main

# Acompanhar workflow no GitHub
# https://github.com/<seu-usuario>/<seu-repo>/actions
```

## Passo 8: Verificar Aplicação

```bash
# Obter External IP
EXTERNAL_IP=$(kubectl get service devops-aks-demo-service \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Testar endpoints
curl http://$EXTERNAL_IP/
curl http://$EXTERNAL_IP/health
curl http://$EXTERNAL_IP/info
```

## Troubleshooting

### Pipeline falha no build

```bash
# Verificar credenciais do ACR
az acr credential show --name $ACR_NAME

# Testar login manual
docker login $ACR_LOGIN_SERVER -u $ACR_USERNAME -p $ACR_PASSWORD
```

### Pipeline falha no deploy

```bash
# Verificar contexto do AKS
kubectl config current-context

# Verificar permissões do Service Principal
az role assignment list \
  --assignee <clientId-from-service-principal> \
  --resource-group $RESOURCE_GROUP
```

### Pods não iniciam

```bash
# Ver logs do pod
kubectl logs -l app=devops-aks-demo

# Descrever pod para ver eventos
kubectl describe pod -l app=devops-aks-demo

# Verificar se imagem foi puxada corretamente
kubectl get pods -o jsonpath='{.items[*].status.containerStatuses[*].image}'
```

### Service sem External IP

```bash
# Verificar status do service
kubectl describe service devops-aks-demo-service

# Verificar eventos do cluster
kubectl get events --sort-by='.lastTimestamp'

# Pode levar alguns minutos para Azure provisionar o Load Balancer
```

## Limpeza dos Recursos

⚠️ **ATENÇÃO:** Isso vai deletar TUDO e é irreversível!

```bash
# Deletar apenas os recursos do Kubernetes
kubectl delete -f k8s/

# OU deletar todo o Resource Group (ACR + AKS + tudo)
az group delete --name $RESOURCE_GROUP --yes --no-wait

# Deletar Service Principal
az ad sp delete --id <clientId-from-service-principal>
```

## Custos Estimados

Recursos criados e custos aproximados (região East US, preços de 2024):

- **AKS**: ~$70/mês (2 nodes Standard_B2s)
- **ACR Standard**: ~$5/mês
- **Load Balancer**: ~$18/mês
- **Total**: ~$93/mês

💡 **Dica**: Para ambiente de testes, lembre-se de deletar os recursos quando não estiver usando!

## Próximos Passos

- [ ] Implementar ambientes (dev, staging, prod)
- [ ] Adicionar testes automatizados no pipeline
- [ ] Configurar monitoramento (Azure Monitor / Application Insights)
- [ ] Implementar scanning de segurança de imagens
- [ ] Adicionar estratégias de deploy avançadas (blue-green, canary)
- [ ] Migrar para Helm charts
- [ ] Implementar GitOps com ArgoCD ou Flux

## Referências

- [Azure CLI Reference](https://docs.microsoft.com/cli/azure/)
- [AKS Documentation](https://docs.microsoft.com/azure/aks/)
- [ACR Documentation](https://docs.microsoft.com/azure/container-registry/)
- [GitHub Actions Documentation](https://docs.github.com/actions)
