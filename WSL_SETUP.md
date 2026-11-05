# Setup no WSL (Windows Subsystem for Linux) 🐧

Guia completo para rodar o projeto no WSL.

## 📋 Pré-requisitos

### 1. Verificar se WSL está instalado

```bash
wsl --version
```

Se não estiver, instale no PowerShell (como Admin):
```powershell
wsl --install
```

### 2. Instalar Azure CLI no WSL

```bash
# Entrar no WSL
wsl

# Instalar Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Verificar instalação
az --version
```

### 3. Instalar kubectl

```bash
# Baixar kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Tornar executável
chmod +x kubectl

# Mover para /usr/local/bin
sudo mv kubectl /usr/local/bin/

# Verificar
kubectl version --client
```

### 4. Instalar Git (se necessário)

```bash
sudo apt update
sudo apt install git -y
git --version
```

---

## 🚀 Setup Completo com Script Automático

### 1. Navegar até o projeto

```bash
# No WSL, acessar o projeto no Windows
cd /mnt/c/Users/edmil/Documents/cogna/repositorios/devops-aks-demo
```

### 2. Dar permissão de execução ao script

```bash
chmod +x setup-azure-wsl.sh
```

### 3. Executar script

```bash
./setup-azure-wsl.sh
```

O script vai:
- ✅ Verificar Azure CLI
- ✅ Fazer login no Azure (se necessário)
- ✅ Registrar provedores necessários
- ✅ Criar Resource Group
- ✅ Criar Azure Container Registry (ACR)
- ✅ Criar Azure Kubernetes Service (AKS)
- ✅ Configurar kubectl
- ✅ Criar Service Principal
- ✅ Gerar arquivo com todos os GitHub Secrets

**⏱️ Tempo estimado:** 10-15 minutos

---

## 📝 Configurar GitHub Secrets

Após o script terminar:

### 1. Ver os secrets gerados

```bash
cat github-secrets.txt
```

### 2. Adicionar no GitHub via CLI

```bash
# Instalar GitHub CLI no WSL (se necessário)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh -y

# Fazer login
gh auth login

# Navegar para o projeto
cd /mnt/c/Users/edmil/Documents/cogna/repositorios/devops-aks-demo

# Adicionar secrets (extrair do arquivo github-secrets.txt)
gh secret set AZURE_CREDENTIALS < azure-credentials.json
gh secret set ACR_LOGIN_SERVER --body "<valor-do-arquivo>"
gh secret set ACR_USERNAME --body "<valor-do-arquivo>"
gh secret set ACR_PASSWORD --body "<valor-do-arquivo>"
gh secret set AKS_CLUSTER_NAME --body "<valor-do-arquivo>"
gh secret set AKS_RESOURCE_GROUP --body "<valor-do-arquivo>"
```

### 3. Ou adicionar manualmente no navegador

```bash
# Abrir repositório
gh repo view --web
# Vá em: Settings → Secrets and variables → Actions
# Copie os valores do arquivo github-secrets.txt
```

---

## 🧪 Testar Setup

### 1. Verificar recursos criados

```bash
# Ver Resource Group
az group show --name rg-devops-aks-demo

# Ver ACR
az acr list --resource-group rg-devops-aks-demo --output table

# Ver AKS
az aks list --resource-group rg-devops-aks-demo --output table

# Ver nodes do Kubernetes
kubectl get nodes
```

### 2. Testar deploy manual (opcional)

```bash
# Build da imagem
docker build -t devops-aks-demo:test .

# Login no ACR
ACR_NAME=$(az acr list --resource-group rg-devops-aks-demo --query "[0].name" -o tsv)
az acr login --name $ACR_NAME

# Tag e push
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer -o tsv)
docker tag devops-aks-demo:test $ACR_LOGIN_SERVER/devops-aks-demo:test
docker push $ACR_LOGIN_SERVER/devops-aks-demo:test

# Deploy no Kubernetes
export ACR_LOGIN_SERVER=$ACR_LOGIN_SERVER
export IMAGE_TAG="test"
envsubst < k8s/deployment.yaml | kubectl apply -f -
kubectl apply -f k8s/service.yaml

# Ver status
kubectl get all -l app=devops-aks-demo
```

---

## 🔄 Testar Pipeline CI/CD

```bash
# Fazer commit
echo "" >> README.md
git add README.md
git commit -m "test: trigger CI/CD pipeline"
git push origin main

# Acompanhar execução
gh run watch

# Ver logs
gh run view --log
```

---

## 🛠️ Comandos Úteis no WSL

### Acesso rápido ao projeto

```bash
# Criar alias no .bashrc
echo 'alias cdproj="cd /mnt/c/Users/edmil/Documents/cogna/repositorios/devops-aks-demo"' >> ~/.bashrc
source ~/.bashrc

# Usar
cdproj
```

### Ver logs do Kubernetes

```bash
kubectl logs -l app=devops-aks-demo --tail=50 -f
```

### Ver status do AKS

```bash
kubectl get all -l app=devops-aks-demo
kubectl get service devops-aks-demo-service
```

### Obter External IP

```bash
kubectl get service devops-aks-demo-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

### Testar aplicação

```bash
EXTERNAL_IP=$(kubectl get service devops-aks-demo-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl http://$EXTERNAL_IP/
curl http://$EXTERNAL_IP/health
curl http://$EXTERNAL_IP/info
```

---

## 🧹 Limpeza

### Deletar recursos Azure

```bash
# Parar AKS (não deleta, mas para de gastar)
az aks stop --name aksdevopsdemo --resource-group rg-devops-aks-demo

# Deletar tudo (irreversível!)
az group delete --name rg-devops-aks-demo --yes --no-wait

# Verificar deleção
az group show --name rg-devops-aks-demo
```

---

## ⚠️ Troubleshooting no WSL

### Azure CLI não encontrado

```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

### kubectl não encontrado

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

### Docker não funciona no WSL

```bash
# Usar Docker Desktop no Windows com integração WSL2
# Ou instalar Docker Engine no WSL:
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

### Permissão negada ao executar script

```bash
chmod +x setup-azure-wsl.sh
```

### PATH do Windows acessível no WSL

```bash
# Arquivos do Windows ficam em /mnt/c/
cd /mnt/c/Users/edmil/Documents/cogna/repositorios/devops-aks-demo
```

---

## 💡 Dicas

1. **Use Tab completion** no Azure CLI:
   ```bash
   echo "source /etc/bash_completion.d/azure-cli" >> ~/.bashrc
   ```

2. **Alias úteis:**
   ```bash
   alias k="kubectl"
   alias kgp="kubectl get pods"
   alias kgs="kubectl get services"
   alias kgn="kubectl get nodes"
   ```

3. **VS Code com WSL:**
   ```bash
   # Instalar extensão "Remote - WSL" no VS Code
   # Abrir projeto no WSL: code .
   ```

---

**Pronto! Tudo funcionando no WSL! 🐧🚀**
