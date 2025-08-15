# PoC — CI/CD com Jenkins + Kubernetes (kind) + Elastic local (OTel + APM) **e Variante Prod‑Ready**
**Atualizado em 2025-08-15**

Este pacote entrega **duas trilhas**:

1. **Local (sem registry)** — para validar rápido:
   - Jenkins (Docker) → `docker build` → `kind load` → deploy K8s → job **k6** (gates) → **OTel → APM → ES → Kibana**.
2. **Prod‑ready (com registry + Helm + hardening)** — para levar a produção com padrões de mercado:
   - **Kaniko** (build sem DinD) + **registry** (Docker Hub/GHCR/ECR…)
   - Deploy com **Helm** (`charts/sampleapp`), **HPA**, **PDB**, **NetworkPolicy**.
   - Observabilidade via **Elastic Cloud** (mais simples) ou **ECK** (self‑managed).
   - **Quality gates**: k6 + **Trivy** (CVEs) + **OPA/Gatekeeper** (políticas).
   - Caminho para **Canary/Blue‑Green** (Argo Rollouts).

---

## 0) Pré‑requisitos
- Docker, kubectl, kind, (opcional) helm.
- Porta 8081 livre (Jenkins).

> Se usar Linux com cgroup v2 e ES, ajuste `vm.max_map_count` nos nós do kind (ver seção troubleshooting).

---

## 1) Trilha Local (sem registry)

### 1.1 Criar cluster kind
```bash
kind create cluster --config kind-cluster.yaml
docker exec -it poc-cicd-control-plane sysctl -w vm.max_map_count=262144 || true
docker exec -it poc-cicd-worker         sysctl -w vm.max_map_count=262144 || true
```

### 1.2 Subir Jenkins (Docker)
```bash
mkdir -p jenkins_home
docker run -d --name jenkins -p 8081:8080 -p 50000:50000   -v $PWD/jenkins_home:/var/jenkins_home   -v /var/run/docker.sock:/var/run/docker.sock   -v $HOME/.kube:/home/jenkins/.kube   jenkins/jenkins:lts

# instalar kubectl e kind dentro do container jenkins:
docker exec -it jenkins bash -lc '  curl -Lo /usr/local/bin/kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64 && chmod +x /usr/local/bin/kind;   curl -Lo /usr/local/bin/kubectl https://dl.k8s.io/release/v1.30.2/bin/linux/amd64/kubectl && chmod +x /usr/local/bin/kubectl '
```

### 1.3 Pipeline
- Crie um job apontando para este repositório (Jenkinsfile raiz).
- O pipeline fará: **build → load no kind → deploy ES/Kibana/APM/OTel + app → job k6**.

### 1.4 Acesso
```bash
kubectl -n cicd port-forward svc/kibana 5601:5601    # Kibana
kubectl -n cicd port-forward svc/sampleapp 8080:8080 # App
```

---

## 2) Observabilidade (Local)
- OTel Collector recebe OTLP (4317/4318) e exporta para o **APM Server** local (gRPC 8200).
- O APM Server indexa no Elasticsearch; visualize no **Kibana > Observability > APM**.
- Para logs/infra do cluster, inclua **Elastic Agent** (DaemonSet) com integrações Kubernetes/System (não incluso por padrão).

---

## 3) Troubleshooting rápido
- **ES CrashLoop** → aplique `vm.max_map_count` nos nós do kind e reinicie o deploy do ES.
- **k6 falhou thresholds** → veja os logs do job `k6-smoke` e ajuste recursos/thresholds.
- **Sem dados no APM** → gere tráfego (`/login`, `/checkout`, `/error`) e veja logs do `otel-collector` e `apm-server`.

---

## 4) Trilha Prod‑Ready (com registry + Helm + hardening)

### 4.1 Pilares
- **Registry**: Docker Hub, GHCR, ECR/ACR/GCR.
- **Build**: **Kaniko** (sem Docker no agente).
- **Deploy**: **Helm** (`charts/sampleapp`) com HPA/PDB/NetworkPolicy.
- **Observabilidade**: **Elastic Cloud** (recomendado) **ou** **ECK** (self‑managed).
- **Segurança**: **Trivy** (CVEs), **OPA/Gatekeeper** (políticas), Pod Security, NetworkPolicy, SBOM.
- **Release strategies**: canary/blue‑green com Argo Rollouts.

### 4.2 Pipelines (Jenkins)
Use `prod/Jenkinsfile-kaniko`. Ajuste:
- `REGISTRY_URL` e `IMAGE_NAME` (ex.: `docker.io/rafasilva1984/sampleapp`).
- Credencial `docker-registry-creds` no Jenkins.
- Namespace de produção (`app`) e permissões (SA/RBAC).

