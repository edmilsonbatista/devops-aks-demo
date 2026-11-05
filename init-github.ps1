# Script PowerShell para inicializar repositório GitHub

Write-Host "Inicializando repositorio Git..." -ForegroundColor Cyan
git init

Write-Host "`nAdicionando todos os arquivos..." -ForegroundColor Cyan
git add .

Write-Host "`nCriando commit inicial..." -ForegroundColor Cyan
git commit -m "feat: initial commit - CI/CD pipeline with GitHub Actions, ACR and AKS"

Write-Host "`nCriando branch main..." -ForegroundColor Cyan
git branch -M main

Write-Host "`nCriando repositorio no GitHub..." -ForegroundColor Cyan
gh repo create devops-aks-demo --public --source=. --remote=origin --description "CI/CD Pipeline completo: GitHub Actions -> Azure Container Registry -> Azure Kubernetes Service"

Write-Host "`nFazendo push para GitHub..." -ForegroundColor Cyan
git push -u origin main

Write-Host "`n============================================" -ForegroundColor Green
Write-Host "Pronto! Repositorio criado e enviado para GitHub" -ForegroundColor Green
Write-Host "`nPara ver o repositorio:" -ForegroundColor Yellow
Write-Host "gh repo view --web" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Green
