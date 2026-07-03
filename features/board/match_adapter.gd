class_name MatchAdapter
extends Node
## Feature board — fronteira ÚNICA entre a casca e o domínio puro `Match` (paradigma,
## implicação 5). Embrulha a partida e converte os eventos retornados pelos comandos
## (AD-02) em sinais Godot. A fila bruta de eventos (`move_resolved`) é entregue à cena
## para animar passo a passo (AD-03); os sinais terminais alimentam a progressão.

signal match_started()
signal move_resolved(events: Array)   ## fila ordenada de um movimento → animação passo a passo
signal move_rejected(reason: String)
signal budget_changed(budget: int)
signal value_collected(value: int)
signal match_won()
signal match_lost(reason: String)

const _REJECTIONS := ["move_rejected", "swap_rejected"]

var match_game: Match


func _init() -> void:
	match_game = Match.new()


func start(level: LevelData, budget: int) -> Array:
	var events := match_game.start(level, budget)
	match_started.emit()
	return events


func move(direction: int) -> Array:
	var events := match_game.move(direction)
	_dispatch(events)
	return events


func swap(value: int) -> Array:
	var events := match_game.swap_value(value)
	_dispatch(events)
	return events


func status() -> int:
	return match_game.status


## Traduz cada evento do domínio em sinal (AD-02) e, para movimentos aceitos, entrega a
## fila inteira à cena animar (AD-03). Movimentos só-rejeitados não geram animação.
func _dispatch(events: Array) -> void:
	for e in events:
		match e["type"]:
			"move_rejected", "swap_rejected":
				move_rejected.emit(str(e["reason"]))
			"move_accepted", "value_swapped":
				budget_changed.emit(int(e["budget"]))
			"merged":
				value_collected.emit(int(e["collected"]))
			"match_won":
				match_won.emit()
			"match_lost":
				match_lost.emit(str(e["reason"]))
	if not events.is_empty() and not _REJECTIONS.has(str(events[0]["type"])):
		move_resolved.emit(events)
