# Checklist de Validação 🎯

Use este checklist para validar cada etapa do deploy seguindo o **Mindset de Validação Completa** do CoE de Qualidade.

## ✅ Fase 1: Validação Local

### [ ] 1.1 - Aplicação Node.js funciona?

```bash
cd app
npm install
npm start
```

**Validação:**
- [ ] Servidor iniciou sem erros
- [ ] Console mostra: `🚀 Server running on port 3000`
- [ ] `curl http://localhost:3000` retorna JSON com `message`
- [ ] `curl http://localhost:3000/health` retorna `status: "healthy"`
- [ ] `curl http://localhost:3000/info` retorna info do sistema

### [ ] 1.2 - Docker build funciona?

```bash
docker build -t devops-aks-demo:local .
```

**Validação:**
- [ ] Build completo sem erros
- [ ] Imagem criada: `docker images | grep devops-aks-demo`
- [ ] Tamanho da imagem < 200MB (idealmente < 150MB)

### [ ] 1.3 - Container executa corretamente?

```bash
docker run -d -p 3000:3000 --name demo devops-aks-demo:local
sleep 5
docker logs demo
```

**Validação:**
- [ ] Container iniciou: `docker ps | grep demo`
- [ ] Logs mostram servidor rodando
- [ ] Health check passa: `docker inspect demo | grep -A5 Health`
- [ ] Endpoints respondem: `curl http://localhost:3000/health`

```bash
# Cleanup
docker stop demo && docker rm demo
```

---

## ✅ Fase 2: Validação Azure Resources

### [ ] 2.1 - Resource Group criado?

```bash
az group show --name $RESOURCE_GROUP
```

**Validação:**
- [ ] Comando retorna JSON (não erro 404)
- [ ] `provisioningState: "Succeeded"`
- [ ] Location correto (ex: `eastus`)

### [ ] 2.2 - ACR criado e acessível?

```bash
az acr show --name $ACR_NAME
az acr login --name $ACR_NAME
```

**Validação:**
- [ ] ACR existe e status `provisioningState: "Succeeded"`
- [ ] Login bem-sucedido: "Login Succeeded"
- [ ] Admin user habilitado: `adminUserEnabled: true`

**Teste de push:**
```bash
docker tag devops-aks-demo:local $ACR_LOGIN_SERVER/devops-aks-demo:test
docker push $ACR_LOGIN_SERVER/devops-aks-demo:test
az acr repository show --name $ACR_NAME --repository devops-aks-demo
```

**Validação:**
- [ ] Push completo sem erros
- [ ] Imagem listada no ACR
- [ ] Tag `test` aparece no repository

### [ ] 2.3 - AKS criado e acessível?

```bash
az aks show --name $AKS_NAME --resource-group $RESOURCE_GROUP
az aks get-credentials --name $AKS_NAME --resource-group $RESOURCE_GROUP --overwrite-existing
kubectl cluster-info
kubectl get nodes
```

**Validação:**
- [ ] Cluster existe: `provisioningState: "Succeeded"`
- [ ] kubeconfig atualizado
- [ ] `kubectl cluster-info` mostra master endpoint
- [ ] `kubectl get nodes` mostra 2 nodes em `Ready`

### [ ] 2.4 - AKS pode puxar do ACR?

```bash
az aks show --name $AKS_NAME --resource-group $RESOURCE_GROUP --query "identityProfile.kubeletidentity.clientId" -o tsv
```

**Validação:**
- [ ] Managed Identity configurado
- [ ] ACR attachment habilitado
- [ ] Teste: `kubectl run test --image=$ACR_LOGIN_SERVER/devops-aks-demo:test --rm -it -- sh`

---

## ✅ Fase 3: Validação GitHub Secrets

### [ ] 3.1 - Secrets configurados?

```bash
gh secret list
```

**Validação:**
- [ ] `AZURE_CREDENTIALS` existe
- [ ] `ACR_LOGIN_SERVER` existe
- [ ] `ACR_USERNAME` existe
- [ ] `ACR_PASSWORD` existe (masked)
- [ ] `AKS_CLUSTER_NAME` existe
- [ ] `AKS_RESOURCE_GROUP` existe

### [ ] 3.2 - Service Principal tem permissões?

```bash
# Extrair clientId do AZURE_CREDENTIALS
CLIENT_ID=$(gh secret get AZURE_CREDENTIALS | jq -r .clientId)

# Verificar role assignments
az role assignment list --assignee $CLIENT_ID --output table
```

**Validação:**
- [ ] Role `Contributor` no Resource Group do AKS
- [ ] Scope correto: `/subscriptions/.../resourceGroups/$RESOURCE_GROUP`

---

## ✅ Fase 4: Validação Pipeline CI/CD

### [ ] 4.1 - Workflow existe e está correto?

```bash
cat .github/workflows/ci-cd.yml
```

