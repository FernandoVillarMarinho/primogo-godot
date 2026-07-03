# tools/extraction/ — pipeline da Fase 0 (fora do build)

O `.gdignore` nesta pasta faz o Godot **não** importar estes arquivos (é ferramenta, não jogo).

## Objetivo (Tarefa 03)

Ler as **126 cenas Unity** (`Assets/Scenes/Stage_*/Level_s_n.unity` do repositório legado,
somente leitura) e gerar `resources/levels/level_s_n.tres` + relatórios:

- `extraction_report.md` — 126 esperados × extraídos, exceções por nível
  (⚠️ o legado tem **10 estágios / 122 cenas** `Level_*.unity`; as specs falam em 12/126 —
  reconciliar aqui).
- `factorability_report.md` — **insumo G-01**: níveis cuja janela alcança o `27` (621/783).
- diff das tabelas de balance transcritas × fonte C#.

## ⚠️ Bloqueio atual (COD-006)

As cenas estão em **formato binário** do Unity 5.3.2f1 (confirmado no cabeçalho — não é YAML).
Um parser simples não funciona. Rotas para desbloquear:

1. **Unity 5.3.2f1 + script exportador (recomendado):** abrir o projeto legado e rodar um
   `EditorScript` que carrega cada cena, lê os campos do `LevelManager`
   (`elements`, `varsArray`, `min`, `max`, `r`, `onlyOneNumber`, dims do `GameManager`) e
   escreve JSON → convertido em `.tres`. Bloqueado hoje: o Unity 5.3.2f1 instalado não abre.
2. **Unity 5.3.2f1 + `binary2text`** (CLI do editor) ou `Asset Serialization → Force Text`,
   depois parsear o YAML resultante.
3. **Parser binário de terceiros** (UnityPy) — frágil para campos custom de MonoBehaviour; evitar.

Insumos já disponíveis localmente (não precisam do APK): banks FMOD em
`Assets/StreamingAssets/*.bank`, tabelas em `Managers/GameManager.cs` e `LevelManager.cs`,
177 sprites, e 20 prints + 3 vídeos como golden provisório.
