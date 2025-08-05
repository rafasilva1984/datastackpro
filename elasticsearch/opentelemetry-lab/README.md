
# 📦 OpenTelemetry + Elastic Stack – Observabilidade na Prática

![DataStackPro](https://img.shields.io/badge/DataStackPro-Projeto%20Oficial-blue)
![Elastic APM](https://img.shields.io/badge/Elastic-APM-yellow)
![OpenTelemetry](https://img.shields.io/badge/OpenTelemetry-Instrumentation-purple)
![Docker](https://img.shields.io/badge/Docker-Compose-blue)

---

Este projeto demonstra como aplicar observabilidade com OpenTelemetry enviando dados diretamente para o Elastic APM Server via OTLP, eliminando o uso do Collector.

---

## 🧱 Componentes

| Serviço         | Descrição                          | Porta  |
|-----------------|------------------------------------|--------|
| app-nodejs      | App com traces OTEL                | 3000   |
| apm-server      | Coleta e envia para Elastic        | 8200   |
| elasticsearch   | Armazena os dados observados       | 9200   |
| kibana          | Interface gráfica de visualização  | 5601   |

---

## 🚀 Como executar

### 1. Clone o repositório

```bash
git clone https://github.com/rafasilva1984/datastackpro.git
cd datastackpro/elasticsearch/opentelemetry-lab/docker
```

### 2. Suba os containers

```bash
docker compose up -d
```

---

### 3. Gere tráfego de teste

Abra outro terminal:

```bash
curl http://localhost:3000/login
curl http://localhost:3000/checkout
curl http://localhost:3000/error
```

---

## 📊 Visualize no Kibana

Acesse: [http://localhost:5601](http://localhost:5601)  
Vá em **APM > Services** e veja os traces do app!

---

## ✍️ Autor

**Rafael Silva**  
🔗 [LinkedIn](http://linkedin.com/in/rafael-silva-leader-coordenador)  
🐙 [GitHub](https://github.com/rafasilva1984)

---

© 2025 - Projeto integrante da iniciativa **DataStackPro**
