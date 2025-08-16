# 🚀 Observabilidade com Experiência Digital + Impacto no Negócio

Este projeto demonstra como **conectar métricas técnicas (latência, erros, disponibilidade)** com **indicadores de negócio (receita, ticket médio, perda estimada)** usando **Elasticsearch + Kibana**.

É um PoC **100% funcional e educacional**, pronto para rodar com **Docker Compose** e gerar **dashboards executivos e técnicos** que mostram, de forma didática, o impacto da TI no negócio.

---

## 🎯 Objetivo

- Simular tráfego de usuários em serviços críticos (checkout, login, catálogo).
- Medir **latência, erros e disponibilidade** desses serviços.
- Traduzir automaticamente esses dados em:
  - Receita gerada 💰
  - Perda estimada por falhas ⚠️
  - Impacto em experiência digital (conversão, usuários ativos)

👉 Assim, o projeto entrega **visão unificada** para **TI** e **Negócio**, essencial em ambientes modernos.

---

## 🗂️ Estrutura do Projeto

```
observabilidade-experiencia-negocio/
 ├── docker-compose.yml           # Elasticsearch + Kibana
 ├── .env.example                 # Configurações de ambiente
 ├── README.md                    # Este guia
 ├── elastic/
 │   ├── ilm/
 │   │   └── app-logs-ilm.json     # Política de ciclo de vida dos logs
 │   ├── templates/
 │   │   ├── app-logs-template.json
 │   │   └── biz-metrics-template.json
 │   └── pipelines/
 │       └── app-logs-pipeline.json
 ├── kibana/
 │   └── saved_objects.ndjson     # Data views + painéis simples
 └── scripts/
     ├── load_all.sh              # Cria estrutura + injeta dados simulados
     └── reset_indices.sh         # Reseta os data streams
```

---

## ⚙️ Requisitos

- Docker e Docker Compose instalados  
- Linux/macOS com **GNU date** (em macOS, instale coreutils → `brew install coreutils`)  
- Acesso às portas `9200` (Elasticsearch) e `5601` (Kibana)

---

## 🚀 Como subir o ambiente

1) **Crie o arquivo de variáveis de ambiente:**

```bash
cp .env.example .env
# Ajuste ELASTIC_PASSWORD se quiser
```

2) **Suba o stack Elastic (Elasticsearch + Kibana):**

```bash
docker compose up -d
```

- Elasticsearch: `http://localhost:9200`  
- Kibana: `http://localhost:5601`  
- Login: usuário `elastic` e senha definida no `.env`.

3) **Carregue a estrutura e os dados simulados:**

```bash
./scripts/load_all.sh
```

Esse script cria:
- Política de ILM, templates e pipeline de ingestão.
- Data streams `app-logs-*` e `biz-metrics-*`.
- **Geração de dados sintéticos** (usuários, erros, receita, perdas).

4) **Importe os dashboards no Kibana:**

- Vá em **Stack Management → Saved Objects → Import**  
- Selecione `kibana/saved_objects.ndjson`

---

## 📊 Dashboards disponíveis

### 🔹 Painel Executivo – Impacto no Negócio
- Receita total gerada por serviço
- Perda estimada de receita devido a falhas
- Top serviços críticos para o negócio
- Projeção de perda se falhas persistirem

### 🔹 Painel Técnico – Saúde de Serviços
- Latência média por rota (checkout, login, catálogo)
- Taxa de erro HTTP por minuto
- Mapa de calor por serviço e região
- Tendência de disponibilidade

---

## 🧩 Parâmetros customizáveis (.env)

| Variável | Descrição | Padrão |
|----------|-----------|---------|
| `ELASTIC_VERSION` | Versão do Elasticsearch/Kibana | 8.19.1 |
| `ELASTIC_PASSWORD` | Senha do usuário `elastic` | elastic |
| `STACK_HOST` | URL do Elasticsearch | http://localhost:9200 |
| `KIBANA_HOST` | URL do Kibana | http://localhost:5601 |
| `DATA_DAYS` | Dias de histórico a gerar | 2 |
| `DOCS_PER_MINUTE` | Qtd. de documentos simulados por minuto (por serviço) | 6 |
| `AVG_TICKET` | Valor médio de ticket em R$ | 150.00 |
| `CONVERSION_LOSS_FACTOR` | Fator de perda de conversão em falhas (0.0–1.0) | 0.7 |

> Aumente `DOCS_PER_MINUTE` para gerar milhares de documentos e testar performance.

---

## 🔄 Comandos úteis

**Parar o stack:**
```bash
docker compose down
```

**Resetar data streams e recomeçar do zero:**
```bash
./scripts/reset_indices.sh
./scripts/load_all.sh
```

---

## 📌 Conceitos reforçados

- Observabilidade não é só **infra**, mas também **negócio**.  
- Métricas técnicas podem (e devem) ser traduzidas em **impacto financeiro**.  
- **Kibana** também entrega **dashboards executivos**.  
- Arquitetura baseada em **data streams + ILM** garante escalabilidade.

---

## 🔐 Licença

Este projeto utiliza apenas recursos **gratuitos** do Elastic Stack (Basic License).  
Livre para uso educacional e PoCs.

---

✍️ **Autor**: DataStackPro — PoC educacional e demonstrativa.