**Validação:**
- [ ] Arquivo existe
- [ ] Trigger em `push: branches: [main]`
- [ ] Job `build-and-push` definido
- [ ] Job `deploy-to-aks` definido
- [ ] Secrets referenciados: `${{ secrets.ACR_LOGIN_SERVER }}`

### [ ] 4.2 - Pipeline executa no push?

```bash
# Fazer commit e push
git add .
git commit -m "test: validate pipeline"
git push origin main

# Acompanhar workflow
gh run watch
```

**Validação CI (build-and-push):**
- [ ] Job iniciou automaticamente
- [ ] Step "Build and push Docker image" completo
- [ ] Imagem no ACR: `az acr repository show-tags --name $ACR_NAME --repository devops-aks-demo`
- [ ] Tag com SHA do commit existe

**Validação CD (deploy-to-aks):**
- [ ] Job iniciou após CI
- [ ] Step "Deploy to AKS" completo
- [ ] Step "Verify deployment" mostra pods rodando
- [ ] Workflow verde (✅ Success)

### [ ] 4.3 - Ver logs completos do workflow

```bash
gh run view --log
```

**Validação:**
- [ ] Nenhum erro nos logs
- [ ] Build time < 5 min
- [ ] Deploy time < 3 min

---

## ✅ Fase 5: Validação Kubernetes

### [ ] 5.1 - Deployment criado?

```bash
kubectl get deployment devops-aks-demo-deployment
kubectl describe deployment devops-aks-demo-deployment
```

**Validação:**
- [ ] Deployment existe
- [ ] READY: `2/2` (2 réplicas rodando)
- [ ] UP-TO-DATE: `2`
- [ ] AVAILABLE: `2`
- [ ] Eventos mostram `ScalingReplicaSet: Scaled up`

### [ ] 5.2 - Pods estão saudáveis?

```bash
kubectl get pods -l app=devops-aks-demo
kubectl describe pods -l app=devops-aks-demo
```

**Validação:**
- [ ] 2 pods listados
- [ ] STATUS: `Running` em ambos
- [ ] READY: `1/1` em ambos
- [ ] RESTARTS: `0` em ambos
- [ ] Events não mostram erros (ImagePullBackOff, CrashLoopBackOff)
- [ ] Liveness probe: ✅ Success
- [ ] Readiness probe: ✅ Success

### [ ] 5.3 - Service criado e acessível?

```bash
kubectl get service devops-aks-demo-service
kubectl describe service devops-aks-demo-service
```

**Validação:**
- [ ] Service existe
- [ ] TYPE: `LoadBalancer`
- [ ] EXTERNAL-IP: não está `<pending>` (tem um IP)
- [ ] PORT: `80:3xxxx/TCP`
- [ ] Endpoints: mostra IPs dos 2 pods

### [ ] 5.4 - Logs dos pods estão corretos?

```bash
kubectl logs -l app=devops-aks-demo --tail=20
```

**Validação:**
- [ ] Logs mostram: `🚀 Server running on port 3000`
- [ ] Logs mostram: `📝 Environment: production`
- [ ] Sem stack traces ou erros
- [ ] Health check logs aparecem

---

## ✅ Fase 6: Validação End-to-End

### [ ] 6.1 - Aplicação responde via IP externo?

```bash
EXTERNAL_IP=$(kubectl get service devops-aks-demo-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Testing: http://$EXTERNAL_IP"

# Testar cada endpoint
curl -s http://$EXTERNAL_IP/ | jq
curl -s http://$EXTERNAL_IP/health | jq
curl -s http://$EXTERNAL_IP/info | jq
```

**Validação:**
- [ ] `curl http://$EXTERNAL_IP/` retorna JSON com dados corretos
- [ ] `message: "DevOps AKS Demo Application"`
- [ ] `version: "1.0.0"`
- [ ] `curl http://$EXTERNAL_IP/health` retorna `status: "healthy"`
- [ ] `uptime` é um número positivo
- [ ] `curl http://$EXTERNAL_IP/info` retorna hostname, platform, nodeVersion

### [ ] 6.2 - Load balancer distribui entre pods?

```bash
# Ver qual pod respondeu (hostname = pod name)
for i in {1..10}; do
  curl -s http://$EXTERNAL_IP/info | jq -r .hostname
done
```

**Validação:**
- [ ] Ambos os pod names aparecem nas respostas
- [ ] Distribuição de carga acontecendo

### [ ] 6.3 - Health checks funcionam?

```bash
# Forçar falha de liveness (opcional - vai reiniciar pod)
POD_NAME=$(kubectl get pods -l app=devops-aks-demo -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD_NAME -- killall node

# Observar Kubernetes reiniciar o pod automaticamente
kubectl get pods -l app=devops-aks-demo --watch
```

**Validação:**
- [ ] Kubernetes detecta container unhealthy
- [ ] Pod é reiniciado automaticamente
- [ ] `RESTARTS` incrementa para 1
- [ ] Service continua funcionando (outro pod responde)

---

## ✅ Fase 7: Validação Rolling Update

