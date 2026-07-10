class_name GridCalibration
extends Resource
## Calibração de layout do tabuleiro por dimensão + posições do balão (target_data_model.md §3).
## Legado: blocos hardcoded do `GameManager.Start`/`CreateTile` + `BalloonController.UpdatePos`
## (BR-015/051). Transcrito em 2026-07-10 com a arte original (T19, Fase 3):
##
##   grade (RxC) | cenário          | célula px | pos matrix (Unity) | escala | tile | balão y | cenário-fundo y
##   5x5         | 5x5_100.png      | 212.4     | (0,-2.20)  | 0.5 (prefab) | 1.0  | 0.75 (default) | 4.45
##   7x6         | 6x7_70.png       | 148.2     | (0,-1.8)   | 0.6          | 0.84 | 1.6            | 5.3
##   7x7         | 7x7_70.png       | 147.3     | (0,-2.25)  | 0.51         | 0.7  | 0.75           | 4.45
##   7x8         | 7x8_61.png       | 128.6     | (0,-2.5)   | 0.51         | 0.6  | 0.15           | 3.8
##
## `cell_px` = célula REAL desenhada na textura = largura_da_textura / colunas (o quadriculado
## preenche a textura de borda a borda). O "_NN" do nome do arquivo é o tamanho NOMINAL da
## célula no design Unity — as texturas foram exportadas a ~2,12× (212,4/100). Usar o nominal
## deixava tiles com metade do tamanho da célula (bug visto no teste em dispositivo 2026-07-10).
##
## Conversão p/ viewport 720x1280: 1 unidade Unity = 128 px (câmera orto 10 un. de altura);
## Unity y+ para cima → Godot y+ para baixo. `scenery_center_y` = centro do Background.png
## (cenário céu/floresta do prefab Scenery) em px de viewport (640 − u·128). `fine_offset`
## existe para o ajuste visual contra os prints (🟡 validação do Villar) — começa em zero.
##
## Consumido pela casca `features/board`, injetado (D-006) — o domínio não conhece calibração.

## "RxC" (ex: "7x8" = 7 linhas x 8 colunas) ->
## { "texture": String, "cell_px": float, "bg_center": Vector2, "bg_scale": float,
##   "tile_scale": float, "fine_offset": Vector2 }
@export var layouts: Dictionary = {}
## "RxC" -> Vector2 (posição do centro do balão em px de viewport nesse layout)
@export var balloon_positions: Dictionary = {}
@export var placeholder: bool = true

const DEFAULT_BALLOON := Vector2(360, 544)  # 0.75 un. acima do centro (default do legado)


func layout_for(rows: int, cols: int) -> Dictionary:
	return layouts.get("%dx%d" % [rows, cols], {})


func balloon_for(rows: int, cols: int) -> Vector2:
	return balloon_positions.get("%dx%d" % [rows, cols], DEFAULT_BALLOON)


## Espaçamento entre centros de células na tela (célula da arte × escala de exibição).
static func spacing_of(layout: Dictionary) -> float:
	return float(layout.get("cell_px", 96.0)) * float(layout.get("bg_scale", 1.0))
