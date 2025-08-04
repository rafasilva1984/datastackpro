
# 📦 Projeto: Elasticsearch ILM com Retenção de Logs de Infraestrutura

Este repositório demonstra como resolver um problema comum em ambientes com Elasticsearch: **o crescimento descontrolado de índices de log**, levando a risco de **falta de espaço em disco** e degradação de performance do cluster.

---

## 🚨 Problema

Ambientes de infraestrutura frequentemente geram milhares de logs por hora. Quando esses logs são indexados continuamente **sem controle de retenção**, os índices crescem sem limite e comprometem o armazenamento do cluster.

---

## ✅ Solução Proposta

Utilizar o **ILM (Index Lifecycle Management)** do Elasticsearch para:

- Fazer **rollover automático** dos índices a cada 3 dias ou 1 GB.
- **Apagar automaticamente** índices com mais de 7 dias.
- Manter dados organizados por meio de **alias**, facilitando o acesso e visualização.

---

## 🛠️ Componentes

| Caminho                     | Descrição |
|----------------------------|-----------|
| `ilm/ilm-policy.json`      | Política de ciclo de vida dos índices |
| `ilm/index-template.json`  | Template com mapeamento e configuração de ILM |
| `ilm/create-index-alias.sh`| Script para aplicar a política, template e criar o primeiro índice |
| `ingestao/dados-infra.json`| Mais de 1200 documentos simulados com dados de infra |
| `ingestao/ingestao.sh`     | Script de ingestão usando `curl` |
| `visualizacao/dashboard.ndjson` | Dashboard para importação no Kibana |

---

## 🧪 Simulação Realista

O arquivo `dados-infra.json` contém **1200 documentos simulando hosts, CPU, memória e status** com timestamps variados durante todo o mês de **agosto de 2025**.

Exemplo de documento:
```json
{
  "host": "infra003",
  "cpu": 87,
  "mem": 76,
  "status": "OK",
  "timestamp": "2025-08-11T14:22:00Z"
}
```

---

## 🚀 Passo a Passo para Rodar

### 1. Subir um cluster Elasticsearch local (ou usar um existente)

```bash
docker run -d --name elastic -p 9200:9200 -e "discovery.type=single-node" -e "xpack.security.enabled=false" elasticsearch:8.12.2
```

### 2. Criar política, template e índice inicial com alias

```bash
bash ilm/create-index-alias.sh
```

### 3. Ingerir os dados simulados

```bash
bash ingestao/ingestao.sh
```

### 4. Importar o dashboard no Kibana (via Stack Management)

1. Acesse `http://localhost:5601`
2. Vá em **Stack Management > Saved Objects > Import**
3. Selecione o arquivo `visualizacao/dashboard.ndjson`

---

## 📊 Visualização

O dashboard contém gráficos de:

- Uso de CPU por host
- Hosts com alertas CRÍTICOS
- Linha do tempo com status da infraestrutura

---

## 🧼 Limpeza Automática

Após 7 dias, os índices serão apagados automaticamente pelo ILM, liberando espaço e mantendo a performance do cluster.

---

## 👨‍💻 Autor

**Rafael Silva**  
🔗 [LinkedIn](https://linkedin.com/in/rafael-silva-leader-coordenador)  
💻 [GitHub](https://github.com/rafasilva1984)

---

Pronto para rodar, modificar e usar como base para seus ambientes!
