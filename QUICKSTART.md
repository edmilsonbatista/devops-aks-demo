# Quickstart - Coloque no ar em 10 minutos! 🚀

## Opção 1: Teste Local (Mais Rápido)

### Sem Docker (Node.js direto)

```bash
# 1. Instalar dependências
cd app
npm install

# 2. Rodar aplicação
npm start

# 3. Testar
curl http://localhost:3000
curl http://localhost:3000/health
```

### Com Docker

```bash
# 1. Build da imagem
docker build -t devops-aks-demo:local .

# 2. Rodar container
docker run -d -p 3000:3000 --name demo devops-aks-demo:local

# 3. Testar
curl http://localhost:3000

# 4. Ver logs
docker logs -f demo

# 5. Parar
docker stop demo && docker rm demo
```

### Com Make (ainda mais fácil!)

```bash
# Instalar deps + Build + Run + Test
make install
make build
make run-docker
make test-local

# Cleanup
make stop-docker
```

---

## Opção 2: Deploy na Azure (Pipeline Completo)

### Passo 1: Criar Recursos Azure (5 min)

```bash
# Definir variáveis
export RESOURCE_GROUP="rg-devops-demo"
export LOCATION="eastus"
export ACR_NAME="acrdevopsdemo$(date +%s)"  # Nome único
export AKS_NAME="aks-devops-demo"

# Criar Resource Group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Criar ACR
az acr create \
  --resource-group $RESOURCE_GROUP \
  --name $ACR_NAME \
  --sku Standard \
  --admin-enabled true

# Criar AKS
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_NAME \
  --node-count 2 \
  --enable-managed-identity \
  --attach-acr $ACR_NAME \
  --generate-ssh-keys

# Configurar kubectl
az aks get-credentials \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_NAME \
  --overwrite-existing

# Verificar
kubectl get nodes
```

### Passo 2: Configurar GitHub Secrets (2 min)

```bash
# Obter credenciais ACR
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer -o tsv)
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query "passwords[0].value" -o tsv)

# Criar Service Principal
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SP_JSON=$(az ad sp create-for-rbac \
  --name "sp-github-actions-demo" \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP \
  --sdk-auth)

# Mostrar valores para adicionar no GitHub
echo "=== ADICIONE ESTES SECRETS NO GITHUB ==="
echo ""
echo "AZURE_CREDENTIALS:"
echo "$SP_JSON"
echo ""
echo "ACR_LOGIN_SERVER: $ACR_LOGIN_SERVER"
echo "ACR_USERNAME: $ACR_USERNAME"
echo "ACR_PASSWORD: $ACR_PASSWORD"
echo "AKS_CLUSTER_NAME: $AKS_NAME"
echo "AKS_RESOURCE_GROUP: $RESOURCE_GROUP"
```

### Passo 3: Adicionar Secrets no GitHub

1. Vá para: `Settings` → `Secrets and variables` → `Actions`
2. Clique em `New repository secret`
3. Adicione cada secret listado acima

**OU use GitHub CLI:**

```bash
# Salvar JSON em arquivo temporário
echo "$SP_JSON" > /tmp/azure-creds.json

# Adicionar secrets
gh secret set AZURE_CREDENTIALS < /tmp/azure-creds.json
gh secret set ACR_LOGIN_SERVER --body "$ACR_LOGIN_SERVER"
gh secret set ACR_USERNAME --body "$ACR_USERNAME"
gh secret set ACR_PASSWORD --body "$ACR_PASSWORD"
gh secret set AKS_CLUSTER_NAME --body "$AKS_NAME"
gh secret set AKS_RESOURCE_GROUP --body "$RESOURCE_GROUP"

# Remover arquivo temporário
rm /tmp/azure-creds.json
```

### Passo 4: Deploy! (3 min)

```bash
# Inicializar repositório Git (se ainda não fez)
git init
git add .
git commit -m "feat: initial CI/CD setup"

# Criar repositório no GitHub
gh repo create devops-aks-demo --public --source=. --remote=origin

# Push para main (aciona o pipeline automaticamente!)
git push -u origin main

# Acompanhar workflow
gh run watch
```

### Passo 5: Verificar (1 min)

```bash
# Ver status do deploy
kubectl get all -l app=devops-aks-demo

# Aguardar External IP (pode levar ~2 min)
kubectl get service devops-aks-demo-service --watch

# Testar aplicação
EXTERNAL_IP=$(kubectl get service devops-aks-demo-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl http://$EXTERNAL_IP
curl http://$EXTERNAL_IP/health
```

---

## Troubleshooting Rápido

### Pipeline falhou?

```bash
# Ver logs do workflow
gh run view --log-failed

# Testar credenciais ACR manualmente
docker login $ACR_LOGIN_SERVER -u $ACR_USERNAME -p $ACR_PASSWORD
```

### Pods não sobem?

```bash
# Ver status detalhado
kubectl describe pod -l app=devops-aks-demo

# Ver logs
kubectl logs -l app=devops-aks-demo --tail=50

# Ver eventos
kubectl get events --sort-by='.lastTimestamp' | tail -20
```

### External IP não aparece?

```bash
# Verificar service
kubectl describe service devops-aks-demo-service

# Pode levar até 3 minutos para Azure provisionar
# Execute este comando e aguarde:
kubectl get service devops-aks-demo-service --watch
```

---

## Próximos Passos

✅ **Você acabou de criar:**
- Pipeline CI/CD completo
- Aplicação containerizada
- Infraestrutura Kubernetes na Azure
- Deploy automático a cada commit

### Melhorias Sugeridas:

1. **Adicionar testes automatizados**
   ```bash
   # Criar tests/app.test.js e adicionar no CI
   ```

2. **Configurar domínio customizado**
   ```bash
   # Adicionar Ingress Controller com cert-manager
   ```

3. **Implementar ambientes (dev/staging/prod)**
   ```bash
   # Criar branches e workflows separados
   ```

4. **Adicionar monitoramento**
   ```bash
   # Integrar Azure Monitor ou Prometheus
   ```

---

## Limpeza (quando terminar)

```bash
# Deletar tudo na Azure (isso vai REMOVER TUDO!)
az group delete --name $RESOURCE_GROUP --yes --no-wait

# Deletar Service Principal
SP_APP_ID=$(echo $SP_JSON | jq -r .clientId)
az ad sp delete --id $SP_APP_ID
```

---

## Comandos Úteis

```bash
# Ver todos os recursos criados
az resource list --resource-group $RESOURCE_GROUP --output table

# Ver custos estimados
az consumption usage list --output table

# Escalar pods
kubectl scale deployment devops-aks-demo-deployment --replicas=3

# Ver métricas
kubectl top nodes
kubectl top pods

# Executar comando dentro do pod
kubectl exec -it deployment/devops-aks-demo-deployment -- sh
```

---

## Precisa de Ajuda?

- 📖 Ver documentação completa: `README.md`
- 🏗️ Entender arquitetura: `ARCHITECTURE.md`
- ⚙️ Setup detalhado: `SETUP.md`
- 🐛 Problemas? Abra uma issue no GitHub!

**Bora codar! 🚀**
