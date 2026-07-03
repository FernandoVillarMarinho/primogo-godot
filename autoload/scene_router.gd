extends Node
## Autoload: scene_router — navegação serializada.
##
## Troca de cena com fade (BR-041) e "Voltar" resolvido por contexto (BR-040). Funde
## `SceneController` + a máquina do `Fade` do legado. A identidade da fase viaja no
## `payload` da navegação — nunca por static global (elimina a fragilidade
## `LevelSelect.currentLevel`, D-003). O fade de transição é próprio deste autoload;
## o Fade de overlays (opções/pausa) vive em `features/shared` (Tarefa 10).
##
## Implementação da Tarefa 09 (fonte: _reversa_sdd/migration).

## Contextos de navegação. Guiam o "Voltar" (BR-040) sem depender do caminho da cena.
enum Context { NONE, SPLASH, MENU, LEVEL_SELECT, BOARD, TUTORIAL }

## Sentinela de "Voltar" que sai do app (Menu → sair, BR-040).
const QUIT := -1

## "Voltar" por contexto (BR-040): Menu → sair; Seleção → Menu; Fase/Tutorial → Seleção.
const BACK_MAP := {
	Context.MENU: QUIT,
	Context.LEVEL_SELECT: Context.MENU,
	Context.BOARD: Context.LEVEL_SELECT,
	Context.TUTORIAL: Context.LEVEL_SELECT,
	Context.SPLASH: Context.MENU,
}

const FADE_TIME := 0.3
const FADE_LAYER := 128  # acima de qualquer cena

signal scene_changed(context: int)   # emitido ao fim da transição (fade-in concluído)
signal navigation_ignored()          # pedido descartado por já haver transição em curso (BR-041)

var current_context: int = Context.NONE
var _payload: Dictionary = {}
var _transitioning: bool = false
var _context_paths: Dictionary = {}  # Context → último caminho conhecido (aprende ao navegar)

var _fade_layer: CanvasLayer
var _fade_rect: ColorRect


func _ready() -> void:
	_build_fade_overlay()


# ------------------------------------------------------------------ fade overlay

func _build_fade_overlay() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = FADE_LAYER
	add_child(_fade_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color.BLACK
	_fade_rect.color.a = 0.0
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(_fade_rect)


# ------------------------------------------------------------------ navegação

## Troca serializada de cena com fade (BR-041). `target` é um caminho `res://…tscn`
## ou um `PackedScene`. `context` classifica o destino (para o "Voltar"). `payload`
## carrega a identidade que a próxima cena vai consumir (ex.: {stage, level}).
## Retorna false e emite `navigation_ignored` se já houver uma transição em curso —
## nunca duas cargas simultâneas.
func change_scene(target: Variant, context: int, payload: Dictionary = {}) -> bool:
	if not _prepare_navigation(context, payload):
		return false
	await _fade_to(1.0)
	_swap(target)
	await _fade_to(0.0)
	_transitioning = false
	scene_changed.emit(context)
	return true


## Registra a intenção de navegar e trava a serialização. Extraído para ser testável
## sem trocar a cena de verdade (o swap real destruiria o runner de teste).
func _prepare_navigation(context: int, payload: Dictionary) -> bool:
	if _transitioning:
		navigation_ignored.emit()
		return false
	_transitioning = true
	current_context = context
	_payload = payload.duplicate(true)
	return true


func _swap(target: Variant) -> void:
	var err := OK
	if target is PackedScene:
		err = get_tree().change_scene_to_packed(target)
	else:
		var path := str(target)
		_context_paths[current_context] = path
		err = get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("scene_router: falha ao trocar de cena (%s)" % [target])


func _fade_to(alpha: float) -> void:
	if _fade_rect == null:
		return
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", alpha, FADE_TIME)
	await tw.finished


# ------------------------------------------------------------------ "Voltar" (BR-040)

## Resolve o destino do "Voltar" a partir do contexto atual (BR-040). Sem estado global:
## Menu → sai do app; Seleção → Menu; Fase/Tutorial → Seleção.
func back_target(context: int) -> int:
	return BACK_MAP.get(context, QUIT)


## Executa o "Voltar" (Escape/Back). Sai do app no Menu; senão navega ao contexto-pai
## reusando o último caminho conhecido dele. Ignorado durante uma transição (BR-041).
func go_back() -> void:
	if _transitioning:
		navigation_ignored.emit()
		return
	var target := back_target(current_context)
	if target == QUIT:
		get_tree().quit()
		return
	if _context_paths.has(target):
		change_scene(_context_paths[target], target)
	else:
		push_warning("scene_router: sem caminho conhecido para o contexto %d" % target)


# ------------------------------------------------------------------ payload

## Consome o payload da navegação (identidade da fase etc.) e o esvazia — a próxima
## cena lê aqui, não de um static (D-003).
func consume_payload() -> Dictionary:
	var p := _payload
	_payload = {}
	return p


func peek_payload() -> Dictionary:
	return _payload


func is_transitioning() -> bool:
	return _transitioning
