class_name BoardScene
extends Node2D
## Feature board — cena de jogo (S-06). Projeta `domain/board` em nós (a cena NÃO contém
## regra), captura swipe (BR-008), anima a fila de eventos passo a passo casada com o
## domínio (AD-03, BR-014: input bloqueado durante a animação), dispara o vocabulário
## sonoro pelo AudioBus (BR-055), exibe o balão de 8 slots (BR-050) e o modal de fim de
## fase com fundo que CLAREIA (DEV-008) no padrão variante A (DEV-007).
##
## VISUAL PLACEHOLDER: tiles são ColorRect + DigitRenderer até os sprites e o
## `resources/layout/grid_calibration.tres` entrarem na validação visual contra os prints
## (COD-007 tile-espelho do balão, COD-008 sprite do dragão, COD-001 durações). A lógica
## (partida ponta a ponta, coreografia de eventos, gate de fim) já é completa.

const LEVELS_DIR := "res://resources/levels/"
const THRESHOLDS_PATH := "res://resources/balance/thresholds.tres"

const TILE := 96.0
const GAP := 8.0
const STEP_TIME := 0.12   # ritmo do passo a passo (placeholder; duração canônica = COD-001)

# tokens de cor (design-system) — placeholders coerentes até o skin final
const COL_EMPTY := Color("3c5a3c")
const COL_TILE := Color("4e7a3e")
const COL_PLAYER := Color("f39221")
const COL_FROZEN := Color("7fb0d8")
const COL_ICE := Color("bfe0f2")

var stage: int = 1
var level: int = 1
var level_data: LevelData
var thresholds: Dictionary = {}
var budget_max: int = 0

var adapter: MatchAdapter
var _animating := false
var _drag_start := Vector2.ZERO
var _dragging := false

var _board_root: Node2D
var _tiles: Dictionary = {}          # Vector2i → ColorRect
var _budget_label: Label
var _balloon: HBoxContainer
var _modal: CanvasLayer
var _tutorial: TutorialOverlay = null


func _ready() -> void:
	_read_payload()
	_load_level()
	adapter = MatchAdapter.new()
	add_child(adapter)
	adapter.match_started.connect(_on_match_started)
	adapter.move_resolved.connect(_on_move_resolved)
	adapter.budget_changed.connect(_on_budget_changed)
	adapter.value_collected.connect(_on_value_collected)
	adapter.match_won.connect(_on_match_won)
	adapter.match_lost.connect(_on_match_lost)
	_build_hud()
	_build_balloon()
	adapter.start(level_data, budget_max)
	_maybe_attach_tutorial()
	_render_grid()
	AudioBus.play_music(AudioBus.MUSIC_GAMEPLAY)


## Nas fases-tutorial (identidade), arma o gate de movimento no domínio (BR-009) e sobrepõe
## a mão demonstrativa (BR-047/048); o balão passa a ser gateado pelo passo (BR-049).
func _maybe_attach_tutorial() -> void:
	if not TutorialSequence.is_tutorial(stage, level):
		return
	var moves := TutorialSequence.move_sequence(TutorialSequence.sequence_for(stage, level))
	adapter.match_game.set_tutorial_sequence(moves)
	_tutorial = TutorialOverlay.new()
	add_child(_tutorial)
	_tutorial.setup(stage, level, adapter)


# ------------------------------------------------------------------ setup

func _read_payload() -> void:
	var p := SceneRouter.consume_payload() if has_node("/root/SceneRouter") else {}
	stage = int(p.get("stage", stage))
	level = int(p.get("level", level))


func _load_level() -> void:
	var path := LEVELS_DIR + "level_%02d_%02d.tres" % [stage, level]
	var res := ResourceLoader.load(path) as LevelResource
	assert(res != null, "board: LevelResource ausente em %s" % path)
	level_data = LevelFactory.from_resource(res)
	var tb := ResourceLoader.load(THRESHOLDS_PATH) as BalanceThresholds
	thresholds = tb.for_level(stage, level) if tb != null else {"three_star": 0, "two_star": 0, "max": 10}
	budget_max = int(thresholds.get("max", 10))  # orçamento = threshold máximo (BR-021)


