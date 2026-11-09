# Proposta futura: Argo CD e GitOps

> **Status:** documentação de uma possível evolução. Argo CD não está instalado ou configurado; o workflow atual publica a imagem e aplica `k8s/` via `kubectl`.

## Objetivo

Usar Git como fonte declarativa do estado da aplicação no AKS. GitHub Actions continuaria construindo e publicando a imagem no ACR; Argo CD sincronizaria os manifests versionados no repositório. O Argo CD não constrói nem publica imagens.

Argo CD é executado dentro de um cluster Kubernetes e monitora um repositório Git para reconciliar recursos. Consulte a [arquitetura oficial](https://argo-cd.readthedocs.io/en/stable/operator-manual/architecture/) e o [guia de primeiros passos](https://argo-cd.readthedocs.io/en/stable/getting_started/).

## Fluxo desejado

```text
Pull request → validação
Merge em main → GitHub Actions constrói e publica imagem com tag SHA
Atualização versionada da tag no Git → Argo CD sincroniza os manifests no AKS
```

O workflow atual ainda não atualiza a tag no Git nem entrega a sincronização ao Argo CD. A automação descrita acima é uma proposta, não uma capacidade já implementada.

## Trabalho necessário antes da adoção

1. Escolher Kustomize ou Helm para parametrizar a imagem. Hoje `k8s/deployment.yaml` usa `${ACR_LOGIN_SERVER}` e `${IMAGE_TAG}` via `envsubst`, que o Argo CD não executa.
2. Definir como o CI registrará a nova tag no Git após publicar a imagem, com permissões mínimas e revisão adequada.
3. Instalar Argo CD no AKS e configurar uma `Application` para acompanhar o caminho dos manifests.
4. Validar sincronização, saúde da aplicação e política de rollback.
5. Só depois da validação, remover do workflow o job que aplica Deployment e Service via `kubectl`, evitando dois controladores para os mesmos recursos.

Comece sem prune automático até validar o comportamento. Consulte a documentação sobre [automação a partir de CI](https://argo-cd.readthedocs.io/en/latest/user-guide/ci_automation/) e [sincronização automática](https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/).

## Acesso à interface

Para uma instalação futura, mantenha a interface privada e use port-forward durante o desenvolvimento:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Então acesse `https://localhost:8080`. Consulte a documentação oficial para [acesso local](https://argo-cd.readthedocs.io/en/stable/try_argo_cd_locally/).

## Recursos e custos

Esta proposta não instala Argo CD nem altera infraestrutura. Uma instalação consome recursos do cluster e pode exigir recursos Azure adicionais. Antes de adotá-la, confira os requisitos atuais do Argo CD, a capacidade do AKS e os custos dos recursos Azure que ficariam ativos, inclusive quando o cluster estiver parado.
