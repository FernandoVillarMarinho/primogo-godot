class_name BoardScene
extends Node2D
## Feature board — cena de jogo (S-06). Projeta `domain/board` em nós (a cena NÃO contém
## regra), captura swipe (BR-008), anima a fila de eventos passo a passo casada com o
## domínio (AD-03, BR-014: input bloqueado durante a animação), dispara o vocabulário
## sonoro pelo AudioBus (BR-055), exibe o balão de 8 slots (BR-050) e o modal de fim de
## fase com fundo que CLAREIA (DEV-008) no padrão variante A (DEV-007).
##
## SKIN ORIGINAL (T19/Fase 3): cenário por grade + tiles via `grid_calibration.tres`
## (transcrito do GameManager legado); player = chama animada (fogo1..3, prefab Number),
## congelado = gelo_numero, gelo puro = gelo (prefab Ice); efeitos one-shot: vapor no
## merge, anim_gelo01..05 no gelo surgindo (reverso ao derreter); balão = slots
## box-numbers com o slot do valor em uso ELEVADO (tile-espelho, COD-007 →
## BalloonController.SetPrimogoValue/ChangeNumber: ±0.25 un.); pausa real (S-07).
## Restam 🟡 para validação visual: fine_offset da calibração e durações (COD-001).

const LEVELS_DIR := "res://resources/levels/"
const THRESHOLDS_PATH := "res://resources/balance/thresholds.tres"
const CALIBRATION_PATH := "res://resources/balance/grid_calibration.tres"

const STEP_TIME := 0.12   # ritmo do passo a passo (placeholder; duração canônica = COD-001)
const EFFECT_FPS := 12.0  # anim_gelo/vapor one-shot (🟡 COD-001)
const FLAME_FPS := 8.0    # chama do player (fogo1..3 em loop)
const SLOT_RAISE := 18.0  # slot selecionado do balão elevado (0.25 un. ≈ 18 px @ escala do balão)

const TEX_SCENERY := preload("res://assets/images/scenery_grid/background.png")
const TEX_FROZEN := preload("res://assets/images/iceandfire/gelo_numero.png")
const TEX_ICE := preload("res://assets/images/iceandfire/gelo.png")
const TEX_SLOT := preload("res://assets/images/gameplay/box-numbers.png")
const TEX_BADGE := preload("res://assets/images/gameplay/energy-bar.png")   # mãozinha + caixa de movimentos (MovesBar)
const TEX_PAUSE_BTN := preload("res://assets/images/gameplay/bt-pause.png")
const TEX_PAUSE_BASE := preload("res://assets/images/gameplay/bt-pause-base.png")
const TEX_RELOAD := preload("res://assets/images/gameplay/bt-reload.png")
const TEX_WIN_BOX := preload("res://assets/images/endgame/box-endgame-parabens.png")
const TEX_LOSE_BOX := preload("res://assets/images/endgame/box-fimdejogo.png")
const FONT_TEXT := preload("res://assets/fonts/katahdin_round.otf")   # fonte de texto do legado
const TEX_BT_NEXT := preload("res://assets/images/endgame/bt-next.png")
const TEX_BT_PLAYAGAIN := preload("res://assets/images/endgame/bt-playagain.png")
const TEX_BT_TRYAGAIN := preload("res://assets/images/endgame/bt-tryagain.png")
const TEX_STAR_ON := preload("res://assets/images/endgame/star.png")
const TEX_STAR_OFF := preload("res://assets/images/endgame/star-off.png")
const TEX_ENERGY := preload("res://assets/images/endgame/icon-energy.png")
const TEX_LEVELSELECT_BTN := preload("res://assets/images/gameplay/pause-bt-selecaodefases.png")

