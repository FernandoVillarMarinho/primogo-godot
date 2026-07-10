class_name Match
extends RefCounted
## Aggregate raiz do contexto Board (uma partida). Puro, sem engine, sem sinais.
## Comandos retornam uma lista de eventos (AD-02); a casca (features/board) os
## converte em sinais. Semântica observável célula a célula (BR-014) preservada do legado.
##
## Rastreabilidade: GameManager.Move/CheckNext/CreateIce/CheckIfIsSorrounded (fundidos).

enum Direction { UP, RIGHT, DOWN, LEFT, NONE }
enum Status { PLAYING, WON, LOST_SIEGE, LOST_EXHAUSTION }

## Ordem circular AROUND do legado (índice 0..7): DOWN, LEFT_DOWN, LEFT, LEFT_UP,
## UP, RIGHT_UP, RIGHT, RIGHT_DOWN. Contrato observável — define a célula do gelo (BR-003).
var _AROUND: Array = [
	Vector2i(0, 1),    # 0 DOWN
	Vector2i(-1, 1),   # 1 LEFT_DOWN
	Vector2i(-1, 0),   # 2 LEFT
	Vector2i(-1, -1),  # 3 LEFT_UP
	Vector2i(0, -1),   # 4 UP
	Vector2i(1, -1),   # 5 RIGHT_UP
	Vector2i(1, 0),    # 6 RIGHT
	Vector2i(1, 1),    # 7 RIGHT_DOWN
]
const _AR_DOWN := 0
const _AR_LEFT := 2
const _AR_UP := 4
const _AR_RIGHT := 6
const _AR_RIGHT_DOWN := 7

var grid: Grid
var collection: Collection
var budget: int
var status: int = Status.PLAYING

var _tutorial_seq: Array = []
var _tutorial_index: int = 0


func _init() -> void:
	grid = Grid.new()
	collection = Collection.new()


## Monta a partida a partir de um LevelData e do orçamento de movimentos (BR-021,
## injetado pela economia/thresholds). elements[0] = jogador; demais = congelados.
func start(level: LevelData, p_budget: int) -> Array:
	grid = Grid.new(level.cols, level.rows)
	collection = Collection.new()
	budget = p_budget
	status = Status.PLAYING
	_tutorial_seq = []
	_tutorial_index = 0

	var p: Dictionary = level.elements[0]
	var initial := level.player_true_value()
	grid.set_cell(int(p["x"]), int(p["y"]), Cell.player(int(p["x"]), int(p["y"]), initial))
	collection.add(initial)   # versão 2026 (RES-026): o primo inicial fica na lista — o
	# jogador pode voltar a usá-lo via troca (os primos ACUMULAM ao longo da fase)
	for f in level.generate_frozen():
		grid.set_cell(int(f["x"]), int(f["y"]), Cell.frozen(int(f["x"]), int(f["y"]), int(f["displayed_value"]), int(f["true_value"]), int(f["primo"])))
	return [{"type": "match_started"}]


## Sequência de tutorial (BR-009): quando não vazia, só a direção esperada é aceita
## (sem custo caso contrário); acerto avança a sequência.
func set_tutorial_sequence(seq: Array) -> void:
	_tutorial_seq = seq.duplicate()
	_tutorial_index = 0


func player_pos() -> Vector2i:
	return grid.find_player()


func player_value() -> int:
	var pp := grid.find_player()
	return grid.at(pp.x, pp.y).value


# ------------------------------------------------------------------ comandos

func move(direction: int) -> Array:
	if status != Status.PLAYING:
		return [{"type": "move_rejected", "reason": "NOT_PLAYING"}]
	if direction == Direction.NONE:
		return [{"type": "move_rejected", "reason": "INVALID_SWIPE"}]

	var pp := grid.find_player()
	var delta := _dir_delta(direction)
	# checkPossibleDirection: um passo dentro dos limites (senão rejeita SEM custo)
	if not grid.in_bounds(pp.x + delta.x, pp.y + delta.y):
		return [{"type": "move_rejected", "reason": "OUT_OF_GRID"}]
	# gate de tutorial (BR-009) — sem custo se fora da sequência
	if not _tutorial_seq.is_empty():
		if direction != int(_tutorial_seq[_tutorial_index]):
			return [{"type": "move_rejected", "reason": "TUTORIAL_SEQUENCE"}]
		_tutorial_index = mini(_tutorial_index + 1, _tutorial_seq.size() - 1)

	budget -= 1  # BR-002: todo movimento aceito custa 1, mesmo sem deslocamento
	var events: Array = [{"type": "move_accepted", "budget": budget}]
	events += _slide(direction)
	_check_exhaustion(events)
	return events


