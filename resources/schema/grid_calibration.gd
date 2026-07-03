class_name GridCalibration
extends Resource
## Calibração de layout do tabuleiro por dimensão + posições do balão (target_data_model.md §3).
## Legado: blocos hardcoded do GameManager + BalloonController.UpdatePos (BR-015/051).
##
## ⚠️ VALORES EXATOS são transcritos do C# legado na Tarefa 03. Consumido pela casca
## `features/board` (Tarefa 11), injetado (D-006) — o domínio não conhece calibração visual.

## "RxC" (ex: "8x8") -> { "offset": Vector2, "mult": Vector2, "scale": float }
@export var layouts: Dictionary = {}
## "RxC" -> Vector2 (posição do balão nesse layout)
@export var balloon_positions: Dictionary = {}
@export var placeholder: bool = true


func layout_for(rows: int, cols: int) -> Dictionary:
	return layouts.get("%dx%d" % [rows, cols], {})
