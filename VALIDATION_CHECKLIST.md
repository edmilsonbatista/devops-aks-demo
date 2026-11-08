# Checklist de validação

## Aplicação e container

- [ ] Usar Node.js 24 LTS ou superior.
- [ ] Executar `npm ci` em `app/`.
- [ ] Iniciar a aplicação e confirmar resposta HTTP 200 em `/health`.
- [ ] Construir a imagem com `docker build -t devops-aks-demo:local .`.
- [ ] Confirmar que o container roda como usuário não-root e que o health check passa.

## Pull request e deploy

- [ ] Abrir um pull request para `main` e confirmar que `Validate pull request` passou.
- [ ] Confirmar que a validação de PR não usa credenciais nem faz push para o ACR.
- [ ] Após o merge, conferir os jobs de publicação da imagem e deploy na aba Actions.
- [ ] Confirmar rollout, probes e Service no cluster.
- [ ] Na regra de proteção de `main`, exigir o check `Validate pull request` depois de ele aparecer pela primeira vez. Exigir aprovação somente se outra pessoa puder revisar o PR.

## Terraform e dados locais

- [ ] Executar `terraform fmt -check -recursive` e `terraform validate` em `infra/terraform/`.
- [ ] Revisar `terraform plan`; não aplicar planos que proponham alterações inesperadas.
- [ ] Confirmar que `terraform.tfvars`, estado, planos, secrets e arquivos de credenciais não estão versionados.
- [ ] Não enviar `terraform.tfstate` ou arquivos locais como artefatos de workflow.

## Segurança e custos

- [ ] Conferir alertas de Secret Scanning no GitHub.
- [ ] Guardar credenciais apenas em GitHub Actions Secrets e revisar o acesso ao repositório.
- [ ] Preferir OIDC e permissões RBAC mínimas para o deploy Azure.
- [ ] Conferir o consumo real no Azure Cost Management; orçamento envia alertas, mas não encerra recursos automaticamente.