const FLAME_FRAMES: Array = [
	preload("res://assets/images/iceandfire/fogo1.png"),
	preload("res://assets/images/iceandfire/fogo2.png"),
	preload("res://assets/images/iceandfire/fogo3.png"),
]
const ICE_ANIM_FRAMES: Array = [
	preload("res://assets/images/iceandfire/anim_gelo01.png"),
	preload("res://assets/images/iceandfire/anim_gelo02.png"),
	preload("res://assets/images/iceandfire/anim_gelo03.png"),
	preload("res://assets/images/iceandfire/anim_gelo04.png"),
	preload("res://assets/images/iceandfire/anim_gelo05.png"),
]
const VAPOR_FRAMES: Array = [
	preload("res://assets/images/iceandfire/vapor01.png"),
	preload("res://assets/images/iceandfire/vapor02.png"),
	preload("res://assets/images/iceandfire/vapor03.png"),
]
const DRAGON_FRAMES: Array = [
	preload("res://assets/images/primogo/dragao_anim01.png"),
	preload("res://assets/images/primogo/dragao_anim02.png"),
	preload("res://assets/images/primogo/dragao_anim03.png"),
	preload("res://assets/images/primogo/dragao_anim04.png"),
	preload("res://assets/images/primogo/dragao_anim05.png"),
	preload("res://assets/images/primogo/dragao_anim06.png"),
	preload("res://assets/images/primogo/dragao_anim07.png"),
	preload("res://assets/images/primogo/dragao_anim08.png"),
]
const DRAGON_FPS := 8.0        # 🟡 COD-001
const DRAGON_DELAY := 0.6      # entrada atrasada do dragão na coreografia S-08 (🟡 COD-001)

var stage: int = 1
var level: int = 1
var level_data: LevelData
var thresholds: Dictionary = {}
var budget_max: int = 0

var adapter: MatchAdapter
var _animating := false
var _drag_start := Vector2.ZERO
var _dragging := false

var _calibration: GridCalibration
var _layout: Dictionary = {}
var _spacing := 96.0
var _board_root: Node2D
var _bg: Sprite2D
var _tiles: Dictionary = {}          # Vector2i → Node2D (raiz do tile na célula)
var _budget_label: Label
var _balloon: HBoxContainer
var _modal: CanvasLayer
var _pause: PauseOverlay
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
	_build_background()
	_build_hud()
	_build_balloon()
	_build_pause()
	adapter.start(level_data, budget_max)
	_maybe_attach_tutorial()
	_render_grid()
	_refresh_balloon()
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
	_calibration = ResourceLoader.load(CALIBRATION_PATH) as GridCalibration


## Cenário céu/floresta (prefab Scenery) + quadriculado da grade (Scenery_Grid),
## posicionados/escalados pela calibração.
func _build_background() -> void:
	var rows := level_data.rows
	var cols := level_data.cols
	_layout = _calibration.layout_for(rows, cols) if _calibration != null else {}
	if _layout.is_empty():
		# grade fora da tabela do legado: fallback neutro centrado (não deve ocorrer nas 122)
		_layout = {"cell_px": 96.0, "bg_scale": 1.0, "bg_center": Vector2(360, 760),
			"texture": "", "tile_scale": 1.0, "fine_offset": Vector2.ZERO}
	_spacing = GridCalibration.spacing_of(_layout)
	var scenery := Sprite2D.new()   # fundo de tela inteira (céu/montanhas/gramado)
	scenery.texture = TEX_SCENERY
	var sc := 720.0 / float(TEX_SCENERY.get_width())
	scenery.scale = Vector2(sc, sc)
	scenery.position = Vector2(360, float(_layout.get("scenery_center_y", -38.4)))
	add_child(scenery)
	var tex_path := str(_layout.get("texture", ""))
	if tex_path != "":
		_bg = Sprite2D.new()
		_bg.texture = load(tex_path)
		_bg.position = _layout["bg_center"] + _layout.get("fine_offset", Vector2.ZERO)
		var s := float(_layout["bg_scale"])
		_bg.scale = Vector2(s, s)
		add_child(_bg)


## Centro da célula (x, y) em coordenadas de viewport (grade centrada no cenário).
func _cell_center(x: int, y: int) -> Vector2:
	var base: Vector2 = _layout["bg_center"] + _layout.get("fine_offset", Vector2.ZERO) \
		- Vector2((level_data.cols - 1) / 2.0, (level_data.rows - 1) / 2.0) * _spacing
	return base + Vector2(x, y) * _spacing


# ------------------------------------------------------------------ input (swipe, BR-008)

func _unhandled_input(event: InputEvent) -> void:
	if _animating or adapter.status() != Match.Status.PLAYING:
		return
	if _pause != null and _pause.is_open():
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
	_refresh_balloon()
	_animating = false


