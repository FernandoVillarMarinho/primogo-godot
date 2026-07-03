class_name MainMenuScene
extends Control
## Feature main_menu — menu principal (S-02). Play redireciona ao tutorial 1 na 1ª
## execução (BR-034) ou à seleção; Opções abre o overlay (BR-043); Facebook/Share atrás
## de config (AD-08, ocultos se vazio). Voltar/Escape = sair do app (BR-040, via router).
## Coreografia de entrada e oscilação do logo em tempo real (Tween — BR-044/045); durações
## canônicas e assets ficam para a validação visual (COD-001/002).

const LEVEL_SELECT := "res://features/level_select/level_select.tscn"
const TUTORIAL_SCENE := "res://features/board/game_board.tscn"  # board detecta a fase-tutorial pela identidade (T14)

var _social: SocialConfig
var _options: OptionsOverlay
var _credits: CreditsView
var _buttons: VBoxContainer
var _logo: Label


func _ready() -> void:
	_social = SocialConfig.new()
	_build_ui()
	AudioBus.play_music(AudioBus.MUSIC_MENU)


func _build_ui() -> void:
	_logo = Label.new()   # placeholder do logo (Menu/logo.png) com pulsação (BR-045)
	_logo.text = "PRIMOGO"
	_logo.position = Vector2(220, 200)
	_logo.add_theme_font_size_override("font_size", 72)
	add_child(_logo)
	ScaleEffects.pulse(_logo)   # osc amortecida exata (logo_osc_value) entra na validação visual

	_buttons = VBoxContainer.new()
	_buttons.position = Vector2(260, 600)
	_buttons.add_theme_constant_override("separation", 24)
	add_child(_buttons)

	_buttons.add_child(_menu_button("JOGAR", _on_play))
	_buttons.add_child(_menu_button("OPÇÕES", _on_options))
	if _social.has_like():   # botão oculto se vazio (AD-08)
		_buttons.add_child(_menu_button("FACEBOOK", _on_facebook))


func _menu_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(200, 72)
	b.pressed.connect(cb)
	return b


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
