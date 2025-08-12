
# Observabilidade Unificada com OpenTelemetry, Loki, Tempo, Prometheus, Alertmanager e Grafana

Este repositório fornece um ambiente completo de observabilidade unificada, pronto para execução local com Docker Compose. Ele integra métricas, logs e traces usando ferramentas open-source de ponta.

---

## 📂 Clonar o Repositório
```bash
git clone https://github.com/SEU_USUARIO/SEU_REPOSITORIO.git
cd SEU_REPOSITORIO
```

---

## 🛠 Componentes

### **1. Prometheus**
- **Função**: Coleta métricas de aplicações e serviços.
- **Porta**: `http://localhost:9090`
- **Como usar**:
  - Interface web acessível no browser.
  - Executa queries em **PromQL**.
  - Serve como fonte de dados para o Grafana.

### **2. Alertmanager**
- **Função**: Recebe alertas do Prometheus e gerencia o envio para canais (e-mail, Slack, etc.).
- **Porta**: `http://localhost:9093`
- **Como usar**:
  - Interface web para ver alertas ativos e o histórico.
  - Configurações via `alertmanager.yml`.

### **3. Grafana**
- **Função**: Visualização centralizada de métricas, logs e traces.
- **Porta**: `http://localhost:3000` (usuário/senha padrão: `admin` / `admin`)
- **Fontes de dados configuradas**:
  - Prometheus (métricas)
  - Loki (logs)
  - Tempo (traces)

### **4. Loki**
- **Função**: Armazenamento e consulta de logs.
- **Porta API**: `http://localhost:3100`
- **Importante**: Ao acessar pelo browser, você verá `404 Page not found`. Isso é esperado, pois Loki é uma API, não um painel web.
- **Como verificar se está rodando**:
```bash
curl -s http://localhost:3100/ready
curl -s http://localhost:3100/loki/api/v1/status/buildinfo
```
- **Consultar labels disponíveis**:
```bash
curl -sG http://localhost:3100/loki/api/v1/label/job/values
```
- **Visualizar logs**:
  - Vá ao Grafana → Explore → Selecione a fonte `Loki`.
  - Query exemplo: `{job="sampleapp"}`.

### **5. Tempo**
- **Função**: Armazenamento e consulta de traces distribuídos.
- **Porta API**: `http://localhost:3200`
- **Importante**: Assim como o Loki, o Tempo também retorna `404 Page not found` no navegador, pois é uma API.
- **Como verificar se está rodando**:
```bash
curl -s http://localhost:3200/ready
curl -s http://localhost:3200/metrics | head
```
- **Visualizar traces**:
  - Vá ao Grafana → Explore → Selecione a fonte `Tempo`.
  - Use “Search” e filtre por **Service name** (ex.: `sampleapp`).

### **6. SampleApp**
- **Função**: Aplicação de exemplo para gerar métricas, logs e traces.
- **Porta**: `http://localhost:3001`
- **Como gerar tráfego**:
```bash
for i in {1..50}; do
  curl -s http://localhost:3001/login >/dev/null
  curl -s http://localhost:3001/checkout >/dev/null
  curl -s http://localhost:3001/error >/dev/null || true
done
```

---

## 🚨 Simular Alertas
Execute uma das queries abaixo no Prometheus ou altere métricas para disparar no Alertmanager.

1. **CPU Alta**:
```bash
curl -X POST http://localhost:3001/simulate/cpu_high
```
2. **Memória Alta**:
```bash
curl -X POST http://localhost:3001/simulate/memory_high
```
3. **Erro na Aplicação**:
```bash
curl -X POST http://localhost:3001/simulate/error
```

---

## 📊 Onde Ver os Dados

| Tipo de Dado | Ferramenta | URL |
|--------------|-----------|-----|
| Métricas     | Prometheus | [http://localhost:9090](http://localhost:9090) |
| Logs         | Grafana + Loki | Grafana → Explore → Loki |
| Traces       | Grafana + Tempo | Grafana → Explore → Tempo |
| Alertas      | Alertmanager | [http://localhost:9093](http://localhost:9093) |
| Dashboards   | Grafana | [http://localhost:3000](http://localhost:3000) |

---

## 🧪 Testando a Saúde dos Serviços
- Loki:
```bash
curl -s http://localhost:3100/ready
```
- Tempo:
```bash
curl -s http://localhost:3200/ready
```
- Prometheus:
```bash
curl -s http://localhost:9090/-/ready
```

Se o retorno for `200 OK` ou similar, o serviço está ativo.

---

## 📚 Fluxo de Dados
1. **SampleApp** gera métricas, logs e traces via OpenTelemetry.
2. **Prometheus** coleta métricas via scraping.
3. **Loki** recebe logs da aplicação.
4. **Tempo** armazena traces distribuídos.
5. **Grafana** centraliza a visualização.
6. **Alertmanager** gerencia e envia notificações baseadas nas regras do Prometheus.

---

## 📝 Observação
Este ambiente é destinado a **estudos, testes e demonstrações**. Para produção, recomenda-se configurar autenticação, persistência de dados e alta disponibilidade.