### [ ] 7.1 - Deploy de nova versão (zero downtime)?

```bash
# Alterar algo na aplicação
sed -i 's/"version": "1.0.0"/"version": "1.1.0"/' app/package.json

# Commit e push
git add app/package.json
git commit -m "feat: bump to v1.1.0"
git push origin main

# Acompanhar rollout
kubectl rollout status deployment/devops-aks-demo-deployment -w
```

**Validação durante rollout:**
```bash
# Em outro terminal, fazer requests contínuos
while true; do
  curl -s http://$EXTERNAL_IP/ | jq -r '.version // "ERROR"'
  sleep 0.5
done
```

**Validação:**
- [ ] Workflow CI/CD executou automaticamente
- [ ] Rolling update aconteceu: pods novos criados antes de matar antigos
- [ ] `kubectl get pods` mostra pods sendo terminados e criados
- [ ] **ZERO downtime:** requests contínuos SEM ERROS durante rollout
- [ ] Nova versão retornada após rollout: `"version": "1.1.0"`

### [ ] 7.2 - Rollback funciona?

```bash
kubectl rollout undo deployment/devops-aks-demo-deployment
kubectl rollout status deployment/devops-aks-demo-deployment
curl -s http://$EXTERNAL_IP/ | jq -r .version
```

**Validação:**
- [ ] Rollback completo sem erros
- [ ] Versão volta para `1.0.0`
- [ ] Zero downtime no rollback também

---

## ✅ Fase 8: Validação de Segurança

### [ ] 8.1 - Container roda como non-root?

```bash
kubectl get pods -l app=devops-aks-demo -o jsonpath='{.items[0].metadata.name}' | xargs -I {} kubectl exec {} -- id
```

**Validação:**
- [ ] `uid=1001(nodejs)` (não é root/0)
- [ ] `gid=1001(nodejs)`

### [ ] 8.2 - Capabilities dropadas?

```bash
kubectl get deployment devops-aks-demo-deployment -o yaml | grep -A5 securityContext
```

**Validação:**
- [ ] `runAsNonRoot: true`
- [ ] `allowPrivilegeEscalation: false`
- [ ] `capabilities.drop: [ALL]`

---

## ✅ Fase 9: Validação de Observabilidade

### [ ] 9.1 - Métricas disponíveis?

```bash
kubectl top nodes
kubectl top pods -l app=devops-aks-demo
```

**Validação:**
- [ ] Comandos retornam CPU e memória (não erro)
- [ ] Usage dentro dos limits definidos (500m CPU, 512Mi RAM)

### [ ] 9.2 - Logs acessíveis?

```bash
kubectl logs -l app=devops-aks-demo --tail=50 --timestamps
```

**Validação:**
- [ ] Logs aparecem com timestamps
- [ ] Formato estruturado e legível
- [ ] Sem erros/warnings inesperados

---

## 🎯 Resumo Final

Se TODOS os checkboxes acima estão marcados ✅, então:

✅ **Aplicação:** Funciona local e containerizada  
✅ **Infraestrutura:** Azure resources provisionados corretamente  
✅ **CI/CD:** Pipeline automático e funcional  
✅ **Kubernetes:** Deploy, scaling, health checks OK  
✅ **Networking:** LoadBalancer acessível publicamente  
✅ **Segurança:** Best practices aplicadas  
✅ **Observabilidade:** Logs e métricas disponíveis  
✅ **Zero Downtime:** Rolling updates sem downtime  

**🎉 PROJETO VALIDADO COMPLETAMENTE!**

---

## 🐛 Troubleshooting por Fase

### Falha na Fase 1 (Local)
- Verificar versão Node.js: `node --version` (>= 18)
- Reinstalar dependências: `rm -rf app/node_modules && cd app && npm install`

### Falha na Fase 2 (Azure)
- Verificar Azure CLI: `az --version`
- Relogin: `az login`
- Verificar subscription: `az account show`

### Falha na Fase 3 (Secrets)
- Verificar gh CLI: `gh --version`
- Reauth: `gh auth login`
- Listar secrets: `gh secret list`

### Falha na Fase 4 (Pipeline)
- Ver logs: `gh run view --log`
- Verificar permissões do Service Principal
- Testar credenciais manualmente: `docker login $ACR_LOGIN_SERVER`

### Falha na Fase 5 (K8s)
- Descrever recurso com erro: `kubectl describe pod <pod-name>`
- Ver eventos: `kubectl get events --sort-by='.lastTimestamp'`
- Verificar imagem no ACR: `az acr repository show-tags --name $ACR_NAME --repository devops-aks-demo`

### Falha na Fase 6 (E2E)
- Aguardar External IP: pode levar até 3 minutos
- Verificar security groups/firewall não estão bloqueando
- Testar de dentro do cluster: `kubectl run -it --rm debug --image=curlimages/curl -- curl http://devops-aks-demo-service`

---

**Lembre-se:** Pecamos pelo excesso, não pela falta! 🎯
