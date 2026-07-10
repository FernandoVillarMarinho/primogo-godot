class_name TutorialOverlay
extends Node2D
## Feature tutorial — camada da mão demonstrativa (S-10) sobre o board nas fases-tutorial.
## Mão unificada e parametrizada pela sequência (BR-047/048); ciclo em TEMPO REAL (Tween,
## não frame-counter — D-005). Gate do balão por identidade do passo (BR-049): o balão só
## é clicável quando o passo corrente é BALLOON, e o clique avança o tutorial. Ao concluir,
## marca a flag persistida (BR-052) via ProgressionStore.
##
## ARTE ORIGINAL (T20/Fase 3): mão real tutorial/mao-tutorial-* por gesto (Hand prefab,
## BR-047). Marcos canônicos 50/65/80/120 do ciclo continuam 🟡 (COD-001).

signal tutorial_finished()

const HAND_BY_DIRECTION: Dictionary = {
	Match.Direction.UP: preload("res://assets/images/tutorial/mao-tutorial-cima.png"),
	Match.Direction.DOWN: preload("res://assets/images/tutorial/mao-tutorial-baixo.png"),
	Match.Direction.LEFT: preload("res://assets/images/tutorial/mao-tutorial-esquerda.png"),
	Match.Direction.RIGHT: preload("res://assets/images/tutorial/mao-tutorial-direita.png"),
}
const HAND_CLICK := preload("res://assets/images/tutorial/mao-tutorial-clique.png")
const HAND_NEUTRAL := preload("res://assets/images/tutorial/mao.png")

var stage: int
var level: int
var adapter: MatchAdapter
var _seq: Array = []
var _index: int = 0
var _which: String = "t1"
var _finished := false
var _hand: Sprite2D


func setup(s: int, l: int, ad: MatchAdapter) -> void:
	stage = s
	level = l
	adapter = ad
	_seq = TutorialSequence.sequence_for(s, l)
	_which = TutorialSequence.which(s, l)
	if adapter != null:
		adapter.move_resolved.connect(_on_move)
	_build_hand()
	_demonstrate()


func balloon_clickable() -> bool:
	return TutorialSequence.is_balloon_step(_seq, _index)


func is_finished() -> bool:
	return _finished


## Avança o passo demonstrado; ao esgotar a sequência marca o tutorial concluído
## (flag persistida, BR-052) e sinaliza.
func advance() -> void:
	if _finished:
		return
	_index += 1
	if _index >= _seq.size():
		_complete()
	else:
		_demonstrate()


## Chamado pela cena quando o balão é usado; só avança se o passo corrente for o do balão.
func notify_balloon_used() -> void:
	if balloon_clickable():
		advance()


func _on_move(_events: Array) -> void:
	# Um swipe aceito avança a demonstração — exceto no passo do balão, que exige o clique.
	if not balloon_clickable():
		advance()


func _complete() -> void:
	_finished = true
	if has_node("/root/ProgressionStore"):
		ProgressionStore.mark_tutorial_done(_which)
	tutorial_finished.emit()


func _build_hand() -> void:
	_hand = Sprite2D.new()
	_hand.texture = HAND_NEUTRAL
	_hand.position = Vector2(360, 700)   # sobre o board (🟡 ajuste fino na validação)
	add_child(_hand)


## Ciclo da mão: mostra o gesto do passo corrente (sprite original por direção; clique no
## passo do balão) e pulsa em loop (BR-047). Durações canônicas = 🟡 COD-001.
func _demonstrate() -> void:
	if _hand == null:
		return
	var step: Variant = _seq[_index] if _index < _seq.size() else null
	if step == TutorialSequence.BALLOON:
		_hand.texture = HAND_CLICK
	else:
		_hand.texture = HAND_BY_DIRECTION.get(step, HAND_NEUTRAL)
	ScaleEffects.pulse(_hand)
