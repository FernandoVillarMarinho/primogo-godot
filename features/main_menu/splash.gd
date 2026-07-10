class_name SplashScene
extends Control
## Feature main_menu — splash (S-01). A splash_grande é a HISTÓRIA do jogo (o mago que
## lança o feitiço congelando a cidade): a câmera PASSEIA pela imagem por ~16s, exatamente
## como o clip `Splash.anim` do legado (cena SplashScreen.unity: Animation de 15,95s com
## curvas de posição + "orthographic size"/zoom). Avança ao menu após 16,5s OU por skip
## antecipado (um tiro, BR-039), via Timer real (não frame-counter). Cena inicial do jogo.

const WAIT := 16.5
const MENU_SCENE := "res://features/main_menu/main_menu.tscn"
const TEX_SPLASH := preload("res://assets/images/splashscreen/splash_grande_recovered.png")

## Passeio da câmera contando a história (~16s, mesmo ritmo do Splash.anim legado),
## RE-COREOGRAFADO para a arte recuperada: splash_grande_recovered (3258×3386) perdeu o
## quadrante superior DIREITO (branco em x ≥ ~+50, y ≤ ~-195, coords centradas).
## Regra: a janela visível (±360/zoom, ±640/zoom) nunca invade o branco.
## História NA ORDEM (3º teste em dispositivo): a TELA INTEIRA do mago lançando o
## feitiço (topo-esq) → aproximação no mago → a neve desce a encosta ATINGINDO a
## cidade/os congelados (baixo-esq) → o dragão de fogo no campo ainda verde (baixo-dir).
const KEYS: Array = [
	{"t": 0.0, "pos": Vector2(-980, -560), "zoom": 0.8},    # cena completa do mago
	{"t": 3.5, "pos": Vector2(-1030, -545), "zoom": 1.0},   # aproxima no feitiço
	{"t": 8.0, "pos": Vector2(-600, 500), "zoom": 0.85},    # a neve desce a encosta
	{"t": 11.5, "pos": Vector2(-300, 980), "zoom": 0.9},    # a cidade congelada embaixo
	{"t": 15.95, "pos": Vector2(900, 750), "zoom": 0.85},   # o dragão no verde (esperança)
]

var _done := false
var _cam: Camera2D


func _ready() -> void:
	# a música entra JUNTO com a imagem (3º teste em dispositivo): intro do menu sem
	# loop e, ao terminar, emenda no loop do menu — que segue tocando na cena do menu
	AudioBus.play_music_with_intro(AudioBus.MUSIC_MENU_INTRO, AudioBus.MUSIC_MENU)
	var art := Sprite2D.new()   # imagem da história, centrada na origem
	art.texture = TEX_SPLASH
	add_child(art)

	_cam = Camera2D.new()
	_cam.limit_left = -TEX_SPLASH.get_width() / 2      # a câmera nunca sai da imagem
	_cam.limit_right = TEX_SPLASH.get_width() / 2
	_cam.limit_top = -TEX_SPLASH.get_height() / 2
	_cam.limit_bottom = TEX_SPLASH.get_height() / 2
	_cam.position = KEYS[0]["pos"]
	_cam.zoom = Vector2.ONE * float(KEYS[0]["zoom"])
	add_child(_cam)
	_cam.make_current()
	_play_story()

	var t := Timer.new()
	t.one_shot = true
	t.wait_time = WAIT
	add_child(t)
	t.timeout.connect(_advance)
	t.start()


## Percorre os keyframes do clip legado em tempo real (posição e zoom em paralelo).
func _play_story() -> void:
	var tp := create_tween()
	var tz := create_tween()
	for i in range(1, KEYS.size()):
		var dt: float = KEYS[i]["t"] - KEYS[i - 1]["t"]
		tp.tween_property(_cam, "position", KEYS[i]["pos"] as Vector2, dt)
		tz.tween_property(_cam, "zoom", Vector2.ONE * float(KEYS[i]["zoom"]), dt)


func _unhandled_input(event: InputEvent) -> void:
	var tap := event is InputEventScreenTouch or event is InputEventMouseButton or event is InputEventKey
	if tap and event.is_pressed():
		_advance()   # skip antecipado


func _advance() -> void:
	if _done:
		return          # um tiro só (BR-039)
	_done = true
	SceneRouter.change_scene(MENU_SCENE, SceneRouter.Context.MENU)
