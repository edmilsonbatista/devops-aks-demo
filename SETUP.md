# Guia geral de configuração

Este arquivo orienta a sequência de configuração. Os detalhes técnicos ficam nos READMEs de cada componente:

1. Revise os recursos Azure existentes e prepare a importação pelo [guia Terraform](infra/terraform/README.md).
2. Configure os secrets exigidos pelo [workflow do GitHub Actions](.github/workflows/README.md).
3. Consulte os [manifests e verificações Kubernetes](k8s/README.md).
4. Execute localmente ou consulte as rotas da [aplicação](app/README.md).

## Fluxo recomendado

- Para executar somente a aplicação, siga [QUICKSTART.md](QUICKSTART.md).
- Para administrar a infraestrutura existente, autentique no Azure CLI e revise `terraform plan` antes de qualquer `terraform apply`.
- Para publicar uma alteração da aplicação, faça push para `main` e acompanhe a execução em **GitHub → Actions**.

Não coloque credenciais, senhas ou arquivos de estado do Terraform no repositório.
