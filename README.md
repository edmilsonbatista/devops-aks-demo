# DevOps AKS Demo

Projeto de demonstração de CI/CD com aplicação Node.js, GitHub Actions, Azure Container Registry (ACR) e Azure Kubernetes Service (AKS). A aplicação inclui um painel visual e endpoints de diagnóstico.

## Visão geral

```text
Desenvolvimento → GitHub → GitHub Actions → ACR → AKS → Aplicação
```

O Terraform gerencia a infraestrutura Azure (incluindo a importação de recursos existentes). Os manifests em `k8s/` descrevem a aplicação implantada no cluster.

## Começar

Para executar apenas a aplicação localmente:

```bash
cd app
npm ci
npm start
```

Abra `http://localhost:3000`. Para fazer o deploy na Azure, consulte os guias específicos abaixo antes de configurar as credenciais e executar alterações de infraestrutura.

## Guias por componente

- [Aplicação Node.js e painel](app/README.md)
- [Infraestrutura Azure com Terraform](infra/terraform/README.md)
- [Manifests Kubernetes](k8s/README.md)
- [Estudo futuro: Argo CD e GitOps](argocd/README.md)
- [Pipeline GitHub Actions](.github/workflows/README.md)

## Guias gerais

- [Início rápido](QUICKSTART.md)
- [Configuração detalhada do projeto](SETUP.md)
- [Arquitetura](ARCHITECTURE.md)
- [Checklist de validação](VALIDATION_CHECKLIST.md)

## Estrutura

```text
.
├── .github/workflows/   # CI/CD da aplicação
├── app/                 # Aplicação e painel web
├── argocd/              # Estudo de integração GitOps futura
├── infra/terraform/     # Infraestrutura Azure como código
└── k8s/                 # Deployment e Service Kubernetes
```
