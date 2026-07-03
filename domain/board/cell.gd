class_name Cell
extends RefCounted
## Célula do tabuleiro (contexto Board). Pura, sem engine.
## NOTHING é a sentinela para fora-do-grid (BR-018) — as varreduras não fazem null-check.

enum Kind { EMPTY, PLAYER, FROZEN, ICE, NOTHING }

var kind: int
var x: int
var y: int
var value: int        ## valor EXIBIDO (PLAYER e FROZEN)
var true_value: int   ## valor REAL (FROZEN; no PLAYER, value == true_value)
var primo: int        ## fator primo de fallback do merge (FROZEN, BR-001)


func _init(p_kind: int = Kind.EMPTY, p_x: int = 0, p_y: int = 0) -> void:
	kind = p_kind
	x = p_x
	y = p_y


static func empty(x: int, y: int) -> Cell:
	return Cell.new(Kind.EMPTY, x, y)


static func nothing() -> Cell:
	return Cell.new(Kind.NOTHING, -1, -1)


static func ice(x: int, y: int) -> Cell:
	return Cell.new(Kind.ICE, x, y)


static func player(x: int, y: int, value: int) -> Cell:
	var c := Cell.new(Kind.PLAYER, x, y)
	c.value = value
	c.true_value = value
	return c


static func frozen(x: int, y: int, displayed: int, real_value: int, primo: int) -> Cell:
	var c := Cell.new(Kind.FROZEN, x, y)
	c.value = displayed
	c.true_value = real_value
	c.primo = primo
	return c
