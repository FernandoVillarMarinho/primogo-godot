# resources/schema/ — tipos de dados (fronteira de serialização)

Classes `Resource` que definem o **formato** dos dados versionados. São a fronteira
entre o disco (`.tres`, `.cfg`) e o domínio puro — o domínio (Tarefa 04+) constrói seus
próprios tipos imutáveis a partir destes.

| Classe | Arquivo | Instâncias (dados) | Populado em |
|---|---|---|---|
| `LevelResource` + `LevelElement` | `level_resource.gd` / `level_element.gd` | `resources/levels/*.tres` (126) | Tarefa 03 (extração) |
| `Rewards` | `rewards.gd` | default embute os valores da spec (5/4·3/2·0) | Tarefa 02 ✓ (default) |
| `EntryCost` | `entry_cost.gd` | default uniforme = 2 | Tarefa 02 ✓ (default) |
| `BalanceThresholds` | `balance_thresholds.gd` | `resources/balance/thresholds.tres` | **Tarefa 03** (transcrição do C#) |
| `GridCalibration` | `grid_calibration.gd` | `resources/layout/grid_calibration.tres` | **Tarefa 03** (transcrição do C#) |
| `SaveSchema` | `save_schema.gd` | contrato do `user://save.cfg` (I/O na Tarefa 07) | Tarefa 02 ✓ |

`LevelResource.validate()` roda na extração e na carga (falha explícita, nunca crash).
Valores exatos de `thresholds`/`grid_calibration` vivem no C# legado
(`StarManager.cs`, `GameManager.cs`) e são transcritos com diff na Tarefa 03 — por isso
essas classes nascem com `placeholder = true`.
