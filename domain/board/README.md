# domain/board/ — contexto Board (partida)

Puro. Grid, movimento com deslizamento **célula a célula** (AD-03/BR-014), merge, gelo,
cerco, coleção e troca pelo balão com descarte (BR-001..019, L-09).

Expõe resultados de comando com eventos (`match_won`, `match_lost`, etc.) — a casca
`features/board/` os converte em sinais. Lê `domain/levels` (só leitura).

**Vazio na Tarefa 01.** Implementado na Tarefa 05. ⚠️ COD-007 (semântica do tile espelho do balão).