# ------------------------------------------------------------------ input (swipe, BR-008)

func _unhandled_input(event: InputEvent) -> void:
	if _animating or adapter.status() != Match.Status.PLAYING:
		return
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			_drag_start = event.position
			_dragging = true
		elif _dragging:
			_dragging = false
			var dir := SwipeDetector.direction_for(event.position - _drag_start)
			if dir != Match.Direction.NONE:
				adapter.move(dir)


# ------------------------------------------------------------------ animação passo a passo (AD-03)

func _on_move_resolved(events: Array) -> void:
	_animating = true
	for e in events:
		_cue_for_event(e)
		await get_tree().create_timer(STEP_TIME).timeout
	_render_grid()  # sincroniza o visual com o estado final do domínio
	_animating = false


## Cada evento dispara seu som do vocabulário (BR-055). O redesenho do grid vem no fim.
func _cue_for_event(e: Dictionary) -> void:
	match str(e["type"]):
		"blocked": AudioBus.play_effect(AudioBus.SFX_COLLISION)          # colisão não divisível
		"merged": AudioBus.play_effect(AudioBus.SFX_PRIME_SWAP)          # troca de primo
		"value_swapped": AudioBus.play_effect(AudioBus.SFX_PRIME_SWAP)
		"ice_spawned": AudioBus.play_effect(AudioBus.SFX_ICE_APPEAR)     # gelo surgindo
		"snow_break": AudioBus.play_effect(AudioBus.SFX_ICE_MELT)        # gelo derretendo


# ------------------------------------------------------------------ render (placeholder)

func _render_grid() -> void:
	if _board_root == null:
		_board_root = Node2D.new()
		_board_root.position = Vector2(120, 300)
		add_child(_board_root)
	for child in _board_root.get_children():
		child.queue_free()
	_tiles.clear()
	var grid: Grid = adapter.match_game.grid
	for y in grid.rows:
		for x in grid.cols:
			var cell: Cell = grid.at(x, y)
			var rect := ColorRect.new()
			rect.size = Vector2(TILE, TILE)
			rect.position = Vector2(x * (TILE + GAP), y * (TILE + GAP))
			rect.color = _color_for(cell)
			_board_root.add_child(rect)
			if cell.kind == Cell.Kind.PLAYER or cell.kind == Cell.Kind.FROZEN:
				var d := DigitRenderer.new()
				# bitmap fonts originais (DEV-002): player = Fonts2/font, congelados = OrangeFont
				d.font = GameFonts.PLAYER if cell.kind == Cell.Kind.PLAYER else GameFonts.TILE
				d.box_size = Vector2(TILE, TILE)
				rect.add_child(d)
				d.set_anchors_preset(Control.PRESET_FULL_RECT)
				d.set_value(cell.value)
			_tiles[Vector2i(x, y)] = rect


func _color_for(cell: Cell) -> Color:
	match cell.kind:
		Cell.Kind.PLAYER: return COL_PLAYER
		Cell.Kind.FROZEN: return COL_FROZEN
		Cell.Kind.ICE: return COL_ICE
		Cell.Kind.EMPTY: return COL_EMPTY
		_: return Color.TRANSPARENT


# ------------------------------------------------------------------ HUD e balão

func _build_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)
	_budget_label = Label.new()
	_budget_label.position = Vector2(24, 24)
	_budget_label.add_theme_font_size_override("font_size", 40)
	hud.add_child(_budget_label)
	_update_budget(budget_max)
	var pause_btn := Button.new()
	pause_btn.text = "PAUSE"
	pause_btn.position = Vector2(560, 24)
	pause_btn.pressed.connect(_on_pause)
	hud.add_child(pause_btn)


func _build_balloon() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_balloon = HBoxContainer.new()
	_balloon.position = Vector2(40, 1160)
	_balloon.add_theme_constant_override("separation", 8)
	layer.add_child(_balloon)


