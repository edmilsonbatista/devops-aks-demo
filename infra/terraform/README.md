# Terraform: infraestrutura Azure

Esta configuração importa recursos Azure já existentes para o estado do Terraform: Resource Group, Azure Container Registry (ACR), Azure Kubernetes Service (AKS) e a atribuição `AcrPull` da identidade kubelet. Os valores de exemplo são fictícios; substitua-os pelos valores do seu ambiente em um arquivo local `terraform.tfvars`, que não deve ser versionado.

## Pré-requisitos

- Terraform CLI compatível com `versions.tf`.
- Azure CLI autenticado na assinatura correta (`az login`).
- Permissões para consultar os recursos e atribuições RBAC.
- Dados atuais dos recursos existentes, consultados no Azure.

O provider AzureRM requer o ID da assinatura nos comandos Terraform. Obtenha-o com:

```bash
az account show --query id -o tsv
```

Copie `terraform.tfvars.example` para `terraform.tfvars` e preencha os nomes e propriedades reais dos recursos. Não cole credenciais, chaves privadas ou o estado Terraform no repositório.

## Consultar o GUID da atribuição AcrPull

Preencha os nomes abaixo localmente antes de executar os comandos:

```bash
RESOURCE_GROUP="<resource-group>"
AKS_NAME="<aks-name>"
ACR_NAME="<acr-name>"

KUBELET_ID=$(az aks show -g "$RESOURCE_GROUP" -n "$AKS_NAME" \
  --query identityProfile.kubeletidentity.objectId -o tsv)
ACR_ID=$(az acr show -g "$RESOURCE_GROUP" -n "$ACR_NAME" --query id -o tsv)

az role assignment list --all --assignee-object-id "$KUBELET_ID" \
  --query "[?scope=='$ACR_ID' && roleDefinitionName=='AcrPull'].name" -o tsv
```

Use o GUID retornado em `acr_pull_role_assignment_guid`. O ACR deve permitir que o AKS faça pull da imagem. O exemplo mantém a conta administrativa desabilitada. O workflow atual ainda publica usando usuário e senha do ACR; antes de aplicar esse valor em um ACR existente, migre a publicação para uma identidade com RBAC `AcrPush` ou ajuste o valor local para refletir o estado atual e revise o plano.

## Planejar a importação

1. Inicialize o diretório:

   ```bash
   terraform init
   ```

2. Formate e valide a configuração:

   ```bash
   terraform fmt -recursive
   terraform validate
   ```

3. Revise o plano antes de qualquer alteração:

   ```bash
   terraform plan
   ```

4. Aplique somente se o plano importar os recursos esperados e não propuser recriações, substituições ou exclusões inesperadas. Depois, rode `terraform plan` novamente e resolva qualquer diferença antes de administrar mudanças.

Não execute `apply` para tentar corrigir um plano inesperado. Os valores no `terraform.tfvars` precisam refletir o estado real do Azure.

## Estado e autenticação

`terraform.tfstate`, arquivos de plano, `.terraform/` e `terraform.tfvars` são locais e podem conter dados sensíveis. O `.gitignore` e o `.dockerignore` excluem esses arquivos. Para trabalho compartilhado, configure backend remoto com controle de acesso e bloqueio de estado.

O workflow GitHub Actions atualmente autentica usando secrets do repositório. Mantenha as credenciais somente nas configurações de Actions; para produção, prefira migrar para OpenID Connect (OIDC) com permissões RBAC mínimas.
