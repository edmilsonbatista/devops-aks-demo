# Terraform — infraestrutura Azure

Esta configuração importa os recursos existentes desta demonstração: Resource Group, Azure Container Registry (ACR), Azure Kubernetes Service (AKS) e a atribuição `AcrPull` do kubelet ao ACR. Ela ficará separada dos manifests da aplicação em `k8s/` e do workflow de CI/CD.

## Pré-requisitos

- Terraform CLI instalado.
- Azure CLI instalado e autenticado na assinatura correta (`az login`).
- Permissão de leitura e gerenciamento dos recursos Azure e atribuições RBAC.
- Nomes e propriedades atuais do Resource Group, ACR e AKS.

O provider AzureRM 4 requer o ID da assinatura nos comandos `plan` e `apply`. Obtenha-o com `az account show --query id -o tsv` e preencha `subscription_id` no arquivo local `terraform.tfvars`.

## Importar recursos existentes

Criar arquivos `.tf` não faz o Terraform assumir recursos já existentes. A configuração contém blocos de importação para associar os recursos atuais ao estado do Terraform.

O cluster identificado é `aksdevopsdemo`, e o registry com a permissão `AcrPull` é `acrdevopsdemo27844`. Para obter o GUID dessa atribuição e preencher `acr_pull_role_assignment_guid` em `terraform.tfvars`, execute no Azure Cloud Shell:

```bash
KUBELET_ID=$(az aks show -g rg-devops-aks-demo -n aksdevopsdemo \
  --query identityProfile.kubeletidentity.objectId -o tsv)
ACR_ID=$(az acr show -g rg-devops-aks-demo -n acrdevopsdemo27844 --query id -o tsv)

az role assignment list --all --assignee-object-id "$KUBELET_ID" \
  --query "[?scope=='$ACR_ID' && roleDefinitionName=='AcrPull'].name" \
  -o tsv
```

O secret `ACR_LOGIN_SERVER` do GitHub Actions também deve apontar para `acrdevopsdemo27844.azurecr.io`; não copie nem envie os secrets de autenticação.

O AKS tem um perfil Linux com chave SSH pública. Preencha `aks_ssh_public_key` no `terraform.tfvars` usando a saída deste comando; não é necessário enviar a chave no chat:

```bash
az aks show -g rg-devops-aks-demo -n aksdevopsdemo \
  --query linuxProfile.ssh.publicKeys[0].keyData -o tsv
```

O registry `acrdevopsdemo10975` também existe no Resource Group, mas não apareceu associado ao kubelet deste AKS e não está incluído nesta configuração. Confirme que o workflow não o utiliza antes de considerar qualquer limpeza.

1. Copie `terraform.tfvars.example` para `terraform.tfvars`, preencha `subscription_id` e confira os demais valores com o Azure. O arquivo local está excluído do Git.
2. Inicialize o diretório:

   ```bash
   terraform init
   ```

3. Formate e valide a configuração:

   ```bash
   terraform fmt -recursive
   terraform validate
   ```

4. Revise o plano de importação:

   ```bash
   terraform plan
   ```

5. Confirme que o plano importa os recursos corretos e não propõe recriação, substituição ou exclusão. Só então aplique o plano para registrar a importação:

   ```bash
   terraform apply
   ```

6. Rode `terraform plan` novamente e resolva qualquer diferença entre a configuração e os recursos reais antes de usar Terraform para administrar mudanças.

Não execute `apply` se o plano mostrar alterações inesperadas. Importar um recurso não garante que a configuração HCL já reflita todos os valores atuais.

## Estado e credenciais

O estado do Terraform pode conter dados sensíveis. Não versione `terraform.tfstate`, arquivos de plano, `.terraform/` ou `terraform.tfvars`. Este repositório os ignora no `.gitignore`. Para uso por várias pessoas ou por automação, configure um backend remoto com controle de acesso e bloqueio de estado antes de compartilhar o estado local.

Autentique pelo Azure CLI. Não inclua senhas do ACR, credenciais de service principal ou segredos do GitHub em arquivos Terraform.

## Relação com o pipeline

O Terraform gerencia a infraestrutura Azure. O workflow em `.github/workflows/` continua responsável por build/push da imagem e pelo deploy no AKS. A aplicação usa `ACR_LOGIN_SERVER`, `AKS_RESOURCE_GROUP` e `AKS_CLUSTER_NAME` nos secrets já configurados no GitHub.
