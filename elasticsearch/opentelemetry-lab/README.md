
# 🚀 OpenTelemetry Lab – Observabilidade com Elastic APM

![DataStackPro](https://img.shields.io/badge/DataStackPro-Projeto%20Oficial-blue)
![Elastic APM](https://img.shields.io/badge/Elastic-APM-yellow)
![OpenTelemetry](https://img.shields.io/badge/OpenTelemetry-Instrumentation-purple)
![Docker](https://img.shields.io/badge/Docker-Compose-blue)

---

Este projeto demonstra, de forma prática, como aplicar observabilidade com OpenTelemetry enviando dados diretamente para o Elastic APM Server diretamente via OTLP para o Elastic APM Server — simulando o comportamento de uma aplicação real monitorada por rastreamento distribuído.

---

## 📌 Arquitetura

```
[ Node.js App ]
     |
     | OTLP HTTP Traces
     v
[ Elastic APM Server ] → [ Elasticsearch ] → [ Kibana ]
```

---

## ✅ Pré-requisitos

- Docker e Docker Compose instalados
- Acesso às portas `3000`, `5601`, `8200`, `9200`
- 4 GB de RAM livre para execução local
- Internet liberada (mesmo com proxy, o build já está preparado para SSL self-signed)

---

## 🧪 Como executar (Passo a Passo)

### 1. Clone o repositório principal

```bash
git clone https://github.com/rafasilva1984/datastackpro.git
cd datastackpro/elasticsearch/opentelemetry-lab/docker
```

---

### 2. Compile e suba os containers com Docker Compose

```bash
docker compose build
docker compose up -d
```

Os seguintes serviços serão iniciados:

| Serviço         | Descrição                   | Porta |
|-----------------|-----------------------------|-------|
| `app`           | Aplicação Node.js instrumentada OTEL | 3000  |
| `apm-server`    | Coletor de traces do Elastic APM     | 8200  |
| `elasticsearch` | Armazenamento dos dados observados  | 9200  |
| `kibana`        | Interface de análise e visualização | 5601  |

---

### 3. Gere tráfego para observação

Abra outro terminal e execute os seguintes comandos:

```bash
curl http://localhost:3000/login
curl http://localhost:3000/checkout
curl http://localhost:3000/error
```

Ou, execute o script automático:

```bash
cd ../scripts
chmod +x load-test.sh
./load-test.sh
```

---

### 4. Visualize no Kibana

Acesse: [http://localhost:5601](http://localhost:5601)

- Vá em **Observability > APM > Services**
- Clique no serviço detectado para visualizar os traces
- Explore transações, erros, dependências e tempo de resposta

---

## 📊 Dashboard adicional

1. Vá em **Stack Management > Saved Objects**
2. Clique em **Import**
3. Escolha o arquivo `dashboards/dashboard-otel.ndjson`
4. Acesse o dashboard importado

---

## 📁 Estrutura do Projeto

```
opentelemetry-lab/
├── app-nodejs/         # Código da aplicação com OpenTelemetry
│   └── Dockerfile      # Build local com suporte a SSL proxy
├── docker/             # Arquivos do Docker Compose
├── scripts/            # Scripts para carga de testes
├── dashboards/         # Dashboards Kibana exportados
└── README.md           # Documentação detalhada
```

---

## 🙋‍♂️ Autor

**Rafael Silva**  
🔗 [LinkedIn](http://linkedin.com/in/rafael-silva-leader-coordenador)  
🐙 [GitHub](https://github.com/rafasilva1984)

---

© 2025 - Projeto integrante da iniciativa **DataStackPro**
