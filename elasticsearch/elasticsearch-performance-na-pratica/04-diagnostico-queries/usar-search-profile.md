# 🔎 Como interpretar `_search/profile`

Ative `profile: true` para ver onde a query gasta tempo. Exemplo no Dev Tools:

```json
GET infra-hosts/_search
{
  "profile": true,
  "query": {
    "bool": {
      "must": [
        { "match": { "status": "warning" } },
        { "range": { "cpu": { "gte": 85 } } }
      ]
    }
  }
}
```

Foque em: `rewrite_time`, `query_time`, `collector` e o `breakdown` por fase. Compare antes/depois de ajustes.
