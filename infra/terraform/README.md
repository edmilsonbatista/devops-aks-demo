# Terraform: infraestrutura Azure

Esta configuração importa para o estado Terraform recursos Azure já existentes: Resource Group, ACR, AKS e a atribuição `AcrPull` da identidade kubelet. Ela não cria nem atualiza esses recursos automaticamente ao ser inicializada; revise o plano antes de aplicar qualquer mudança.

## Pré-requisitos

- Terraform CLI 1.5 ou superior.
- Azure CLI autenticado (`az login`) com acesso à assinatura e aos recursos.
- Permissões para consultar recursos e atribuições RBAC.
- Valores atuais dos recursos existentes.

Confira e selecione a assinatura correta:

```bash
az account show --query id -o tsv
az account set --subscription "<subscription-id>"
```

Copie `terraform.tfvars.example` para `terraform.tfvars` e substitua **todos** os exemplos pelos dados reais. O exemplo não representa uma configuração pronta para aplicar. Não inclua tokens, senhas ou chaves privadas.

## Obter o GUID da atribuição AcrPull

Preencha os nomes reais localmente. Estes comandos Bash consultam a identidade kubelet e o escopo do ACR:

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

Use o GUID retornado em `acr_pull_role_assignment_guid`. Confirme também que os valores do `terraform.tfvars` correspondem ao estado real no Azure.

## Importar e revisar

Execute na pasta `infra/terraform/`:

```bash
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan
```

Os blocos `import` em `main.tf` associam os recursos existentes ao estado Terraform. Confira cada ação do plano. Só aplique se os recursos importados forem os esperados e o plano não contiver alterações destrutivas ou inesperadas:

```bash
terraform apply
terraform plan
```

Se o plano propor recriar, substituir ou excluir recursos, interrompa e corrija a configuração ou as importações antes de aplicar. Não use `apply` para tentar resolver divergências sem entender o plano.

## Credenciais do ACR no CI

O workflow atual publica imagens no ACR usando `ACR_USERNAME` e `ACR_PASSWORD` configurados como GitHub Actions Secrets. O exemplo Terraform define `acr_admin_enabled = false`; portanto, não aplique essa configuração ao ACR atual sem primeiro migrar o workflow para uma identidade com RBAC `AcrPush`, ou confirmar e representar corretamente o estado desejado. O Azure Login do workflow também usa credencial armazenada; OIDC com permissões mínimas é a evolução recomendada.

## Estado e dados locais

`terraform.tfstate`, arquivos de plano, `.terraform/` e `terraform.tfvars` podem conter dados sensíveis. Eles são ignorados pelo Git e pelo contexto Docker; mantenha-os fora de commits e backups públicos. Para trabalho compartilhado, configure um backend remoto protegido com controle de acesso e bloqueio de estado.
