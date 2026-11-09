# Aplicação Node.js

Aplicação de demonstração em Express, com um painel estático e endpoints para saúde e metadados. O HTML está em `src/public/index.html`; as rotas estão em `src/index.js`.

## Requisitos e execução local

Requer Node.js 24 ou superior. Execute na pasta `app/`:

```bash
npm ci
npm start
```

Acesse `http://localhost:3000`. Para desenvolvimento com reinício automático ao alterar arquivos, use `npm run dev`.

## Endpoints

| Rota | Conteúdo |
| --- | --- |
| `/` | Painel de demonstração |
| `/health` | Estado de saúde, horário e uptime do processo |
| `/info` | Plataforma do sistema e versão do Node.js |
| `/api` | Versão do app, commit, tag da imagem e ambiente |

O painel consulta os endpoints de saúde e metadados ao abrir e periodicamente. Em execução local, `/api` informa `commit: null` e `imageTag: "local"` quando as variáveis correspondentes não estão definidas.

## Executar em container

Os comandos devem ser executados na raiz do repositório, pois o Dockerfile usa `app/` como diretório de origem:

```bash
docker build -t devops-aks-demo:local .
docker run --rm -p 3000:3000 devops-aks-demo:local
```

O container usa Node.js 24 Alpine e executa a aplicação como usuário sem privilégios. O Compose local também pode ser iniciado pela raiz com `docker compose up --build`.
