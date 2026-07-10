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
## merge, anim_gelo01..05 no gelo surgindo (reverso ao derreter); balão da versão 2026
## (RES-026): aba do primordial + 8 slots com TODOS os primos acumulados em ordem
## crescente e o ATIVO destacado no próprio slot (elevado/maior/dourado); deslize
## contínuo do fogo + celebração de primo novo (a vitória ESPERA a celebração) e mago
## na derrota (2º/3º testes em dispositivo); pausa real (S-07).
## Restam 🟡 para validação visual: fine_offset da calibração e durações (COD-001).

const LEVELS_DIR := "res://resources/levels/"
const THRESHOLDS_PATH := "res://resources/balance/thresholds.tres"
const CALIBRATION_PATH := "res://resources/balance/grid_calibration.tres"

const STEP_TIME := 0.12          # pausa entre efeitos pós-deslize (🟡 COD-001)
const SLIDE_TIME_PER_CELL := 0.05  # deslize contínuo do fogo, fluido como 2048 (2º teste em dispositivo)
const EFFECT_FPS := 12.0  # anim_gelo/vapor one-shot (🟡 COD-001)
const FLAME_FPS := 8.0    # chama do player (fogo1..3 em loop)

# Balão (versão 2026, RES-026): aba à esquerda com o valor PRIMORDIAL da fase; fileira
# de 8 slots SEMPRE visível com TODOS os primos acumulados em ordem CRESCENTE (reforço
# didático da sequência); o primo ATIVO (em uso pelo fogo) fica destacado — elevado e
# maior no próprio slot (eco do tile-espelho +0,25 un. do legado, COD-007/AMB-201).
const SLOT_SIZE := 70.0
const SLOT_GAP := 6.0
const TAB_X := 8.0          # aba do valor primordial, colada à esquerda
const ROW_X := 92.0         # início da fileira de 8 slots
const TAB_RAISE := 24.0     # aba levemente acima da linha dos slots
const ACTIVE_RAISE := 18.0  # o slot ATIVO sobe ~0,25 slot (destaque do primo em uso)
const ACTIVE_SCALE := 1.18  # ... e cresce a partir do centro
const ACTIVE_TINT := Color(1.0, 0.88, 0.55)  # caixa do slot ativo aquecida (dourado)

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
const MAGE_FRAMES: Array = [
	preload("res://assets/images/mageanimation/mago_anim_01.png"),
	preload("res://assets/images/mageanimation/mago_anim_02.png"),
	preload("res://assets/images/mageanimation/mago_anim_03.png"),
	preload("res://assets/images/mageanimation/mago_anim_04.png"),
	preload("res://assets/images/mageanimation/mago_anim_05.png"),
	preload("res://assets/images/mageanimation/mago_anim_06.png"),
	preload("res://assets/images/mageanimation/mago_anim_07.png"),
]
const STAR_FX_FRAMES: Array = [   # faíscas da conquista de primo novo (mageanimation/estrela_*)
	preload("res://assets/images/mageanimation/estrela_01.png"),
	preload("res://assets/images/mageanimation/estrela_02.png"),
	preload("res://assets/images/mageanimation/estrela_03.png"),
]
const TEX_VOCETEM := preload("res://assets/images/endgame/vocetem.png")
const DRAGON_FPS := 8.0        # 🟡 COD-001
const DRAGON_DELAY := 0.25     # entrada do dragão/mago logo após o card (3º teste: 0,6 arrastava)

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
var _player_node: Node2D = null      # raiz do tile do player (alvo do deslize fluido)
var _initial_value := 0              # valor primordial da fase (aba esquerda do balão)
var _seen_values: Array[int] = []    # primos já celebrados (efeito de conquista dispara 1×)
var _conquest_tween: Tween = null    # voo do primo conquistado (a vitória espera por ele)
var _pending_endgame: Dictionary = {}  # fim de fase adiado até a animação terminar (item 3/2026)
var _budget_label: Label
var _balloon: Control
var _balloon_y := 0.0
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
	_initial_value = _player_value()
	_seen_values = adapter.match_game.collection.values()   # o primo inicial não é "novo"
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
	await _slide_player(events)   # deslize contínuo primeiro (fluido, como 2048)
	var had_effect := false
	for e in events:
		if _cue_for_event(e):
			had_effect = true
			await get_tree().create_timer(STEP_TIME).timeout
	if had_effect:
		await get_tree().create_timer(STEP_TIME).timeout   # respiro p/ o efeito aparecer
	_render_grid()  # sincroniza o visual com o estado final do domínio
	_refresh_balloon()
	if not _pending_endgame.is_empty():
		# item 3 (2026): a vitória/derrota só aparece DEPOIS da celebração do primo
		# conquistado terminar — o último primo entra no balão com o mesmo efeito dos demais
		if _conquest_tween != null and _conquest_tween.is_running():
			await _conquest_tween.finished
		var pe := _pending_endgame
		_pending_endgame = {}
		_show_endgame(bool(pe["won"]), int(pe["stars"]))
	_animating = false


