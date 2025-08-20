# ⚡ Elasticsearch Performance na Prática

Segundo repositório da trilha. Foco: performance, benchmark, diagnóstico e dashboards.

## Passo a passo
1. Suba o ambiente:
```bash
cd 01-ambiente-docker && docker-compose up -d
```
2. Crie índice e ingeste 10k docs:
```bash
cd ../02-benchmark-indexacao
bash criar-indice-base.sh
bash ingestar-bulk.sh
```
3. Rode benchmarks e compare:
```bash
bash benchmark-variacoes.sh
```
4. Diagnostique queries com profile:
```bash
cd ../04-diagnostico-queries
bash profile-examples.sh
```
5. Crie o dashboard (veja 05-dashboard-performance/instrucoes-dashboard.md).

## Observações
- Se editar `.sh` no Windows e aparecer `^M`, use `dos2unix *.sh`.
- Todos os dados usam timestamps de **julho/2025**.
