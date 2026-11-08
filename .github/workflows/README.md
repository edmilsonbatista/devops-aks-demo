# GitHub Actions

O workflow `ci-cd.yml` valida pull requests sem usar credenciais Azure e publica/deploya somente depois de um push ou execução manual na branch `main`.

## Fluxo

- `pull_request` para `main`: instala dependências com `npm ci`, testa `/health` e constrói a imagem Docker sem login ou push para Azure.
- `push` para `main`: publica a imagem no ACR com a tag SHA curta e `latest`, depois aplica os manifests de `k8s/` no AKS.
- `workflow_dispatch`: publica e implanta somente quando executado a partir de `main`.

## Secrets necessários para deploy

| Secret | Uso |
| --- | --- |
| `ACR_LOGIN_SERVER` | Endereço do ACR |
| `ACR_USERNAME` | Usuário de publicação no ACR |
| `ACR_PASSWORD` | Senha de publicação no ACR |
| `AZURE_CREDENTIALS` | Credenciais utilizadas pelo Azure Login |
| `AKS_RESOURCE_GROUP` | Resource Group do AKS |
| `AKS_CLUSTER_NAME` | Nome do cluster AKS |

Cadastre-os em **Settings → Secrets and variables → Actions**. Nunca inclua valores no código, nos logs ou em arquivos versionados. O workflow não usa esses secrets para pull requests.

O login atual do ACR usa usuário e senha. Esses dados dependem de um método de autenticação do ACR que os aceite; se a conta administrativa do ACR estiver desabilitada, o job de publicação precisa ser migrado para identidade Azure com RBAC (`AcrPush`) antes de executar.

Para reduzir o risco de credenciais de longa duração, migre o login Azure e a publicação no ACR para OIDC e atribua apenas as permissões RBAC necessárias. Proteja a branch `main`; o check `Validate pull request` pode ser exigido na regra depois da primeira execução bem-sucedida.

O Terraform em [`infra/terraform/README.md`](../../infra/terraform/README.md) gerencia a infraestrutura separadamente do deploy da aplicação.
