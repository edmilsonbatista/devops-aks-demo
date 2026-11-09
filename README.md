# DevOps AKS Demo

Projeto de portfólio que demonstra uma aplicação Node.js conteinerizada, validação contínua com GitHub Actions e publicação e implantação em Azure Container Registry (ACR) e Azure Kubernetes Service (AKS).

> **Estado do deploy:** o workflow publica e implanta quando há push na branch `main` ou execução manual nessa branch. O AKS precisa estar em execução para o job de deploy alcançar a API Kubernetes. Se o cluster estiver parado para economizar recursos, a validação de pull request continua disponível, mas o deploy falhará até o cluster ser iniciado.

## Componentes

```text
Pull request → validação e build sem credenciais Azure
Push/execução manual em main → build → ACR → deploy no AKS
```

- `app/`: serviço Express e painel de demonstração.
- `k8s/`: Deployment e Service da aplicação.
- `infra/terraform/`: configuração para importar e gerenciar recursos Azure existentes.
- `.github/workflows/`: workflow de CI/CD e sua documentação.
- `argocd/`: proposta de evolução futura para GitOps; Argo CD ainda não faz parte do deploy ativo.

## Executar localmente

Requer Node.js 24 ou superior. Os comandos a seguir usam o lockfile para instalar versões reproduzíveis:

```bash
cd app
npm ci
npm start
```

Abra `http://localhost:3000`. Para executar em container, a partir da raiz do repositório:

```bash
docker build -t devops-aks-demo:local .
docker run --rm -p 3000:3000 devops-aks-demo:local
```

## Deploy no AKS

O workflow requer os GitHub Actions Secrets descritos em [`.github/workflows/README.md`](.github/workflows/README.md). PRs para `main` não recebem esses secrets. Para um deploy, confirme que o cluster está `Running` e que o workflow concluiu o build e o push da imagem.

Se o AKS estiver parado, inicie-o no Azure antes de executar o workflow. O plano de controle também para e o `kubectl` não consegue acessar a API. Após a inicialização, aguarde o estado `Running` e execute novamente o workflow. Consulte a [documentação da Microsoft sobre parar e iniciar AKS](https://learn.microsoft.com/azure/aks/start-stop-cluster).

Parar o cluster não garante que todos os recursos relacionados deixem de gerar custos. Verifique os recursos provisionados e o Cost Management da assinatura, incluindo registry, discos, IP público e balanceador de carga.

## Documentação

- [Início rápido](QUICKSTART.md) e [configuração](SETUP.md)
- [Aplicação Node.js](app/README.md)
- [Manifests Kubernetes](k8s/README.md)
- [Infraestrutura Azure](infra/README.md) e [guia Terraform](infra/terraform/README.md)
- [Workflow GitHub Actions](.github/workflows/README.md)
- [Proposta futura de Argo CD](argocd/README.md)
- [Arquitetura](ARCHITECTURE.md) e [checklist de validação](VALIDATION_CHECKLIST.md)
