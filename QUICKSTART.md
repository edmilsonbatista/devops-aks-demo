# Início rápido

## Rodar a aplicação localmente

```bash
cd app
npm ci
npm start
```

Abra `http://localhost:3000`. Para detalhes da aplicação e suas rotas, consulte [app/README.md](app/README.md).

## Usar a infraestrutura Azure existente

O Terraform gerencia os recursos Azure existentes. Antes de importar ou aplicar alterações, siga [`infra/terraform/README.md`](infra/terraform/README.md) e revise o plano.

## Publicar alterações da aplicação

1. Configure os secrets de deploy seguindo [`.github/workflows/README.md`](.github/workflows/README.md).
2. Crie uma branch, envie um pull request para `main` e confirme que o check `Validate pull request` passou.
3. Depois do merge, acompanhe a publicação e o deploy na aba **Actions** do GitHub.

O pipeline publica a imagem no ACR e implanta a aplicação no AKS. Os manifests e comandos de verificação estão em [k8s/README.md](k8s/README.md).
