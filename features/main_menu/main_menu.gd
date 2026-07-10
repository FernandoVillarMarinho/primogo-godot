class_name MainMenuScene
extends Control
## Feature main_menu — menu principal (S-02). Play redireciona ao tutorial 1 na 1ª
## execução (BR-034) ou à seleção; Opções abre o overlay (BR-043); Facebook/Share atrás
## de config (AD-08, ocultos se vazio). Voltar/Escape = sair do app (BR-040, via router).
## Coreografia de entrada e oscilação do logo em tempo real (Tween — BR-044/045).
## Arte original (T20/Fase 3): céu, logo+nome com pulse, botões sobre as bases.

const LEVEL_SELECT := "res://features/level_select/level_select.tscn"
const TUTORIAL_SCENE := "res://features/board/game_board.tscn"  # board detecta a fase-tutorial pela identidade (T14)

const TEX_SKY := preload("res://assets/images/menu/cenario_ceu.png")
const TEX_LOGO := preload("res://assets/images/menu/logo.png")
const TEX_NAME := preload("res://assets/images/menu/nome.png")
const TEX_BT_PLAY := preload("res://assets/images/menu/bt-jogar.png")
const TEX_BT_PLAY_BASE := preload("res://assets/images/menu/bt-base-jogar.png")
const TEX_BT_OPTIONS := preload("res://assets/images/menu/bt-opcoes.png")
const TEX_BT_OPTIONS_BASE := preload("res://assets/images/menu/bt-base-opcoes.png")
const TEX_BT_FACEBOOK := preload("res://assets/images/menu/bt-facebook.png")
const TEX_BT_FACEBOOK_BASE := preload("res://assets/images/menu/bt-base-facebook.png")

var _social: SocialConfig
var _options: OptionsOverlay
var _credits: CreditsView
var _buttons: VBoxContainer
var _logo: Control


func _ready() -> void:
	_social = SocialConfig.new()
	_build_ui()
	AudioBus.play_music(AudioBus.MUSIC_MENU)


func _build_ui() -> void:
	var sky := TextureRect.new()
	sky.texture = TEX_SKY
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sky)

	_logo = VBoxContainer.new()   # logo.png + nome.png com pulsação (BR-045)
	_logo.position = Vector2(160, 140)
	add_child(_logo)
	for tex: Texture2D in [TEX_LOGO, TEX_NAME]:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_logo.add_child(tr)
	ScaleEffects.pulse(_logo)   # osc amortecida exata (logo_osc_value) 🟡 COD-001

	_buttons = VBoxContainer.new()
	_buttons.position = Vector2(200, 640)
	_buttons.add_theme_constant_override("separation", 24)
	add_child(_buttons)

	_buttons.add_child(_menu_button(TEX_BT_PLAY, TEX_BT_PLAY_BASE, _on_play))
	_buttons.add_child(_menu_button(TEX_BT_OPTIONS, TEX_BT_OPTIONS_BASE, _on_options))
	if _social.has_like():   # botão oculto se vazio (AD-08)
		_buttons.add_child(_menu_button(TEX_BT_FACEBOOK, TEX_BT_FACEBOOK_BASE, _on_facebook))


## Botão do menu: arte do rótulo sobre a base (bt-base-*.png do legado).
func _menu_button(tex: Texture2D, base: Texture2D, cb: Callable) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(320, 110)
	var base_rect := TextureRect.new()
	base_rect.texture = base
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


# ------------------------------------------------------------------ ações

func _on_play() -> void:
	if bool(ProgressionStore.progress.tutorial_flags.get("t1_done", false)):
		SceneRouter.change_scene(LEVEL_SELECT, SceneRouter.Context.LEVEL_SELECT)
	else:   # 1ª execução → tutorial 1 (BR-034)
		SceneRouter.change_scene(TUTORIAL_SCENE, SceneRouter.Context.TUTORIAL, {"stage": 1, "level": 0})


func _on_options() -> void:
	if _options == null:
		_options = OptionsOverlay.new()
		add_child(_options)
		_options.credits_requested.connect(_on_credits)
	_options.open()


func _on_facebook() -> void:
	if _social.has_like():
		OS.shell_open(_social.like_url)


func _on_credits() -> void:
	_options.close()
	_buttons.visible = false
	if _credits == null:
		_credits = CreditsView.new()
		_credits.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(_credits)
		_credits.credits_finished.connect(func() -> void: _buttons.visible = true)
	_credits.play()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		SceneRouter.go_back()   # Menu → sair do app (BR-040)
