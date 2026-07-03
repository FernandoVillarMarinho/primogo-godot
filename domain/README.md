# domain/ — núcleo puro (sem engine)

Implementa **todas** as regras do puzzle e da economia como classes GDScript puras
(`extends RefCounted`), sem `Node`, sem sinais, sem acesso à árvore de cena.

## Regra de fronteira (inviolável)

- `domain/` **não importa** nada de `features/` nem de `autoload/`.
- O domínio expõe **resultados de comando** (objetos com lista de eventos, AD-02);
  a casca converte esses eventos em sinais na borda.
- Roda **headless** — a suíte GUT em `domain/tests/` valida o domínio sem subir a engine.
  É também o alvo do oráculo de paridade (compara o domínio direto contra o legado).

## Módulos

| Pasta | Contexto | Regras | Tarefa |
|---|---|---|---|
| `board/` | Board (partida) | grid, movimento célula a célula, merge, gelo, cerco, coleção/troca (BR-001..019) | 05 |
| `economy/` | Progression | orçamento, energia, estrelas, recorde, desbloqueio, gate, recompensa (BR-021..033) | 06 |
| `levels/` | Content | LevelData imutável, cadeia de primos, disfarce `r` (BR-007/010) | 04 |
| `tests/` | — | testes GUT (TT-xx / paridade PAR-xx) headless | contínuo |

Ordem de construção (bottom-up): `levels` → `board` → `economy`.