## Troca pelo balão (BR-012/013): só para valor coletado e diferente do atual;
## custa 1 + penalidade de gelo; NÃO devolve o valor corrente (L-09). Na versão 2026
## (RES-026) todos os primos usados já estão na coleção (inicial entra no start, os
## demais no merge) — o jogador troca livremente entre eles enquanto tiver energia.
func swap_value(value: int) -> Array:
	if status != Status.PLAYING:
		return [{"type": "swap_rejected", "reason": "NOT_PLAYING"}]
	var pp := grid.find_player()
	var pv := grid.at(pp.x, pp.y).value
	if not collection.has(value) or value == pv:
		return [{"type": "swap_rejected", "reason": "INVALID"}]

	budget -= 1
	var player := grid.at(pp.x, pp.y)
	player.value = value
	player.true_value = value
	var events: Array = [{"type": "value_swapped", "new_value": value, "budget": budget}]
	events += _apply_ice_penalty()
	_check_exhaustion(events)
	return events


# ------------------------------------------------------------------ deslizamento

func _slide(direction: int) -> Array:
	var events: Array = []
	var delta := _dir_delta(direction)
	while true:
		var pp := grid.find_player()
		var np := pp + delta
		if not grid.in_bounds(np.x, np.y):
			events += _blocked()
			return events
		var ncell := grid.at(np.x, np.y)
		if ncell.kind == Cell.Kind.EMPTY:
			_move_player(pp, np)
			events.append({"type": "moved", "from": pp, "to": np})
			continue
		elif ncell.kind == Cell.Kind.FROZEN:
			var pv := grid.at(pp.x, pp.y).value
			if ncell.value % pv == 0:
				events += _merge(pp, np)
			else:
				events += _blocked()
			return events
		else:  # ICE, NOTHING, etc → bloqueio
			events += _blocked()
			return events
	return events


func _move_player(from: Vector2i, to: Vector2i) -> void:
	var player := grid.at(from.x, from.y)
	grid.set_cell(from.x, from.y, Cell.empty(from.x, from.y))
	grid.set_cell(to.x, to.y, player)


## Merge (BR-001): descongela o alvo divisível; coleta o quociente (ou o fator primo
## de fallback); o jogador avança para a célula do alvo com seu valor INALTERADO.
func _merge(from: Vector2i, to: Vector2i) -> Array:
	var player := grid.at(from.x, from.y)
	var target := grid.at(to.x, to.y)
	var pv := player.value
	var merged: int = (target.true_value / pv) if (target.true_value % pv == 0) else target.primo
	collection.add(merged)

	grid.set_cell(from.x, from.y, Cell.empty(from.x, from.y))
	grid.set_cell(to.x, to.y, Cell.player(to.x, to.y, pv))

	var events: Array = [{"type": "merged", "at": to, "collected": merged}]
	if grid.count_frozen() == 0:  # CheckVictory (BR-005)
		status = Status.WON
		events.append({"type": "match_won"})
	var melted := grid.snow_break()  # BR-004
	if melted > 0:
		events.append({"type": "snow_break", "melted": melted})
	return events


# ------------------------------------------------------------------ punição de gelo

func _blocked() -> Array:
	var events: Array = [{"type": "blocked"}]
	events += _apply_ice_penalty()
	return events


func _apply_ice_penalty() -> Array:
	var events: Array = []
	var result := _punish_ice()
	var spawned: Array = result["spawned"]
	if not spawned.is_empty():
		events.append({"type": "ice_spawned", "cells": spawned})
	if result["lost"] and status == Status.PLAYING:
		status = Status.LOST_SIEGE
		events.append({"type": "match_lost", "reason": "SIEGE"})
	return events


