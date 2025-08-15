# PoC — CI/CD com Jenkins + Kubernetes (kind) + Elastic local (APM + OTel) — PACOTE COMPLETO

> **Objetivo:** Subir uma pipeline CI/CD **sem registry** (build local → `kind load`), fazer deploy em Kubernetes, executar **teste de fumaça (k6)** e observar **traces/métricas** com **OpenTelemetry Collector → APM Server → Elasticsearch → Kibana** — tudo **local** e replicável.
>
> **Público-alvo:** times DevOps/SRE/Engenharia que querem uma PoC prática, com “caminho para produção” no final.

---

## 0) Estrutura do repositório

```
poc-cicd-jenkins-kind-elastic/
├─ Jenkinsfile
├─ kind-cluster.yaml
├─ sampleapp/
│  ├─ Dockerfile
│  ├─ package.json
│  └─ app.js
└─ k8s/
   ├─ namespace.yaml
   ├─ app/
   │  ├─ deployment.yaml
   │  └─ service.yaml
   ├─ jobs/
   │  └─ k6-smoke-job.yaml
   └─ observability/
      ├─ elasticsearch.yaml
      ├─ kibana.yaml
      ├─ apm-server.yaml
      └─ otel-collector.yaml
```

**Pontos-chave**
- **Sem registry:** `imagePullPolicy: IfNotPresent` e `kind load docker-image`.
- **Observabilidade local:** OTel Collector → APM Server → Elasticsearch → Kibana (sem segurança, por simplicidade de PoC).

---

## 1) Pré-requisitos de host

- **Docker Engine** (rootless funciona também)
- **kubectl** (>= 1.28 recomendado)
- **kind** (>= 0.23)
- (Opcional) **helm**
- Porta livre **8081** para Jenkins, **5601** e **8080** para port-forward

> ### Dica de conferência
> ```bash
> docker --version
> kubectl version --client
> kind version
> ```

---

## 2) Subindo o cluster Kubernetes (kind)

1. Crie o cluster:
   ```bash
   kind create cluster --config kind-cluster.yaml
   kubectl cluster-info
   ```
2. **Ajuste obrigatório para Elasticsearch** nos nós do kind (repetir sempre que recriar o cluster):
   ```bash
   docker exec -it poc-cicd-control-plane sysctl -w vm.max_map_count=262144 || true
   docker exec -it poc-cicd-worker         sysctl -w vm.max_map_count=262144 || true
   ```

> **Por que isso?** O Elasticsearch usa mmap; `vm.max_map_count` baixo causa crashloop no pod.

---

## 3) Jenkins local (em Docker)

1. Suba o Jenkins com acesso ao Docker e ao kubeconfig do host:
   ```bash
   mkdir -p jenkins_home
   docker run -d --name jenkins      -p 8081:8080 -p 50000:50000      -v "$PWD/jenkins_home:/var/jenkins_home"      -v /var/run/docker.sock:/var/run/docker.sock      -v $HOME/.kube:/home/jenkins/.kube      jenkins/jenkins:lts
   ```

2. Instale **kubectl** e **kind** dentro do container do Jenkins (uma vez):
   ```bash
   docker exec -it jenkins bash -lc '     apt-get update && apt-get install -y curl ca-certificates &&      curl -Lo /usr/local/bin/kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64 && chmod +x /usr/local/bin/kind &&      curl -Lo /usr/local/bin/kubectl https://dl.k8s.io/release/v1.30.2/bin/linux/amd64/kubectl && chmod +x /usr/local/bin/kubectl &&      kubectl version --client && kind version    '
   ```

3. Acesse **http://localhost:8081**, finalize o setup inicial e garanta que os plugins **Pipeline**, **Credentials Binding** e **Timestamper** estão instalados.

---

## 4) Criar o pipeline

- Crie um **Pipeline** no Jenkins apontando para este diretório (com `Jenkinsfile` na raiz).  
  (Pode ser Pipeline “clássico” com SCM ou Multibranch).  
- Não são necessárias credenciais extras, pois o pipeline **não usa registry**.

> **Fluxo do Jenkinsfile**
> 1. `npm ci && npm test` (sampleapp)  
> 2. `docker build -t sampleapp:<TAG>`  
> 3. `kind load docker-image sampleapp:<TAG>`  
> 4. `kubectl apply` (Elastic stack + app) e `rollout status`  
> 5. Job **k6** com thresholds (falha pipeline se quebrar)

---

## 5) Primeiro build e validação

Após rodar o pipeline:

### 5.1 Ver pods
```bash
kubectl -n cicd get pods -o wide
```

Você deverá ver `elasticsearch`, `kibana`, `apm-server`, `otel-collector`, `sampleapp`, e o Job `k6-smoke` com status **Completed**.

### 5.2 Acessar o app
```bash
kubectl -n cicd port-forward svc/sampleapp 8080:8080
curl http://localhost:8080/login
curl http://localhost:8080/checkout
curl -i http://localhost:8080/error
```

### 5.3 Acessar o Kibana
```bash
kubectl -n cicd port-forward svc/kibana 5601:5601
# Navegue em http://localhost:5601
# APM: Observability > APM > Serviços -> "sampleapp"
```

> **Dica:** se o APM ainda estiver vazio, gere tráfego chamando os endpoints acima por 1–2 minutos ou reexecute o Job k6:
> ```bash
> kubectl -n cicd delete job k6-smoke --ignore-not-found=true
> kubectl -n cicd apply -f k8s/jobs/k6-smoke-job.yaml
> kubectl -n cicd wait --for=condition=complete job/k6-smoke --timeout=180s
> ```

