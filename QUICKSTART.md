# Início rápido

## Rodar a aplicação localmente

```bash
cd app
npm install
npm start
```

Abra `http://localhost:3000`. Para detalhes da aplicação e suas rotas, consulte [app/README.md](app/README.md).

## Usar a infraestrutura Azure existente

Este projeto está preparando a adoção dos recursos atuais do Azure com Terraform. Antes de importar ou aplicar alterações, siga [`infra/terraform/README.md`](infra/terraform/README.md) e revise o plano.

## Publicar alterações da aplicação

1. Configure os secrets do repositório seguindo [`.github/workflows/README.md`](.github/workflows/README.md).
2. Faça push para `main`.
3. Acompanhe o workflow na aba **Actions** do GitHub.

O pipeline publica a imagem no ACR e implanta a aplicação no AKS. Os manifests e comandos de verificação estão em [k8s/README.md](k8s/README.md).