func _punish_ice() -> Dictionary:
	# CreateIce(false): sem célula vazia em lugar nenhum → nada acontece (nem avalia derrota).
	if not grid.has_empty():
		return {"spawned": [], "lost": false}
	var spawned := _spawn_ice()
	var lost := false
	# CreateIce(true) só avalia derrota se ainda restar célula vazia após o spawn.
	if grid.has_empty():
		lost = _is_siege()
	return {"spawned": spawned, "lost": lost}


## Spawn: para cada congelado, varre AROUND a partir da posição inicial (por borda),
## instancia 1 gelo no 1º EMPTY e para. Máx. 1 gelo por congelado por movimento (BR-003).
func _spawn_ice() -> Array:
	var spawned: Array = []
	for fp in grid.frozen_positions():
		var around := _around_cells(fp.x, fp.y)  # relido do grid vivo por congelado
		var pos := _first_ice_pos(fp.x, fp.y)
		for _j in 8:
			var t: Cell = around[pos]
			if t.kind == Cell.Kind.EMPTY:
				grid.set_cell(t.x, t.y, Cell.ice(t.x, t.y))
				spawned.append(Vector2i(t.x, t.y))
				break
			pos = (pos + 1) % 8
	return spawned


## Derrota por cerco (BR-006), tradução fiel do laço isGameOverLoop do legado.
func _is_siege() -> bool:
	var surrounded := _check_surrounded()
	var found_empty := false
	var found_player := false
	if not surrounded:
		for fp in grid.frozen_positions():
			for c in _around_cells(fp.x, fp.y):
				if c.kind == Cell.Kind.EMPTY:
					found_empty = true
				elif c.kind == Cell.Kind.PLAYER:
					found_player = true
	if not found_empty and found_player:
		return surrounded  # hasDivisibleNumber = !surrounded
	elif not found_empty and not found_player:
		return true
	return false


## CheckIfIsSorrounded: 4 ortogonais do jogador (LEFT, RIGHT, UP, DOWN). Escapa se
## houver EMPTY ou congelado divisível pelo valor atual OU por qualquer coletado.
func _check_surrounded() -> bool:
	var pp := grid.find_player()
	var pv := grid.at(pp.x, pp.y).value
	var neighbors: Array = [
		grid.at(pp.x - 1, pp.y),
		grid.at(pp.x + 1, pp.y),
		grid.at(pp.x, pp.y - 1),
		grid.at(pp.x, pp.y + 1),
	]
	for t in neighbors:
		if t.kind == Cell.Kind.NOTHING:
			continue
		if t.kind == Cell.Kind.EMPTY:
			return false
		if t.kind == Cell.Kind.FROZEN and _check_player_numbers(t.value, pv):
			return false
	return true


func _check_player_numbers(tile_value: int, player_value: int) -> bool:
	if player_value != 0 and tile_value % player_value == 0:
		return true
	for c in collection.values():
		if c != 0 and tile_value % c == 0:
			return true
	return false


## Posição inicial da varredura por posição do congelado (contrato observável, BR-003).
func _first_ice_pos(x: int, y: int) -> int:
	if y == 0 and x != grid.cols - 1:
		return _AR_RIGHT
	elif y == grid.rows - 1 and x != 0:
		return _AR_LEFT
	elif x == 0 and y != 0:
		return _AR_UP
	elif x == grid.cols - 1 and y != grid.rows - 1:
		return _AR_DOWN
	return _AR_RIGHT_DOWN


func _around_cells(x: int, y: int) -> Array:
	var out: Array = []
	for d in _AROUND:
		out.append(grid.at(x + d.x, y + d.y))
	return out


func _dir_delta(direction: int) -> Vector2i:
	match direction:
		Direction.UP: return Vector2i(0, -1)
		Direction.RIGHT: return Vector2i(1, 0)
		Direction.DOWN: return Vector2i(0, 1)
		Direction.LEFT: return Vector2i(-1, 0)
	return Vector2i.ZERO


func _check_exhaustion(events: Array) -> void:
	if status == Status.PLAYING and budget <= 0:  # BR-021
		status = Status.LOST_EXHAUSTION
		events.append({"type": "match_lost", "reason": "EXHAUSTION"})