## Cada evento dispara seu som do vocabulário (BR-055) e o efeito visual one-shot
## ancorado na célula do evento. O redesenho do grid vem no fim.
func _cue_for_event(e: Dictionary) -> void:
	match str(e["type"]):
		"blocked":
			AudioBus.play_effect(AudioBus.SFX_COLLISION)          # colisão não divisível
		"merged":
			AudioBus.play_effect(AudioBus.SFX_PRIME_SWAP)         # troca de primo
			if e.has("at"):
				_spawn_effect(VAPOR_FRAMES, e["at"], false)       # vapor do merge
		"value_swapped":
			AudioBus.play_effect(AudioBus.SFX_PRIME_SWAP)
		"ice_spawned":
			AudioBus.play_effect(AudioBus.SFX_ICE_APPEAR)         # gelo surgindo
			for c in e.get("cells", []):
				_spawn_effect(ICE_ANIM_FRAMES, c, false)
		"snow_break":
			AudioBus.play_effect(AudioBus.SFX_ICE_MELT)           # gelo derretendo
			for c in e.get("melted", []):
				_spawn_effect(ICE_ANIM_FRAMES, c, true)           # derreter = reverso


## AnimatedSprite2D one-shot na célula; libera-se ao terminar.
func _spawn_effect(frame_textures: Array, cell: Variant, reverse: bool) -> void:
	var pos := _cell_center(int(cell.x), int(cell.y))
	var frames := SpriteFrames.new()
	frames.add_animation("fx")
	frames.set_animation_speed("fx", EFFECT_FPS)
	frames.set_animation_loop("fx", false)
	var ordered := frame_textures.duplicate()
	if reverse:
		ordered.reverse()
	for t in ordered:
		frames.add_frame("fx", t)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.position = pos
	var tex: Texture2D = ordered[0]
	var s := _spacing / maxf(float(tex.get_width()), float(tex.get_height()))
	sprite.scale = Vector2(s, s)
	add_child(sprite)
	sprite.animation_finished.connect(sprite.queue_free)
	sprite.play("fx")


# ------------------------------------------------------------------ render (skin original)

func _render_grid() -> void:
	if _board_root == null:
		_board_root = Node2D.new()
		add_child(_board_root)
	for child in _board_root.get_children():
		child.queue_free()
	_tiles.clear()
	var grid: Grid = adapter.match_game.grid
	for y in grid.rows:
		for x in grid.cols:
			var cell: Cell = grid.at(x, y)
			if cell.kind == Cell.Kind.EMPTY:
				continue  # célula vazia = o próprio cenário da grade
			var root := Node2D.new()
			root.position = _cell_center(x, y)
			_board_root.add_child(root)
			match cell.kind:
				Cell.Kind.PLAYER:
					root.add_child(_flame_sprite())
					root.add_child(_digits(cell.value, GameFonts.PLAYER))
				Cell.Kind.FROZEN:
					root.add_child(_tile_sprite(TEX_FROZEN))
					root.add_child(_digits(cell.value, GameFonts.TILE))
				Cell.Kind.ICE:
					root.add_child(_tile_sprite(TEX_ICE))
			_tiles[Vector2i(x, y)] = root


func _tile_sprite(tex: Texture2D) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = tex
	var s := _spacing / maxf(float(tex.get_width()), float(tex.get_height()))
	sprite.scale = Vector2(s, s)
	return sprite


## Chama animada do player (prefab Number do legado: fogo1..3 + fogo2.controller).
func _flame_sprite() -> AnimatedSprite2D:
	var frames := SpriteFrames.new()
	frames.add_animation("burn")
	frames.set_animation_speed("burn", FLAME_FPS)
	frames.set_animation_loop("burn", true)
	for t in FLAME_FRAMES:
		frames.add_frame("burn", t)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	var tex: Texture2D = FLAME_FRAMES[0]
	var s := _spacing / maxf(float(tex.get_width()), float(tex.get_height())) * 1.15
	sprite.scale = Vector2(s, s)
	sprite.play("burn")
	return sprite


func _digits(value: int, font: Font) -> DigitRenderer:
	var d := DigitRenderer.new()
	d.font = font
	d.box_size = Vector2(_spacing, _spacing)
	d.position = Vector2(-_spacing / 2.0, -_spacing / 2.0)
	d.set_value(value)
	return d


# ------------------------------------------------------------------ HUD e balão