---

## 6) O que está por trás (funcionalidades e fluxos)

### 6.1 CI/CD (Jenkinsfile)
- **Build local**: imagem criada via Docker no host (montado no Jenkins).
- **Distribuição para o cluster**: `kind load docker-image` injeta a imagem **direto** no runtime do kind.
- **Deploy**: substituição de tag no `Deployment` (`sampleapp:__TAG__` → `sampleapp:<TAG>`) e `kubectl apply`.
- **Teste de fumaça**: Job k6 roda thresholds (`p95 < 300ms`, `erro < 2%`) e falha o pipeline se violar.

### 6.2 Observabilidade
- **OTLP**: o app envia para `otel-collector` (`4317` gRPC).  
- **Collector**: exporta para **APM Server** (gRPC `8200`) e também imprime no `stdout` (exporter `logging`).
- **APM Server**: indexa no **Elasticsearch**.  
- **Kibana**: visualiza em **Observability > APM**, com latência, taxa de erro, throughput e traces.

### 6.3 App demo
- Endpoints:
  - `/login` → 200 OK
  - `/checkout` → 200 com latência aleatória até 200 ms
  - `/error` → 500 (para orçamento de erro/thresholds)
- Probes: `/healthz` (liveness) e `/readyz` (readiness).

---

## 7) Troubleshooting rápido

- **ES em CrashLoopBackOff** → setar `vm.max_map_count` nos nós do kind (Seção 2).  
- **Kibana acessível mas sem dados** → gere tráfego e verifique `kubectl -n cicd logs deploy/otel-collector -f` e `deploy/apm-server -f`.  
- **k6 falha thresholds** → veja logs do Job:  
  ```bash
  kubectl -n cicd logs job/k6-smoke
  ```
- **Jenkins não tem kubectl/kind** → instale conforme Seção 3.2.  
- **Port-forward ocupado** → troque a porta local (`5602`, `8081`, etc.).

---

## 8) Como levar este cenário para produção

### 8.1 Container Registry
- Adote **Docker Hub / GHCR / Artifactory / ECR / ACR**.
- Troque a stage `kind load` por **Kaniko** + push e inclua `imagePullSecrets` no Deployment.  
- Use **tags imutáveis** (ex.: commit SHA) e mantenha “latest” só para dev.

### 8.2 Elastic “prod‑ready”
- **Elastic Cloud** (recomendado) ou **ECK Operator** para self‑managed.
- **Segurança**: habilite TLS, autenticação (`elastic`, `kibana_system`) e RBAC.
- **Persistência**: troque `emptyDir` por **PVCs** (StorageClass do provedor).
- **Backups**: snapshots periódicos (S3/GCS/NFS).

### 8.3 Observabilidade expandida
- Adicione **Elastic Agent** (DaemonSet) para **logs/métricas de cluster** (kubelet, kube‑state, cAdvisor).
- Coleta **Prometheus** via OTel Receiver (para métricas de apps/libs).
- **SLOs**: configure em Kibana (Observability > SLO) e publique **gates no Jenkins** (chamando API do Kibana).

### 8.4 Entrega e Release
- Substitua `sed` por **Helm**/**Kustomize** (valores versionados).
- **Ambientes**: `dev` → `stg` → `prod` com promotion manual/automática.
- **Estratégias**: **Canary/Blue‑Green** (Argo Rollouts) com análise baseada em métricas (APM/Prometheus/k6).

### 8.5 Segurança e Compliance
- **Trivy** no estágio de build (falha se CVEs críticas).  
- **OPA/Gatekeeper**: policies (no root, fs read-only, limits obrigatórios, no privileged).  
- **SBOM** (Syft/Grype) e assinatura de imagens (Cosign).

---

## 9) Operação do dia a dia (comandos úteis)

```bash
# Visão geral
kubectl -n cicd get all

# Logs do Collector e APM
kubectl -n cicd logs deploy/otel-collector -f
kubectl -n cicd logs deploy/apm-server -f

# Reaplicar somente o app após novo build local
kubectl -n cicd rollout restart deploy/sampleapp

# Executar k6 novamente
kubectl -n cicd delete job k6-smoke --ignore-not-found=true
kubectl -n cicd apply -f k8s/jobs/k6-smoke-job.yaml
kubectl -n cicd wait --for=condition=complete job/k6-smoke --timeout=180s

# Port-forward rápido
kubectl -n cicd port-forward svc/kibana    5601:5601
kubectl -n cicd port-forward svc/sampleapp 8080:8080
```

---

## 10) Roadmap opcional desta PoC (quando quiser evoluir)
- **Dashboards APM** exportados (`ndjson`) + **alertas** de p95/erro.
- **Elastic Agent** + integrações Kubernetes/System para visão “full cluster”.
- **Canary** com Argo Rollouts e promoção automática por SLO.
- **Pipelines multi‑ambiente** (dev/stg/prod) com approvals e gates.
- **FinOps básico**: custo aproximado por serviço (eventos/tamanho/uptime).
- **Observabilidade de segurança**: ingestão de audit logs do K8s e do Jenkins.

---

## Créditos
Pacote preparado para o cenário do **Rafael Silva** (DevOps + SRE + Observabilidade).  
Versão: **2025‑08‑15**.

---

**Dúvidas?** Me chame que ajusto o que precisar — inclusive posso gerar a variante “prod-ready” com Helm/ECK, segurança e registry.
