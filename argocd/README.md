# Estudo futuro: Argo CD e GitOps

> **Status:** proposta futura. Argo CD não está instalado nem configurado neste cluster.

## Objetivo

Usar Argo CD para sincronizar a aplicação no AKS a partir dos manifests versionados no Git. O Terraform continua responsável pela infraestrutura Azure; GitHub Actions continua responsável pelo build e publicação da imagem no ACR.

## Onde o Argo CD é executado

Argo CD é uma aplicação open source que roda dentro de um cluster Kubernetes. A instalação cria vários componentes, executados em pods — normalmente no namespace `argocd` — que leem o repositório Git e sincronizam os recursos declarados com o cluster. A arquitetura e seus componentes estão descritos na [documentação oficial](https://argo-cd.readthedocs.io/en/stable/operator-manual/architecture/).

Para esta demo, a proposta é instalar o Argo CD no AKS já existente, sem criar outro cluster. Os pods do Argo CD usarão CPU e memória dos nodes atuais; se a capacidade ficar insuficiente, pode ser necessário aumentar os recursos do cluster, o que pode gerar custos adicionais. O [guia oficial de instalação e primeiros passos](https://argo-cd.readthedocs.io/en/stable/getting_started/) cobre a instalação, o acesso à interface e a criação de uma aplicação a partir do Git.

## Fluxo proposto

```text
Push do código
  → GitHub Actions cria e publica imagem com tag SHA no ACR
  → CI atualiza a tag de imagem no repositório Git
  → Argo CD detecta a alteração e sincroniza k8s/ no AKS
  → AKS executa a nova versão
```

Argo CD acompanha o estado declarado no Git e pode sincronizar automaticamente as mudanças detectadas no cluster. O fluxo do Argo CD não constrói nem publica imagens; essa parte permanece no CI. Veja a [automação do Argo CD a partir de pipelines CI](https://argo-cd.readthedocs.io/en/latest/user-guide/ci_automation/) e a [sincronização automática](https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/).

## Ajustes necessários antes da adoção

1. Migrar a imagem do deployment para Kustomize ou Helm. Hoje `k8s/deployment.yaml` usa `${ACR_LOGIN_SERVER}` e `${IMAGE_TAG}`, preenchidos pelo `envsubst` do workflow; Argo CD não executará essa etapa do shell.
2. Fazer o CI atualizar a tag SHA no repositório Git depois de publicar a imagem. Argo CD então aplica a versão declarada no Git.
3. Instalar Argo CD no AKS e declarar uma `Application` que acompanhe o caminho `k8s/`.
4. Validar a sincronização e o estado saudável da aplicação.
5. Depois da validação, remover do workflow GitHub Actions o job `deploy-to-aks`, que atualmente usa `kubectl apply`. Argo CD deve ser o único responsável por sincronizar `Deployment` e `Service` para evitar dois controladores disputando os mesmos recursos.

Para o primeiro uso, recomenda-se validar a sincronização manualmente e deixar `prune` desativado até confirmar o comportamento. Argo CD desativa o prune automático por padrão; habilitá-lo depois pode remover recursos que deixarem de existir nos manifests.

## Acesso à interface

Por padrão, a interface do Argo CD não é exposta fora do cluster. Para uma demo, use port-forward local:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Depois, acesse `https://localhost:8080`. Isso evita criar um novo Service `LoadBalancer` apenas para a interface. A [documentação de acesso do Argo CD](https://argo-cd.readthedocs.io/en/stable/try_argo_cd_locally/) descreve esse método.

## Custos para esta demo

- **Licença do Argo CD:** sem cobrança de licença; o projeto usa licença Apache 2.0 ([repositório oficial](https://github.com/argoproj/argo-cd)).
- **Recursos do cluster:** Argo CD executa componentes dentro do AKS e consome CPU e memória dos nodes existentes. Se a capacidade ficar insuficiente e for necessário aumentar ou adicionar nodes, haverá custo adicional.
- **Tier do AKS:** o cluster está no tier `Free`; esse tier não cobra a gestão do control plane, mas os recursos Azure subjacentes continuam cobrados ([preços do AKS](https://azure.microsoft.com/en-us/pricing/details/kubernetes-service/)).
- **Exposição externa:** usar um novo `LoadBalancer`, IP público ou gateway para a interface pode adicionar custos de rede. A cobrança do Standard Load Balancer depende de regras configuradas e tráfego processado ([preços do Load Balancer](https://azure.microsoft.com/en-us/pricing/details/load-balancer/)). Para a demo, port-forward evita essa exposição.

Não há um custo mensal fixo específico do Argo CD. O valor incremental depende do consumo real do cluster e de como a interface é exposta. Esta proposta não provisiona recursos nem muda o workflow atual.
