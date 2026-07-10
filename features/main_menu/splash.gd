class_name SplashScene
extends Control
## Feature main_menu — splash (S-01). Avança ao menu após 16,5s OU por skip antecipado
## (um tiro, BR-039), via Timer real (não frame-counter). Cena inicial do jogo.
## Arte original: splash_grande_recovered.png (T20/Fase 3).

const WAIT := 16.5
const MENU_SCENE := "res://features/main_menu/main_menu.tscn"
const TEX_SPLASH := preload("res://assets/images/splashscreen/splash_grande_recovered.png")

var _done := false


func _ready() -> void:
	var bg := TextureRect.new()
	bg.texture = TEX_SPLASH
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = WAIT
	add_child(t)
	t.timeout.connect(_advance)
	t.start()


func _unhandled_input(event: InputEvent) -> void:
	var tap := event is InputEventScreenTouch or event is InputEventMouseButton or event is InputEventKey
	if tap and event.is_pressed():
		_advance()   # skip antecipado


func _advance() -> void:
	if _done:
		return          # um tiro só (BR-039)
	_done = true
	SceneRouter.change_scene(MENU_SCENE, SceneRouter.Context.MENU)
