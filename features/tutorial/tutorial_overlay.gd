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
const FONT_TEXT := preload("res://assets/fonts/katahdin_round.otf")

const HAND_HOME := Vector2(360, 700)   # posição padrão da mão, sobre o board

var stage: int
var level: int
var adapter: MatchAdapter
var _seq: Array = []
var _captions: Array = []
var _index: int = 0
var _which: String = "t1"
var _finished := false
var _hand: Sprite2D
var _caption: Label
var _caption_panel: PanelContainer


func setup(s: int, l: int, ad: MatchAdapter) -> void:
	stage = s
	level = l
	adapter = ad
	_seq = TutorialSequence.sequence_for(s, l)
	_captions = TutorialSequence.captions_for(s, l)
	_which = TutorialSequence.which(s, l)
	if adapter != null:
		adapter.move_resolved.connect(_on_move)
	_build_hand()
	_build_caption()
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
	if _hand != null:
		_hand.visible = false
	if _caption_panel != null:
		_caption_panel.visible = false
	if has_node("/root/ProgressionStore"):
		ProgressionStore.mark_tutorial_done(_which)
	tutorial_finished.emit()


## Move a mão para um alvo específico (ex.: o slot do primo a clicar no balão) — a cena
## do board chama no passo do balão; o próximo _demonstrate devolve à posição padrão.
func point_to(pos: Vector2) -> void:
	if _hand != null:
		_hand.position = pos


func _build_hand() -> void:
	_hand = Sprite2D.new()
	_hand.texture = HAND_NEUTRAL
	_hand.position = HAND_HOME   # sobre o board (🟡 ajuste fino na validação)
	add_child(_hand)


## Instrução curta do passo corrente (4º teste), num cartão legível sobre qualquer fundo,
## posicionado por âncoras (topo, largura total com margens — item 9: sem coordenada fixa).
func _build_caption() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_caption_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.2, 0.32, 0.82)
	style.set_corner_radius_all(18)
	style.content_margin_left = 22.0
	style.content_margin_right = 22.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	_caption_panel.add_theme_stylebox_override("panel", style)
	_caption_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_caption_panel.offset_left = 30.0
	_caption_panel.offset_right = -30.0
	_caption_panel.offset_top = 120.0   # abaixo do HUD (energia/pausa)
	layer.add_child(_caption_panel)
	_caption = Label.new()
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.add_theme_font_override("font", FONT_TEXT)
	_caption.add_theme_font_size_override("font_size", 28)
	_caption.add_theme_color_override("font_color", Color.WHITE)
	_caption.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	_caption.add_theme_constant_override("shadow_offset_x", 2)
	_caption.add_theme_constant_override("shadow_offset_y", 2)
	_caption_panel.add_child(_caption)


## Ciclo da mão: mostra o gesto do passo corrente (sprite original por direção; clique no
## passo do balão) e pulsa em loop (BR-047); a instrução escrita avança junto com o passo
## e some quando a ação correspondente é concluída. Durações canônicas = 🟡 COD-001.
func _demonstrate() -> void:
	if _hand == null:
		return
	var step: Variant = _seq[_index] if _index < _seq.size() else null
	if step == TutorialSequence.BALLOON:
		_hand.texture = HAND_CLICK
	else:
		_hand.texture = HAND_BY_DIRECTION.get(step, HAND_NEUTRAL)
		_hand.position = HAND_HOME
	if _caption != null:
		_caption.text = str(_captions[_index]) if _index < _captions.size() else ""
		_caption_panel.visible = _caption.text != ""
	ScaleEffects.pulse(_hand)