func _build_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)

	var badge := TextureRect.new()   # MovesBar do legado: mãozinha + caixa (energy-bar.png)
	badge.texture = TEX_BADGE
	badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	badge.position = Vector2(20, 16)
	badge.custom_minimum_size = Vector2(190, 96)
	badge.size = badge.custom_minimum_size
	hud.add_child(badge)
	_budget_label = Label.new()   # "XX/YY" na caixa do badge (a caixa é a metade direita da arte)
	_budget_label.position = Vector2(92, 40)
	_budget_label.add_theme_font_override("font", FONT_TEXT)
	_budget_label.add_theme_font_size_override("font_size", 34)
	_budget_label.add_theme_color_override("font_color", Color("f39221"))
	hud.add_child(_budget_label)
	_update_budget(budget_max)

	hud.add_child(_hud_button(TEX_RELOAD, TEX_RELOAD, Vector2(524, 20), Vector2(72, 76), _on_retry))
	hud.add_child(_hud_button(TEX_PAUSE_BTN, TEX_PAUSE_BASE, Vector2(616, 20), Vector2(72, 76), _on_pause))


## Botão do HUD: arte sobre a base circular, com tamanho explícito (a arte é maior que o alvo).
func _hud_button(tex: Texture2D, base: Texture2D, pos: Vector2, size: Vector2, cb: Callable) -> Control:
	var holder := Control.new()
	holder.position = pos
	holder.custom_minimum_size = size
	holder.size = size
	if base != tex:
		var base_rect := TextureRect.new()
		base_rect.texture = base
		base_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		base_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		base_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		holder.add_child(base_rect)
	var b := TextureButton.new()
	b.texture_normal = tex
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.pressed.connect(cb)
	holder.add_child(b)
	return holder


func _build_balloon() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var pos: Vector2 = _calibration.balloon_for(level_data.rows, level_data.cols) \
		if _calibration != null else GridCalibration.DEFAULT_BALLOON
	var strip := Control.new()   # faixa de largura total; o HBox centra os slots nela
	strip.set_anchors_preset(Control.PRESET_TOP_WIDE)
	strip.offset_top = pos.y - 48
	strip.offset_bottom = pos.y + 48
	layer.add_child(strip)
	_balloon = HBoxContainer.new()
	_balloon.set_anchors_preset(Control.PRESET_FULL_RECT)
	_balloon.alignment = BoxContainer.ALIGNMENT_CENTER
	_balloon.add_theme_constant_override("separation", 6)
	strip.add_child(_balloon)


## Balão de 8 slots (BR-050): o 1º slot espelha o valor EM USO do player, elevado
## (tile-espelho — COD-007/AMB-201 resolvida: BalloonController.SetPrimogoValue eleva o
## slot selecionado +0.25 un. e ChangeNumber troca a elevação junto com a troca de valor).
## Os demais slots são os valores coletados, clicáveis para a troca (BR-012/013).
func _refresh_balloon() -> void:
	if _balloon == null:
		return
	for child in _balloon.get_children():
		child.queue_free()
	var current := _player_value()
	_balloon.add_child(_balloon_slot(current, true, false))
	for value in adapter.match_game.collection.values():   # ≤ 8 slots, ≤ 2 dígitos (BR-050)
		_balloon.add_child(_balloon_slot(int(value), false, true))


func _balloon_slot(value: int, raised: bool, clickable: bool) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(76, 76 + SLOT_RAISE)
	var slot := TextureButton.new()
	slot.texture_normal = TEX_SLOT
	slot.ignore_texture_size = true
	slot.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	slot.size = Vector2(76, 76)
	slot.position = Vector2(0, 0 if raised else SLOT_RAISE)
	slot.disabled = not clickable
	if clickable:
		slot.pressed.connect(_on_slot_pressed.bind(value))
	holder.add_child(slot)
	var d := DigitRenderer.new()
	d.font = GameFonts.TILE   # balão usa OrangeFont (BalloonController.allSprites)
	d.box_size = Vector2(60, 60)
	d.position = Vector2(8, (0 if raised else SLOT_RAISE) + 8)
	d.set_value(value)
	holder.add_child(d)
	return holder


func _player_value() -> int:
	var grid: Grid = adapter.match_game.grid
	for y in grid.rows:
		for x in grid.cols:
			var cell: Cell = grid.at(x, y)
			if cell.kind == Cell.Kind.PLAYER:
				return cell.value
	return 0


func _on_slot_pressed(value: int) -> void:
	if _animating or adapter.status() != Match.Status.PLAYING:
		return
	if _pause != null and _pause.is_open():
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

