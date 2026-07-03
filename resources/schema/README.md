# resources/schema/ — tipos de dados (fronteira de serialização)

Classes `Resource` que definem o **formato** dos dados versionados. São a fronteira
entre o disco (`.tres`, `.cfg`) e o domínio puro — o domínio (Tarefa 04+) constrói seus
próprios tipos imutáveis a partir destes.

| Classe | Arquivo | Instâncias (dados) | Status |
|---|---|---|---|
| `LevelResource` + `LevelElement` | `level_resource.gd` / `level_element.gd` | `resources/levels/*.tres` (**122**, extraídos da Fase 0) | ✓ |
| `Rewards` | `rewards.gd` | default embute os valores da spec (5/4·3/2·0) | ✓ |
| `EntryCost` | `entry_cost.gd` | default uniforme = 2 | ✓ |
| `BalanceThresholds` | `balance_thresholds.gd` | `resources/balance/thresholds.tres` (movements[stage][level]) | ⏳ transcrever do `StarManager.cs` |
| `GridCalibration` | `grid_calibration.gd` | `resources/layout/grid_calibration.tres` | ⏳ transcrever do `GameManager.cs` |
| `SaveSchema` | `save_schema.gd` | contrato do `user://save.cfg` (I/O na Tarefa 07) | ✓ |

## LevelResource — geração fiel ao legado (confirmada na Fase 0)

Cada elemento carrega o **valor** do primo (`primo`, não um índice). O domínio (`LevelData`)
reproduz o `GameManager.CreateTile`:

- jogador = `elements[0].primo`
- congelado `i` = `elements[i].primo * elements[i-1].primo` (ou `* elements[0].primo` se `only_one_number`)
- exibido = `int(trueValue * r[i-1])` — `r` (disfarce) é **variável por fase**

`varsArray`/`vars`/`min`/`max` do legado são **vestigiais** (só no ramo morto `wonTheLevel`) —
não entram na geração. Por isso o `27` do `varsArray` default é inerte (G-01 resolvida).

Valores exatos de `thresholds`/`grid_calibration` vivem no C# legado e são transcritos na
Tarefa 03 (por isso nascem com `placeholder = true`).
