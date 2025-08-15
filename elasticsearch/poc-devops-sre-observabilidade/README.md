# PoC CI/CD + K8s (kind) + Observabilidade (Elastic local)

## 0) Visão geral

Objetivo: uma PoC local, sem registry, que comprova **DevOps + SRE + Observabilidade ponta-a-ponta**:

```
Dev → Git push → Jenkins (Docker) 
      ├─ docker build sampleapp:<TAG>
      ├─ kind load docker-image sampleapp:<TAG>
      ├─ kubectl apply (Deploy/Service)
      └─ Job k6 (smoke + thresholds)

[SampleApp] -- OTLP --> [OpenTelemetry Collector] -- OTLP --> [APM Server]
                                              ↘ logs (stdout)
                 [APM Server] → [Elasticsearch] ↔ [Kibana (APM)]
```

**Por que funciona sem registry?**  
A imagem é construída localmente, e o `kind load docker-image` copia a imagem para o runtime dos nós do cluster kind. O Deployment usa `imagePullPolicy: IfNotPresent`, então o kubelet encontra a imagem local no nó e não tenta puxar de um registry externo.

---

## 1) O que vem no repositório

```
.
├─ Jenkinsfile                           # pipeline sem registry
├─ kind-cluster.yaml                     # cluster local (kind)
├─ sampleapp/                            # app NodeJS com healthchecks
│  ├─ Dockerfile
│  ├─ package.json
│  └─ app.js
└─ k8s/
   ├─ namespace.yaml                     # namespace cicd
   ├─ app/
   │  ├─ deployment.yaml                 # image: sampleapp:__TAG__ + OTEL envs
   │  └─ service.yaml                    # Service (ClusterIP)
   ├─ jobs/
   │  └─ k6-smoke-job.yaml               # smoke test (p95<300ms, erro<2%)
   └─ observability/
      ├─ elasticsearch.yaml              # ES single-node (sem auth) p/ PoC
      ├─ kibana.yaml                     # Kibana apontando para ES local
      ├─ apm-server.yaml                  # APM Server com OTLP habilitado
      └─ otel-collector.yaml              # OTel Collector (OTLP→APM + logging)
```

---

## 2) Requisitos

### Windows (recomendado)
- Docker Desktop (habilite “Use the WSL 2 based engine”).
- `kubectl.exe` no PATH — [download](https://dl.k8s.io/release/v1.30.2/bin/windows/amd64/kubectl.exe)  
- `kind.exe` no PATH — [download](https://kind.sigs.k8s.io/dl/latest/kind-windows-amd64)  
  Renomeie para `kind.exe` e adicione ao PATH.

Valide no PowerShell:
```powershell
kind version
kubectl version --client
```

### macOS / Linux
- Docker, kubectl e kind instalados (via brew/apt/yum).

---

## 3) Subindo o cluster kind
```powershell
kind create cluster --config kind-cluster.yaml
kubectl get nodes
```

**Ajuste necessário para o Elasticsearch (vm.max_map_count)**:
```powershell
docker exec -it poc-cicd-control-plane sysctl -w vm.max_map_count=262144
docker exec -it poc-cicd-worker         sysctl -w vm.max_map_count=262144
```

---

## 4) Subindo o Jenkins (em Docker) com acesso ao Docker/K8s
```powershell
mkdir jenkins_home

docker run -d --name jenkins `
  -p 8081:8080 -p 50000:50000 `
  -v "$PWD/jenkins_home:/var/jenkins_home" `
  -v "//var/run/docker.sock:/var/run/docker.sock" `
  -v "$env:USERPROFILE\.kube:/home/jenkins/.kube" `
  jenkins/jenkins:lts
```

**Instalar kubectl e kind dentro do container**:
```bash
docker exec -it jenkins bash -lc '
  apt-get update && apt-get install -y curl ca-certificates;
  curl -Lo /usr/local/bin/kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64 && chmod +x /usr/local/bin/kind;
  curl -Lo /usr/local/bin/kubectl https://dl.k8s.io/release/v1.30.2/bin/linux/amd64/kubectl && chmod +x /usr/local/bin/kubectl;
  kubectl version --client && kind version
'
```

---

## 5) Criando o pipeline e primeiro build
No Jenkins:
1. Crie Pipeline apontando para este repositório.
2. Execute.

Estágios:
- **Checkout**
- **Unit tests** (Node 20)
- **Build image**  
  `docker build -t sampleapp:<TAG> -f sampleapp/Dockerfile .`
- **Load para kind**  
  `kind load docker-image sampleapp:<TAG> --name poc-cicd`
- **Deploy**
- **Smoke Test (k6)**

---

## 6) Acessando app e Kibana
```powershell
# Kibana
kubectl -n cicd port-forward svc/kibana 5601:5601
# App
kubectl -n cicd port-forward svc/sampleapp 8080:8080
```
- Kibana: [http://localhost:5601](http://localhost:5601) → Observability > APM  
- App: [http://localhost:8080/login](http://localhost:8080/login)

---

## 7) Entendendo a Observabilidade
- **OpenTelemetry Collector** → recebe OTLP, exporta para logging + APM Server.
- **APM Server** → habilitado para OTLP, indexa no Elasticsearch.
- **Elasticsearch & Kibana** → armazenam e exibem dados APM.

---

## 8) k6 (quality gate)
Rodar manualmente:
```bash
kubectl -n cicd delete job k6-smoke --ignore-not-found=true
kubectl -n cicd apply -f k8s/jobs/k6-smoke-job.yaml
kubectl -n cicd wait --for=condition=complete job/k6-smoke --timeout=180s
```

---

## 9) Troubleshooting
- **Elasticsearch CrashLoopBackOff** → ajustar `vm.max_map_count`.
- **Jenkins sem acesso a Docker/K8s** → conferir volumes montados.
- **Sem dados no APM** → gerar tráfego no app e verificar logs.
- **k6 falhando thresholds** → verificar recursos e ajustar thresholds.

---

## 10) Extensões úteis
- Elastic Agent (DaemonSet) para logs/métricas do cluster.
- SLOs & Alertas no Kibana.
- Quality Gate via SLO.

---

## 11) Limpeza
```powershell
docker rm -f jenkins
kind delete cluster --name poc-cicd
```

---

## 12) Glossário rápido
- **kind**: Kubernetes in Docker.  
- **Jenkins**: servidor de automação/CI.  
- **OpenTelemetry (OTel)**: padrão aberto para observabilidade.  
- **APM Server**: recebe dados APM/OTLP e indexa no ES.  
- **Elasticsearch/Kibana**: armazenamento/visualização.  
- **k6**: testes de carga e performance.
