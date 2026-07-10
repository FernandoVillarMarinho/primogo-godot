class_name LevelSelectScene
extends Control
## Feature level_select — grade paginada (S-05). Projeta o desbloqueio/estrelas do
## `domain/economy` via ProgressionStore; a entrada na fase passa pelo gate único do
## domínio (BR-033, `try_enter`), com redirect a tutorial na 1ª visita à 02-01 (BR-034) e
## balanço de recusa no contador de energia (BR-042). Índice/paginação em `LevelGrid`.
##
## ARTE ORIGINAL (T20/Fase 3): fundo cenario_fases-08; banner = title-nivelNN.png por
## página (o número vem EMBUTIDO na arte — por isso não há bitmap font no banner);
## caixas = box_1.png com até 3 star_1.png + dígito na font_Select (btn_Box do legado);
## energia = icon-energy (raio, DEV-003) + dígitos na fonte numbers; navegação =
## bt-nivelanterior/bt-proximonivel sobre as bases; voltar = bt_voltar.
## ⚠️ ACHADO (registrar): existem title-nivel01..14 (14 títulos) para 10 estágios
## navegáveis (BR-037) / 12 construídos (L-04) — arte preparada para expansão.

const THRESHOLDS_PATH := "res://resources/balance/thresholds.tres"
const BOARD_SCENE := "res://features/board/game_board.tscn"
const MENU_SCENE := "res://features/main_menu/main_menu.tscn"
const TUTORIAL_SCENE := "res://features/board/game_board.tscn"  # board detecta a fase-tutorial pela identidade (T14)

const TITLE_PATH := "res://assets/images/levelselect/title-nivel%02d.png"
const TEX_BG := preload("res://assets/images/cenario_fases-08.png")
const TEX_BOX := preload("res://assets/images/levelselect/box_1.png")
const TEX_STAR := preload("res://assets/images/levelselect/star_1.png")
const TEX_ENERGY := preload("res://assets/images/endgame/icon-energy.png")  # MiniEnergy (DEV-003)
const TEX_BACK := preload("res://assets/images/levelselect/bt_voltar.png")
const TEX_PREV := preload("res://assets/images/levelselect/bt-nivelanterior.png")
const TEX_PREV_BASE := preload("res://assets/images/levelselect/bt-nivelanterior-base.png")
const TEX_NEXT := preload("res://assets/images/levelselect/bt-proximonivel.png")
const TEX_NEXT_BASE := preload("res://assets/images/levelselect/bt-proximonivel-base.png")

var page: int = 1
var _thresholds_res: BalanceThresholds
var _banner: TextureRect
var _energy_label: Label
var _energy_box: HBoxContainer
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
	var bg := TextureRect.new()
	bg.texture = TEX_BG
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var back := TextureButton.new()   # bt_voltar 175×184 nativo → 88×92
	back.texture_normal = TEX_BACK
	back.ignore_texture_size = true
	back.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	back.custom_minimum_size = Vector2(88, 92)
	back.size = Vector2(88, 92)
	back.position = Vector2(24, 24)
	back.pressed.connect(_on_back)
	add_child(back)

	_banner = TextureRect.new()   # title-nivelNN.png (487×172): número embutido na arte (S-05)
	_banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_banner.custom_minimum_size = Vector2(360, 127)
	_banner.size = Vector2(360, 127)
	_banner.position = Vector2(180, 20)   # centrado no viewport 720
	add_child(_banner)

	_energy_box = HBoxContainer.new()   # contador de energia com ícone raio (DEV-003)
	_energy_box.position = Vector2(570, 34)
	_energy_box.add_theme_constant_override("separation", 8)
	add_child(_energy_box)
	var icon := TextureRect.new()
	icon.texture = TEX_ENERGY
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(34, 50)
	_energy_box.add_child(icon)
	_energy_label = Label.new()
	_energy_label.add_theme_font_override("font", GameFonts.NUMBERS)
	_energy_label.add_theme_font_size_override("font_size", 36)
	_energy_box.add_child(_energy_label)

	add_child(_nav_button(TEX_PREV, TEX_PREV_BASE, Vector2(40, 1140), _on_prev_page))
	add_child(_nav_button(TEX_NEXT, TEX_NEXT_BASE, Vector2(590, 1140), _on_next_page))

	_grid_box = GridContainer.new()
	_grid_box.columns = LevelGrid.COLS
	_grid_box.position = Vector2(100, 280)
	_grid_box.add_theme_constant_override("h_separation", 30)
	_grid_box.add_theme_constant_override("v_separation", 30)
	add_child(_grid_box)


