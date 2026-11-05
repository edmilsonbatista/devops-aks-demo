# GitHub Actions

O workflow `ci-cd.yml` implementa o pipeline da aplicação.

## Quando executa

- `push` para `main`: build e publicação da imagem no ACR, seguidos do deploy no AKS.
- `pull_request` direcionado a `main`: executa o job de build.
- `workflow_dispatch`: permite iniciar o workflow manualmente; o deploy continua restrito a pushes em `main`.

## Secrets necessários

| Secret | Uso |
| --- | --- |
| `ACR_LOGIN_SERVER` | Login e endereço do registry |
| `ACR_USERNAME` | Usuário para autenticação no ACR |
| `ACR_PASSWORD` | Senha para autenticação no ACR |
| `AZURE_CREDENTIALS` | Credenciais usadas pelo Azure Login |
| `AKS_RESOURCE_GROUP` | Resource Group onde está o AKS |
| `AKS_CLUSTER_NAME` | Nome do cluster AKS |

Configure os secrets nas configurações do repositório GitHub, em **Settings → Secrets and variables → Actions**. Não grave credenciais no repositório.

## Fluxo

1. Build da imagem Docker e publicação no ACR com a tag do commit.
2. No push para `main`, configuração do contexto do AKS.
3. Aplicação dos manifests de `k8s/` com a tag e o SHA do commit.
4. Espera do rollout e exibição do endereço do Service.

As etapas de criação da infraestrutura Azure estão isoladas em [`infra/terraform/README.md`](../../infra/terraform/README.md).
