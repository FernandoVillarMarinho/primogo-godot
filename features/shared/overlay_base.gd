class_name OverlayBase
extends CanvasLayer
## Feature shared — base reutilizável de overlays de opções/pausa (BR-043). Abre com
## meio-escurecimento (preto @ alpha 0,5, `color.overlay.dim`), trava anti-clique-duplo
## de 1s e emite `overlay_opened`/`overlay_closed` — substitui o static global
## `optionsActive` do legado (D-006), que outras features consultavam por polling.
## As features de opções (T13) e pausa (T11) estendem este nó.

const DIM_ALPHA := 0.5           # motion.halffade.alpha / color.overlay.dim
const CLICK_LOCK_MS := 1000      # motion.click.lock = 1 s (trava anti-clique-duplo)

signal overlay_opened()
signal overlay_closed()

var _dim: ColorRect
var _open := false
var _lock_until_ms := 0


func _ready() -> void:
	_build_dim()
	visible = false


func _build_dim() -> void:
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, DIM_ALPHA)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP  # engole cliques na cena de trás
	add_child(_dim)
	move_child(_dim, 0)  # o dim fica atrás do conteúdo do overlay


## Abre o overlay: mostra o dim, arma a trava de 1s e sinaliza. Reaberturas dentro da
## trava são ignoradas (anti-clique-duplo). Bloquear navegação = consumir o sinal.
func open() -> void:
	if _open:
		return
	_open = true
	_lock_until_ms = Time.get_ticks_msec() + CLICK_LOCK_MS
	visible = true
	overlay_opened.emit()


func close() -> void:
	if not _open:
		return
	_open = false
	visible = false
	overlay_closed.emit()


func is_open() -> bool:
	return _open


## True enquanto a trava anti-clique-duplo está ativa: os botões do overlay devem
## ignorar cliques nesse intervalo (BR-043).
func is_input_locked() -> bool:
	return Time.get_ticks_msec() < _lock_until_ms
