class_name EntryCost
extends Resource
## Custo de energia por tentativa de fase (target_data_model.md §3).
## Legado: GlobalStats.energyCost[12][12] — uniforme = 2. Modelado como default
## com overrides opcionais por fase, caso a transcrição (Tarefa 03) revele exceções.

@export var default_cost: int = 2
@export var overrides: Dictionary = {}  ## "stage_level" (1-based) -> int


func cost_for(stage: int, level: int) -> int:
	return int(overrides.get("%d_%d" % [stage, level], default_cost))
