
# OpenTelemetry Lab com Elasticsearch + Kibana (Segurança Ativada)

Este laboratório faz parte da iniciativa **DataStackPro** e demonstra como integrar uma aplicação Node.js instrumentada com OpenTelemetry a um cluster Elasticsearch com **X-Pack Security habilitado**, utilizando o APM da Elastic para observabilidade real.

---

## 🔐 Segurança

Este ambiente já está configurado com autenticação básica via X-Pack.

- **Usuário**: `elastic`
- **Senha**: `changeme` (definida apenas para fins locais/testes)

---

## 📦 Estrutura do Projeto

```
opentelemetry-lab/
├── app/                 # Aplicação Node.js instrumentada
│   ├── app.js
│   ├── package.json
│   └── Dockerfile
├── docker/              # Arquivos de configuração do Elastic e Kibana
│   ├── elasticsearch.yml
│   ├── kibana.yml
│   └── docker-compose.yml
├── dashboards/          # Dashboards prontos para importar no Kibana
│   └── apm-dashboard.ndjson
├── scripts/             # Scripts utilitários
│   └── load.sh
└── README.md            # Este arquivo
```

---

## 🚀 Como rodar o projeto localmente (Docker Desktop)

1. Clone este repositório:
```bash
git clone https://github.com/rafasilva1984/datastackpro.git
cd datastackpro/elasticsearch/opentelemetry-lab
```

2. Suba os containers:
```bash
docker compose -f docker/docker-compose.yml up --build -d
```

3. Aguarde 1-2 minutos até os serviços inicializarem.

4. Inicie a carga simulada de dados:
```bash
bash scripts/load.sh
```

---

## 📊 Acessando o Kibana

- URL: [http://localhost:5601](http://localhost:5601)
- Usuário: `elastic`
- Senha: `changeme`

> Vá em *APM > Services* para visualizar os dados de telemetria.

---

## 📌 Observações

- Este ambiente roda **totalmente local**, com dados simulados.
- O `X-Pack Security` é ativado para permitir uso do **Fleet** e **APM UI**.
- Toda a comunicação entre os serviços usa `localhost`, sem necessidade de certificados adicionais.

---

## 🤝 Projeto mantido por [Rafael Silva](https://github.com/rafasilva1984) para a comunidade de Observabilidade.

Siga e contribua com o projeto no GitHub: ⭐  
https://github.com/rafasilva1984/datastackpro