## Desliza o sprite do player pelas células "moved" (+ a célula do merge) num tween
## ÚNICO e linear — antes o grid só era redesenhado no fim, com timers de 0.12s entre
## eventos, e o fogo parecia travado (achado do 2º teste em dispositivo).
func _slide_player(events: Array) -> void:
	var path: Array[Vector2i] = []
	for e in events:
		match str(e["type"]):
			"moved":
				path.append(Vector2i(e["to"]))
			"merged":
				path.append(Vector2i(e["at"]))   # o merge avança o player para o alvo
	if path.is_empty() or _player_node == null or not is_instance_valid(_player_node):
		return
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_LINEAR)
	for c in path:
		tw.tween_property(_player_node, "position", _cell_center(c.x, c.y), SLIDE_TIME_PER_CELL)
	await tw.finished


## Cada evento dispara seu som do vocabulário (BR-055) e o efeito visual one-shot
## ancorado na célula do evento; retorna true quando houve efeito visível (para o
## pequeno respiro entre eles). O redesenho do grid vem no fim.
func _cue_for_event(e: Dictionary) -> bool:
	match str(e["type"]):
		"blocked":
			AudioBus.play_effect(AudioBus.SFX_COLLISION)          # colisão não divisível
			return false
		"merged":
			AudioBus.play_effect(AudioBus.SFX_PRIME_SWAP)         # troca de primo
			if e.has("at"):
				_spawn_effect(VAPOR_FRAMES, e["at"], false)       # vapor do merge
			var v := int(e.get("collected", 0))
			if v > 0 and not _seen_values.has(v):                 # primo NOVO → celebração
				_seen_values.append(v)                            # (objetivo didático: fixar a sequência)
				_conquest_effect(v, Vector2i(e["at"]))
			return true
		"value_swapped":
			AudioBus.play_effect(AudioBus.SFX_PRIME_SWAP)
			return false
		"ice_spawned":
			AudioBus.play_effect(AudioBus.SFX_ICE_APPEAR)         # gelo surgindo
			for c in e.get("cells", []):
				_spawn_effect(ICE_ANIM_FRAMES, c, false)
			return true
		"snow_break":
			AudioBus.play_effect(AudioBus.SFX_ICE_MELT)           # gelo derretendo
			for c in e.get("melted", []):
				_spawn_effect(ICE_ANIM_FRAMES, c, true)           # derreter = reverso
			return true
	return false