## Modal padronizado variante A (DEV-007) sobre o board CLAREADO (DEV-008), com a arte
## original (box-endgame-parabens/endgame_lose, bt-next/playagain/tryagain, estrelas,
## icon-energy). Dragão animado da coreografia (COD-008) entra na T20. Durações = COD-001.
func _show_endgame(won: bool, stars: int) -> void:
	AudioBus.play_stinger(AudioBus.STINGER_WIN if won else AudioBus.STINGER_LOSE)
	_modal = CanvasLayer.new()
	add_child(_modal)
	var lighten := ColorRect.new()   # DEV-008: overlay branco semitransparente (não escuro)
	lighten.color = Color(1, 1, 1, 0.4)
	lighten.set_anchors_preset(Control.PRESET_FULL_RECT)
	lighten.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal.add_child(lighten)

	# CenterContainer garante o card no CENTRO da tela (PRESET_CENTER + min size cresce
	# para a direita/baixo — era o bug do modal deslocado visto no teste em dispositivo)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modal.add_child(center)

	var panel := Control.new()
	panel.custom_minimum_size = Vector2(560, 640)
	center.add_child(panel)

	var card := TextureRect.new()    # a arte já traz o título ("PARABÉNS!" / "FIM DE JOGO")
	card.texture = TEX_WIN_BOX if won else TEX_LOSE_BOX
	card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(card)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_top = 150.0   # abaixo do título desenhado no card
	box.offset_bottom = -60.0
	box.add_theme_constant_override("separation", 14)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(box)

	if won:
		box.add_child(_center_h(_stars_row(stars)))
		box.add_child(_center_h(_reward_row(ProgressionStore.energy())))
		box.add_child(_center_h(_endgame_button(TEX_BT_NEXT, _on_next)))
		box.add_child(_center_h(_endgame_button(TEX_BT_PLAYAGAIN, _on_retry)))
		_spawn_dragon()   # dragão original dragao_anim01..08 (fecha COD-008)
	else:
		box.add_child(_center_h(_endgame_button(TEX_BT_TRYAGAIN, _on_retry)))
	box.add_child(_center_h(_endgame_button(TEX_LEVELSELECT_BTN, _on_level_select)))


func _center_h(c: Control) -> Control:
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return c


## Dragão animado da coreografia de entrada (S-08): aparece com atraso após o card
## (target_screens.md — "delayed dragon"). Sprites originais primogo/dragao_anim01..08,
## que respondem à AMB-202 (o set real é o LARANJA do runtime, não o verde de Icon/).
func _spawn_dragon() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation("fly")
	frames.set_animation_speed("fly", DRAGON_FPS)
	frames.set_animation_loop("fly", true)
	for t in DRAGON_FRAMES:
		frames.add_frame("fly", t)
	var dragon := AnimatedSprite2D.new()
	dragon.sprite_frames = frames
	dragon.position = Vector2(360, 210)   # acima do card (🟡 ajuste fino na validação)
	dragon.scale = Vector2(0.4, 0.4)      # arte nativa 733×609 → ~293×244 na tela
	dragon.modulate.a = 0.0
	_modal.add_child(dragon)
	dragon.play("fly")
	var tw := create_tween()
	tw.tween_interval(DRAGON_DELAY)
	tw.tween_property(dragon, "modulate:a", 1.0, 0.25)


func _stars_row(stars: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	for i in 3:
		var star := TextureRect.new()
		star.texture = TEX_STAR_ON if i < stars else TEX_STAR_OFF
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.custom_minimum_size = Vector2(96, 97)
		row.add_child(star)
	return row


## "⚡ {{reward}}" da variante A (DEV-007): ícone de energia original + dígitos.
func _reward_row(energy: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	var icon := TextureRect.new()
	icon.texture = TEX_ENERGY
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(34, 50)
	row.add_child(icon)
	var l := Label.new()
	l.text = str(energy)
	l.add_theme_font_override("font", GameFonts.NUMBERS)
	l.add_theme_font_size_override("font_size", 40)
	row.add_child(l)
	return row


## Botão do fim de fase no tamanho de exibição (a arte é 596×117 — nativa estoura o card).
func _endgame_button(tex: Texture2D, cb: Callable) -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = tex
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.custom_minimum_size = Vector2(380, 75)
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


func _build_pause() -> void:
	_pause = PauseOverlay.new()
	add_child(_pause)
	_pause.level_select_requested.connect(_on_level_select)
	_pause.quit_requested.connect(func() -> void: SceneRouter.go_back())


func _on_pause() -> void:
	_pause.open()   # modal de pausa real (S-07)