## Seta de navegação sobre a base laranja: os dois PNGs têm o MESMO canvas nativo
## (131×138), então precisam do mesmo retângulo de desenho — sem holder.size e sem
## EXPAND_IGNORE_SIZE a base saía do lugar (2º teste em dispositivo).
func _nav_button(tex: Texture2D, base: Texture2D, pos: Vector2, cb: Callable) -> Control:
	var holder := Control.new()
	holder.position = pos
	holder.size = Vector2(96, 96)
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


func _render_page() -> void:
	var title_path := TITLE_PATH % page
	if ResourceLoader.exists(title_path):
		_banner.texture = load(title_path)
	_energy_label.text = str(ProgressionStore.energy())
	for child in _grid_box.get_children():
		child.queue_free()
	var stage := page
	# GridContainer preenche linha a linha; a caixa em (linha,coluna) mostra a fase col*4+row.
	for row in LevelGrid.ROWS:
		for col in LevelGrid.COLS:
			_grid_box.add_child(_make_box(stage, col, row))


## Geometria da caixa da fase: box_1.png (205×230) desenhada KEEP_ASPECT_CENTERED num
## holder de 130×160. As 3 estrelas CINZAS são embutidas na arte (centros medidos no
## PNG); as douradas conquistadas se SOBREPÕEM exatamente a elas, o número vai no
## centro da área branca — correções do 2º teste em dispositivo.
const BOX_HOLDER := Vector2(130, 160)
const BOX_NATIVE := Vector2(205, 230)
const GRAY_STAR_CENTERS: Array = [Vector2(39.5, 50.5), Vector2(102.5, 37.0), Vector2(164.5, 50.5)]
const NUMBER_CENTER := Vector2(102.5, 118.0)   # centro da área branca (entre estrelas e faixa)


## Converte um ponto da arte nativa da caixa para coordenadas do holder.
func _box_art_point(p: Vector2) -> Vector2:
	var s := minf(BOX_HOLDER.x / BOX_NATIVE.x, BOX_HOLDER.y / BOX_NATIVE.y)
	return (BOX_HOLDER - BOX_NATIVE * s) / 2.0 + p * s


## Caixa da fase no padrão btn_Box do legado: box_1.png + dígito (font_Select) +
## até 3 estrelas (star_1.png); bloqueada = mesma arte esmaecida (btn_BoxLocked).
func _make_box(stage: int, col: int, row: int) -> Control:
	var lvl := LevelGrid.level_number(col, row)
	var is_first := col == 0 and row == 0
	var unlock := ProgressionStore.unlock_of(stage, lvl)
	var state := LevelGrid.box_state(unlock, is_first)

	var holder := Control.new()
	holder.custom_minimum_size = BOX_HOLDER

	var b := TextureButton.new()
	b.texture_normal = TEX_BOX
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.set_anchors_preset(Control.PRESET_FULL_RECT)
	if state == PlayerProgress.UnlockState.LOCKED:
		b.disabled = true
		b.modulate = Color(0.45, 0.45, 0.5)   # btn_BoxLocked: mesma arte esmaecida
	else:
		b.pressed.connect(_on_box_pressed.bind(stage, lvl))
	holder.add_child(b)

	var d := DigitRenderer.new()   # número da fase na fonte da seleção (font_Select)
	d.font = GameFonts.SELECT
	d.box_size = Vector2(80, 80)
	d.position = _box_art_point(NUMBER_CENTER) - Vector2(40, 40)
	d.set_value(lvl)
	holder.add_child(d)

	if state == PlayerProgress.UnlockState.WON:
		var th := _thresholds_res.for_level(stage, lvl) if _thresholds_res != null else {}
		var stars: int = ProgressionStore.stars_of(stage, lvl, th)
		for i in mini(stars, GRAY_STAR_CENTERS.size()):
			var s := TextureRect.new()   # dourada POR CIMA da cinza correspondente
			s.texture = TEX_STAR
			s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			s.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			s.size = Vector2(32, 32)
			s.position = _box_art_point(GRAY_STAR_CENTERS[i]) - Vector2(16, 16)
			holder.add_child(s)

	return holder


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
				ScaleEffects.swing_refuse(_energy_box)   # BR-042


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
