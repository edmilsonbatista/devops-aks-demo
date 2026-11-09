# Infraestrutura Azure

O diretório `terraform/` contém configuração para importar recursos Azure já existentes para o estado local do Terraform e então gerenciá-los como infraestrutura como código. A aplicação é implantada separadamente pelos manifests em [`../k8s/`](../k8s/README.md) e pelo workflow do GitHub Actions.

Antes de usar Terraform, leia o [guia de infraestrutura](terraform/README.md). O exemplo de variáveis contém valores fictícios; preencha um `terraform.tfvars` local com os valores do seu ambiente. Não versione esse arquivo, o estado Terraform ou arquivos de plano.

Sempre revise `terraform plan` antes de aplicar. Esta configuração importa recursos existentes; um plano que proponha recriação, substituição ou exclusão inesperada deve ser investigado antes de qualquer `apply`.
