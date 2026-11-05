@echo off
echo Inicializando repositorio Git...
git init

echo.
echo Adicionando todos os arquivos...
git add .

echo.
echo Criando commit inicial...
git commit -m "feat: initial commit - CI/CD pipeline with GitHub Actions, ACR and AKS"

echo.
echo Criando branch main...
git branch -M main

echo.
echo Criando repositorio no GitHub...
gh repo create devops-aks-demo --public --source=. --remote=origin --description "CI/CD Pipeline completo: GitHub Actions -> Azure Container Registry -> Azure Kubernetes Service"

echo.
echo Fazendo push para GitHub...
git push -u origin main

echo.
echo ============================================
echo Pronto! Repositorio criado e enviado para GitHub
echo.
echo Para ver o repositorio:
echo gh repo view --web
echo ============================================
pause
