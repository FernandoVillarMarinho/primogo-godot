class_name LevelData
extends RefCounted
## VO imutável de uma fase (contexto Content). PURO — sem engine, sem Node.
## Construído a partir de um LevelResource pelo LevelFactory (adaptador de fronteira).
##
## Implementa:
## - BR-010 (geração de valores): congelado com índice k na cadeia vale
##   chain[k]*chain[k-1] (ou chain[k]*chain[0] se only_one_number).
## - BR-007 (disfarce): só o 1º congelado dobra o exibido (r = {2,1,1,...});
##   a matemática do jogo usa sempre o valor REAL (true_value).
## - BR-016: valor exibido ≤ 9999.
## - I2: valor do jogador é um membro da cadeia.
##
## elements: Array de dicts {x:int, y:int, primo_index:int}; elements[0] = jogador.

const MAX_DISPLAYED := 9999

var stage: int
var level: int
var rows: int
var cols: int
var chain: PackedInt32Array
var only_one_number: bool
var disguise: PackedFloat32Array
var elements: Array


func _init(
	p_stage: int = 0,
	p_level: int = 0,
	p_rows: int = 0,
	p_cols: int = 0,
	p_chain: PackedInt32Array = PackedInt32Array(),
	p_only_one_number: bool = false,
	p_disguise: PackedFloat32Array = PackedFloat32Array(),
	p_elements: Array = []
) -> void:
	stage = p_stage
	level = p_level
	rows = p_rows
	cols = p_cols
	chain = p_chain
	only_one_number = p_only_one_number
	disguise = p_disguise
	elements = p_elements


func key() -> Vector2i:
	return Vector2i(stage, level)


## Valor real do jogador (elements[0]): um primo da cadeia (I2).
func player_true_value() -> int:
	return chain[int(elements[0]["primo_index"])]


## Gera os pedaços congelados com valor real e exibido (BR-010 + BR-007).
## Retorna Array de dicts {x, y, true_value, displayed_value}. Ordem = ordem em elements[1..].
func generate_frozen() -> Array:
	var out := []
	for i in range(1, elements.size()):
		var e: Dictionary = elements[i]
		var k: int = int(e["primo_index"])
		var factor: int = chain[0] if only_one_number else chain[maxi(k - 1, 0)]
		var true_value: int = chain[k] * factor
		var frozen_index: int = i - 1  # ordem entre os congelados (0 = primeiro)
		var r: float = disguise[frozen_index] if frozen_index < disguise.size() else 1.0
		var displayed_value: int = int(round(true_value * r))
		out.append({
			"x": int(e["x"]),
			"y": int(e["y"]),
			"true_value": true_value,
			"displayed_value": displayed_value,
			"primo": chain[k],  # fator primo do tile: fallback do merge quando true % jogador != 0 (BR-001)
		})
	return out


## Erros estruturais/de domínio (vazio = válido). Aplicada na carga (C2/C3, I6).
func validate() -> PackedStringArray:
	var errors := PackedStringArray()

	if elements.size() < 2:
		errors.append("elements.size()=%d: mínimo 2 (jogador + ao menos 1 congelado)" % elements.size())

	for i in elements.size():
		var k: int = int(elements[i]["primo_index"])
		if k < 0 or k >= chain.size():
			errors.append("elements[%d].primo_index=%d fora da cadeia (size=%d)" % [i, k, chain.size()])

	# Sem índices válidos não dá para gerar valores — evita index-error.
	if not errors.is_empty():
		return errors

	for f in generate_frozen():
		if f["displayed_value"] > MAX_DISPLAYED:
			errors.append("valor exibido %d > %d (BR-016)" % [f["displayed_value"], MAX_DISPLAYED])

	return errors


func is_valid() -> bool:
	return validate().is_empty()
