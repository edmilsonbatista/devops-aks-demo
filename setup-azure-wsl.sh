#!/bin/bash

###############################################################################
# Setup Azure Resources - WSL/Linux Script
# Projeto: DevOps AKS Demo
# Descrição: Cria todos os recursos Azure necessários para o pipeline CI/CD
###############################################################################

set -e  # Parar em caso de erro

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}"
echo "=============================================="
echo "  DevOps AKS Demo - Setup Azure Resources"
echo "=============================================="
echo -e "${NC}"

# Verificar se Azure CLI está instalado
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI não encontrado!${NC}"
    echo "Instale com: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
    exit 1
fi

echo -e "${GREEN}✅ Azure CLI encontrado${NC}"

# Login no Azure (se necessário)
echo -e "${YELLOW}Verificando autenticação Azure...${NC}"
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}Fazendo login no Azure...${NC}"
    az login
fi

echo -e "${GREEN}✅ Autenticado no Azure${NC}"

# Mostrar subscription ativa
echo -e "${CYAN}Subscription ativa:${NC}"
az account show --query "{Name:name, ID:id, State:state}" -o table

# Confirmar
read -p "Esta é a subscription correta? (s/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[SsYy]$ ]]; then
    echo -e "${YELLOW}Liste suas subscriptions com: az account list --output table${NC}"
    echo -e "${YELLOW}E escolha uma com: az account set --subscription <ID>${NC}"
    exit 1
fi

# Variáveis
RESOURCE_GROUP="rg-devops-aks-demo"
LOCATION="eastus"
ACR_NAME="acrdevopsdemo$RANDOM"  # Nome único com número aleatório
AKS_NAME="aksdevopsdemo"

echo -e "${CYAN}"
echo "Configuração:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Location: $LOCATION"
echo "  ACR Name: $ACR_NAME"
echo "  AKS Name: $AKS_NAME"
echo -e "${NC}"

# 1. Registrar provedores
echo -e "${YELLOW}📝 Registrando provedores Azure...${NC}"
az provider register --namespace Microsoft.ContainerRegistry
az provider register --namespace Microsoft.ContainerService

echo -e "${YELLOW}⏳ Aguardando registro dos provedores (pode levar 1-2 min)...${NC}"

# Aguardar registro do Container Registry
while [ "$(az provider show --namespace Microsoft.ContainerRegistry --query 'registrationState' -o tsv)" != "Registered" ]; do
  echo -n "."
  sleep 5
done
echo -e "\n${GREEN}✅ Microsoft.ContainerRegistry registrado${NC}"

# Aguardar registro do Container Service
while [ "$(az provider show --namespace Microsoft.ContainerService --query 'registrationState' -o tsv)" != "Registered" ]; do
  echo -n "."
  sleep 5
done
echo -e "\n${GREEN}✅ Microsoft.ContainerService registrado${NC}"

# 2. Criar Resource Group
echo -e "${YELLOW}📦 Criando Resource Group...${NC}"
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION \
  --output table

echo -e "${GREEN}✅ Resource Group criado${NC}"

# 3. Criar Azure Container Registry
echo -e "${YELLOW}🐳 Criando Azure Container Registry (pode levar 2-3 min)...${NC}"
az acr create \
  --resource-group $RESOURCE_GROUP \
  --name $ACR_NAME \
  --sku Basic \
  --location $LOCATION \
  --admin-enabled true \
  --output table

echo -e "${GREEN}✅ ACR criado${NC}"

# 4. Criar Azure Kubernetes Service
echo -e "${YELLOW}☸️  Criando Azure Kubernetes Service (pode levar 5-10 min)...${NC}"
echo -e "${YELLOW}   Isso vai demorar um pouco, aproveite para tomar um café ☕${NC}"

az aks create \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_NAME \
  --node-count 2 \
  --node-vm-size Standard_B2s \
  --enable-managed-identity \
  --attach-acr $ACR_NAME \
  --location $LOCATION \
  --generate-ssh-keys \
  --output table

