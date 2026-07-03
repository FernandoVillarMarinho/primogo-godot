class_name TutorialOverlay
extends Node2D
## Feature tutorial — camada da mão demonstrativa (S-10) sobre o board nas fases-tutorial.
## Mão unificada e parametrizada pela sequência (BR-047/048); ciclo em TEMPO REAL (Tween,
## não frame-counter — D-005). Gate do balão por identidade do passo (BR-049): o balão só
## é clicável quando o passo corrente é BALLOON, e o clique avança o tutorial. Ao concluir,
## marca a flag persistida (BR-052) via ProgressionStore.
##
## VISUAL/DURAÇÃO PLACEHOLDER: sprites da mão (up/right/down/left/click/pure) e os marcos
## canônicos 50/65/80/120 do ciclo (COD-001) entram na validação visual.

signal tutorial_finished()

var stage: int
var level: int
var adapter: MatchAdapter
var _seq: Array = []
var _index: int = 0
var _which: String = "t1"
var _finished := false
var _hand: Label


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
	_hand = Label.new()
	_hand.text = "☝"
	_hand.add_theme_font_size_override("font_size", 64)
	add_child(_hand)


## Ciclo da mão: deslizar → pausar → fade-out → teleportar → próximo gesto, em loop
## (BR-047). Placeholder: pulsa a mão indicando o próximo gesto (durações = COD-001).
func _demonstrate() -> void:
	if _hand != null:
		ScaleEffects.pulse(_hand)