func _refresh_balloon() -> void:
	for child in _balloon.get_children():
		child.queue_free()
	for value in adapter.match_game.collection.values():   # ≤ 8 slots, ≤ 2 dígitos (BR-050)
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(72, 72)
		slot.text = str(value)
		slot.add_theme_font_override("font", GameFonts.TILE)  # balão usa OrangeFont (legado)
		slot.pressed.connect(_on_slot_pressed.bind(value))
		_balloon.add_child(slot)


func _on_slot_pressed(value: int) -> void:
	if _animating or adapter.status() != Match.Status.PLAYING:
		return
	if _tutorial != null and not _tutorial.balloon_clickable():
		return  # no tutorial, o balão só responde no passo do balão (BR-049)
	adapter.swap(value)  # BR-012/013
	if _tutorial != null:
		_tutorial.notify_balloon_used()


# ------------------------------------------------------------------ sinais do adaptador

func _on_match_started() -> void:
	_update_budget(budget_max)


func _on_budget_changed(b: int) -> void:
	_update_budget(b)


func _update_budget(b: int) -> void:
	if _budget_label != null:
		_budget_label.text = "%02d/%02d" % [b, budget_max]  # zero à esquerda (S-06)


func _on_value_collected(_value: int) -> void:
	_refresh_balloon()


func _on_match_won() -> void:
	# recompensa e desbloqueio via progressão (única porta do save, AD-04)
	ProgressionStore.register_win(stage, level, adapter.match_game.budget, thresholds)
	var stars := StarRating.stars_for(adapter.match_game.budget, thresholds)  # GetStars(true)
	_show_endgame(true, stars)


func _on_match_lost(_reason: String) -> void:
	ProgressionStore.register_loss(stage, level)  # reset punitivo (BR-028)
	_show_endgame(false, 0)


# ------------------------------------------------------------------ fim de fase (S-08/S-09)

## Modal padronizado variante A (DEV-007) sobre o board CLAREADO (DEV-008). Coreografia
## de entrada (fundo clareia → card sobe → estrelas → dragão) especificada; durações
## exatas (COD-001) e sprites (COD-008 dragão) entram na validação visual.
func _show_endgame(won: bool, stars: int) -> void:
	AudioBus.play_stinger(AudioBus.STINGER_WIN if won else AudioBus.STINGER_LOSE)
	_modal = CanvasLayer.new()
	add_child(_modal)
	var lighten := ColorRect.new()   # DEV-008: overlay branco semitransparente (não escuro)
	lighten.color = Color(1, 1, 1, 0.4)
	lighten.set_anchors_preset(Control.PRESET_FULL_RECT)
	lighten.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal.add_child(lighten)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.add_theme_constant_override("separation", 16)
	_modal.add_child(box)
	box.add_child(_title_label("PARABÉNS!" if won else "FIM DE JOGO"))
	if won:
		box.add_child(_title_label("%d★" % stars))
		var reward: int = ProgressionStore.energy()
		box.add_child(_title_label("⚡ %d" % reward))
		box.add_child(_modal_button("PRÓXIMO", _on_next))
		box.add_child(_modal_button("JOGAR DE NOVO", _on_retry))
	else:
		box.add_child(_modal_button("TENTAR DE NOVO", _on_retry))
	box.add_child(_modal_button("SELEÇÃO DE FASES", _on_level_select))


func _title_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 48)
	return l


func _modal_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	return b


# ------------------------------------------------------------------ navegação de fim/pausa

func _on_next() -> void:
	if level >= 12:  # BR-035: 12º → seleção
		_on_level_select()
	else:
		_goto_board(stage, level + 1)


func _on_retry() -> void:
	_goto_board(stage, level)


func _on_level_select() -> void:
	SceneRouter.change_scene("res://features/level_select/level_select.tscn",
		SceneRouter.Context.LEVEL_SELECT)


func _goto_board(s: int, l: int) -> void:
	SceneRouter.change_scene("res://features/board/game_board.tscn",
		SceneRouter.Context.BOARD, {"stage": s, "level": l})


func _on_pause() -> void:
	SceneRouter.go_back()  # placeholder; pause_overlay (S-07) é da T13/refino
