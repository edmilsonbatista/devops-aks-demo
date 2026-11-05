# Setup do Repositório GitHub 🚀

## Opção 1: Executar Script Automaticamente (Recomendado)

### Windows (cmd):
```cmd
cd c:\Users\edmil\Documents\cogna\repositorios\devops-aks-demo
init-github.bat
```

### PowerShell:
```powershell
cd c:\Users\edmil\Documents\cogna\repositorios\devops-aks-demo
.\init-github.ps1
```

---

## Opção 2: Comandos Manuais (Passo a Passo)

### 1. Abrir terminal no diretório do projeto

```cmd
cd c:\Users\edmil\Documents\cogna\repositorios\devops-aks-demo
```

### 2. Inicializar Git

```cmd
git init
```

### 3. Adicionar todos os arquivos

```cmd
git add .
```

### 4. Criar commit inicial

```cmd
git commit -m "feat: initial commit - CI/CD pipeline with GitHub Actions, ACR and AKS"
```

### 5. Renomear branch para main

```cmd
git branch -M main
```

### 6. Criar repositório no GitHub

```cmd
gh repo create devops-aks-demo --public --source=. --remote=origin --description "CI/CD Pipeline completo: GitHub Actions -> Azure Container Registry -> Azure Kubernetes Service"
```

### 7. Fazer push para GitHub

```cmd
git push -u origin main
```

### 8. Abrir repositório no navegador

```cmd
gh repo view --web
```

---

## Verificação

Após executar, verifique que tudo está OK:

```cmd
# Ver status do Git
git status

# Ver repositório remoto
git remote -v

# Ver no navegador
gh repo view --web
```

---

## Troubleshooting

### Erro: "gh not found"

Instale o GitHub CLI:
```
winget install GitHub.cli
```

### Erro: "git not found"

Instale o Git:
```
winget install Git.Git
```

### Erro: "Authentication failed"

Faça login no GitHub CLI:
```
gh auth login
```

---

## Próximos Passos Após o Push

1. **Configurar Secrets do GitHub** (necessário para o pipeline funcionar)
   - Vá em: Settings → Secrets and variables → Actions
   - Adicione os secrets listados no `SETUP.md`

2. **Criar recursos Azure** (se ainda não criou)
   - Siga o guia em `SETUP.md` ou `QUICKSTART.md`

3. **Testar pipeline**
   - Faça um commit qualquer
   - Pipeline vai executar automaticamente
   - Acompanhe em: Actions tab no GitHub

---

## URL do Repositório

Após criado, seu repositório estará em:
```
https://github.com/<seu-usuario>/devops-aks-demo
```

Para descobrir seu username:
```cmd
gh api user --jq .login
```

---

**Pronto! Seu projeto está no GitHub! 🎉**
