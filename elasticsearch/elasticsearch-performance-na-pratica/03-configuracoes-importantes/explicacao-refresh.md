# ⏱️ refresh_interval — quando e por quê ajustar

- `-1` durante grandes cargas em `_bulk` acelera ingestão, mas desabilita a visibilidade imediata de novos docs.
- `1s` (padrão) equilibra latência de leitura e custo de refresh.
- Aumentar (ex: `10s`) em ingestões contínuas pesadas reduz custo de refresh/segmentos.