echo -e "${GREEN}✅ AKS criado${NC}"

# 5. Configurar kubectl
echo -e "${YELLOW}⚙️  Configurando kubectl...${NC}"
az aks get-credentials \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_NAME \
  --overwrite-existing

echo -e "${GREEN}✅ kubectl configurado${NC}"

# 6. Verificar nodes
echo -e "${YELLOW}🔍 Verificando nodes do cluster...${NC}"
kubectl get nodes

# 7. Criar Service Principal para GitHub Actions
echo -e "${YELLOW}🔐 Criando Service Principal para GitHub Actions...${NC}"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

SP_JSON=$(az ad sp create-for-rbac \
  --name "sp-github-devops-demo-$RANDOM" \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP \
  --sdk-auth)

# 8. Obter credenciais ACR
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer -o tsv)
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query "passwords[0].value" -o tsv)

# 9. Salvar secrets em arquivo
SECRETS_FILE="github-secrets.txt"

echo -e "${YELLOW}💾 Salvando GitHub Secrets em $SECRETS_FILE...${NC}"

cat > $SECRETS_FILE << EOF
===========================================
  GITHUB SECRETS - COPIE PARA O GITHUB
===========================================

Vá em: Settings → Secrets and variables → Actions
Clique em: New repository secret
Adicione cada secret abaixo:

-------------------------------------------
AZURE_CREDENTIALS
-------------------------------------------
$SP_JSON

-------------------------------------------
ACR_LOGIN_SERVER
-------------------------------------------
$ACR_LOGIN_SERVER

-------------------------------------------
ACR_USERNAME
-------------------------------------------
$ACR_USERNAME

-------------------------------------------
ACR_PASSWORD
-------------------------------------------
$ACR_PASSWORD

-------------------------------------------
AKS_CLUSTER_NAME
-------------------------------------------
$AKS_NAME

-------------------------------------------
AKS_RESOURCE_GROUP
-------------------------------------------
$RESOURCE_GROUP

===========================================
EOF

echo -e "${GREEN}✅ Secrets salvos em $SECRETS_FILE${NC}"

# 10. Resumo
echo -e "${GREEN}"
echo "=============================================="
echo "  🎉 SETUP COMPLETO!"
echo "=============================================="
echo -e "${NC}"

echo -e "${CYAN}Recursos criados:${NC}"
echo "  ✅ Resource Group: $RESOURCE_GROUP"
echo "  ✅ Container Registry: $ACR_LOGIN_SERVER"
echo "  ✅ Kubernetes Cluster: $AKS_NAME (2 nodes)"
echo "  ✅ Service Principal: criado"
echo ""

echo -e "${YELLOW}📋 Próximos passos:${NC}"
echo ""
echo "1. Abra o arquivo: $SECRETS_FILE"
echo "   cat $SECRETS_FILE"
echo ""
echo "2. Configure os 6 secrets no GitHub:"
echo "   https://github.com/<seu-usuario>/devops-aks-demo/settings/secrets/actions"
echo ""
echo "3. Faça um commit para testar o pipeline:"
echo "   git add ."
echo "   git commit -m \"test: trigger pipeline\""
echo "   git push origin main"
echo ""
echo "4. Acompanhe a execução:"
echo "   gh run watch"
echo ""

echo -e "${CYAN}💰 Custos estimados:${NC}"
echo "  ~\$3/dia (~\$93/mês com os \$200 de crédito Free Trial)"
echo ""

echo -e "${RED}⚠️  Lembre-se de deletar os recursos quando terminar:${NC}"
echo "  az group delete --name $RESOURCE_GROUP --yes --no-wait"
echo ""

echo -e "${GREEN}Documentação completa:${NC}"
echo "  README.md, SETUP.md, QUICKSTART.md"
echo ""
echo -e "${GREEN}Tudo pronto para CI/CD! 🚀${NC}"
