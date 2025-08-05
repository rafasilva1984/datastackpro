
# 📡 OpenTelemetry Lab com Elasticsearch + Kibana (Segurança Ativada)

Este laboratório faz parte da iniciativa **[DataStackPro](https://github.com/rafasilva1984/datastackpro)** e simula um cenário real de observabilidade para aplicações modernas com **OpenTelemetry** + **Elastic APM**, integrando rastreamento distribuído, análise de performance e dashboards prontos em um cluster com **segurança ativada** via X-Pack.

---

## 🔐 Segurança (X-Pack Enabled)

O ambiente está protegido com autenticação básica via **X-Pack Security**, simulando ambientes corporativos reais.

| Recurso     | Valor     |
|-------------|-----------|
| Usuário     | `elastic` |
| Senha       | `changeme` (uso apenas local/testes) |

> Todos os serviços compartilham credenciais e autenticação integrada no cluster. O Fleet/APM requerem esse nível básico de segurança ativo.

---

## 🧱 Estrutura do Projeto

```bash
opentelemetry-lab/
├── app/                 # Aplicação Node.js instrumentada com OTEL
│   ├── app.js
│   ├── package.json
│   └── Dockerfile
├── docker/              # Configurações dos containers e serviços
│   ├── docker-compose.yml
│   ├── elasticsearch.yml
│   └── kibana.yml
├── dashboards/          # Dashboards APM customizados exportados do Kibana
│   └── apm-dashboard.ndjson
├── scripts/             # Script utilitário para simular carga de requisições
│   └── load.sh
└── README.md            # Este guia
```

---

## 🚀 Como executar o projeto (Docker Desktop)

### 1. Clone o repositório

```bash
git clone https://github.com/rafasilva1984/datastackpro.git
cd datastackpro/elasticsearch/opentelemetry-lab
```

### 2. Suba todos os serviços com Docker Compose

```bash
docker compose -f docker/docker-compose.yml up --build -d
```

⚠️ Aguarde cerca de 1–2 minutos para os containers estarem prontos. Verifique com:

```bash
docker ps
```

---

## 🧪 Gerar dados de telemetria simulados

Execute o script de carga para gerar tráfego com spans, latência, erros e requisições reais:

```bash
bash scripts/load.sh
```

Esse script executa diversas rotas da aplicação `/login`, `/checkout`, `/error`, permitindo visualizar os fluxos no Kibana.

---

## 📊 Acessando o Kibana

- URL: [http://localhost:5601](http://localhost:5601)
- Login: `elastic`
- Senha: `changeme`

### Navegue até:

- **Observability > APM > Services** → Ver os serviços OTEL
- **Dashboards** → Importar visualizações extras

---

## 📈 Importando Dashboard Personalizado (Opcional)

1. Vá em **Stack Management > Saved Objects**
2. Clique em **Import**
3. Selecione o arquivo: `dashboards/apm-dashboard.ndjson`
4. Após importar, vá em **Dashboard > APM – OTEL Lab**

---

## 📌 Observações Importantes

- ✅ Ideal para estudos, PoCs, workshops ou treinamento de equipes.
- ✅ Stack completa com dados reais trafegando localmente.
- ✅ Usa `OTLP/gRPC` como protocolo padrão entre app e o APM Server.
- ✅ Todo ambiente roda em `localhost`, sem necessidade de certificados TLS.
- 🚫 Não recomendado usar `changeme` em ambientes reais.

---

## 💡 Extensões futuras

- 📦 Adicionar métricas com OpenTelemetry Metrics + Elastic Agent
- 🧵 Habilitar logging estruturado com Elastic Logging
- 📬 Incluir alertas com Watcher / Kibana Alerts
- 🌍 Integração com observabilidade distribuída multi-stack

---

## 👨‍💻 Autor

**Rafael Silva** – Especialista em Observabilidade, Elastic Stack, Dados e DevOps  
🔗 [LinkedIn](http://linkedin.com/in/rafael-silva-leader-coordenador)  
🐙 [GitHub](https://github.com/rafasilva1984)

---

© 2025 – Projeto mantido na comunidade **[DataStackPro](https://github.com/rafasilva1984/datastackpro)**  
Compartilhe, contribua e fortaleça a cultura DevOps com observabilidade real.
