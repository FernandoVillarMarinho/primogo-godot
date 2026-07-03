class_name LevelSelectScene
extends Control
## Feature level_select — grade paginada (S-05). Projeta o desbloqueio/estrelas do
## `domain/economy` via ProgressionStore; a entrada na fase passa pelo gate único do
## domínio (BR-033, `try_enter`), com redirect a tutorial na 1ª visita à 02-01 (BR-034) e
## balanço de recusa no contador de energia (BR-042). Índice/paginação em `LevelGrid`.
##
## VISUAL PLACEHOLDER: caixas são Button até os sprites (box/box-locked) + a bitmap font
## de seleção entrarem na validação visual contra IMG_3089.

const THRESHOLDS_PATH := "res://resources/balance/thresholds.tres"
const BOARD_SCENE := "res://features/board/game_board.tscn"
const MENU_SCENE := "res://features/main_menu/main_menu.tscn"
const TUTORIAL_SCENE := "res://features/board/game_board.tscn"  # board detecta a fase-tutorial pela identidade (T14)

var page: int = 1
var _thresholds_res: BalanceThresholds
var _banner: Label
var _energy_label: Label
var _grid_box: GridContainer


func _ready() -> void:
	_thresholds_res = ResourceLoader.load(THRESHOLDS_PATH) as BalanceThresholds
	var p := SceneRouter.consume_payload() if has_node("/root/SceneRouter") else {}
	page = LevelGrid.clamp_page(int(p.get("page", 1)))
	_build_ui()
	_render_page()
	AudioBus.play_music(AudioBus.MUSIC_LEVEL_SELECT)


# ------------------------------------------------------------------ UI

func _build_ui() -> void:
	var back := Button.new()
	back.text = "◀"
	back.position = Vector2(24, 24)
	back.pressed.connect(_on_back)
	add_child(back)

	_banner = Label.new()
	_banner.position = Vector2(260, 30)
	_banner.add_theme_font_size_override("font_size", 40)
	add_child(_banner)

	_energy_label = Label.new()   # contador de energia com ícone raio (DEV-003)
	_energy_label.position = Vector2(600, 30)
	_energy_label.add_theme_font_size_override("font_size", 40)
	add_child(_energy_label)

	var prev := Button.new()
	prev.text = "◀ Pág"
	prev.position = Vector2(40, 1160)
	prev.pressed.connect(_on_prev_page)
	add_child(prev)

	var next := Button.new()
	next.text = "Pág ▶"
	next.position = Vector2(560, 1160)
	next.pressed.connect(_on_next_page)
	add_child(next)

	_grid_box = GridContainer.new()
	_grid_box.columns = LevelGrid.COLS
	_grid_box.position = Vector2(120, 300)
	_grid_box.add_theme_constant_override("h_separation", 24)
	_grid_box.add_theme_constant_override("v_separation", 24)
	add_child(_grid_box)


func _render_page() -> void:
	_banner.text = "Nível %02d" % page          # zero à esquerda (S-05)
	_energy_label.text = "⚡ %d" % ProgressionStore.energy()
	for child in _grid_box.get_children():
		child.queue_free()
	var stage := page
	# GridContainer preenche linha a linha; a caixa em (linha,coluna) mostra a fase col*4+row.
	for row in LevelGrid.ROWS:
		for col in LevelGrid.COLS:
			_grid_box.add_child(_make_box(stage, col, row))


func _make_box(stage: int, col: int, row: int) -> Button:
	var lvl := LevelGrid.level_number(col, row)
	var is_first := col == 0 and row == 0
	var unlock := ProgressionStore.unlock_of(stage, lvl)
	var state := LevelGrid.box_state(unlock, is_first)
	var b := Button.new()
	b.custom_minimum_size = Vector2(120, 140)
	var label := str(lvl)
	if state == PlayerProgress.UnlockState.WON:
		var th := _thresholds_res.for_level(stage, lvl) if _thresholds_res != null else {}
		label += "  %d★" % ProgressionStore.stars_of(stage, lvl, th)
	elif state == PlayerProgress.UnlockState.LOCKED:
		b.disabled = true
	b.text = label
	b.pressed.connect(_on_box_pressed.bind(stage, lvl))
	return b


# ------------------------------------------------------------------ gate de entrada (BR-033/034/042)

func _on_box_pressed(stage: int, lvl: int) -> void:
	var th := _thresholds_res.for_level(stage, lvl) if _thresholds_res != null else {}
	var events := ProgressionStore.try_enter(stage, lvl, th)
	for e in events:
		match str(e["type"]):
			"entry_granted":
				SceneRouter.change_scene(BOARD_SCENE, SceneRouter.Context.BOARD,
					{"stage": stage, "level": lvl})
			"entry_redirected":
				SceneRouter.change_scene(TUTORIAL_SCENE, SceneRouter.Context.TUTORIAL,
					{"stage": stage, "level": lvl})
			"entry_refused":
				ScaleEffects.swing_refuse(_energy_label)   # BR-042


# ------------------------------------------------------------------ paginação

func _on_prev_page() -> void:
	_go_to_page(page - 1)


func _on_next_page() -> void:
	_go_to_page(page + 1)


func _go_to_page(target: int) -> void:
	var clamped := LevelGrid.clamp_page(target)
	if clamped != page:
		page = clamped
		_render_page()


func _on_back() -> void:
	SceneRouter.change_scene(MENU_SCENE, SceneRouter.Context.MENU)
