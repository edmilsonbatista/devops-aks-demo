# Arquitetura

```text
Pull request para main
  → valida aplicação e constrói a imagem sem credenciais

Merge em main
  → GitHub Actions constrói e publica imagem no ACR
  → GitHub Actions aplica os manifests no AKS

Terraform
  → importa e administra os recursos Azure separadamente
```

## Componentes

- **Aplicação:** Node.js 24 e Express, com painel e endpoints `/health`, `/info` e `/api`.
- **Container:** Docker multi-stage, dependências reproduzíveis com `npm ci` e processo executado como usuário não-root.
- **Kubernetes:** Deployment com duas réplicas, atualização gradual, probes de saúde, requests e limits de CPU/memória e contexto de segurança não-root.
- **Service:** `LoadBalancer` expõe a aplicação. Um endereço público pode gerar custos Azure; avalie a necessidade antes de manter recursos ativos.
- **CI/CD:** pull requests executam validações sem secrets Azure. Publicação no ACR e deploy no AKS só rodam em `main`.
- **Terraform:** configuração isolada em `infra/terraform/`; planeje e revise importações e mudanças antes de aplicar.
- **Argo CD:** documentado como evolução futura. Não está instalado nem participa do fluxo atual.

## Limites de segurança

- Secrets ficam nas configurações de GitHub Actions; nunca devem entrar no repositório ou no contexto do Docker.
- O workflow usa credenciais armazenadas no GitHub para o deploy. Para reduzir credenciais de longa duração, migre para OIDC e RBAC mínimo.
- O estado Terraform e arquivos `tfvars` ficam fora do Git. Use backend remoto protegido se compartilhar o estado.
- Requests e limites ajudam a controlar consumo do cluster, mas não são um mecanismo de orçamento Azure.

Não há estimativa fixa de custo neste documento. O custo depende de região, SKU, capacidade, tráfego e tempo em execução; confira os recursos e o consumo no Azure Cost Management antes de usar a demonstração.
