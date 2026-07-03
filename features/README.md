# features/ — casca Godot (cenas + sinais)

Projeta o estado do `domain/` em nós visuais e converte input em comandos. **Sem regra de
negócio** (regra na casca = defeito). Lê/escreve progressão apenas via `ProgressionStore`.

| Pasta | Cena | Origem no legado | Tarefa |
|---|---|---|---|
| `shared/` | fade, overlays, efeitos de escala, dígitos-sprite | Fade, AutoGrow*, Number | 10 |
| `board/` | cena de jogo: grid 3×4, swipe, animações, HUD, balão | GameManager (render/input/anim), BalloonController | 11 |
| `level_select/` | grade 12 páginas, paginação, energia | LevelSelect, TouchLevelSelect, SwangEnergy | 12 |
| `main_menu/` | splash, menu, créditos, opções, social | Menu, SceneController, CloseOptions, LikeScript | 13 |
| `tutorial/` | mão demonstrativa + gate do balão | TutorialManager{,2} — fundidos | 14 |

Ordem de construção: `shared` (folha) → `board` → `level_select` → `main_menu` → `tutorial`.
Todas **vazias** na Tarefa 01.
