class_name LevelData
extends RefCounted
## VO imutável de uma fase (contexto Content). PURO — sem engine.
## Reproduz FIELMENTE a geração do legado (GameManager.CreateTile, confirmada na Fase 0):
##
## - jogador     = elements[0].primo
## - congelado i = elements[i].primo * elements[i-1].primo
##                 (ou * elements[0].primo se only_one_number)   ← BR-010
## - exibido     = int(trueValue * r[i-1])   ← BR-007 (truncamento, como o (int) do C#)
## - teto        = exibido ≤ 9999            ← BR-016
##
## `r` é o disfarce, VARIÁVEL por fase. `varsArray`/`vars`/`min`/`max` do legado são
## vestigiais (só no ramo morto wonTheLevel) — não entram na geração (G-01 resolvida).
##
## elements: Array de dicts {x:int, y:int, primo:int}; elements[0] = jogador.

const MAX_DISPLAYED := 9999

var stage: int
var level: int
var rows: int
var cols: int
var only_one_number: bool
var r: PackedFloat32Array
var elements: Array


func _init(
	p_stage: int = 0,
	p_level: int = 0,
	p_rows: int = 0,
	p_cols: int = 0,
	p_only_one_number: bool = false,
	p_r: PackedFloat32Array = PackedFloat32Array(),
	p_elements: Array = []
) -> void:
	stage = p_stage
	level = p_level
	rows = p_rows
	cols = p_cols
	only_one_number = p_only_one_number
	r = p_r
	elements = p_elements


func key() -> Vector2i:
	return Vector2i(stage, level)


## Valor real do jogador (elements[0].primo). I2: membro derivado da cadeia.
func player_true_value() -> int:
	return int(elements[0]["primo"])


## Gera os pedaços congelados com valor real, exibido e o fator primo de fallback do merge.
## Retorna Array de dicts {x, y, true_value, displayed_value, primo}.
func generate_frozen() -> Array:
	var out := []
	for i in range(1, elements.size()):
		var e: Dictionary = elements[i]
		var factor: int = int(elements[0]["primo"]) if only_one_number else int(elements[i - 1]["primo"])
		var true_value: int = int(e["primo"]) * factor
		var rp: float = r[i - 1] if (i - 1) < r.size() else 1.0
		var displayed_value: int = int(true_value * rp)  # trunca, como o (int) do C#
		out.append({
			"x": int(e["x"]),
			"y": int(e["y"]),
			"true_value": true_value,
			"displayed_value": displayed_value,
			"primo": int(e["primo"]),  # fallback do merge quando true % jogador != 0 (BR-001)
		})
	return out


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if elements.size() < 2:
		errors.append("elements.size()=%d: mínimo 2 (jogador + ao menos 1 congelado)" % elements.size())
		return errors
	for f in generate_frozen():
		if f["displayed_value"] > MAX_DISPLAYED:
			errors.append("valor exibido %d > %d (BR-016)" % [f["displayed_value"], MAX_DISPLAYED])
	return errors


func is_valid() -> bool:
	return validate().is_empty()
