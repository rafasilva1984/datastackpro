
# 🧠 Observabilidade com OpenTelemetry + Elastic Stack

Este projeto é um laboratório completo que demonstra como implementar observabilidade full-stack em uma aplicação Node.js usando OpenTelemetry e Elastic Stack (Elasticsearch, Kibana, APM Server).

---

## 🚀 Visão Geral

Neste cenário simulado, temos:

- Uma aplicação Node.js com três rotas principais (`/login`, `/checkout`, `/error`)
- Coleta de traces com OpenTelemetry
- Exportação dos dados via OpenTelemetry Collector
- Visualização dos dados em dashboards no Kibana (métricas, logs e traces)

---

## 🧱 Arquitetura

```
[Usuário] → [Aplicação Node.js] → [OTel Collector] → [APM Server] → [Elasticsearch] → [Kibana]
```

---

## 📦 Componentes

| Serviço        | Porta | Descrição                                |
|----------------|-------|------------------------------------------|
| Node.js App    | 3000  | Gera logs/traces                         |
| OTEL Collector | 4317  | Recebe os traces                         |
| APM Server     | 8200  | Converte para dados do Elastic APM       |
| Elasticsearch  | 9200  | Armazena dados observados                |
| Kibana         | 5601  | Interface de visualização e dashboards   |

---

## 🛠️ Como executar

### 1. Clone o repositório

```bash
git clone https://github.com/rafasilva1984/datastackpro/tree/main/elasticsearch/opentelemetry-lab
cd opentelemetry-lab/docker
```

### 2. Suba a stack com Docker Compose

```bash
docker compose up -d
```

Aguarde 1-2 minutos até todos os serviços estarem no ar.

### 3. Acesse o Kibana

Acesse: [http://localhost:5601](http://localhost:5601)

### 4. Gere dados com o app

Abra um terminal e rode:

```bash
curl http://localhost:3000/login
curl http://localhost:3000/checkout
curl http://localhost:3000/error
```

Repita algumas vezes para gerar mais de 200 traces diferentes.

---

## 📊 Dashboards

Importe o arquivo `dashboards/dashboard-otel.ndjson` no Kibana para visualizar os traces de forma organizada por rota, tempo e status.

---

## 📚 História do cenário

Imagine um time de SRE monitorando uma API crítica. Com OpenTelemetry, é possível rastrear onde está a lentidão, identificar gargalos e ver como os usuários trafegam pelo sistema. Com Elastic APM, visualizamos esses dados em tempo real e acionamos alertas se necessário.

---

## 👨‍💻 Autor

Rafael Silva  
[LinkedIn](http://linkedin.com/in/rafael-silva-leader-coordenador) | [GitHub](https://github.com/rafasilva1984)

---

## 🧠 Dica

Use `hey` ou `k6` para gerar carga automatizada. Veja o diretório `scripts`.



---

## 💡 Rodando tudo localmente na sua máquina

Essa PoC foi desenhada para funcionar **apenas com Docker** na sua própria máquina, sem necessidade de nenhum ambiente em nuvem ou cluster Kubernetes.

### Por que isso funciona?

- O Docker Compose cria uma **rede interna isolada**, onde os containers (app, collector, apm-server, etc) se comunicam entre si por nome.
- A sua máquina só precisa ter **Docker e Docker Compose** instalados.
- Todos os serviços são configurados com recursos leves (1 GB RAM por container no máximo).
- Perfeito para simular um cenário real sem exigir recursos de nuvem.

---

## 🐳 Dependências necessárias

Certifique-se de ter os seguintes itens instalados antes de subir a stack:

- Docker Engine (versão 20.10+)
- Docker Compose (integrado ou standalone)

---



---

## 📊 Dashboard no Kibana

Após executar a PoC e gerar os dados, importe o dashboard pronto:

1. Acesse o Kibana: [http://localhost:5601](http://localhost:5601)
2. Vá em **Stack Management > Saved Objects**
3. Clique em **Import** e selecione o arquivo `dashboards/dashboard-otel.ndjson`
4. O dashboard "OpenTelemetry - App Observability" será criado

---

## 🔁 Como gerar carga automaticamente

Use o script a seguir para simular chamadas à aplicação:

```bash
cd scripts
chmod +x load-test.sh
./load-test.sh
```

Isso irá gerar 210 requisições (70 de cada tipo), o suficiente para visualizar um cenário real de tráfego no painel.

---

## 📌 Considerações Finais

Esta PoC foi criada para rodar de forma simples e eficiente **100% localmente**, simulando um ambiente real de Observabilidade como usado por equipes de SRE e DevOps.

Você poderá:
- Rastrear erros reais gerados pela app
- Visualizar latência entre serviços
- Entender como os dados trafegam da aplicação até o Elasticsearch

Este laboratório pode ser expandido com:
- Alertas automáticos no Kibana
- Análise de logs com Filebeat
- Métricas de infraestrutura com Metricbeat

---

🧠 Explore, teste, quebre e aprenda!
