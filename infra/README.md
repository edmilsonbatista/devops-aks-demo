# Infraestrutura Azure

Esta pasta concentra os recursos de nuvem usados pelo projeto. O Terraform em `terraform/` adota o Resource Group existente, o Azure Container Registry e o Azure Kubernetes Service. Os manifests de `../k8s/` descrevem a aplicação que roda no cluster.

Consulte o [guia do Terraform](terraform/README.md) antes de inicializar ou aplicar mudanças. O estado deve permanecer fora do Git e operações que alterem recursos precisam ser revisadas com `terraform plan`.
