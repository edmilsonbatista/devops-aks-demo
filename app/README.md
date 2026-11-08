# Aplicação

Aplicação de demonstração em Node.js e Express. O conteúdo da página inicial está em `src/public/index.html`; as rotas de diagnóstico e metadados são implementadas em `src/index.js`.

## Executar localmente

Requer Node.js 24 LTS ou superior.

```bash
npm ci
npm start
```

Acesse `http://localhost:3000`.

## Endpoints

| Rota | Resposta |
| --- | --- |
| `/` | Painel visual da demonstração |
| `/health` | Estado de saúde, horário da verificação e uptime |
| `/info` | Plataforma e versão do Node.js, sem expor o hostname do pod |
| `/api` | Versão, commit, tag da imagem e ambiente |

O painel consulta `/health`, `/info` e `/api` ao abrir e depois a cada 30 segundos. Se `GIT_SHA` e `IMAGE_TAG` não estiverem definidos, a API informa execução local.

## Container local

Execute os comandos a partir da raiz do repositório:

```bash
docker build -t devops-aks-demo:local .
docker run --rm -p 3000:3000 devops-aks-demo:local
```

O Dockerfile copia a pasta `app/src` inteira para a imagem, incluindo o painel em `src/public/`.