## Celebração da conquista de um primo NOVO: o número pulsa grande na célula do merge,
## faíscas (estrela_01..03) irradiam e o número voa até o balão — reforço didático da
## sequência dos primos (pedido do 2º teste em dispositivo; antes só o gelo derretia).
func _conquest_effect(value: int, cell: Vector2i) -> void:
	var pos := _cell_center(cell.x, cell.y)
	AudioBus.play_effect(AudioBus.SFX_CLICK_OK)
	for i in 6:   # faíscas irradiando da célula
		var dir := Vector2.RIGHT.rotated(TAU * i / 6.0)
		var spark := _one_shot_sprite(STAR_FX_FRAMES, pos, 10.0)
		spark.animation_finished.disconnect(spark.queue_free)   # o tween é o dono da vida
		spark.scale = Vector2(2.0, 2.0)
		var stw := create_tween()
		stw.tween_property(spark, "position", pos + dir * 90.0, 0.45)
		stw.parallel().tween_property(spark, "modulate:a", 0.0, 0.45)
		stw.tween_callback(spark.queue_free)
	var d := DigitRenderer.new()   # o primo conquistado, grande, na fonte laranja
	d.font = GameFonts.TILE
	d.box_size = Vector2(140, 140)
	d.position = pos - Vector2(70, 70)
	d.pivot_offset = Vector2(70, 70)
	d.scale = Vector2(0.3, 0.3)
	d.set_value(value)
	add_child(d)
	# voa até o slot que o primo vai OCUPAR na fileira ordenada (item 4/2026)
	var sorted := adapter.match_game.collection.values()
	sorted.sort()
	var idx := maxi(sorted.find(value), 0)
	var target := Vector2(ROW_X + idx * (SLOT_SIZE + SLOT_GAP) + SLOT_SIZE / 2.0, _balloon_y) \
		- Vector2(70, 70)
	var tw := create_tween()
	tw.tween_property(d, "scale", Vector2(1.0, 1.0), 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.4)
	tw.tween_property(d, "position", target, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(d, "scale", Vector2(0.45, 0.45), 0.45)
	tw.tween_callback(d.queue_free)
	_conquest_tween = tw   # a tela de vitória espera este voo terminar (item 3/2026)


## AnimatedSprite2D one-shot na célula, no tamanho da célula; libera-se ao terminar.
func _spawn_effect(frame_textures: Array, cell: Variant, reverse: bool) -> void:
	var ordered := frame_textures.duplicate()
	if reverse:
		ordered.reverse()
	var sprite := _one_shot_sprite(ordered, _cell_center(int(cell.x), int(cell.y)), EFFECT_FPS)
	var tex: Texture2D = ordered[0]
	var s := _spacing / maxf(float(tex.get_width()), float(tex.get_height()))
	sprite.scale = Vector2(s, s)


## AnimatedSprite2D one-shot já adicionado à cena (escala padrão 1; o chamador ajusta).
func _one_shot_sprite(frame_textures: Array, pos: Vector2, fps: float) -> AnimatedSprite2D:
	var frames := SpriteFrames.new()
	frames.add_animation("fx")
	frames.set_animation_speed("fx", fps)
	frames.set_animation_loop("fx", false)
	for t in frame_textures:
		frames.add_frame("fx", t)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.position = pos
	add_child(sprite)
	sprite.animation_finished.connect(sprite.queue_free)
	sprite.play("fx")
	return sprite


# ------------------------------------------------------------------ render (skin original)

func _render_grid() -> void:
	if _board_root == null:
		_board_root = Node2D.new()
		add_child(_board_root)
	for child in _board_root.get_children():
		child.queue_free()
	_tiles.clear()
	_player_node = null
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
					_player_node = root
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
	_budget_label = Label.new()   # "XX/YY" BRANCO centrado na caixa do badge (IMG_3096 —
	# laranja sobre laranja era ilegível); começa DEPOIS do círculo do raio, que na arte
	# vai até x≈102 do HUD — o 1º dígito ficava atrás dele (3º teste em dispositivo)
	_budget_label.position = Vector2(106, 28)
	_budget_label.size = Vector2(94, 64)
	_budget_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_budget_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_budget_label.add_theme_font_override("font", FONT_TEXT)
	_budget_label.add_theme_font_size_override("font_size", 32)
	_budget_label.add_theme_color_override("font_color", Color.WHITE)
	_budget_label.add_theme_color_override("font_shadow_color", Color(0.55, 0.3, 0.05, 0.85))
	_budget_label.add_theme_constant_override("shadow_offset_x", 2)
	_budget_label.add_theme_constant_override("shadow_offset_y", 2)
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
	_balloon_y = pos.y
	_balloon = Control.new()   # faixa com posicionamento manual (layout do legado)
	_balloon.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_balloon.offset_top = pos.y - ACTIVE_RAISE - SLOT_SIZE / 2.0 - 12.0  # folga p/ o slot ativo crescido
	_balloon.offset_bottom = pos.y + SLOT_SIZE / 2.0
	_balloon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_balloon)


## Balão da versão 2026 (RES-026): aba à esquerda com o valor PRIMORDIAL (display);
## fileira de 8 slots sempre visível com TODOS os primos acumulados em ordem CRESCENTE
## (item 4 — reforço didático da sequência dos primos); o primo ATIVO fica destacado no
## próprio slot (elevado + maior + caixa dourada, itens 1/2); clicar em outro primo da
## lista troca o valor do fogo imediatamente, custando 1 energia (BR-012/013).
func _refresh_balloon() -> void:
	if _balloon == null:
		return
	for child in _balloon.get_children():
		child.queue_free()
	var row_y := ACTIVE_RAISE + 12.0   # linha-base da fileira dentro da faixa
	var current := _player_value()
	_balloon.add_child(_balloon_slot(_initial_value, Vector2(TAB_X, row_y - TAB_RAISE), false, false))
	var values := adapter.match_game.collection.values()   # ≤ 8 slots, ≤ 2 dígitos (BR-050)
	values.sort()
	var col := 0
	for value in values:
		var active := int(value) == current
		var pos := Vector2(ROW_X + col * (SLOT_SIZE + SLOT_GAP), row_y - (ACTIVE_RAISE if active else 0.0))
		_balloon.add_child(_balloon_slot(int(value), pos, not active, active))
		col += 1
	while col < 8:   # slots vazios sempre visíveis, como no legado
		_balloon.add_child(_empty_slot(Vector2(ROW_X + col * (SLOT_SIZE + SLOT_GAP), row_y)))
		col += 1


