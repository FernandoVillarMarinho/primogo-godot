class_name BalanceThresholds
extends Resource
## Movimentos necessários por faixa de estrelas, por fase (target_data_model.md §3).
## Legado: StarManager.movementsInLevel[12][12][3] (ADR-004, hardcode).
##
## ⚠️ VALORES EXATOS são transcritos do C# legado na Tarefa 03 (transcrição + diff).
## Estágios 8–12 permanecem `placeholder = true` mesmo após a transcrição (BR-030).

## "stage_level" (1-based) -> { "three_star": int, "two_star": int, "max": int }
@export var entries: Dictionary = {}
@export var placeholder: bool = true


func for_level(stage: int, level: int) -> Dictionary:
	return entries.get("%d_%d" % [stage, level], {})


func has_level(stage: int, level: int) -> bool:
	return entries.has("%d_%d" % [stage, level])
