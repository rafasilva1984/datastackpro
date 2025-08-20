# 🔎 Cheatsheet — _search/profile_ (Diagnóstico de Queries)

Use `"profile": true` no corpo da busca para ver **onde o tempo é gasto** por shard.

## Principais campos
- **rewrite_time**: custo para reescrever a query (wildcards/regex/expansões). Alto = query “se expande demais”.
- **query[].time_in_nanos**: tempo de execução dos componentes da query.
- **collector.time_in_nanos**: custo para coletar/ordenar `size` resultados (piora com sort cardinal e size alto).
- **breakdown**: sub-etapas (criar peso, avançar iterador, pontuação).
- **aggs**: quando presentes, aparece o tempo por agregação.

## Gargalos típicos & correções
- `match` em campo `keyword` → troque por **term**.
- Ordenação por campo de **alta cardinalidade** → reduza `size`, filtre melhor, use `search_after`.
- Muitas agregações ou `terms` com `size` alto → reduza o conjunto com a query/filters antes de agregar.
- Shard específico sempre lento → desbalanceamento/segmentação; considere reindex, forcemerge (só laboratório) e ajuste de shards.

## Demos (iguais no Dev Tools e cURL)
1) Baseline: `status=warning AND cpu>=85`  
2) Otimização: `term` em `status` (keyword) + `range` em `cpu`  
3) Com agregação: `terms` por `servico`  
4) Ordenação por `@timestamp` para observar o `collector`

Veja `diagnostico-demos.json` com os quatro exemplos.
