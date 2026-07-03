# resources/ — conteúdo versionado (dados, não código)

Escrito **apenas** pelo pipeline `tools/extraction` (Fase 0) e por level designers — nunca
em runtime (regra de fronteira da topologia).

| Pasta | Conteúdo | Origem | Tarefa |
|---|---|---|---|
| `levels/` | 126 `LevelResource` (.tres) — `stage`/`level` explícitos (mata ADR-005) | cenas Unity `Level_s_n` | 02/03 |
| `balance/` | tabelas de movimentos/energia (`movementsInLevel`/`energyCost`) | GameManager/LevelManager.cs | 02 |
| `layout/` | calibração de grid por dimensão (`grid_calibration.tres`) | blocos do GameManager | 02 |

Vazias na Tarefa 01. Populadas pela Fase 0 (Tarefa 03), hoje bloqueada em COD-006
(cenas em formato **binário** — requer Unity 5.3.2f1 funcional ou conversor).