func _balloon_slot(value: int, pos: Vector2, clickable: bool, active: bool) -> Control:
	var holder := _empty_slot(pos)
	var slot := holder.get_child(0) as TextureButton
	slot.disabled = not clickable
	if clickable:
		slot.pressed.connect(_on_slot_pressed.bind(value))
	if active:   # destaque do primo em uso pelo fogo (item 2/2026)
		holder.pivot_offset = Vector2(SLOT_SIZE / 2.0, SLOT_SIZE / 2.0)
		holder.scale = Vector2(ACTIVE_SCALE, ACTIVE_SCALE)
		slot.modulate = ACTIVE_TINT
	var d := DigitRenderer.new()
	d.font = GameFonts.TILE   # balão usa OrangeFont (BalloonController.allSprites)
	d.box_size = Vector2(SLOT_SIZE - 14, SLOT_SIZE - 14)
	d.position = Vector2(7, 7)
	d.set_value(value)
	holder.add_child(d)
	return holder


func _empty_slot(pos: Vector2) -> Control:
	var holder := Control.new()
	holder.position = pos
	holder.size = Vector2(SLOT_SIZE, SLOT_SIZE)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var slot := TextureButton.new()
	slot.texture_normal = TEX_SLOT
	slot.ignore_texture_size = true
	slot.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	slot.size = Vector2(SLOT_SIZE, SLOT_SIZE)
	slot.disabled = true
	holder.add_child(slot)
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


## Os sinais terminais chegam ANTES da fila de animação (`move_resolved`) — o modal é
## ADIADO para depois do deslize + celebração do primo (item 3/2026); a escrita na
## progressão continua imediata (única porta do save, AD-04).
func _on_match_won() -> void:
	ProgressionStore.register_win(stage, level, adapter.match_game.budget, thresholds)
	var stars := StarRating.stars_for(adapter.match_game.budget, thresholds)  # GetStars(true)
	_pending_endgame = {"won": true, "stars": stars}


func _on_match_lost(_reason: String) -> void:
	ProgressionStore.register_loss(stage, level)  # reset punitivo (BR-028)
	_pending_endgame = {"won": false, "stars": 0}


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
	# pop-in rápido do card (item 5/2026: entrada dinâmica, não lenta nem estática)
	panel.pivot_offset = panel.custom_minimum_size / 2.0
	panel.scale = Vector2(0.6, 0.6)
	var pop := create_tween()
	pop.tween_property(panel, "scale", Vector2.ONE, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

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
		_spawn_character(DRAGON_FRAMES, DRAGON_FPS, Vector2(515, 1075), 0.5)   # dragão (COD-008)
	else:
		box.add_child(_center_h(_endgame_button(TEX_BT_TRYAGAIN, _on_retry)))
		_spawn_character(MAGE_FRAMES, DRAGON_FPS, Vector2(360, 1070), 0.3)   # mago da derrota
	box.add_child(_center_h(_endgame_button(TEX_LEVELSELECT_BTN, _on_level_select)))


func _center_h(c: Control) -> Control:
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return c


## Personagem animado da coreografia de fim de fase, com entrada atrasada após o card
## (target_screens.md S-08 — "delayed dragon"). Vitória = dragão laranja no canto
## inferior direito (IMG_3108, AMB-202); derrota = MAGO (mago_anim_01..07, prefab
## Canvas do legado) embaixo do card — pedido do 2º teste em dispositivo.
func _spawn_character(char_frames: Array, fps: float, pos: Vector2, char_scale: float) -> void:
	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.set_animation_speed("idle", fps)
	frames.set_animation_loop("idle", true)
	for t in char_frames:
		frames.add_frame("idle", t)
	var who := AnimatedSprite2D.new()
	who.sprite_frames = frames
	who.position = pos
	who.scale = Vector2(char_scale, char_scale)
	who.modulate.a = 0.0
	_modal.add_child(who)
	who.play("idle")
	var tw := create_tween()
	tw.tween_interval(DRAGON_DELAY)
	tw.tween_property(who, "modulate:a", 1.0, 0.25)


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


## "VOCÊ TEM: ⚡ {{reward}}" da variante A (DEV-007/IMG_3108): arte vocetem.png +
## ícone de energia original + dígitos.
func _reward_row(energy: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	var caption := TextureRect.new()   # "VOCÊ TEM:" (431×96 nativo)
	caption.texture = TEX_VOCETEM
	caption.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	caption.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	caption.custom_minimum_size = Vector2(225, 50)
	row.add_child(caption)
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