### 4.3 Helm do app
- Chart em `charts/sampleapp` com:
  - HPA ligado a CPU/Mem.
  - PDB (minAvailable: 1).
  - NetworkPolicy (deny-all + egress OTEL).
  - Env OTEL (endpoint/env).
- Instalação:
```bash
helm upgrade --install sampleapp charts/sampleapp -n app   --set image.repository=docker.io/rafasilva1984/sampleapp   --set image.tag=1.0.0   --set otel.endpoint=http://otel-collector.observability.svc.cluster.local:4317   --set otel.environment=production
```

### 4.4 Observabilidade em produção
**Opção A — Elastic Cloud** (mais simples)
1. Crie a API Key e obtenha o endpoint APM.
2. Aplique o secret e o OTel Collector:
   ```bash
   kubectl apply -f prod/observability/elastic-cloud/secret-apm.yaml
   kubectl apply -f prod/observability/otel-collector.yaml
   ```
3. Configure o Helm do app com `otel.endpoint` apontando para o Collector.

**Opção B — ECK (self‑managed)**
1. Instale o **ECK Operator** (ver docs oficiais).
2. Aplique os manifests:
   ```bash
   kubectl apply -f prod/observability/eck/namespace.yaml
   kubectl apply -f prod/observability/eck/elasticsearch.yaml
   kubectl apply -f prod/observability/eck/kibana.yaml
   kubectl apply -f prod/observability/eck/apmserver.yaml
   ```
3. Pegue a senha do `elastic` gerada pelo ECK (secret) e acesse o Kibana.
4. Aponte o OTel Collector para o APM do ECK (TLS).

### 4.5 Hardening
- **NetworkPolicy**: veja `prod/k8s/app/networkpolicy-*.yaml`.
- **PDB**: `prod/k8s/app/pdb.yaml`.
- **Pod Security**: rótulo `pod-security.kubernetes.io/enforce=baseline` no namespace.
- **Gates de segurança**:
  - **Trivy** (`prod/ci/trivy-scan.sh`): falha o build em CVEs críticos/altos.
  - **OPA/Gatekeeper** (`prod/policy/gatekeeper-constraint.yaml`): exige requests/limits.
- **SBOM**: gere com **Syft** e armazene por build.

### 4.6 Canary / Blue‑Green (opcional)
- Use **Argo Rollouts** com análise (k6 ou métricas APM). Exemplo de análise pode rodar um job k6 curto e só promover se thresholds ok.

---

## 5) Boas práticas para SRE/SLO gates
- Mantenha thresholds do **k6** alinhados aos **SLOs** (p95, taxa de erro).
- Adicione **quality gate** que consulta a API do Kibana/Elastic (SLO em “Observability → SLO”) antes de promover a release.
- Gere **links de trace** (trace.id) nos logs do pipeline para depuração.

---

## 6) Estrutura do repositório (resumo)
```
charts/sampleapp/                 # Helm chart prod-ready
prod/
  Jenkinsfile-kaniko              # pipeline para produção (com registry)
  ci/trivy-scan.sh
  k6/k6-smoke-job.yaml
  k8s/app/*.yaml                  # namespace, networkpolicy, pdb
  observability/
    elastic-cloud/*.yaml          # OTel -> Elastic Cloud
    eck/*.yaml                    # Elasticsearch/Kibana/APM via ECK
k8s/                              # (PoC local)
  observability/*.yaml            # ES/Kibana/APM/OTel locais (sem auth)
  app/*.yaml                      # app para PoC local
  jobs/k6-smoke-job.yaml
Jenkinsfile                       # pipeline PoC (kind load)
kind-cluster.yaml
sampleapp/ (Node app)
```

---

## 7) Próximos passos sugeridos
- Validar **PoC local** (tudo neste repo).
- Escolher caminho de produção: **Elastic Cloud vs ECK** + **registry**.
- Substituir deploy PoC por **Helm** (chart incluso).
- Adicionar **Trivy** e **Gatekeeper** no pipeline.
- (Opcional) Argo Rollouts + SLO gates automáticos.

---

## 8) Troubleshooting (produção)
- **Pull falha (ImagePullBackOff)** → confira `imagePullSecrets`/credencial do registry.
- **TLS quebrado no ECK** → verifique secrets e endpoints; inicie com self‑signed e evolua para cert‑manager.
- **HPA não escala** → verifique métricas server (metrics‑server) e targets.

---

**FIM** — Dúvidas ou quer que eu personalize para Docker Hub, GHCR ou ECR já com seus nomes e tokens? Posso deixar 100% “colar e rodar”.
